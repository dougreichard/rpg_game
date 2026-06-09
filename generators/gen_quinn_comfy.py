#!/usr/bin/env python3
"""
Quinn sprite sheet generator using ComfyUI + SDXL + pixel-art LoRA.

Usage:
  1. Start ComfyUI:  cd ~/ComfyUI && python3.11 main.py --use-mps
  2. Run this:       python3.11 gen_quinn_comfy.py

Generates assets/art/sprites/quinn.png (320x544, 17 rows x 10 cols x 32x32).
"""
import json, time, urllib.request, urllib.parse, base64, io, os
from PIL import Image

COMFY_URL = "http://127.0.0.1:8188"
OUT_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                        "assets", "art", "sprites", "quinn.png")

CHECKPOINT = "sd_xl_base_1.0.safetensors"
LORA       = "pixel-art-xl.safetensors"

# ── Prompt building ────────────────────────────────────────────────────────────

BASE_POS  = ("pixel art sprite, single character, white background, "
             "bold black outline, flat cel shading, limited palette, "
             "teenage boy, slim build, black wide brim fedora hat, "
             "round wire frame glasses, long black trench coat, black boots, "
             "small brass wrench tool clipped at belt, pale skin, short dark hair, "
             "full body visible, centered in frame")
BASE_NEG  = ("gun, shotgun, firearm, pistol, rifle, sword, weapon in hand, "
             "wizard, mage, staff, robes, fantasy, magic, lantern, cape, hood, "
             "orange clothing, red clothing, white coat, brown coat, multiple views, "
             "reference sheet, photo, 3d, realistic, blurry, gradient, noise, "
             "multiple characters, background, text, watermark, extra limbs, deformed")
# SDXL native resolution — generates clean results; we pixelate in post-process
GEN_W, GEN_H = 1024, 1024

FRAMES = [
    # (row_name, pose_description, n_frames)
    ("idle",         "standing idle front view",                              6),
    ("walk_down",    "walking toward camera front view stride",               8),
    ("walk_up",      "walking away from camera back view",                    8),
    ("walk_right",   "walking right side profile view",                       8),
    ("run_down",     "running toward camera front view fast stride",          8),
    ("run_up",       "running away from camera back view fast",               8),
    ("run_right",    "running right side profile forward lean",               8),
    ("attack",       "swinging wrench attack right side profile",             6),
    ("special",      "HA laugh special arms wide open mouth front view",      8),
    ("talk",         "talking gesturing front view",                          6),
    ("talk_closeup", "talking head and shoulders closeup front view",         8),
    ("hurt",         "recoiling from hit hat tilted hurt expression",         4),
    ("down",         "crumpled fallen on floor knocked down",                 10),
    ("revive",       "rising from floor adjusting hat getting up",            8),
    ("dash",         "low lunging dash to the right coat streaming behind",   5),
    ("interact",     "crouching using wrench repair interact",                8),
    ("doorway",      "reaching forward through doorway side profile",         6),
]

T = 32  # output tile size

# ── ComfyUI workflow template ──────────────────────────────────────────────────

def make_workflow(prompt: str, neg: str, seed: int) -> dict:
    """Minimal SDXL + LoRA workflow — KSampler → VAEDecode → SaveImage."""
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
                         "seed": seed, "steps": 25, "cfg": 6.0,
                         "sampler_name": "dpmpp_2m",
                         "scheduler": "karras",
                         "denoise": 1.0}},
        "7": {"class_type": "VAEDecode",
              "inputs": {"samples": ["6", 0], "vae": ["1", 2]}},
        "8": {"class_type": "SaveImage",
              "inputs": {"images": ["7", 0], "filename_prefix": "sprite_"}},
    }

# ── ComfyUI API helpers ────────────────────────────────────────────────────────

def _post(endpoint: str, data: dict) -> dict:
    payload = json.dumps(data).encode()
    req = urllib.request.Request(
        f"{COMFY_URL}/{endpoint}", data=payload,
        headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())

def _get(endpoint: str) -> dict:
    with urllib.request.urlopen(f"{COMFY_URL}/{endpoint}", timeout=10) as r:
        return json.loads(r.read())

def queue_prompt(workflow: dict) -> str:
    """Queue a prompt and return its prompt_id."""
    resp = _post("prompt", {"prompt": workflow})
    return resp["prompt_id"]

def wait_for_prompt(prompt_id: str, timeout: int = 120) -> None:
    """Block until the queued prompt finishes."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        history = _get(f"history/{prompt_id}")
        if prompt_id in history and history[prompt_id].get("outputs"):
            return
        time.sleep(0.5)
    raise TimeoutError(f"Prompt {prompt_id} didn't finish in {timeout}s")

def fetch_image(prompt_id: str) -> Image.Image:
    """Retrieve the generated image from ComfyUI output directory."""
    history = _get(f"history/{prompt_id}")
    outputs = history[prompt_id]["outputs"]
    # Find SaveImage node output
    for node_id, node_out in outputs.items():
        if "images" in node_out:
            img_info = node_out["images"][0]
            fname    = img_info["filename"]
            subfolder = img_info.get("subfolder", "")
            params   = urllib.parse.urlencode(
                {"filename": fname, "subfolder": subfolder, "type": "output"})
            with urllib.request.urlopen(
                    f"{COMFY_URL}/view?{params}", timeout=15) as r:
                return Image.open(io.BytesIO(r.read())).convert("RGBA")
    raise RuntimeError(f"No image output found for prompt {prompt_id}")

def remove_background(img: Image.Image, threshold: int = 30) -> Image.Image:
    """Flood-fill from all four corners to remove solid background color."""
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    # Sample background color from top-left corner
    bg = px[0, 0][:3]
    visited = [[False] * h for _ in range(w)]
    stack = [(0, 0), (w-1, 0), (0, h-1), (w-1, h-1)]
    while stack:
        x, y = stack.pop()
        if x < 0 or x >= w or y < 0 or y >= h or visited[x][y]:
            continue
        visited[x][y] = True
        r, g, b, a = px[x, y]
        if all(abs(int(c) - int(bg[i])) <= threshold for i, c in enumerate((r, g, b))):
            px[x, y] = (0, 0, 0, 0)
            for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
                stack.append((x+dx, y+dy))
    return img

def to_sprite(img: Image.Image) -> Image.Image:
    """Remove background, pixelate: 1024 → 64 → 32 (nearest-neighbor)."""
    img = remove_background(img)
    w, h = img.size
    s = min(w, h)
    img = img.crop(((w - s) // 2, (h - s) // 2, (w + s) // 2, (h + s) // 2))
    img = img.resize((64, 64), Image.NEAREST)
    return img.resize((T, T), Image.NEAREST)

# ── Main generation loop ───────────────────────────────────────────────────────

def check_server() -> bool:
    try:
        _get("system_stats")
        return True
    except Exception:
        return False

def generate_frame(pose: str, seed: int) -> Image.Image:
    prompt  = f"{BASE_POS}, {pose}"
    wf      = make_workflow(prompt, BASE_NEG, seed)
    pid     = queue_prompt(wf)
    wait_for_prompt(pid)
    img     = fetch_image(pid)
    return to_sprite(img)

def main():
    print("Checking ComfyUI server...", end=" ", flush=True)
    if not check_server():
        print("NOT RUNNING")
        print("\nStart ComfyUI first:")
        print("  cd ~/ComfyUI && python3.11 main.py --use-mps")
        return
    print("OK")

    sheet = Image.new("RGBA", (T * 10, T * len(FRAMES)), (0, 0, 0, 0))
    seed  = 42

    for row, (name, pose, n_frames) in enumerate(FRAMES):
        print(f"Row {row:02d}: {name:<16} ({n_frames} frames) ", end="", flush=True)
        for col in range(n_frames):
            # Vary seed per frame for animation variety, but keep same character
            frame_seed = seed + row * 100 + col
            frame = generate_frame(pose, frame_seed)
            sheet.paste(frame, (col * T, row * T))
            print(".", end="", flush=True)
        print()

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    sheet.save(OUT_PATH)
    print(f"\nSaved {sheet.width}×{sheet.height} → {OUT_PATH}")

if __name__ == "__main__":
    main()
