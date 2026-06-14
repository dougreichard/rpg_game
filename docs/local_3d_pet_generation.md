# Local 3D pet generation — NVIDIA box guide

A recipe for generating the pet companion **base meshes** on an NVIDIA/CUDA
machine, then rigging + animating them for the game. This is the "do it properly
later" path; the game currently ships a faster stopgap (flat-shaded low-poly
billboards — see `synty_source/blender/scripts/make_pet_billboard.py`).

> All these tools output a **static mesh + texture only** — no rig, no animation.
> Generation replaces *modeling*; you still rig (Auto-Rig Pro) and animate.

---

## 1. Pick a generator (free, open, runs local on CUDA)

Best quality first. Most are **image-to-3D**, so generate a reference image first
(SD/Flux in ComfyUI) then feed it in. VRAM is approximate — check each repo's
current README.

| Tool | Quality | ~VRAM | License | Why |
|------|---------|-------|---------|-----|
| **TRELLIS** (Microsoft) | ★★★★★ | ~16 GB | **MIT** | Cleanest license for a commercial/original game; excellent geometry. **Top pick.** |
| **Hunyuan3D-2.1** (Tencent) | ★★★★★ | ~16–24 GB | Tencent community | Best textures (full PBR); turbo/low-VRAM variants exist. |
| **Hunyuan3D-2.0** | ★★★★☆ | ~10–16 GB | Tencent community | Best ComfyUI support. |
| **TripoSG** | ★★★★☆ | ~12–16 GB | open | Strong rectified-flow geometry. |
| **Stable Fast 3D (SF3D)** | ★★★☆☆ | ~7 GB | Stability community | ~1s/gen — great for fast drafts. |
| **TripoSR** | ★★★☆☆ | ~6 GB | MIT | Lightest; quick rough drafts. |

**Recommendation:** TRELLIS (license-clean) or Hunyuan3D-2.1 (best textures). Use
SF3D/TripoSR while you dial in prompts.

> **Hunyuan3D has a "Studio" style that is LOW-POLY** — use it for the pets so the
> generated meshes match the Synty look out of the box (less retopo/decimation).

## 2. Run it via ComfyUI (you already use ComfyUI)

- Start ComfyUI in a visible Terminal window (per your usual setup).
- Install the custom nodes:
  - Hunyuan3D: search Manager for **ComfyUI-Hunyuan3DWrapper** (or `ComfyUI-Hunyuan3D-2`).
  - TRELLIS: **ComfyUI-TRELLIS** wrapper.
  - Image gen for the reference: your existing SD/Flux workflow.
- Typical graph: `Load/Generate Image → (background removal) → 3D node → Save GLB/OBJ`.
- Tip: feed a **clean side or 3/4 reference image** on a plain background; remove
  the background first (rembg / SAM node) for cleaner geometry.

## 3. Prompt recipes (aim for low-poly to match Synty)

Generate the reference image with a low-poly / flat-shaded style so the result
sits next to the Synty art. Base style suffix for every prompt:

> `…, low-poly, flat shading, simple stylized 3D game asset, solid colors,
> minimal detail, neutral background, full body side view`

Per pet:
- **Frosty** — "small fluffy white schnoodle dog (schnauzer-poodle mix), …"
- **Twinkle** — "tiny pomeranian dog, fluffy, big round body, short legs, …"
- **Calvin & Coolidge** — "large white Great Pyrenees dog, thick coat, …"
  (or generate one generic dog and recolor/scale all three in Blender)
- **William & Mary** — "small rabbit, upright ears, round body, …"
- **Guinea pigs** — "guinea pig, fat oval body, tiny legs, no tail, …"
- **Lizard** — "small lizard / gecko, long body, splayed legs, long tail, …"

## 4. Clean up + style-match (Blender)

- **Decimate / retopo** if topology is dense or messy (Decimate modifier, or
  Quad Remesher). Billboards are tiny on-screen, so silhouette > detail.
- Recolor to flat solid colors if needed; apply a flat/emission-ish material so it
  reads like Synty (no harsh specular).
- Scale to roughly real proportions; keep feet on the floor (Z=0) and facing +Y.

## 5. Rig + animate with Auto-Rig Pro

- ARP *Smart* auto-detect is biped-only → for quadrupeds, append the **ARP
  quadruped** armature, position the reference bones to the mesh, then **Bind**
  (ARP auto-skin is solid even on imperfect topology; clean up weights as needed).
- Author a few short looping cycles — **idle, walk, run/charge, hurt** is plenty.
  Rough reads fine at billboard scale. Name the actions clearly.
- (Optional) Use ARP's **Remap** to retarget if you find animal animation sources.

## 6. Export for the game pipeline (the handoff to me)

Export each pet as **FBX or glTF with its animation actions baked in**, named with
these (or close) action names — the renderer maps them to the engine's anim names:

```
idle, walk, run            (run reused for "charge"/"gallop")
hurt, death                (death reused for "down")
```

Drop the exported files in **`synty_source/packs/Quaternius/`** (git-ignored).
Then I run a **clip-based billboard renderer** (`render_clip_model.py` +
`render_anim_pet.sh`) to bake 8-way animated strips into
`assets/art/pets/anim/<key>/`, scale/anchor them, and wire each companion script
to load them (replacing the stopgap billboards). Fallback chain is preserved, so
swapping in the real pets is a clean, low-risk upgrade.

---

### TL;DR
ComfyUI + **TRELLIS** (or Hunyuan3D-2.1) → low-poly reference image → mesh →
Blender cleanup → **Auto-Rig Pro** quadruped rig + a few cycles → export FBX with
actions → drop in `synty_source/packs/Quaternius/` → I bake billboards + integrate.
