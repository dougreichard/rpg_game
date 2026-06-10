#!/usr/bin/env python3
"""
Identity-reference image generator — Evan, Ben, Ethan.

Same "STEP 1" as gen_quinn_comfy_ipadapter.py / gen_erin_comfy_ipadapter.py:
one SDXL + LoRA txt2img pass per character (fixed REFERENCE_SEED) producing
a 1024x1024 "ground truth" portrait. Saved as assets/art/sprites/<name>_reference.png,
where a future gen_<name>_comfy_ipadapter.py full pipeline (mirroring Quinn's/
Erin's) will pick it up automatically as its cached IP-Adapter reference image.

Usage:
  cd ~/ComfyUI && python3.11 main.py
  python3 generators/gen_character_reference.py                  # all characters
  python3 generators/gen_character_reference.py evan ben         # subset
  python3 generators/gen_character_reference.py --regenerate evan
"""
import argparse, json, time, urllib.request, urllib.parse, io, os
from PIL import Image

COMFY_URL = "http://127.0.0.1:8188"
ROOT      = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES   = os.path.join(ROOT, "assets", "art", "sprites")

CHECKPOINT = "sd_xl_base_1.0.safetensors"
LORA       = "pixel-art-xl.safetensors"
LORA_STRENGTH = 0.70
STEPS      = 25
CFG        = 7.0
GEN_SIZE   = 1024

BASE_NEG_COMMON = (
    "multiple characters, multiple poses, reference sheet, chart, grid, "
    "photo, 3d render, realistic, blurry, noisy, gradient, anti-aliasing, "
    "colored background, gray background, grey background, tan background, "
    "beige background, shadow, "
    "extra limbs, deformed, text, watermark, "
    "second figure, duplicate character, two characters side by side, "
    "silhouette, panel, frame, border, vignette"
)

REFERENCE_POSE = "standing still front view, neutral pose, arms relaxed at sides"

# ── Per-character config ───────────────────────────────────────────────────────
CONFIGS = {
    "evan": {
        "seed": 9201,
        "pos": (
            "pixel art sprite, single character on plain white background, "
            "bold 1px black outline, flat cel shading, limited 16-color palette, "
            "teenage boy, broad wide-shouldered build, short dark hair, "
            "warm tan skin, olive green t-shirt, brown cargo shorts, "
            "brown hiking boots, bare muscular arms, "
            "full body, centered, no shadow, " + REFERENCE_POSE
        ),
        "neg": (
            "hat, glasses, coat, trench coat, jacket, long sleeves, "
            "dog, animal, gun, sword, firearm, staff, cape, hood, robes, "
            "fantasy costume, props, bag, box, furniture, extra objects"
        ),
    },
    "ben": {
        "seed": 9303,
        "pos": (
            "pixel art sprite, single character on plain white background, "
            "bold 1px black outline, flat cel shading, limited 16-color palette, "
            "teenage boy, medium build, messy brown hair, pale skin, "
            "wearing a colorful patchwork jacket covered in mismatched fabric "
            "patches of orange, green, red and navy, dark trousers, brown ankle boots, "
            "small keytar keyboard hanging across his chest on a guitar strap, "
            "both hands resting on the keytar's cyan piano keys, "
            "full body, centered, no shadow, " + REFERENCE_POSE
        ),
        "neg": (
            "hat, glasses, wrench, tool belt, dog, animal, "
            "gun, sword, firearm, staff, cape, hood, robes, fantasy costume, "
            "plain jacket, solid color jacket, leather jacket, "
            "guitar, bass guitar, electric guitar, violin, "
            "keyboard stand, music stand, easel, "
            "vignette, circle, glow, halo, spotlight, "
            "bag, box, furniture, extra objects"
        ),
    },
    "ethan": {
        "seed": 9401,
        "pos": (
            "pixel art sprite, single character on plain white background, "
            "bold 1px black outline, flat cel shading, limited 16-color palette, "
            "teenage boy, wiry lean build, short dark hair, pale skin, "
            "rectangular dark-blue AR glasses, grey hoodie, dark navy cargo pants, "
            "off-white sneakers, holding a small cyan glowing hacking device, "
            "full body, centered, no shadow, " + REFERENCE_POSE
        ),
        "neg": (
            "hat, wrench, coat, trench coat, cape, hood, robes, fantasy costume, "
            "dog, animal, gun, sword, firearm, staff, "
            "bag, box, furniture, extra objects"
        ),
    },
}

# ── ComfyUI helpers (shared with gen_quinn_comfy_ipadapter.py) ─────────────────

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

def make_reference_workflow(prompt: str, neg: str, seed: int, prefix: str) -> dict:
    """SDXL + LoRA txt2img: EmptyLatentImage -> KSampler -> VAEDecode -> Save."""
    return {
        "1": {"class_type": "CheckpointLoaderSimple",
              "inputs": {"ckpt_name": CHECKPOINT}},
        "2": {"class_type": "LoraLoader",
              "inputs": {"model": ["1", 0], "clip": ["1", 1],
                         "lora_name": LORA,
                         "strength_model": LORA_STRENGTH,
                         "strength_clip":  LORA_STRENGTH}},
        "3": {"class_type": "CLIPTextEncode",
              "inputs": {"clip": ["2", 1], "text": prompt}},
        "4": {"class_type": "CLIPTextEncode",
              "inputs": {"clip": ["2", 1], "text": neg}},
        "5": {"class_type": "EmptyLatentImage",
              "inputs": {"width": GEN_SIZE, "height": GEN_SIZE, "batch_size": 1}},
        "6": {"class_type": "KSampler",
              "inputs": {"model": ["2", 0],
                         "positive": ["3", 0], "negative": ["4", 0],
                         "latent_image": ["5", 0],
                         "seed": seed, "steps": STEPS, "cfg": CFG,
                         "sampler_name": "dpmpp_2m", "scheduler": "karras",
                         "denoise": 1.0}},
        "7": {"class_type": "VAEDecode",
              "inputs": {"samples": ["6", 0], "vae": ["1", 2]}},
        "8": {"class_type": "SaveImage",
              "inputs": {"images": ["7", 0], "filename_prefix": prefix}},
    }

def queue_prompt(wf: dict) -> str:
    return _post_json("prompt", {"prompt": wf})["prompt_id"]

def wait_for_prompt(pid: str, timeout: int = 300) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        history = _get(f"history/{pid}")
        if pid in history:
            entry = history[pid]
            if entry.get("outputs"):
                return
            status = entry.get("status", {})
            if status.get("completed"):
                raise RuntimeError(
                    f"Prompt {pid} completed with no outputs "
                    f"(status={status.get('status_str')}) — "
                    f"likely a fully-cached SaveImage; use a unique filename_prefix")
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

# ── Main ────────────────────────────────────────────────────────────────────────

def generate_reference(name: str, regenerate: bool) -> str:
    cfg = CONFIGS[name]
    ref_path = os.path.join(SPRITES, f"{name}_reference.png")
    if os.path.exists(ref_path) and not regenerate:
        print(f"{name}: cached reference exists at {ref_path} (use --regenerate to redo)")
        return ref_path

    print(f"{name}: generating identity-reference image...", end=" ", flush=True)
    wf = make_reference_workflow(cfg["pos"], f"{BASE_NEG_COMMON}, {cfg['neg']}",
                                  cfg["seed"], f"hb_{name}_ref_")
    pid = queue_prompt(wf)
    wait_for_prompt(pid)
    result = fetch_image(pid)
    os.makedirs(SPRITES, exist_ok=True)
    result.save(ref_path)
    print(f"done -> {ref_path}")
    return ref_path

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("characters", nargs="*", choices=list(CONFIGS),
                    default=list(CONFIGS),
                    help="Characters to generate (default: all)")
    ap.add_argument("--regenerate", action="store_true",
                    help="Force regenerating even if a reference image already exists.")
    args = ap.parse_args()

    print("Checking ComfyUI server...", end=" ", flush=True)
    if not check_server():
        print("NOT RUNNING\n")
        print("Start ComfyUI first:")
        print("  cd ~/ComfyUI && python3.11 main.py")
        return
    print("OK")

    names = args.characters or list(CONFIGS)
    for name in names:
        generate_reference(name, args.regenerate)

if __name__ == "__main__":
    main()
