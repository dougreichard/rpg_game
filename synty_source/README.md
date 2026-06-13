# synty_source/ — raw Synty assets & Blender working files (NOT shipped)

This is a **local-only staging area** for the 2.5D art pipeline
(see [`docs/synty_2_5d_art_plan.md`](../docs/synty_2_5d_art_plan.md)).

- **Git:** the contents are git-ignored (only this `README.md` and `.gdignore`
  are tracked). Never commit the Synty FBX/textures — they're licensed and large.
- **Godot:** the empty `.gdignore` file tells Godot to skip this whole folder, so
  raw `.fbx`/`.blend` files are never imported by the engine. Only the **rendered
  PNGs** that get copied into `assets/art/synty/` are processed by Godot.

## Structure

```
synty_source/
  .gdignore          Empty marker — Godot skips this folder
  README.md          This file
  packs/             UNZIPPED Synty packs, one folder per pack. Currently:
                     Environment (exteriors): Town/ City/ SciFiCity/
                       Construction/ Shops/ Starter/ Casino/ Adventure/
                       Nature/ NatureBiomes_AridDesert/ NatureBiomes_MeadowForest/
                     Interiors/props: Office/ (servers, cabinets, signs)
                       SpyKit/ (Ethan gadgets) Kids/
                     Enemies/characters: CityCharacters/ GangWarfare/ Heist/
                       Mech/ (robots+bosses) HorrorCarnival/ SciFiSpace/ Knights/
                       Western/ WesternFrontier/ (priest=Father Aldric, miner/cowboy
                       =Quinn options; binary FBX). Props: LegendaryChest/ (fancy
                       loot-box upgrade candidate, fantasy-gold) -- see plan doc.
                     Interiors (cont): CoffeeShop/ (NEW, cafe/lounge)
                     Animation: AnimLocomotion/ (walk/idle/run; Sidekick + Polygon
                       rig sets). CityCharacters v2 = modern *Sidekick* rig (binary
                       FBX, ASCII issue gone) -> use Animations/Sidekick/* for it;
                       old POLYGON-rig packs -> Animations/Polygon/*.
                       -- NOTE: even matched, a bone-name CASE mismatch (UpperArm_L
                       vs upperarm_l) leaves arms at rest; clean anim needs a
                       case-normalizing retarget + Blender 5.x slotted-action API.
                       Feasible but a mini-project; static billboards remain chosen.
                     Refreshed to current versions: CityCharacters v2, Office v4,
                       Adventure v4, SpyKit v4, Knights v3.
                     2D UI: ApocalypseHUD/ (INTERFACE sprite pack — HUD reskin)
                     Pack notes: Casino is MODULAR (kit walls/neon) + multi-atlas
                       — assemble, don't expect single hero FBX. Adventure has
                       clean single-FBX Stalls/Village (good carnival booths).
                     _zips/  holds the original .zip archives (re-extract source)
                     Inside each: FBX/ (meshes), Textures/ (shared atlases),
                       and a POLYGON_<Name>_Demo.fbx demo scene.
                     NOTE: FBX/ pieces are MODULAR (walls/roofs/decks, named
                       SM_Bld_*). Complete, pre-assembled buildings live in the
                       Demo.fbx demo scene — pull whole buildings from there.
  blender/
    template.blend   Reusable render scene (ortho camera @ fixed 3/4 angle, lights)
    scripts/         Python render/batch scripts driven via Blender MCP
  renders/           Raw PNG output from Blender (intermediate).
                     Approved sprites get copied to ../assets/art/synty/
```

## Workflow (per asset)

1. Unzip a Synty pack into `packs/<PackName>/`.
2. In Blender (via the Blender MCP), import the FBX, place it in `template.blend`.
3. Render to `renders/<category>/<name>.png` (transparent, fixed angle/scale).
4. Approve, then copy into `assets/art/synty/<category>/` where Godot imports it
   with `filter=off`, `mipmaps=off`.

See the plan doc for the scale contract (32 px/tile, 1280×720, integer scaling)
and the per-location → pack mapping.
