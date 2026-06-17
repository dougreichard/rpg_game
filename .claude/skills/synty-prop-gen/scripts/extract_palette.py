"""Stage 3.55 helper — derive a vertex-colour band palette from the prop's own SDXL
reference image, so colours come from stage 1 (the real wood/brass/steel of the reference)
instead of hand-picked RGB. Masks the plain background, splits the object into N vertical
strips, takes each strip's median colour, and prints a band spec for vertex_color.py
(bottom strip -> low mesh frac). Run with the env that has numpy+PIL (hunyuan3d).

  python extract_palette.py <ref.png> [n_bands=4] [sat=1.0] [contrast=1.0]
  # prints "frac:r,g,b ..."; sat>1 punches saturation, contrast>1 spreads light/dark
  # (Synty refs are low-saturation + strips blend regions, so a hybrid sat~1.8 contrast~1.4
  #  keeps the real reference HUES but makes the zones read as distinct flat tones.)
"""
import sys, colorsys
import numpy as np
from PIL import Image

IMG = sys.argv[1]
N = int(sys.argv[2]) if len(sys.argv) > 2 else 4
SAT = float(sys.argv[3]) if len(sys.argv) > 3 else 1.0
CONTRAST = float(sys.argv[4]) if len(sys.argv) > 4 else 1.0

im = np.asarray(Image.open(IMG).convert("RGB"), dtype=float) / 255.0
H, W, _ = im.shape

# background colour = mean of the four 8x8 corners; mask out pixels close to it
c = np.concatenate([im[:8, :8].reshape(-1, 3), im[:8, -8:].reshape(-1, 3),
                    im[-8:, :8].reshape(-1, 3), im[-8:, -8:].reshape(-1, 3)])
bg = c.mean(0)
dist = np.linalg.norm(im - bg, axis=2)
mask = dist > 0.12
ys, _ = np.where(mask)
if ys.size == 0:
    print("0.5:0.5,0.5,0.5 1.0:0.6,0.6,0.6"); sys.exit(0)
ymin, ymax = ys.min(), ys.max()
h = max(ymax - ymin, 1)
rows = np.arange(H)[:, None]

bands = []
for i in range(N):                       # i=0 -> bottom of the object -> low mesh frac
    y_hi = ymax - i * h / N              # image Y is inverted (0 = top), so bottom = high Y
    y_lo = ymax - (i + 1) * h / N
    strip = mask & (rows >= y_lo) & (rows < y_hi)
    px = im[strip]
    col = np.median(px, axis=0) if px.shape[0] > 20 else bands[-1][1] if bands else bg
    bands.append(((i + 1) / N, np.clip(col, 0, 1)))

# kill grey artefacts: a strip that sampled background/shadow comes back near-grey (e.g. the
# bottom legs). Give any near-grey band the dominant (most-saturated) band's hue, keeping its
# own brightness — so grey legs become wood, not concrete.
hsvs = [colorsys.rgb_to_hsv(*c) for _, c in bands]
dom_h, dom_s, _ = max(hsvs, key=lambda t: t[1])
fixed = []
for (f, c), (h, s, v) in zip(bands, hsvs):
    if s < 0.10 and dom_s > 0.12:
        c = np.array(colorsys.hsv_to_rgb(dom_h, dom_s * 0.8, v))
    fixed.append((f, c))
bands = fixed

# hybrid punch: keep the reference hues, boost saturation + spread value around the mean so
# the bands read as distinct flat Synty tones instead of muddy mid-greys.
if SAT != 1.0 or CONTRAST != 1.0:
    vmean = float(np.mean([colorsys.rgb_to_hsv(*c)[2] for _, c in bands]))
    out = []
    for f, c in bands:
        h, s, v = colorsys.rgb_to_hsv(*c)
        s = min(1.0, s * SAT)
        v = min(1.0, max(0.0, vmean + (v - vmean) * CONTRAST))
        out.append((f, np.array(colorsys.hsv_to_rgb(h, s, v))))
    bands = out

print(" ".join(f"{f:.2f}:{c[0]:.3f},{c[1]:.3f},{c[2]:.3f}" for f, c in bands))
