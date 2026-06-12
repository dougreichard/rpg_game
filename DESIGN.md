# DESIGN.md — Hunkle Bunkle Visual Design

This document consolidates the project's **visual design language** — color
palettes, art-generation conventions, UI styling, and on-screen feedback
(telegraphs/FX) — in one place. It complements, but doesn't replace:

- **`sprites.md`** — the authoritative spec for character/enemy/animal sprite
  sheets (the 16-color PICO-8 palette, ligne-claire style guide, per-character
  designs, and AI-prompt blocks for generating real art).
- **`CLAUDE.md`** — project-wide mechanical conventions, per-location
  implementation notes, and the full rollout history. Color values quoted here
  are pulled from the live `.gd`/`.tres` source; if the two ever disagree,
  the source is correct and this file should be updated.

---

## 1. Pixel grid & viewport

> **Target spec (current generation).** This section describes the viewport
> and room scale all *new* work should target. The 13 existing location
> scenes were authored at the previous 1280×720 / 640×360 spec (see
> "Migration note" below) — bringing them up to this spec is tracked as a
> separate follow-up pass, not part of this document update.

- **Tile size (gameplay grid):** 32×32 px — collision, `TileMap` cells, and
  level-layout math (`FLOOR_COLS`/`FLOOR_ROWS`, wall placement, prop
  positions) are all still expressed in this grid. Unchanged from before —
  bumping the viewport does not change how levels are built.
- **Character sprite (gameplay footprint):** still occupies one 32×32 tile
  (Brute and the Boss break this — see below). **Source art resolution is now
  64×64 px per frame** (2× oversample) so characters render with finer linework
  and shading at the larger viewport — see §3/§4 and `sprites.md`.
- **Viewport:** **1920×1080**, with `Camera2D.zoom = Vector2(2, 2)` — every
  level is authored at **960×540 "logical" pixels** and rendered at 2×.
- **Room footprint:** every level is built from a shared **960×540 base room**
  (1.5× the previous 640×360), expanded per-location into a bespoke multi-room
  layout (see CLAUDE.md "Doorways, camera-follow & multi-room levels").
  `FLOOR_COLS`/`FLOOR_ROWS` scale with each location's bounding box at
  `room_px / 32` (rounded up) — a 960×540 base room is `30 × 17` tiles.
- **Exceptions to 32×32 (gameplay tile):**
  - **Brute** — 48×32 px tile (wider silhouette for a bigger, slower enemy).
  - **Boss (Clockwork Guardian)** — 64×64 px tile (used at both Clocktower and
    Grand Marquee Cinema).
  - **Sentry projectile** — 16×16 px tile.
  - **Item icons** — 16×16 px (`InventoryPanel`).
  - Source-art canvases for these double the same way as the 32×32 case
    (96×64, 128×128, 32×32, 32×32 respectively) — see `sprites.md`.

### Migration note (1280×720 → 1920×1080)

The 13 shipped locations, the overworld map, and all UI panel positions
(`InventoryPanel` at `(1112, 136)`, `DuoPanel` at `(1112, 16)`, etc.) were
built against the 1280×720 / 640×360 / 20×12-tile spec and remain correct
*as-is* — nothing breaks by leaving them alone. Recomputing room bounding
boxes, camera limits, `FLOOR_COLS`/`FLOOR_ROWS`, and absolute UI positions for
the new 1920×1080 / 960×540 / 30×17-tile spec across all 13 locations is a
larger follow-up effort, deliberately out of scope here. New locations and any
future visual-rework pass should target the new spec from the start.

---

## 2. Color palette system

Two palette systems coexist:

1. **Sprite art (`sprites.md`)** — an **extended ~32-color palette** (§2.0)
   shared by every character/enemy/animal/NPC sheet, plus each
   character/enemy/location's own accent color from §2.1–§2.4 and its
   `.lightened()`/`.darkened()` variants. This **replaces the old fixed
   16-color PICO-8 palette** — sprite art is no longer constrained to a single
   retro swatch set, and is free to use richer shading/highlight ramps.
2. **Procedural/runtime art (`PlaceholderArt`)** — environment tiles, walls,
   props, gates, and item icons are generated at runtime from arbitrary
   `Color` values (always unconstrained), each derived from a per-location
   "base" color via `.lightened()`/`.darkened()` — see §4.

### 2.0 Extended sprite palette

The shared base palette every sprite sheet draws from — neutrals, skin/hair
tones, and a spread of saturated accent colors for clothing, FX, and glyphs.
It is intentionally broader and more vibrant than a single retro 8-bit set:
artists should pick the closest swatch and may use `.lightened()`/
`.darkened()` steps from it (or from a character's own accent color, §2.1) to
build a 2–3 step shading ramp per shape — flat single-tone fills are no longer
the goal.

| Group | Swatches (hex) |
|-------|----------------|
| Ink / outline | `#1A1A22` (soft ink — replaces pure `#000000` for linework) |
| Neutrals | `#2E2E3A` `#5C5C6E` `#A8A8B8` `#F4F0E6` `#FFFFFF` |
| Skin tones | `#FFE3C7` `#F2C49B` `#D9A36E` `#8A5A3C` |
| Hair tones | `#18141A` `#4A2E1C` `#9C5A2E` `#B8814B` |
| Reds / corals | `#E13B4A` `#FF6B5C` |
| Oranges / ambers | `#FF9A3C` `#FFC94D` |
| Yellows | `#FFE066` |
| Greens | `#4FB05C` `#2E7D4F` |
| Teals / aquas | `#4FD1C5` `#1F7A78` |
| Blues | `#4D9CE6` `#2F4A99` `#5ED6FF` |
| Purples / magentas | `#8C6FD1` `#C2528C` |
| Browns / olives | `#9C8A4E` `#6E4A2E` |
| Pinks | `#FF9CC2` |
| Steel | `#6E7A86` |

This palette is descriptive, not exclusive — a character or location's own
accent color (§2.1–§2.4) always takes priority for *that* character/location's
signature hue, with this set filling in everything else (skin, hair, neutrals,
shared FX colors like fire/cyan-tech/sound-wave glyphs).

### 2.1 Character sprite colors (`data/characters/*.tres: sprite_color`)

| Character | Color | Hex (approx) |
|-----------|-------|--------------|
| Quinn | `Color(0.3, 0.45, 0.85)` | `#4D73D9` blue |
| Erin | `Color(0.9, 0.35, 0.1)` | `#E6591A` orange |
| Evan | `Color(0.55, 0.42, 0.18)` | `#8C6B2E` olive/khaki |
| Ben | `Color(0.75, 0.25, 0.55)` | `#BF408C` magenta |
| Ethan | `Color(0.2, 0.65, 0.6)` | `#33A699` teal |

### 2.2 Enemy sprite colors (`data/enemies/*.tres: sprite_color`)

| Enemy | Color | Hex (approx) |
|-------|-------|--------------|
| Grunt | `Color(0.38, 0.32, 0.28)` | `#615247` drab brown |
| Runner | `Color(0.5, 0.18, 0.62)` | `#802E9E` purple |
| Brute | `Color(0.45, 0.2, 0.18)` | `#73332E` dark red |
| Sentry | `Color(0.3, 0.55, 0.65)` | `#4D8CA6` steel blue |
| Boss | `Color(0.5, 0.12, 0.55)` | `#801F8C` deep magenta |

### 2.3 Per-location floor palettes (`FLOOR_BASE_COLOR` / `FLOOR_ACCENT_COLOR`)

Every level's `_build_floor()` paints a 2-tone tile grid
(`PlaceholderArt.make_level_tileset(base, accent)`) with walls colored via
`FLOOR_BASE_COLOR.darkened(0.35)`. Palette is the primary per-location visual
identity signal — chosen to evoke each location's setting:

| # | Location | `FLOOR_BASE_COLOR` | `FLOOR_ACCENT_COLOR` | Identity |
|---|----------|--------------------|----------------------|----------|
| 1 | Bellows & Sons Pipe Organ Works | `(0.32, 0.29, 0.27)` | `(0.6, 0.48, 0.22)` | warm workshop wood/brass |
| 2 | The Old Parish Church | `(0.60, 0.58, 0.52)` | `(0.75, 0.72, 0.60)` | cool stone + candlelight |
| 3 | Iron & Strings Gym | `(0.28, 0.26, 0.26)` | `(0.62, 0.30, 0.26)` | industrial grey + iron-red |
| 4 | The Recording Studio | `(0.32, 0.27, 0.24)` | `(0.55, 0.40, 0.30)` | warm acoustic-foam tones |
| 5 | The Clocktower | `(0.32, 0.30, 0.27)` | `(0.62, 0.52, 0.28)` | aged brass/gear tones |
| 6 | The Harbor & Docks | `(0.28, 0.31, 0.33)` | `(0.45, 0.55, 0.50)` | cool dock grey/sea green |
| 7 | The Public Library & Archive | `(0.34, 0.30, 0.25)` | `(0.58, 0.48, 0.32)` | warm wood/parchment |
| 8 | The Carnival & Fairground | `(0.34, 0.29, 0.33)` | `(0.78, 0.55, 0.24)` | midway purple + marquee gold |
| 9 | The Underground Tunnels | `(0.20, 0.20, 0.19)` | `(0.38, 0.35, 0.28)` | dark earthy tones |
| 10 | Zip Line Park | `(0.27, 0.33, 0.26)` | `(0.55, 0.50, 0.30)` | outdoor green + rope-tan |
| 11 | VR Escape Room (base) | `(0.21, 0.25, 0.32)` | `(0.30, 0.65, 0.70)` | cyber-blue + glitch-cyan |
| 11a | — Stage Alpha overlay | `(0.34, 0.27, 0.17)` | `(0.62, 0.50, 0.28)` | "medieval" amber/stone |
| 11b | — Stage Beta overlay | `(0.14, 0.32, 0.36)` | `(0.30, 0.64, 0.62)` | "underwater" teal/aqua |
| 12 | The Drop | `(0.36, 0.34, 0.30)` | `(0.58, 0.40, 0.30)` | dusty landing-zone tan |
| 13 | The Grand Marquee Cinema | `(0.30, 0.21, 0.23)` | `(0.72, 0.55, 0.28)` | theater red + gold |

VR Escape Room is the only location with **layered palettes**: a base
cyber-blue `TileMap` plus two stage-specific `TileMap`s
(`_paint_stage_floor()`) drawn on top over each stage's footprint — crossing a
corridor visibly recolors the floor underfoot.

### 2.4 Per-location prop/gate/companion accent colors

Beyond the floor palette, several locations define one-off accent colors for
collidable props (the "cosmetic-to-collider" gates) and summoned companions:

| Location | Const | Color | Use |
|----------|-------|-------|-----|
| Iron & Strings Gym | `FROSTY_COLOR` | `(0.95, 0.95, 0.95)` | Frosty companion |
| Carnival | `BACKSTAGE_GATE_COLOR` | `(0.5, 0.18, 0.4)` | velvet curtain gate |
| Carnival | `DOUG_POSTER_COLOR` | `(0.75, 0.65, 0.5)` | hidden poster reveal |
| Harbor & Docks | `CALVIN_COLOR` | `(0.96, 0.96, 0.92)` | Calvin companion |
| Harbor & Docks | `COOLIDGE_COLOR` | `(0.90, 0.88, 0.80)` | Coolidge companion |
| Harbor & Docks | `MAZE_CRATE_COLOR` | `(0.5, 0.36, 0.16)` | maze obstacle crates |
| Underground Tunnels | `FROSTY_COLOR` | `(0.95, 0.95, 0.95)` | Twinkle's summon reuses Frosty's palette name |
| The Drop | `FROSTY_COLOR` | `(0.95, 0.95, 0.95)` | (legacy const, unused companion) |
| The Drop | `WILLIAM_COLOR` | `(0.82, 0.78, 0.72)` | William companion |
| The Drop | `MARY_COLOR` | `(0.70, 0.62, 0.56)` | Mary companion |
| Old Parish Church | `PEW_COLOR` | `(0.30, 0.20, 0.12)` | pew benches |

Gate/door props (`BoothDoor`, `Container`, `LibrarianDesk`, `Barbell`, etc.)
that don't define their own const reuse `FLOOR_ACCENT_COLOR` or a
`.darkened()`/`.lightened()` variant of `FLOOR_BASE_COLOR` via
`PlaceholderArt.make_gate_texture()` — see §4.

---

## 3. Style guide (sprite art)

From `sprites.md` — applies to every player, animal, enemy, and NPC sheet:

- **Art style:** Clean, high-readability modern pixel art — inspired by
  *Stranger Things: 1984*'s character-swapping promo aesthetic: crisp
  silhouettes, soft directional shading with 2–3 step gradients/highlights for
  real volume (not flat single-tone cel-shading), grounded teen-adventure
  character designs. More vibrant and detailed than the project's earlier flat
  ligne-claire look — see `gem/` (below) for the target fidelity.
- **Reference sheets:** `gem/quinn.png`, `gem/erin.png`, `gem/evan.png`,
  `gem/ben.png`, `gem/ethan.png` (plus the animal-companion sheets in the same
  folder) are the canonical visual targets for the five player characters —
  match their level of detail, shading, and color richness when generating or
  revising sprite sheets.
- **Perspective:** top-down, ~¾ overhead.
- **Proportions (64×64 source frame):** head ≈20px, torso ≈20px, legs ≈24px —
  same 1:1:1.2 ratio as before, doubled for the higher-resolution canvas (still
  renders into one 32×32 gameplay tile).
- **Eyes:** 4×4px white square + 2×2px dark pupil, plus simple eyebrows/mouth
  shapes where the larger canvas allows — still the primary face-reading
  device.
- **Background:** fully transparent.
- **Mirroring rule:** left-facing walk/run/attack rows are never drawn — code
  flips the right-facing row.
- **Sheet layout:** one animation per row, 10 frames/row (640px wide at 64px
  tiles), unused frames transparent.
- **Animation timing:** 10fps default; idle/talk 6–8fps; dash/hurt 12–15fps.

Each of the five playable characters, the animal companions, and the five
enemy archetypes has a full sprite-sheet spec (row-by-row animation table +
AI-prompt block) in `sprites.md` — not duplicated here. Quick identity hooks:

- **Quinn** — all-black coat/hat, round glasses, brass wrench.
- **Erin** — dark-green jacket, auburn hair, fingertip flame flicker.
- **Evan** — broadest silhouette, olive tee, Frosty visible at his feet.
- **Ben** — patchwork jacket, glowing-cyan keytar, musical-note glyphs.
- **Ethan** — grey hoodie, dark AR glasses, glowing cyan device.

`PlaceholderArt._humanoid()` (the runtime fallback, §4) encodes a simplified
version of these same hooks: Quinn's newsboy cap, Erin's auburn hair,
Evan's crew-cut + wide shoulders, Ben's spiky hair, Ethan's glasses — plus a
held-prop silhouette per character (wrench, torch, fists, keytar, tech
gadget). The procedural fallback stays at 32×32/flat-fill — it does not need
to match the new 64×64/shaded spec, since it's superseded wherever a real
sheet exists.

---

## 4. Procedural art generation (`PlaceholderArt`)

`scripts/systems/placeholder_art.gd` (`class_name PlaceholderArt extends
RefCounted`) generates every runtime texture as an `Image`/`ImageTexture` —
no imported assets required (original-IP guarantee). Catalog of generator
functions:

| Function | Output | Used for |
|----------|--------|----------|
| `make_player_frames(color, character_name)` | `SpriteFrames` | Fallback player sprite — 32×32 humanoid, per-character head accessory + held prop (see §3) |
| `make_enemy_frames(color, enemy_name, stocky)` | `SpriteFrames` | Fallback enemy sprite — 5 distinct silhouettes (Grunt/Runner/Brute/Sentry/Boss) |
| `make_level_tileset(base, accent)` | `TileSet` (2 tiles, 32×32) | Per-location floor — beveled stone tile + diamond-inlay accent tile (§2.3) |
| `make_hb_tileset()` | `TileSet` (12×8 tiles, 32×32, cached singleton) | Overworld `TileMap` — loads `assets/art/tiles/hb_tiles.png`, 2× upscaled. 8 terrain rows: `0=STONE 1=WORKSHOP 2=WOOD 3=OUTDOOR 4=TUNNEL 5=DOCK 6=CARPET 7=CYBER` |
| `make_wall_texture(color, w, h)` | `ImageTexture` | Running-bond brick pattern, scaled to any collider rect — walls use `FLOOR_BASE_COLOR.darkened(0.35)` |
| `make_gate_texture(color, w, h)` | `ImageTexture` | Generic beveled panel + black frame — doors/containers/barbells/etc. (3-D bevel if `w>16 and h>16`) |
| `make_item_icon(color, is_junk)` | `ImageTexture` (16×16) | Collectible icon — gem/diamond shape; junk items get `darkened(0.35)` fill + dimmer backing |
| `make_organ_texture(color, w, h)` | `ImageTexture` | Pipe organ prop (Pipe Organ Works, Old Parish Church loft) |
| `make_console_texture(color, w, h)` | `ImageTexture` | Soundboard/terminal prop (Recording Studio, VR Escape Room, Library) |
| `make_gear_prop_texture(color, w, h)` | `ImageTexture` | Clockwork gear mechanism (Clocktower) |
| `make_bell_texture(color, w, h)` | `ImageTexture` | Twin bells + clappers (Clocktower belfry) |
| `make_barbell_texture(color, w, h)` | `ImageTexture` | Weight barbell prop (Iron & Strings Gym) |
| `make_pew_texture(color, w, h)` | `ImageTexture` | Pew bench (Old Parish Church) |
| `make_altar_texture(w, h)` | `ImageTexture` | Stone altar w/ red cloth (Old Parish Church) |
| `make_stained_glass_texture(w, h, colors)` | `ImageTexture` | 3×4 stained-glass panel grid (Old Parish Church nave) |
| `make_candle_texture(w, h, lit)` | `ImageTexture` | Candle prop, lit/unlit (Old Parish Church) |
| `make_arch_window_texture(w, h, glass_color)` | `ImageTexture` | Pointed-arch window (Old Parish Church altar wall) |

All functions follow the same idiom: `Image.create(...)`, draw via the shared
`_rect()` helper (or per-pixel `set_pixel`), wrap in `ImageTexture
.create_from_image()`. Most accept a single base `color` and derive
highlights/shadows via `.lightened()`/`.darkened()` — keeping each prop
visually tied to its location's palette (§2.3/§2.4) without hardcoding
secondary colors.

**Asset pipeline note:** real sprite sheets are generated by the
`generators/gen_*.py` PIL scripts (not ComfyUI) and dropped into
`assets/art/sprites/`. All five player sheets — `quinn.png`/`erin.png`/
`evan.png`/`ben.png`/`ethan.png` — are now at the current **640×1088
(64×64-frame)** spec. `generators/_sprite_player_common.py` provides shared
biped-drawing helpers (`biped_front`/`biped_back`/`biped_side`/`biped_lying`)
for future characters. `PlaceholderArt` remains the runtime fallback wherever
a real sheet isn't loaded; wiring the real sheets into `make_player_frames()`
call sites is tracked in §9.

**`gem/` reference folder:** `gem/quinn.png`, `gem/erin.png`, `gem/evan.png`,
`gem/ben.png`, `gem/ethan.png` (plus animal-companion sheets — `frosty.png`,
`twinkle.png`, `lizard.png`, `william_and_mary.png`,
`calvin_and_coolidge.png`, `guinea_pigs.png`) are the visual-fidelity target
per §3. All five player sheets have been regenerated at the 64×64-frame spec
via the `generators/gen_*.py` PIL scripts; animal-companion sheets are
likewise PIL-generated at 64×64.

---

## 5. "Clear-animation" flavors

Each location's puzzle-gate prop that graduated from cosmetic sprite to a
real `StaticBody2D` collider gets its own **distinct** clear animation — all
built from `create_tween()`, no new assets:

| # | Location | Prop | Animation |
|---|----------|------|-----------|
| 1 | Iron & Strings Gym | Barbell | horizontal slide aside |
| 2 | The Recording Studio | BoothDoor | vertical slide into ceiling |
| 3 | The Harbor & Docks | Container | hoist-up + swinging rotation (crane) |
| 4 | The Public Library & Archive | LibrarianDesk | scale-down + fade ("packs up and steps aside") |
| 5 | The Carnival & Fairground | BackstageGate (curtain) | upward slide + scale-to-near-zero (curtain into rigging) |

Two locations also use **secret-passage reveals** (disable collider + fade
sprite via `create_tween()`, distinct from the above five): Pipe Organ Works'
parts closet and Old Parish Church's organ loft.

---

## 6. UI visual language

### 6.1 Shared menu palette (`title_screen.gd`, `pause_menu.gd`)

| Const | Color | Use |
|-------|-------|-----|
| `BORDER_COLOR` / `SLIDER_COLOR` | `(0.55, 0.45, 0.75)` | panel borders, slider fill — muted violet |
| `TITLE_COLOR` / `SELECTED_COLOR` | `(0.95, 0.85, 0.2)` | titles, selected menu item — gold |
| `NORMAL_COLOR` | `(0.72, 0.72, 0.82)` | unselected menu text |
| `DIMMED_COLOR` | `(0.32, 0.32, 0.40)` | disabled/locked items |
| `HINT_COLOR` | `(0.45, 0.45, 0.55)` | footer hint text |
| `SLIDER_BG_COLOR` | `(0.18, 0.16, 0.28)` | slider track |
| panel background | `(0.08, 0.07, 0.14, 0.97)` | menu panel fill |
| dim overlay | `(0.0, 0.0, 0.0, 0.55–0.65)` | screen dim behind a modal |

Title screen extras: subtitle text `(0.65, 0.6, 0.9)`, controls hint
`(0.30, 0.30, 0.36)`, "New Game" confirm accent `(0.85, 0.25, 0.25)` /
`(0.95, 0.35, 0.35)`, background fill `(0.05, 0.04, 0.13)`, drifting motes
`(0.5, 0.45, 0.75, 0.35)`.

### 6.2 Dialog box (`scripts/ui/dialog_box.gd`)

| Const | Color |
|-------|-------|
| `PANEL_COLOR` | `(0.05, 0.05, 0.09, 0.92)` |
| `BORDER_COLOR` | `(0.85, 0.78, 0.35, 1.0)` — gold |
| `NAME_COLOR` | `(1.0, 0.92, 0.4, 1.0)` — bright gold |
| `TEXT_COLOR` | `(0.92, 0.92, 0.95, 1.0)` |
| `PROMPT_COLOR` | `(0.55, 0.55, 0.6, 1.0)` |

### 6.3 DuoPanel (`scripts/ui/duo_panel.gd`)

| Const | Color |
|-------|-------|
| `ACTIVE_BORDER` | `(1.0, 0.85, 0.3, 1.0)` — gold, pulses on swap |
| `IDLE_BORDER` | `(0.4, 0.4, 0.46, 0.6)` |
| `BG_COLOR` | `(0.1, 0.1, 0.14, 0.75)` |

### 6.4 InventoryPanel (`scripts/ui/inventory_panel.gd`)

- `ICON_SIZE = 16.0`
- `FUNCTIONAL_BORDER = (1.0, 0.85, 0.3, 0.9)` — gold, signals "might matter later"
- `JUNK_BORDER = (0.6, 0.6, 0.66, 0.35)` — dim grey, signals "keepsake"

### 6.5 HUD (`scripts/ui/hud.gd`)

- Bies Mode charge bar pulses toward `Color(1.0, pulse, 0.2, 1.0)` (gold→red
  ramp) when full.
- Health bars / labels driven by `Player.hp_changed` — no hardcoded palette
  beyond the engine default `ProgressBar` styling.

### 6.6 ResultScreen (`scripts/ui/result_screen.gd`)

`CHAR_COLORS` array (one swatch per unlockable character, in unlock order)
mirrors §2.1's `sprite_color` values. Locked characters render as
`(0.3, 0.3, 0.3)`. Background `(0.06, 0.05, 0.1)`, title fade-in
`(0.95, 0.85, 0.2)`, story text `(0.85, 0.85, 0.92)`, stats text
`(0.65, 0.6, 0.9)`, "press enter" prompt `(0.6, 0.95, 0.7)`, drifting motes
`(0.95, 0.85, 0.45, 0.4)`.

---

## 7. Combat & stealth visual telegraphs

All on-screen warning/progress indicators use the same `_draw()`/
`queue_redraw()` programmatic pattern — "combat must stay readable" (CLAUDE.md
guardrail).

### 7.1 Boss AoE slam (`scripts/enemies/enemy.gd`)

| Const | Color | Use |
|-------|-------|-----|
| `TELEGRAPH_COLOR` | `(1.0, 0.3, 0.2, 0.85)` | expanding warning ring outline |
| `TELEGRAPH_FILL_COLOR` | `(1.0, 0.3, 0.2, 0.18)` | ring interior fill |
| `TELEGRAPH_RANGE_COLOR` | `(1.0, 0.3, 0.2, 0.3)` | final slam-radius outline |
| `SLAM_FLASH_COLOR` | `(1.0, 0.45, 0.3, 0.4)` | impact flash |

### 7.2 Stealth — vision cone & alert ring (`scripts/enemies/enemy.gd`)

| Const | Color | Use |
|-------|-------|-----|
| `VISION_CONE_COLOR_LOW` | `(0.95, 0.95, 0.6, 0.10)` | vision-cone wedge, low alert |
| `VISION_CONE_COLOR_HIGH` | `(1.0, 0.3, 0.2, 0.16)` | vision-cone wedge, high alert (lerped) |
| `ALERT_RING_BG_COLOR` | `(0.1, 0.1, 0.1, 0.35)` | alert-meter ring background |
| `ALERT_RING_LOW_COLOR` | `(0.85, 0.85, 0.4, 0.9)` | alert ring fill, low |
| `ALERT_RING_HIGH_COLOR` | `(1.0, 0.3, 0.2, 0.95)` | alert ring fill, high (lerped) |

`Player.HIDDEN_MODULATE = (1.0, 1.0, 1.0, 0.55)` dims a hidden player's sprite
to 55% alpha while inside a `HidingSpot`.

### 7.3 Revive ring (`scripts/players/player.gd`)

| Const | Color |
|-------|-------|
| `REVIVE_RING_BG_COLOR` | `(0.4, 1.0, 0.6, 0.25)` |
| `REVIVE_RING_FILL_COLOR` | `(0.4, 1.0, 0.6, 0.95)` — also used for `CombatFX.sparks()` on revive |

### 7.4 Hit feedback (`combat_fx.gd`, `player.gd`, `enemy.gd`)

- **Hit-flash:** sprite `modulate = Color(5.0, 5.0, 5.0, 1.0)` (overbright
  white flash) on both player and enemy hit.
- **Sparks:** `CombatFX.sparks(pos, color, count)` spawns a one-shot
  `CPUParticles2D` burst (4×4 white square texture, tinted by `color`,
  0.35s lifetime, upward + 180° spread). Player hurt uses
  `(1.0, 0.25, 0.25)` (red); enemy death uses `(1.0, 0.95, 0.4)` (yellow);
  revive uses the revive-ring green.
- **Screen shake:** `CombatFX.shake(amount)` — trauma-based camera offset,
  `MAX_SHAKE_PX = 6.0`, decays at `TRAUMA_DECAY = 3.0`/s.

---

## 8. Screen-wide post-processing (`scripts/autoload/crt_overlay.gd`)

A `CanvasLayer` (layer 90, `PROCESS_MODE_ALWAYS`) drawn over everything:

- **Scanlines:** horizontal lines every `SCANLINE_STEP = 2`px,
  `Color(0, 0, 0, 0.18)`.
- **Vignette:** four edge gradients (`reach = 110.0`px), from
  `Color(0, 0, 0, 0.30)` at the screen edge to fully transparent — drawn as
  per-vertex-colored polygons for smooth interpolation.

Static overlay — drawn once, no per-frame updates.

---

## 9. Open items / not yet unified

- `make_player_frames()`'s procedural humanoids are still the active runtime
  path; the real 64×64 sprite sheets (all 5 characters in `assets/art/sprites/`)
  are not yet wired into `make_player_frames()`'s call sites — when they are,
  §3/§4 should be updated to describe the real-sprite path as primary and
  `PlaceholderArt` as fallback-only.
- The `gen_*_comfy*.py` scripts in `generators/` are legacy ComfyUI pipelines
  superseded by the `gen_*.py` PIL scripts — they can be deleted when the PIL
  sheets are fully wired in.
- **Viewport/spec migration (§1):** the new 1920×1080 / 960×540-logical spec
  (§1–§3) applies to *new* work. Migrating the 13 existing locations' room
  geometry, camera bounds, and UI positions is a tracked follow-up — all 13
  still use the 1280×720 / 640×360 layout. Sprite sheet regeneration is done.
