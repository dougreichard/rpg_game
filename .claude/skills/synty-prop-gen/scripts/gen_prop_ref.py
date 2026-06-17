"""Stage 1 — Synty-style reference image(s) for a prop, via SDXL on Apple MPS.
Reuses the existing ComfyUI SDXL checkpoint (no new download). float32 on MPS
avoids the fp16 black-image bug. Writes ~/ai/refs/<name>_ref_seed<s>.png.

  conda run -n hunyuan3d python gen_prop_ref.py --name organ_console \
      --prompt "antique pipe organ, dark wooden console with keyboard and a tall bank of golden brass pipes"
"""
import argparse, os, torch
from diffusers import StableDiffusionXLPipeline

# Enforces the Synty low-poly look + a clean image-to-3D friendly framing.
# Pushes for BOLD, DISTINCT colours per material (muted refs gave muddy auto-palettes +
# hard-to-tell-apart parts) — name the colours in --prompt too (e.g. "dark walnut top,
# golden brass pipes, silver steel rods") for the strongest effect.
STYLE = (", flat shading, distinct flat colours per material, clear colour separation "
         "between parts, clean colour blocking, minimal geometric detail, Synty low-poly "
         "3D game asset style, soft even studio lighting, plain light grey seamless "
         "background, centered, whole object in frame, front three-quarter view")
NEG = ("monochrome, desaturated, muted colors, washed out, pale, grayscale, sepia, uniform "
       "single colour, realistic, photograph, photorealistic, high detail, busy background, "
       "text, watermark, logo, person, hands, blurry, cropped, dark, harsh shadows")

ap = argparse.ArgumentParser()
ap.add_argument("--name", required=True, help="asset slug, e.g. organ_console")
ap.add_argument("--prompt", required=True, help="subject description (style is appended)")
ap.add_argument("--seeds", default="11,42,777")
ap.add_argument("--neg", default=NEG)
a = ap.parse_args()

ckpt = os.path.expanduser("~/ComfyUI/models/checkpoints/sd_xl_base_1.0.safetensors")
out = os.path.expanduser("~/ai/refs"); os.makedirs(out, exist_ok=True)
device = "mps" if torch.backends.mps.is_available() else "cpu"

print(f"loading SDXL on {device} (float32) ...")
pipe = StableDiffusionXLPipeline.from_single_file(ckpt, torch_dtype=torch.float32).to(device)
pipe.enable_attention_slicing()

prompt = "low poly 3D game asset, stylized " + a.prompt.strip() + STYLE
for s in [int(x) for x in a.seeds.split(",")]:
    g = torch.Generator(device=device).manual_seed(s)
    print(f"seed {s} ...")
    img = pipe(prompt=prompt, negative_prompt=a.neg, num_inference_steps=30,
               guidance_scale=8.0, width=1024, height=1024, generator=g).images[0]
    p = os.path.join(out, f"{a.name}_ref_seed{s}.png"); img.save(p); print("saved", p)
print("DONE — review candidates in", out)
