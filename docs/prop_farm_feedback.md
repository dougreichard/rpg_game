# Prop Farm feedback (Mac → Windows/3090 Claude)

Notes from wiring Prop Farm output into Godot levels on the Mac. Sync channel = this repo.

## 0. ⚠ Painted output isn't base-aligned / height-normalized (this was the real bug)
The **painted-track** GLB came back **origin-centred** with a **~2-unit** bbox (Y spanned
−1.0 → +1.0), NOT base-at-floor / height-1.0 like the flat track's `normalize_prop` output.
Placing it at floor level sank the **bottom half below the floor** → looked like "missing
parts" (legs/lower bench underground), and it was ~2× too tall. The flat track is fine; the
**paint pipeline's final GLB skips the base-align + height-normalize step.**
- **Mac fix (applied):** `recenter_glb.py` — transform-only normalize (base min→0, centre
  X/Y, scale to height 1.0) that **preserves vertex colours** (exports `COLOR_0` active-only;
  does NOT dissolve/reduce, so the painted palette is untouched).
- **Please fix on the Prop Farm:** run the same base-align + height-1.0 (the `normalize_prop`
  transform block) on the **painted** output too, so both tracks emit base-at-floor, height-1.0
  GLBs. Then the Mac can `prop(...)` them with a plain scale and no recenter step.

## 1. Recalculate normals before export (do this regardless of the colour approach)
The painted-track GLB (`tuning_bench`, painted) had **inconsistent face winding**: in a GLB
viewer it looks complete, but in Godot — which is **single-sided / back-face culled by
default** — chunks of the mesh **disappear** (faces whose normals point inward get culled).

- **Mac workaround (already applied):** the level material sets `cull_mode = CULL_DISABLED`
  (double-sided) so everything shows. Works, but double-siding everything is a band-aid
  (doubles overdraw, can cause lighting/normal artefacts).
- **Proper fix on the Prop Farm:** before the final GLB export, run a
  **`normals_make_consistent(inside=False)`** (Blender: recalculate normals → outside) — or
  the trimesh/equivalent — so the winding is correct and Godot can keep culling on. This is
  a **geometry** fix, independent of how colour is handled, so it's worth doing even if the
  vertex-colour step is removed.

## 2. If you remove the vertex-colour step — tell the Mac
Right now the Mac wires painted props with `_apply_vcolor` (a `StandardMaterial3D` with
`vertex_color_use_as_albedo = true`) because the painted track bakes the flat palette as
**vertex colours** (glTF `COLOR_0`). If the pipeline changes to, say, a **baked texture** or
a per-material split instead:
- The Mac wiring must change too (use the GLB's own material / texture, not `_apply_vcolor`).
- Please note the new colour representation in the SKILL.md "Preferred path" section (or here)
  so the Mac side switches the drop-in correctly. A quick line like "painted track now emits
  a texture, not COLOR_0" is enough.

## 3. Minor: poly budget
The painted `tuning_bench` came back ~40k tris (vs ~10k on the flat/dissolve track). Fine for
a hero prop, but if the painted track can target a lower budget (or expose an angle/face-cap
like `normalize_prop.py`) that'd help for set-dressing.
