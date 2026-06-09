#!/usr/bin/env python3
"""
Quinn sprite sheet — ComfyUI img2img from PIL structure frames.

Uses gen_quinn.py output as init images so every frame starts from the same
character skeleton: correct hat/coat/proportions locked by the PIL art.
ComfyUI then adds pixel-art visual quality while the structure holds.

Pipeline per frame:
  PIL frame (32x32, RGBA transparent)
    -> composite on white, upscale to 1024x1024 nearest-neighbor
    -> upload to ComfyUI, run img2img (denoise=DENOISE, fixed CHARACTER_SEED)
    -> download 1024x1024 result
    -> downscale: 1024 -> 128 -> 32 nearest-neighbor (two-pass)
    -> flood-fill background removal from all four corners
    -> paste into output sheet

Key difference from old approach:
  OLD: KSampler from empty latent, seed varies per frame -> every frame
       generates a different character from scratch.
  NEW: KSampler from PIL-encoded init latent, ONE fixed seed for all Quinn
       frames -> character identity stays consistent; only the init image
       drives pose/animation variation.

Usage:
  1. Make sure quinn.png (PIL version) is fresh:
       python3 generators/gen_quinn.py
  2. Start ComfyUI:
       cd ~/ComfyUI && python3.11 main.py --use-mps
  3. Run this:
       python3 generators/gen_quinn_comfy.py

Tunables (adjust at top of file):
  CHARACTER_SEED  -- fixed seed for ALL Quinn frames; change to explore looks
  DENOISE         -- 0.5 = very close to PIL init; 0.7 = more AI flair
  LORA_STRENGTH   -- pixel-art LoRA weight (0.6-0.8 works well)
"""
import json, time, urllib.request, urllib.parse, io, os, uuid, subprocess, sys
from PIL import Image

COMFY_URL  = "http://127.0.0.1:8188"
ROOT       = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PIL_PATH   = os.path.join(ROOT, "assets", "art", "sprites", "quinn.png")
OUT_PATH   = PIL_PATH   # overwrite with the ComfyUI-enhanced version
DEBUG_PATH = os.path.join(ROOT, "assets", "art", "sprites", "quinn_debug")

CHECKPOINT    = "sd_xl_base_1.0.safetensors"
LORA          = "pixel-art-xl.safetensors"
CHARACTER_SEED = 7142        # fixed for all Quinn frames — change to explore looks
DENOISE        = 0.60        # 0.5 = stick close to PIL; 0.7 = more creative
LORA_STRENGTH  = 0.70
STEPS          = 25
CFG            = 7.0
GEN_SIZE       = 1024        # SDXL native resolution
T              = 32          # output tile size
SAVE_DEBUG     = False       # set True to save each init + result at full size

BASE_POS = (
    "pixel art sprite, single character on plain white background, "
    "bold 1px black outline, flat cel shading, limited 16-color palette, "
    "teenage boy, slim build, all-black wide brim hat, round wire-frame glasses, "
    "long black trench coat, black work boots, brass wrench clipped at belt, "
    "pale skin, dark hair, full body, centered, no shadow"
)
BASE_NEG = (
    "multiple characters, multiple poses, reference sheet, chart, grid, "
    "photo, 3d render, realistic, blurry, noisy, gradient, anti-aliasing, "
    "colored background, shadow, colored clothing other than black, "
    "gun, sword, firearm, staff, cape, hood, robes, fantasy costume, "
    "orange coat, brown coat, white coat, extra limbs, deformed, text, watermark"
)

FRAMES = [
    # (row_name, pose_hint, n_frames)
    ("idle",         "standing still front view arms relaxed at sides",                6),
    ("walk_down",    "walking toward viewer front view mid stride",                    8),
    ("walk_up",      "walking away from viewer back view mid stride",                  8),
    ("walk_right",   "walking right side profile mid stride",                          8),
    ("run_down",     "running toward viewer front view fast stride arms pumping",      8),
    ("run_up",       "running away from viewer back view fast",                        8),
    ("run_right",    "running right side profile forward lean coat billowing",         8),
    ("attack",       "swinging wrench attack side profile arm raised follow-through",  6),
    ("special",      "HA laugh both arms spread wide head tilted back mouth open",     8),
    ("talk",         "talking gesturing hands front view slight lean",                 6),
    ("talk_closeup", "head and shoulders portrait front view talking",                 8),
    ("hurt",         "recoiling backward from impact hat askew grimace",               4),
    ("down",         "fallen on ground face-down coat spread knocked out",            10),
    ("revive",       "rising from floor one knee up adjusting hat",                    8),
    ("dash",         "low lunge dash to the right coat streaming behind",              5),
    ("interact",     "crouching both hands on wrench repairing object",                8),
    ("doorway",      "stepping through doorway side profile arms reaching forward",    6),
]

# ── ComfyUI helpers ───────────────────────────────────────────────────────────

def _get(endpoint: str) -> dict:
    with urllib.request.urlopen(f"{COMFY_URL}/{endpoint}", timeout=10) as r:
        return json.loads(r.read())

def _post_json(endpoint: str, data: dict) -> dict:
    payload = json.dumps(data).encode()
    req = urllib.request.Request(
        f"{COMFY_URL}/{endpoint}", data=payload,
        headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())

def check_server() -> bool:
    try:
        _get("system_stats")
        return True
    except Exception:
        return False

def upload_image(img: Image.Image, name: str) -> str:
    """Upload a PIL image to ComfyUI input folder, return the server filename."""
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    raw = buf.read()

    boundary = uuid.uuid4().hex
    body = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="image"; filename="{name}"\r\n'
        f"Content-Type: image/png\r\n\r\n"
    ).encode() + raw + f"\r\n--{boundary}--\r\n".encode()

    req = urllib.request.Request(
        f"{COMFY_URL}/upload/image",
        data=body,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        result = json.loads(r.read())
    return result["name"]

def make_img2img_workflow(prompt: str, neg: str, seed: int,
                          init_name: str, denoise: float) -> dict:
    """SDXL + LoRA img2img: LoadImage -> VAEEncode -> KSampler -> VAEDecode -> Save."""
    return {
        "1":  {"class_type": "CheckpointLoaderSimple",
               "inputs": {"ckpt_name": CHECKPOINT}},
        "2":  {"class_type": "LoraLoader",
               "inputs": {"model": ["1", 0], "clip": ["1", 1],
                          "lora_name": LORA,
                          "strength_model": LORA_STRENGTH,
                          "strength_clip":  LORA_STRENGTH}},
        "3":  {"class_type": "CLIPTextEncode",
               "inputs": {"clip": ["2", 1], "text": prompt}},
        "4":  {"class_type": "CLIPTextEncode",
               "inputs": {"clip": ["2", 1], "text": neg}},
        # Load the uploaded init image and encode to latent
        "5":  {"class_type": "LoadImage",
               "inputs": {"image": init_name, "upload": "image"}},
        "6":  {"class_type": "VAEEncode",
               "inputs": {"pixels": ["5", 0], "vae": ["1", 2]}},
        # img2img KSampler — same seed for every Quinn frame
        "7":  {"class_type": "KSampler",
               "inputs": {"model": ["2", 0],
                          "positive": ["3", 0], "negative": ["4", 0],
                          "latent_image": ["6", 0],
                          "seed": seed, "steps": STEPS, "cfg": CFG,
                          "sampler_name": "dpmpp_2m", "scheduler": "karras",
                          "denoise": denoise}},
        "8":  {"class_type": "VAEDecode",
               "inputs": {"samples": ["7", 0], "vae": ["1", 2]}},
        "9":  {"class_type": "SaveImage",
               "inputs": {"images": ["8", 0], "filename_prefix": "hb_quinn_"}},
    }

def queue_prompt(wf: dict) -> str:
    return _post_json("prompt", {"prompt": wf})["prompt_id"]

def wait_for_prompt(pid: str, timeout: int = 180) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        history = _get(f"history/{pid}")
        if pid in history and history[pid].get("outputs"):
            return
        time.sleep(0.5)
    raise TimeoutError(f"Prompt {pid} timed out after {timeout}s")

def fetch_image(pid: str) -> Image.Image:
    history = _get(f"history/{pid}")
    for node_out in history[pid]["outputs"].values():
        if "images" in node_out:
            info = node_out["images"][0]
            params = urllib.parse.urlencode({
                "filename": info["filename"],
                "subfolder": info.get("subfolder", ""),
                "type": "output",
            })
            with urllib.request.urlopen(
                    f"{COMFY_URL}/view?{params}", timeout=15) as r:
                return Image.open(io.BytesIO(r.read())).convert("RGBA")
    raise RuntimeError(f"No image output found for prompt {pid}")

# ── Image processing ──────────────────────────────────────────────────────────

def pil_frame_to_init(frame: Image.Image) -> Image.Image:
    """
    Prepare a 32x32 PIL sprite frame as a ComfyUI init image.
    Composites transparent frame onto white, then upscales to GEN_SIZE
    using nearest-neighbor so the pixel-art blocks stay crisp and give
    the model clear structural cues.
    """
    white = Image.new("RGBA", (T, T), (255, 255, 255, 255))
    white.paste(frame, mask=frame.split()[3])   # alpha-composite
    return white.resize((GEN_SIZE, GEN_SIZE), Image.NEAREST)

def flood_remove_bg(img: Image.Image, threshold: int = 35) -> Image.Image:
    """
    Flood-fill from all four corners to remove the near-white background
    the model generates. More reliable than global threshold on AI output
    because it only removes connected regions touching the image edges.
    """
    img = img.convert("RGBA")
    px  = img.load()
    w, h = img.size
    bg = px[0, 0][:3]
    visited = [[False] * h for _ in range(w)]
    stack = [(0, 0), (w-1, 0), (0, h-1), (w-1, h-1)]
    while stack:
        x, y = stack.pop()
        if x < 0 or x >= w or y < 0 or y >= h or visited[x][y]:
            continue
        visited[x][y] = True
        r, g, b, _ = px[x, y]
        if all(abs(int(c) - int(bg[i])) <= threshold for i, c in enumerate((r, g, b))):
            px[x, y] = (0, 0, 0, 0)
            for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
                stack.append((x+dx, y+dy))
    return img

def result_to_sprite(result: Image.Image) -> Image.Image:
    """
    Downscale ComfyUI output to 32x32 sprite.
    Two-pass nearest-neighbor (1024->128->32) gives cleaner pixel edges
    than a single jump.  Background removed after downscale so the
    flood-fill works on the smaller image (faster, fewer edge-case leaks).
    """
    mid = result.resize((128, 128), Image.NEAREST)
    small = mid.resize((T, T), Image.NEAREST)
    return flood_remove_bg(small, threshold=40)

# ── Main ──────────────────────────────────────────────────────────────────────

def ensure_pil_sprite() -> Image.Image:
    """Load PIL sprite sheet, generating it first if missing."""
    if not os.path.exists(PIL_PATH):
        print("PIL sprite not found — generating it first...")
        gen = os.path.join(ROOT, "generators", "gen_quinn.py")
        subprocess.run([sys.executable, gen], check=True)
    return Image.open(PIL_PATH).convert("RGBA")

def main() -> None:
    print("Checking ComfyUI server...", end=" ", flush=True)
    if not check_server():
        print("NOT RUNNING\n")
        print("Start ComfyUI first:")
        print("  cd ~/ComfyUI && python3.11 main.py --use-mps")
        return
    print("OK")

    pil_sheet = ensure_pil_sprite()
    sheet     = Image.new("RGBA", (T * 10, T * len(FRAMES)), (0, 0, 0, 0))

    if SAVE_DEBUG:
        os.makedirs(DEBUG_PATH, exist_ok=True)

    for row, (name, pose, n_frames) in enumerate(FRAMES):
        print(f"Row {row:02d} {name:<18} [{n_frames} frames]", flush=True)

        for col in range(n_frames):

            # Extract the matching PIL frame (already shows the correct pose)
            pil_frame = pil_sheet.crop((col * T, row * T, (col+1)*T, (row+1)*T))

            # Prepare init image: white bg + upscale to SDXL resolution
            init_img  = pil_frame_to_init(pil_frame)

            if SAVE_DEBUG:
                init_img.save(os.path.join(DEBUG_PATH, f"init_r{row:02d}_c{col:02d}.png"))

            # Upload to ComfyUI
            init_name = upload_image(init_img, f"hb_quinn_r{row:02d}_c{col:02d}.png")

            # Build prompt: base character description + pose hint for this row
            prompt = f"{BASE_POS}, {pose}"

            # Queue img2img — FIXED seed so character stays the same Quinn
            wf  = make_img2img_workflow(prompt, BASE_NEG, CHARACTER_SEED,
                                        init_name, DENOISE)
            pid = queue_prompt(wf)
            print(f"  col {col}: queued {pid[:8]}...", end=" ", flush=True)

            wait_for_prompt(pid)
            result = fetch_image(pid)

            if SAVE_DEBUG:
                result.save(os.path.join(DEBUG_PATH, f"result_r{row:02d}_c{col:02d}.png"))

            sprite = result_to_sprite(result)
            sheet.paste(sprite, (col * T, row * T))
            print("done", flush=True)
            

        print()

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    sheet.save(OUT_PATH)
    print(f"Saved {sheet.width}x{sheet.height} -> {OUT_PATH}")
    print(f"Seed used: {CHARACTER_SEED}  denoise: {DENOISE}")
    print("To try a different look, change CHARACTER_SEED at the top of this file.")

if __name__ == "__main__":
    main()
