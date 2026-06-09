#!/usr/bin/env python3
"""
Erin sprite sheet generator using ComfyUI + SDXL + pixel-art LoRA.

Usage:
  1. Ensure ComfyUI is running:  cd ~/ComfyUI && python3.11 main.py
  2. Run:  python3.11 gen_erin_comfy.py

Generates assets/art/sprites/erin.png (320x544, 17 rows x 10 cols x 32x32).

Erin: teenage girl, lithe/quick build, dark-green fitted jacket, black jeans,
scuffed sneakers, short red-auburn hair, small orange flame at fingertips.
Fastest character — animations should feel light, fast, low to ground.
"""
import json, time, urllib.request, urllib.parse, io, os
from PIL import Image

COMFY_URL  = "http://127.0.0.1:8188"
OUT_PATH   = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                          "assets", "art", "sprites", "erin.png")
CHECKPOINT = "sd_xl_base_1.0.safetensors"
LORA       = "pixel-art-xl.safetensors"
GEN_W = GEN_H = 1024
T = 32

# ── Prompts ───────────────────────────────────────────────────────────────────

BASE_POS = ("pixel art sprite, single character, white background, "
            "bold black outline, flat cel shading, limited palette, "
            "teenage girl, slim lithe build, short red auburn hair, "
            "dark green fitted jacket, black jeans, scuffed sneakers, "
            "hands slightly raised ready to move, confident mischievous expression, "
            "full body visible, centered in frame")

BASE_NEG = ("hat, glasses, coat, trench coat, wizard, mage, male, boy, "
            "gun, firearm, staff, robes, fantasy, magic, cape, hood, "
            "multiple views, reference sheet, photo, 3d, realistic, blurry, "
            "gradient, noise, multiple characters, background, text, watermark, "
            "extra limbs, deformed, ugly")

FIRE_SUFFIX = ", small orange flames at fingertips, fire ability"

FRAMES = [
    # (row_name, pose_suffix, n_frames)
    ("idle",         "standing idle front view, subtle weight shift" + FIRE_SUFFIX,                    6),
    ("walk_down",    "walking toward camera front view, light quick steps",                             8),
    ("walk_up",      "walking away from camera back view, short red hair visible",                     8),
    ("walk_right",   "walking right side profile, quick confident stride",                             8),
    ("run_down",     "sprinting toward camera front view, aggressive fast run, fastest character",      8),
    ("run_up",       "sprinting away from camera back view, near sprint",                              8),
    ("run_right",    "sprinting right side profile, aggressive forward lean, arms pumping fast",       8),
    ("attack",       "fire jab attack right, hand igniting with orange flame, punch strike" + FIRE_SUFFIX, 6),
    ("special",      "fast talk special, rapid hand gestures, leaning forward persuading, "
                     "speech bubble above head, expressive face",                                      8),
    ("stealth",      "stealth crouch walk, low crouch tiptoeing slowly, reduced height silhouette",    6),
    ("talk",         "talking full body, expressive arm gestures, leaning forward animated",           6),
    ("talk_closeup", "talking head and shoulders closeup, half smile eyebrow arch, confident",        8),
    ("hurt",         "stumbling backward recoiling from hit, red hair flicking forward, surprised",    4),
    ("down",         "falling forward knocked down, crumpled on floor, flame extinguishing",          10),
    ("revive",       "rolling to hands and knees, pushing up quickly from floor, getting up fast",    8),
    ("dash",         "low side step dodge, very low to ground lower than normal, quick dart",         5),
    ("hide",         "ducking down crouching, knees pulled in, silhouette shrinking disappearing",    6),
]

# ── ComfyUI helpers (shared with gen_quinn_comfy.py) ─────────────────────────

def _post(endpoint, data):
    payload = json.dumps(data).encode()
    req = urllib.request.Request(f"{COMFY_URL}/{endpoint}", data=payload,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())

def _get(endpoint):
    with urllib.request.urlopen(f"{COMFY_URL}/{endpoint}", timeout=10) as r:
        return json.loads(r.read())

def make_workflow(prompt, neg, seed):
    return {
        "1": {"class_type": "CheckpointLoaderSimple",
              "inputs": {"ckpt_name": CHECKPOINT}},
        "2": {"class_type": "LoraLoader",
              "inputs": {"model": ["1", 0], "clip": ["1", 1],
                         "lora_name": LORA,
                         "strength_model": 0.6, "strength_clip": 0.6}},
        "3": {"class_type": "CLIPTextEncode",
              "inputs": {"clip": ["2", 1], "text": prompt}},
        "4": {"class_type": "CLIPTextEncode",
              "inputs": {"clip": ["2", 1], "text": neg}},
        "5": {"class_type": "EmptyLatentImage",
              "inputs": {"width": GEN_W, "height": GEN_H, "batch_size": 1}},
        "6": {"class_type": "KSampler",
              "inputs": {"model": ["2", 0],
                         "positive": ["3", 0], "negative": ["4", 0],
                         "latent_image": ["5", 0],
                         "seed": seed, "steps": 25, "cfg": 7.0,
                         "sampler_name": "dpmpp_2m",
                         "scheduler": "karras",
                         "denoise": 1.0}},
        "7": {"class_type": "VAEDecode",
              "inputs": {"samples": ["6", 0], "vae": ["1", 2]}},
        "8": {"class_type": "SaveImage",
              "inputs": {"images": ["7", 0], "filename_prefix": "erin_"}},
    }

def queue_prompt(workflow):
    return _post("prompt", {"prompt": workflow})["prompt_id"]

def wait_for_prompt(prompt_id, timeout=120):
    deadline = time.time() + timeout
    while time.time() < deadline:
        history = _get(f"history/{prompt_id}")
        if prompt_id in history and history[prompt_id].get("outputs"):
            return
        time.sleep(0.5)
    raise TimeoutError(f"Prompt {prompt_id} timed out")

def fetch_image(prompt_id):
    outputs = _get(f"history/{prompt_id}")[prompt_id]["outputs"]
    for node_out in outputs.values():
        if "images" in node_out:
            info   = node_out["images"][0]
            params = urllib.parse.urlencode({"filename": info["filename"],
                                             "subfolder": info.get("subfolder", ""),
                                             "type": "output"})
            with urllib.request.urlopen(f"{COMFY_URL}/view?{params}", timeout=15) as r:
                return Image.open(io.BytesIO(r.read())).convert("RGBA")
    raise RuntimeError("No image in output")

def remove_background(img, threshold=30):
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    bg = px[0, 0][:3]
    visited = [[False] * h for _ in range(w)]
    stack = [(0,0),(w-1,0),(0,h-1),(w-1,h-1)]
    while stack:
        x, y = stack.pop()
        if x < 0 or x >= w or y < 0 or y >= h or visited[x][y]:
            continue
        visited[x][y] = True
        r, g, b, a = px[x, y]
        if all(abs(int(c)-int(bg[i])) <= threshold for i,c in enumerate((r,g,b))):
            px[x, y] = (0,0,0,0)
            for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                stack.append((x+dx,y+dy))
    return img

def to_sprite(img):
    img = remove_background(img)
    w, h = img.size
    s = min(w, h)
    img = img.crop(((w - s) // 2, (h - s) // 2, (w + s) // 2, (h + s) // 2))
    img = img.resize((64, 64), Image.NEAREST)
    return img.resize((T, T), Image.NEAREST)

def generate_frame(pose_suffix, seed):
    prompt = f"{BASE_POS}, {pose_suffix}"
    wf     = make_workflow(prompt, BASE_NEG, seed)
    pid    = queue_prompt(wf)
    wait_for_prompt(pid)
    return to_sprite(fetch_image(pid))

def check_server():
    try:
        _get("system_stats")
        return True
    except Exception:
        return False

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    print("Checking ComfyUI server...", end=" ", flush=True)
    if not check_server():
        print("NOT RUNNING")
        print("\nStart ComfyUI first:  cd ~/ComfyUI && python3.11 main.py")
        return
    print("OK")

    sheet = Image.new("RGBA", (T * 10, T * len(FRAMES)), (0, 0, 0, 0))

    for row, (name, pose, n_frames) in enumerate(FRAMES):
        print(f"Row {row:02d}: {name:<16} ({n_frames} frames) ", end="", flush=True)
        for col in range(n_frames):
            frame = generate_frame(pose, seed=1000 + row * 100 + col)
            sheet.paste(frame, (col * T, row * T))
            print(".", end="", flush=True)
        print()

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    sheet.save(OUT_PATH)
    print(f"\nSaved {sheet.width}×{sheet.height} → {OUT_PATH}")

if __name__ == "__main__":
    main()
