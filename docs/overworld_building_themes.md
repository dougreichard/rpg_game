# Overworld building themes — proposal (for review, nothing baked yet)

Doug asked for more **thematic variety** in the overworld buildings (the generic City
`shop_*` / `bld_*` meshes are reused a lot). This is a survey + proposal: pick a more
fitting Synty whole-building mesh per location, then bake on approval.

## How a swap works
Each overworld building is a committed GLB in `assets/models/town/`, placed by
`overworld3d.gd` (`LOCS[i]["glb"]` + `BLD_SCALE`). Baking a new one is one command via the
existing pipeline (`synty_source/blender/scripts/export_prop.py`):

```
Blender --background --factory-startup --python export_prop.py -- \
    --fbx synty_source/packs/<PACK>/FBX/<MESH>.fbx \
    --atlas synty_source/packs/<PACK>/Textures/<ATLAS>.png \
    --out assets/models/town/<id>.glb --ground
```

Per-pack **scale gotcha** (CLAUDE.md): City = metres, Town = cm (`--scale 0.01`). Other
packs need a one-off scale check at bake time. After baking, update that location's `glb`
(and `BLD_SCALE` if the footprint needs trimming) in `overworld3d.gd`.

## Proposed mapping
All proposed FBX verified to exist (✓). "Keep" = current City mesh already reads fine.

| # | Location | Current glb | Proposed mesh | Pack | Why |
|---|----------|-------------|---------------|------|-----|
| 1 | Pipe Organ Works | shop_01 | keep (OfficeOld_Small) | City | reads as an old workshop already |
| 2 | Old Parish Church | bld_octagon | `SM_Bld_Church_01` ✓ | Town | an actual church — strong fit |
| 3 | Iron & Strings Gym | shop_02 | keep / `SM_Bld_Cafe_01` ✓ as storefront | City/CoffeeShop | optional; current shop is OK |
| 4 | Recording Studio | shop_03 | keep | City | generic storefront fine |
| 5 | The Clocktower | bld_square | `SM_Bld_WaterTower_01` ✓ (tower silhouette) | Construction | gives real vertical-tower read |
| 6 | Harbor & Docks | shop_04 | `SM_Bld_Warehouse_01` ✓ | SciFiCity | industrial dock warehouse |
| 7 | Library & Archive | bld_office_small | `SM_Bld_CityHall_01` ✓ | City | grand civic façade = library/archive |
| 8 | Carnival & Fairground | shop_05 | `SM_Bld_Stall_03` ✓ (+ HorrorCarnival props) | Adventure/HorrorCarnival | fairground stall; carnival pack has rides/fences to dress |
| 9 | Underground Tunnels | shop_06 | keep / Construction portable office | City/Construction | utilitarian entrance, fine as-is |
| 10 | Zip Line Park | bld_round | `SM_Bld_Cafe_01` ✓ or a Town shed | CoffeeShop/Town | a park kiosk/lodge reads better than a tower |
| 11 | VR Escape Room | bld_square3 | `SM_Bld_Warehouse_01` ✓ / a SciFiCity block | SciFiCity | sci-fi tech building |
| 12 | The Drop | shop_corner | `SM_Bld_Chopshop_01` ✓ | SciFiCity | gritty hideout/garage |
| 13 | Grand Marquee Cinema | bld_office_large | `SM_Bld_OfficeOld_Large_01` ✓ + marquee signage | City | grand façade; add a lit marquee prop |
| 14 | Gimme Dat Spoon (hidden **arcade**) | bld_round3 | `SM_Bld_OfficeRound_01` ✓ **+ Casino neon signage** | City + Casino | see caveat below |

## Caveat — the arcade / casino
The **Casino pack is modular** (walls, doors, trim, `Stage`, `Cowgirl_Sign`, neon signs in
`SciFiCity/OBJ/SM_Sign_Neon_*`) — there is **no single "casino building" mesh** to drop in.
Two ways to get the casino/arcade feel:
- **Quick:** keep a clean City building (`OfficeRound_01`) and bake a couple of **Casino/neon
  sign props** (`SM_Bld_Cowgirl_Sign_01`, `SciFiCity` neon signs) to mount on the façade +
  emissive glow. Low effort, gives the vibe.
- **Full:** assemble a casino façade in Blender from the Casino modular kit (walls + entrance
  + signage) and bake it as one mesh. Higher effort, best look.

Recommend the **quick** option first for the arcade, and the same signage trick for the
cinema marquee.

## Suggested first batch (highest visual payoff, all single-mesh, low risk)
`old_parish_church` (Church), `library` (CityHall), `clocktower` (WaterTower),
`harbor_docks` (Warehouse), `the_drop` (Chopshop), `carnival` (Stall). These are clean
whole-mesh swaps. The arcade/cinema signage + carnival dressing are a second pass.

> **Status:** nothing baked. Pick the rows you want and I'll bake + wire them, then capture
> each for a look before committing.
