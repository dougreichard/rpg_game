#!/usr/bin/env python3
"""
Erin sprite sheet — ComfyUI img2img from PIL structure frames.

Same pipeline as gen_quinn_comfy.py: PIL frames drive structure/pose,
ComfyUI adds visual quality, fixed CHARACTER_SEED keeps Erin consistent
across all 17 rows x n frames.

Usage:
  1. Make sure erin.png (PIL version) is fresh:
       python3 generators/gen_erin.py
  2. Start ComfyUI:
       cd ~/ComfyUI && python3.11 main.py --use-mps
  3. Run this:
       python3 generators/gen_erin_comfy.py

Tunables:  CHARACTER_SEED, DENOISE, LORA_STRENGTH (top of file)
"""
import json, time, urllib.request, urllib.parse, io, os, uuid, subprocess, sys
from PIL import Image

COMFY_URL  = "http://127.0.0.1:8188"
ROOT       = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PIL_PATH   = os.path.join(ROOT, "assets", "art", "sprites", "erin.png")
OUT_PATH   = PIL_PATH
DEBUG_PATH = os.path.join(ROOT, "assets", "art", "sprites", "erin_debug")

CHECKPOINT     = "sd_xl_base_1.0.safetensors"
LORA           = "pixel-art-xl.safetensors"
CHARACTER_SEED  = 3891        # fixed for all Erin frames
DENOISE         = 0.60
LORA_STRENGTH   = 0.70
STEPS           = 25
CFG             = 7.0
GEN_SIZE        = 1024
T               = 32
SAVE_DEBUG      = False

BASE_POS = (
    "pixel art sprite, single character on plain white background, "
    "bold 1px black outline, flat cel shading, limited 16-color palette, "
    "teenage girl, slim lithe build, short red-auburn hair, "
    "dark green fitted jacket, black jeans, scuffed sneakers, "
    "hands slightly raised ready to move, confident mischievous expression, "
    "full body, centered, no shadow"
)
BASE_NEG = (
    "multiple characters, multiple poses, reference sheet, chart, grid, "
    "photo, 3d render, realistic, blurry, noisy, gradient, anti-aliasing, "
    "colored background, shadow, hat, glasses, coat, trench coat, "
    "male, boy, gun, sword, firearm, staff, cape, hood, robes, "
    "extra limbs, deformed, text, watermark"
)
FIRE = ", small orange flame at fingertips"

FRAMES = [
    # (row_name, pose_hint, n_frames)
    ("idle",         "standing still front view arms slightly raised" + FIRE,                         6),
    ("walk_down",    "walking toward viewer front view light quick steps",                            8),
    ("walk_up",      "walking away from viewer back view short hair visible",                         8),
    ("walk_right",   "walking right side profile quick confident stride",                             8),
    ("run_down",     "sprinting toward viewer front view aggressive fast run arms pumping",            8),
    ("run_up",       "sprinting away from viewer back view near sprint",                              8),
    ("run_right",    "sprinting right side profile aggressive forward lean coat open",                 8),
    ("attack",       "fire jab punch right side profile hand igniting orange flame" + FIRE,           6),
    ("special",      "fast-talk rapid hand gestures leaning forward persuading small speech bubble",  8),
    ("stealth",      "stealth crouch walk low tiptoeing slowly reduced silhouette",                   6),
    ("talk",         "talking full body expressive arm gestures animated lean",                       6),
    ("talk_closeup", "head and shoulders portrait talking half smile eyebrow arch",                   8),
    ("hurt",         "stumbling backward recoiling hit red hair flicking forward",                    4),
    ("down",         "fallen forward on ground crumpled knocked out flame extinguishing",            10),
    ("revive",       "pushing up quickly from floor one knee up getting up fast",                     8),
    ("dash",         "low lunge dash right side profile fast forward lean",                           5),
    ("doorway",      "stepping through doorway side profile low crouch cautious",                     6),
]

# ── ComfyUI helpers (same as gen_quinn_comfy.py) ──────────────────────────────

def _get(endpoint):
    with urllib.request.urlopen(f"{COMFY_URL}/{endpoint}", timeout=10) as r:
        return json.loads(r.read())

def _post_json(endpoint, data):
    payload = json.dumps(data).encode()
    req = urllib.request.Request(
        f"{COMFY_URL}/{endpoint}", data=payload,
        headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())

def check_server():
    try:
        _get("system_stats")
        return True
    except Exception:
        return False

def upload_image(img, name):
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
        f"{COMFY_URL}/upload/image", data=body,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        method="POST")
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())["name"]

def make_img2img_workflow(prompt, neg, seed, init_name, denoise):
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
        "5":  {"class_type": "LoadImage",
               "inputs": {"image": init_name, "upload": "image"}},
        "6":  {"class_type": "VAEEncode",
               "inputs": {"pixels": ["5", 0], "vae": ["1", 2]}},
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
               "inputs": {"images": ["8", 0], "filename_prefix": "hb_erin_"}},
    }

def queue_prompt(wf):
    return _post_json("prompt", {"prompt": wf})["prompt_id"]

def wait_for_prompt(pid, timeout=180):
    deadline = time.time() + timeout
    while time.time() < deadline:
        history = _get(f"history/{pid}")
        if pid in history and history[pid].get("outputs"):
            return
        time.sleep(0.5)
    raise TimeoutError(f"Prompt {pid} timed out")

def fetch_image(pid):
    history = _get(f"history/{pid}")
    for node_out in history[pid]["outputs"].values():
        if "images" in node_out:
            info   = node_out["images"][0]
            params = urllib.parse.urlencode({
                "filename": info["filename"],
                "subfolder": info.get("subfolder", ""),
                "type": "output"})
            with urllib.request.urlopen(
                    f"{COMFY_URL}/view?{params}", timeout=15) as r:
                return Image.open(io.BytesIO(r.read())).convert("RGBA")
    raise RuntimeError(f"No image for {pid}")

# ── Image processing ──────────────────────────────────────────────────────────

def pil_frame_to_init(frame):
    white = Image.new("RGBA", (T, T), (255, 255, 255, 255))
    white.paste(frame, mask=frame.split()[3])
    return white.resize((GEN_SIZE, GEN_SIZE), Image.NEAREST)

def flood_remove_bg(img, threshold=40):
    img = img.convert("RGBA")
    px  = img.load()
    w, h = img.size
    bg = px[0, 0][:3]
    visited = [[False] * h for _ in range(w)]
    stack = [(0,0),(w-1,0),(0,h-1),(w-1,h-1)]
    while stack:
        x, y = stack.pop()
        if x < 0 or x >= w or y < 0 or y >= h or visited[x][y]:
            continue
        visited[x][y] = True
        r, g, b, _ = px[x, y]
        if all(abs(int(c)-int(bg[i])) <= threshold for i,c in enumerate((r,g,b))):
            px[x, y] = (0,0,0,0)
            for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                stack.append((x+dx, y+dy))
    return img

def result_to_sprite(result):
    mid   = result.resize((128, 128), Image.NEAREST)
    small = mid.resize((T, T), Image.NEAREST)
    return flood_remove_bg(small)

def ensure_pil_sprite():
    if not os.path.exists(PIL_PATH):
        print("PIL sprite not found — generating it first...")
        gen = os.path.join(ROOT, "generators", "gen_erin.py")
        subprocess.run([sys.executable, gen], check=True)
    return Image.open(PIL_PATH).convert("RGBA")

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
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
            pil_frame = pil_sheet.crop((col*T, row*T, (col+1)*T, (row+1)*T))
            init_img  = pil_frame_to_init(pil_frame)

            if SAVE_DEBUG:
                init_img.save(os.path.join(DEBUG_PATH, f"init_r{row:02d}_c{col:02d}.png"))

            init_name = upload_image(init_img, f"hb_erin_r{row:02d}_c{col:02d}.png")
            prompt    = f"{BASE_POS}, {pose}"
            wf        = make_img2img_workflow(prompt, BASE_NEG, CHARACTER_SEED,
                                              init_name, DENOISE)
            pid       = queue_prompt(wf)
            print(f"  col {col}: queued {pid[:8]}...", end=" ", flush=True)
            wait_for_prompt(pid)
            result = fetch_image(pid)

            if SAVE_DEBUG:
                result.save(os.path.join(DEBUG_PATH, f"result_r{row:02d}_c{col:02d}.png"))

            sprite = result_to_sprite(result)
            sheet.paste(sprite, (col*T, row*T))
            print("done", flush=True)
        print()

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    sheet.save(OUT_PATH)
    print(f"Saved {sheet.width}x{sheet.height} -> {OUT_PATH}")
    print(f"Seed used: {CHARACTER_SEED}  denoise: {DENOISE}")

if __name__ == "__main__":
    main()
