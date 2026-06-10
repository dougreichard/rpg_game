#!/usr/bin/env python3
"""
Erin sprite sheet — ComfyUI img2img + IP-Adapter identity conditioning.

"Option B" approach (see gen_quinn_comfy_ipadapter.py for the prototype and
full rationale): a fixed-seed img2img pass alone (gen_erin_comfy.py) can
drift in character identity across frames. This adds an IP-Adapter identity
reference image alongside the existing PIL pose-frame structure guidance.

Pipeline:
  STEP 1 — generate ONE reference image of Erin via txt2img (SDXL + LoRA,
           fixed REFERENCE_SEED). This is the "ground truth" Erin.
  STEP 2 — for every animation frame:
           PIL pose frame (32x32) -> composite on white, upscale to 1024
             -> img2img init image (structure/pose guidance)
           reference image -> IP-Adapter (identity/style guidance)
           Both feed the same KSampler: VAEEncode(init) for the latent,
           IPAdapterAdvanced(reference) patches the model before sampling.
           -> downscale 1024 -> 128 -> 32, flood-fill bg removal, paste.

Requires (one-time setup, already done for this project):
  ~/ComfyUI/custom_nodes/ComfyUI_IPAdapter_plus/
  ~/ComfyUI/models/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors
  ~/ComfyUI/models/ipadapter/ip-adapter-plus_sdxl_vit-h.safetensors

Usage:
  cd ~/ComfyUI && python3.11 main.py
  python3 generators/gen_erin_comfy_ipadapter.py                # full run
  python3 generators/gen_erin_comfy_ipadapter.py --ref-only     # just make/preview the reference image
  python3 generators/gen_erin_comfy_ipadapter.py --rows idle,walk_down --max-frames-per-row 2
"""
import argparse, json, time, urllib.request, urllib.parse, io, os, uuid, subprocess, sys
from PIL import Image

COMFY_URL  = "http://127.0.0.1:8188"
ROOT       = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PIL_PATH   = os.path.join(ROOT, "assets", "art", "sprites", "erin.png")
OUT_PATH   = PIL_PATH   # overwrite with the ComfyUI-enhanced version
PLACEHOLDER_PATH = os.path.join(ROOT, "assets", "art", "sprites", "erin_placeholder.png")
REF_PATH   = os.path.join(ROOT, "assets", "art", "sprites", "erin_reference.png")
DEBUG_PATH = os.path.join(ROOT, "assets", "art", "sprites", "erin_debug_ip")

CHECKPOINT     = "sd_xl_base_1.0.safetensors"
LORA           = "pixel-art-xl.safetensors"
CLIP_VISION    = "CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"
IPADAPTER_FILE = "ip-adapter-plus_sdxl_vit-h.safetensors"

CHARACTER_SEED = 3891        # fixed for all per-frame img2img passes (matches gen_erin_comfy.py)
REFERENCE_SEED = 9002        # fixed seed for the one identity-reference image
DENOISE        = 0.72        # 0.5 = stick close to PIL; 0.7 = more creative
LORA_STRENGTH  = 0.70
IP_WEIGHT      = 0.75        # IP-Adapter identity strength
IP_WEIGHT_TYPE = "style transfer"    # linear | style transfer | composition | ...
STEPS          = 25
CFG            = 7.0
GEN_SIZE       = 1024        # SDXL native resolution
T              = 32          # output tile size
SAVE_DEBUG     = False        # set True to save each init + result at full size

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
    "colored background, gray background, grey background, tan background, "
    "beige background, shadow, hat, glasses, coat, trench coat, "
    "male, boy, gun, sword, firearm, staff, cape, hood, robes, fantasy costume, "
    "extra limbs, deformed, text, watermark, "
    "props, bag, box, furniture, extra objects, "
    "second figure, duplicate character, two characters side by side, "
    "silhouette, panel, frame, border, vignette"
)
FIRE = ", small orange flame at fingertips"
REFERENCE_POSE = "standing still front view, neutral pose"

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

def make_reference_workflow(prompt: str, neg: str, seed: int) -> dict:
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
              "inputs": {"images": ["7", 0], "filename_prefix": "hb_erin_ref_"}},
    }

def make_img2img_ipadapter_workflow(prompt: str, neg: str, seed: int,
                                     init_name: str, ref_name: str,
                                     denoise: float, prefix: str) -> dict:
    """
    SDXL + LoRA img2img, with IP-Adapter identity conditioning from the
    reference image patched onto the model before sampling:
      LoadImage(init) -> VAEEncode -> latent
      LoadImage(ref) + CLIPVisionLoader + IPAdapterModelLoader
        -> IPAdapterAdvanced(model) -> patched model
      patched model + latent -> KSampler -> VAEDecode -> Save
    """
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
        # Pose-structure init image
        "5":  {"class_type": "LoadImage",
               "inputs": {"image": init_name, "upload": "image"}},
        "6":  {"class_type": "VAEEncode",
               "inputs": {"pixels": ["5", 0], "vae": ["1", 2]}},
        # IP-Adapter identity conditioning from the reference image
        "10": {"class_type": "CLIPVisionLoader",
               "inputs": {"clip_name": CLIP_VISION}},
        "11": {"class_type": "IPAdapterModelLoader",
               "inputs": {"ipadapter_file": IPADAPTER_FILE}},
        "12": {"class_type": "LoadImage",
               "inputs": {"image": ref_name, "upload": "image"}},
        "13": {"class_type": "IPAdapterAdvanced",
               "inputs": {"model": ["2", 0],
                          "ipadapter": ["11", 0],
                          "image": ["12", 0],
                          "weight": IP_WEIGHT,
                          "weight_type": IP_WEIGHT_TYPE,
                          "combine_embeds": "average",
                          "start_at": 0.0, "end_at": 1.0,
                          "embeds_scaling": "V only",
                          "clip_vision": ["10", 0]}},
        # img2img KSampler — patched model + pose-init latent, fixed seed
        "7":  {"class_type": "KSampler",
               "inputs": {"model": ["13", 0],
                          "positive": ["3", 0], "negative": ["4", 0],
                          "latent_image": ["6", 0],
                          "seed": seed, "steps": STEPS, "cfg": CFG,
                          "sampler_name": "dpmpp_2m", "scheduler": "karras",
                          "denoise": denoise}},
        "8":  {"class_type": "VAEDecode",
               "inputs": {"samples": ["7", 0], "vae": ["1", 2]}},
        "9":  {"class_type": "SaveImage",
               "inputs": {"images": ["8", 0], "filename_prefix": prefix}},
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

def ensure_placeholder_sprite() -> Image.Image:
    """
    Load the pristine placeholder sprite sheet — the source of pose-frame
    structure guidance for every run. Generated once and never overwritten by
    this script, so re-running on the same rows/cols (e.g. while tuning
    DENOISE/IP_WEIGHT) always starts each frame from the same clean
    placeholder instead of compounding on a previous AI-rendered frame.
    """
    if not os.path.exists(PLACEHOLDER_PATH):
        print("Placeholder baseline not found — generating via gen_erin.py...")
        gen = os.path.join(ROOT, "generators", "gen_erin.py")
        subprocess.run([sys.executable, gen], check=True)
        os.makedirs(os.path.dirname(PLACEHOLDER_PATH), exist_ok=True)
        Image.open(PIL_PATH).convert("RGBA").save(PLACEHOLDER_PATH)
    return Image.open(PLACEHOLDER_PATH).convert("RGBA")

def generate_reference(regenerate: bool) -> Image.Image:
    """Generate (or load cached) the single Erin identity-reference image."""
    if os.path.exists(REF_PATH) and not regenerate:
        print(f"Using cached reference image: {REF_PATH}")
        return Image.open(REF_PATH).convert("RGBA")

    print("Generating Erin identity-reference image...", end=" ", flush=True)
    prompt = f"{BASE_POS}, {REFERENCE_POSE}"
    wf = make_reference_workflow(prompt, BASE_NEG, REFERENCE_SEED)
    pid = queue_prompt(wf)
    wait_for_prompt(pid)
    result = fetch_image(pid)
    os.makedirs(os.path.dirname(REF_PATH), exist_ok=True)
    result.save(REF_PATH)
    print(f"done -> {REF_PATH}")
    return result

RUN_ID = uuid.uuid4().hex[:8]  # forces fresh SaveImage outputs even if a frame's inputs were cached from a prior run

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ref-only", action="store_true",
                    help="Generate (or regenerate) the reference image and exit.")
    ap.add_argument("--regenerate-ref", action="store_true",
                    help="Force regenerating the reference image even if cached.")
    ap.add_argument("--rows", type=str, default=None,
                    help="Comma-separated list of FRAMES row names to process (default: all).")
    ap.add_argument("--max-frames-per-row", type=int, default=None,
                    help="Cap the number of columns processed per row (for quick tests).")
    args = ap.parse_args()

    print("Checking ComfyUI server...", end=" ", flush=True)
    if not check_server():
        print("NOT RUNNING\n")
        print("Start ComfyUI first:")
        print("  cd ~/ComfyUI && python3.11 main.py")
        return
    print("OK")

    reference = generate_reference(args.regenerate_ref or args.ref_only)
    if args.ref_only:
        return

    ref_name = upload_image(reference, "hb_erin_reference.png")

    placeholder_sheet = ensure_placeholder_sprite()
    if os.path.exists(OUT_PATH):
        sheet = Image.open(OUT_PATH).convert("RGBA")  # resume, preserving prior AI-rendered rows
    else:
        sheet = Image.new("RGBA", placeholder_sheet.size, (0, 0, 0, 0))
        sheet.paste(placeholder_sheet, (0, 0))

    selected_rows = set(args.rows.split(",")) if args.rows else None

    if SAVE_DEBUG:
        os.makedirs(DEBUG_PATH, exist_ok=True)

    for row, (name, pose, n_frames) in enumerate(FRAMES):
        if selected_rows is not None and name not in selected_rows:
            continue

        cols = n_frames if args.max_frames_per_row is None else min(n_frames, args.max_frames_per_row)
        print(f"Row {row:02d} {name:<18} [{cols}/{n_frames} frames]", flush=True)

        for col in range(cols):

            # Extract the matching PIL frame from the pristine placeholder (already shows the correct pose)
            pil_frame = placeholder_sheet.crop((col * T, row * T, (col+1)*T, (row+1)*T))

            # Prepare init image: white bg + upscale to SDXL resolution
            init_img  = pil_frame_to_init(pil_frame)

            if SAVE_DEBUG:
                init_img.save(os.path.join(DEBUG_PATH, f"init_r{row:02d}_c{col:02d}.png"))

            # Upload to ComfyUI
            init_name = upload_image(init_img, f"hb_erin_ip_r{row:02d}_c{col:02d}.png")

            # Build prompt: base character description + pose hint for this row
            prompt = f"{BASE_POS}, {pose}"

            # Queue img2img + IP-Adapter — fixed seed, identity locked by reference image
            wf  = make_img2img_ipadapter_workflow(prompt, BASE_NEG, CHARACTER_SEED,
                                                   init_name, ref_name, DENOISE,
                                                   f"hb_erin_ip_r{row:02d}_c{col:02d}_{RUN_ID}_")
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

        # Checkpoint after each row so a late failure doesn't lose earlier rows
        os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
        sheet.save(OUT_PATH)

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    sheet.save(OUT_PATH)
    print(f"Saved {sheet.width}x{sheet.height} -> {OUT_PATH}")
    print(f"Reference: {REF_PATH}  seed: {REFERENCE_SEED}")
    print(f"Per-frame seed: {CHARACTER_SEED}  denoise: {DENOISE}  ip_weight: {IP_WEIGHT} ({IP_WEIGHT_TYPE})")

if __name__ == "__main__":
    main()
