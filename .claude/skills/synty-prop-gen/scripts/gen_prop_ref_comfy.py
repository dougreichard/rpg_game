"""Stage 1 (ComfyUI/CUDA variant) — Synty-style reference image(s) for a prop, via SDXL on a
local ComfyUI server (fp16, fast). Mirrors gen_prop_ref.py's prompt/STYLE, but adds two CUDA-only
upgrades driven through the ComfyUI HTTP API:
  --style-image  : IPAdapter — lock a whole prop set to one visual style (set consistency).
  --control-image: depth ControlNet — constrain silhouette/framing from a source image.
Both are optional; with neither, it's a plain fast SDXL txt2img.

  conda run -n comfyui python gen_prop_ref_comfy.py --name organ_console \
      --prompt "antique pipe organ, dark wooden console, tall bank of golden brass pipes" \
      [--style-image refs/prev_prop.png] [--control-image sketch.png] [--seed 11]

Requires the ComfyUI server running (main.py --listen 127.0.0.1 --port 8188).
"""
import argparse, json, os, sys, time, uuid, urllib.request, urllib.parse, io, mimetypes

# IMPORTANT: image-to-3D needs ONE centered object. SDXL otherwise tends to TILE the subject
# into a grid (a field of barrels / pins), which Hunyuan then reconstructs as a featureless cube.
# The single-object emphasis + strong anti-tiling negatives below are load-bearing.
_PROP = (", a single isolated object, ONE object only, the complete whole object centered "
         "with a small margin of empty background around it, full object visible, not "
         "cropped, not cut off, front three-quarter view, flat shading, distinct flat "
         "colours per material, clear colour separation between parts, clean colour "
         "blocking, minimal geometric detail, Synty low-poly 3D game asset style, soft "
         "even studio lighting, plain light grey background")
_CHARACTER = (", a single full-body humanoid game character standing in a symmetrical T-pose with "
              "both arms straight out to the sides, front view, the entire body visible from head to "
              "feet, feet flat on the ground, neutral expression, flat shading, distinct flat colours "
              "per material, clean colour blocking, Synty low-poly 3D game character style, soft even "
              "studio lighting, plain light grey background")
_CREATURE = (", a single full-body creature, the entire body visible head to tail, standing in a "
             "neutral relaxed pose, front three-quarter view, flat shading, distinct flat colours, "
             "Synty low-poly 3D game style, soft even studio lighting, plain light grey background")
STYLES = {"prop": _PROP, "character": _CHARACTER, "creature": _CREATURE}

_NEG = ("grid, tiled, tiling, pattern, repeated, repeating, multiple objects, many objects, "
        "two objects, several, collection, set, array, rows, columns, collage, montage, "
        "contact sheet, sprite sheet, thumbnails, duplicated, photorealistic, busy texture, "
        "clutter, text, watermark, harsh shadows, dark background, cropped, cut off")
_NEG_FIG = (", sitting, crouching, kneeling, action pose, dynamic pose, walking, running, "
            "cropped legs, cut off feet, cut off head, close-up, portrait crop")
NEGS = {"prop": _NEG, "character": _NEG + _NEG_FIG + ", multiple characters, two people, crowd",
        "creature": _NEG + _NEG_FIG + ", multiple creatures, herd"}
# back-compat aliases
STYLE = _PROP
NEG = _NEG

ap = argparse.ArgumentParser()
ap.add_argument("--name", required=True)
ap.add_argument("--prompt", required=True)
ap.add_argument("--kind", choices=["prop", "character", "creature"], default="prop",
                help="style/framing: prop (3/4 object) · character (full-body T-pose) · creature")
ap.add_argument("--negative", default=None)
ap.add_argument("--seed", type=int, default=11)
# 16 steps (was 30): the reference is throwaway — it only needs a clean, single-object,
# colour-blocked silhouette for Hunyuan, not finished art. dpmpp_2m karras converges fast.
# (A 4-8 step SDXL-Lightning/Turbo LoRA would cut this further, but none is installed.)
ap.add_argument("--steps", type=int, default=16)
ap.add_argument("--cfg", type=float, default=7.0)
ap.add_argument("--count", type=int, default=1,
                help="generate N candidates at DISTINCT seeds (seed, seed+1, …, seed+N-1), one "
                     "image per seed. The caller ranks them and pins the winning seed; that seed "
                     "+ --count 1 reproduces the exact image (batch-index noise would not).")
# Portrait default (832x1216): SDXL base TILES props into a grid at square 1024x1024 (barrels,
# pins) which Hunyuan then cubes — a tall frame can't tile a grid, so it yields one object.
ap.add_argument("--width", type=int, default=832)
ap.add_argument("--height", type=int, default=1216)
ap.add_argument("--ckpt", default="sd_xl_base_1.0.safetensors")
ap.add_argument("--style-image", default=None, help="IPAdapter style reference")
ap.add_argument("--ip-weight", type=float, default=0.7)
ap.add_argument("--ip-preset", default="STANDARD (medium strength)")
ap.add_argument("--control-image", default=None, help="depth ControlNet source")
ap.add_argument("--cn-strength", type=float, default=0.6)
ap.add_argument("--controlnet", default="controlnet-depth-sdxl-1.0.safetensors")
ap.add_argument("--server", default="127.0.0.1:8188")
ap.add_argument("--out-dir", default=os.path.expanduser("~/ai/refs"))
a = ap.parse_args()

BASE = f"http://{a.server}"

def upload_image(path):
    """POST an image to ComfyUI's /upload/image; returns the server-side filename."""
    path = os.path.abspath(os.path.expanduser(path))
    fname = os.path.basename(path)
    boundary = "----comfyref" + uuid.uuid4().hex
    with open(path, "rb") as f:
        data = f.read()
    ctype = mimetypes.guess_type(path)[0] or "image/png"
    body = io.BytesIO()
    def w(s): body.write(s.encode() if isinstance(s, str) else s)
    w(f"--{boundary}\r\n")
    w(f'Content-Disposition: form-data; name="image"; filename="{fname}"\r\n')
    w(f"Content-Type: {ctype}\r\n\r\n"); w(data); w("\r\n")
    w(f"--{boundary}\r\n")
    w('Content-Disposition: form-data; name="overwrite"\r\n\r\ntrue\r\n')
    w(f"--{boundary}--\r\n")
    req = urllib.request.Request(f"{BASE}/upload/image", data=body.getvalue(),
                                 headers={"Content-Type": f"multipart/form-data; boundary={boundary}"})
    r = json.load(urllib.request.urlopen(req))
    name = r["name"] if not r.get("subfolder") else f"{r['subfolder']}/{r['name']}"
    print("uploaded", path, "->", name)
    return name

# ---- build the API prompt graph ----
g = {}
g["4"] = {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": a.ckpt}}
g["6"] = {"class_type": "CLIPTextEncode", "inputs": {"text": a.prompt + STYLES[a.kind], "clip": ["4", 1]}}
g["7"] = {"class_type": "CLIPTextEncode", "inputs": {"text": a.negative or NEGS[a.kind], "clip": ["4", 1]}}
g["5"] = {"class_type": "EmptyLatentImage", "inputs": {"width": a.width, "height": a.height, "batch_size": 1}}

model_ref = ["4", 0]
if a.style_image:
    style_name = upload_image(a.style_image)
    g["10"] = {"class_type": "IPAdapterUnifiedLoader", "inputs": {"model": ["4", 0], "preset": a.ip_preset}}
    g["11"] = {"class_type": "LoadImage", "inputs": {"image": style_name}}
    g["12"] = {"class_type": "IPAdapterAdvanced", "inputs": {
        "model": ["10", 0], "ipadapter": ["10", 1], "image": ["11", 0],
        "weight": a.ip_weight, "weight_type": "linear", "combine_embeds": "concat",
        "start_at": 0.0, "end_at": 1.0, "embeds_scaling": "V only"}}
    model_ref = ["12", 0]

pos_ref, neg_ref = ["6", 0], ["7", 0]
if a.control_image:
    ctrl_name = upload_image(a.control_image)
    g["13"] = {"class_type": "LoadImage", "inputs": {"image": ctrl_name}}
    g["14"] = {"class_type": "DepthAnythingV2Preprocessor", "inputs": {"image": ["13", 0], "resolution": 1024}}
    g["15"] = {"class_type": "ControlNetLoader", "inputs": {"control_net_name": a.controlnet}}
    g["16"] = {"class_type": "ControlNetApplyAdvanced", "inputs": {
        "positive": ["6", 0], "negative": ["7", 0], "control_net": ["15", 0], "image": ["14", 0],
        "strength": a.cn_strength, "start_percent": 0.0, "end_percent": 1.0}}
    pos_ref, neg_ref = ["16", 0], ["16", 1]

g["3"] = {"class_type": "KSampler", "inputs": {
    "model": model_ref, "seed": a.seed, "steps": a.steps, "cfg": a.cfg,
    "sampler_name": "dpmpp_2m", "scheduler": "karras",
    "positive": pos_ref, "negative": neg_ref, "latent_image": ["5", 0], "denoise": 1.0}}
g["8"] = {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}}
g["9"] = {"class_type": "SaveImage", "inputs": {"images": ["8", 0], "filename_prefix": f"ref_{a.name}"}}

os.makedirs(os.path.expanduser(a.out_dir), exist_ok=True)


def run_one(seed):
    """Queue one generation at `seed` (batch_size 1), wait, save -> {name}_ref_seed{seed}.png.
    Distinct-seed (not batch-index) so the winner is reproducible by seed alone."""
    g["3"]["inputs"]["seed"] = seed
    client_id = uuid.uuid4().hex
    req = urllib.request.Request(f"{BASE}/prompt", data=json.dumps({"prompt": g, "client_id": client_id}).encode(),
                                 headers={"Content-Type": "application/json"})
    pid = json.load(urllib.request.urlopen(req))["prompt_id"]
    t0 = time.time()
    while True:
        hist = json.load(urllib.request.urlopen(f"{BASE}/history/{pid}"))
        if pid in hist:
            break
        if time.time() - t0 > 600:
            print("TIMEOUT seed", seed); sys.exit(1)
        time.sleep(1.0)
    dst = os.path.join(os.path.expanduser(a.out_dir), f"{a.name}_ref_seed{seed}.png")
    for out in hist[pid]["outputs"].values():
        for img in out.get("images", []):
            q = urllib.parse.urlencode({"filename": img["filename"], "subfolder": img.get("subfolder", ""), "type": img.get("type", "output")})
            data = urllib.request.urlopen(f"{BASE}/view?{q}").read()
            with open(dst, "wb") as f:
                f.write(data)
            print("saved", dst, f"({len(data)//1024} KB, {time.time()-t0:.0f}s)")
            return dst
    return None


print("queuing", a.count, "candidate(s)", "(IPAdapter)" if a.style_image else "", "(ControlNet)" if a.control_image else "")
T0 = time.time()
saved = [p for p in (run_one(a.seed + i) for i in range(a.count)) if p]
print(f"done in {time.time()-T0:.0f}s ->", saved)
