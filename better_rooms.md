# Better Locations — Visual Richness, Multi-Room Design & Working with Claude

---

## The Core Problem

Right now every location is structurally identical: a `TileMap` floor, `StaticBody2D` walls with a brick texture, and a few colored rectangles as props. The game *plays* correctly but nothing *looks* like anything. The Old Parish Church looks like the Harbor & Docks with different color values.

The gap is a **prop/decoration layer** — environmental detail that makes a space readable as a specific place. Stained glass windows, pews, and an altar are what make a church feel like a church. This guide covers how to build that layer.

---

## Tilemap vs Background Images — Short Answer

**Use both, for different things.**

| Layer | Best tool | Why |
|---|---|---|
| Floor | `TileMap` (already doing this) | Repeated pattern, easy to extend |
| Structural walls | `StaticBody2D` (already doing this) | Collision, easily resized |
| Decorative wall surfaces (stone, brick, stained glass) | `Sprite2D` on wall | One image per wall face, no tiling |
| Furniture / props (pews, altar, barrels) | `Sprite2D` + optional `StaticBody2D` | Unique, positioned by hand |
| Background atmosphere (sky through a window, distant arches) | `Sprite2D` behind everything | Pure decoration, no collision |

**Background images beat tilemaps for unique architectural details.** A stained glass window is a single image — tiling it would look wrong. A pew row is also a single image. Tilemaps are for things that repeat (floor stones, corridor walls). For anything unique to a room, one `Sprite2D` is simpler and looks better.

---

## The Prop Library Pattern

The scalable path is to build a **prop library** — a set of reusable visual pieces that Claude can place in any scene. Think of it like furniture: you define the pieces once, then arrange them per room.

### What to build (in priority order)

**Structural props** — shapes every interior needs:
- `ArchWindow` — arched opening with optional colored glass fill
- `RoundWindow` — circular window (churches, clocktowers)
- `Pillar` — vertical column, collidable or decorative
- `WallPanel` — decorative surface texture applied to a wall face
- `Doorframe` — arched or rectangular opening (distinct from the `Doorway` exit logic)

**Church-specific props:**
- `Pew` — a bench with a back, 2–3 tiles wide, collidable
- `Altar` — raised platform with a cloth-draped table
- `CandleStick` — vertical prop, flickering light particle optional
- `StainedGlass` — colored geometric fill pattern in an arch shape

**Environment props (general):**
- `Crate` / `Barrel` — generic obstacle
- `Table` / `Chair`
- `Bookshelf` — good for Library
- `ConsoleProp` — generic panel/terminal (good for VR Room, Recording Studio)

### How to define them for Claude

The cleanest way is a `PropData` Resource, same pattern as `ItemData` and `EnemyData`:

```gdscript
# scripts/systems/prop_data.gd
class_name PropData extends Resource

@export var prop_name: String = ""
@export var base_color: Color = Color.WHITE
@export var accent_color: Color = Color.GRAY
@export var width_px: int = 32
@export var height_px: int = 32
@export var has_collision: bool = false
@export var collision_width: int = 0
@export var collision_height: int = 0
```

Then `PlaceholderArt` gets a `make_prop_texture(prop_data)` function that draws the right shape. Claude can generate a new drawing function for each prop type — the same way `make_wall_texture` and `make_gate_texture` already work.

---

## How to Build a Richer Church (Concrete Plan)

Here is how to turn the current flat rectangle into something that reads as a church.

### Step 1 — Define the floor plan in a comment block

Before asking Claude to write code, write a clear ASCII layout. Claude works much better from a layout you've thought through than from a vague description.

```
# OLD PARISH CHURCH — FLOOR PLAN
#
# +------------------+--+------------------+
# |                  |  |                  |
# |   SIDE CHAPEL    |  |   SIDE CHAPEL    |  ← optional alcoves
# |   (loot box)     |  |   (organ loft)   |
# |                  |  |                  |
# +---+----------+---+  +---+----------+---+
#     |                              |
#     |          N A V E             |  ← main corridor, pews each side
#     |     [pew] [pew] [pew]        |
#     |     [pew] [pew] [pew]        |
#     |                              |
#     +--+------------------------+--+
#        |       VESTIBULE        |      ← entry, Doorway here
#        |         [door]         |
#        +------------------------+
#
# ALTAR is at the north end of the nave.
# STAINED GLASS windows are in the nave's east and west walls.
# BLUE pillar (Quinn puzzle) is west nave wall mid-point.
# RED pillar (Erin puzzle) is east nave wall mid-point.
```

Give Claude this diagram and say "build the wall layout to match this floor plan." You'll get a much better result than "make it look like a church."

### Step 2 — Add prop draw functions one at a time

Ask Claude for **one prop at a time**, not all props at once. For each:

> "Add a `make_pew_texture(color, w, h)` function to `PlaceholderArt`. A pew is a bench: dark wood rectangle with a thin back rail at the top and leg details at each end. No new files — just add the function."

Then separately:
> "Add `make_stained_glass_texture(width, height, colors)` to `PlaceholderArt`. Divide the space into a 3×4 grid of colored panels separated by 1px dark lead lines. Pick colors from the provided array sequentially."

This keeps each change small and reviewable.

### Step 3 — Place props in the scene script

Once the draw functions exist, Claude adds placement code to `old_parish_church.gd`:

```gdscript
func _build_props() -> void:
    # Pew rows — left and right of the nave aisle
    for i in range(3):
        _place_pew(Vector2(180, 200 + i * 80), false)   # left row
        _place_pew(Vector2(420, 200 + i * 80), false)   # right row
    # Altar at north end
    _place_altar(Vector2(300, 80))
    # Stained glass in east/west nave walls
    _place_stained_glass(Vector2(160, 300), [Color(0.8,0.2,0.2), Color(0.2,0.5,0.8), ...])
    _place_stained_glass(Vector2(440, 300), [Color(0.2,0.8,0.3), Color(0.8,0.7,0.1), ...])

func _place_pew(pos: Vector2, collidable: bool) -> void:
    var body := StaticBody2D.new() if collidable else Node2D.new()
    var sprite := Sprite2D.new()
    sprite.texture = PlaceholderArt.make_pew_texture(PEW_COLOR, 80, 20)
    body.add_child(sprite)
    if collidable:
        var cs := CollisionShape2D.new()
        cs.shape = RectangleShape2D.new()
        cs.shape.size = Vector2(80, 20)
        body.add_child(cs)
    body.global_position = pos
    add_child(body)
```

---

## Multi-Floor Buildings

The Clocktower already proved the stacked-floors pattern. The key decisions for a richer multi-floor building:

### Single scene vs multiple scenes

**Single scene** (current approach): All floors are in one `.tscn`, camera scrolls between them. Best for buildings where you move up/down freely (church nave + organ loft, harbor crane platform).

**Multiple scenes with transitions**: Each floor loads as a separate scene when the player crosses a threshold. Best for large buildings where you'd never see two floors at once (a skyscraper, a dungeon with many levels). Harder to implement — adds scene loading, state transfer, and loading screens.

**Recommendation: stay with single scene** until a location genuinely needs more than ~1500×1500 px of playable space. The Clocktower's three-floor vertical shaft is already a good template.

### Telling Claude about multi-floor layouts

Give explicit pixel bounds per floor:

```
# FLOOR 0 (ground):  x 0–640,  y 400–640
# FLOOR 1 (main):    x 0–640,  y 160–400
# FLOOR 2 (loft):    x 0–640,  y 0–160
# Stairwell gap:     x 280–360 at each floor boundary
# Camera: CAMERA_LIMIT_TOP = 0, CAMERA_LIMIT_BOTTOM = 640
```

Claude can then build walls and set camera limits directly from these numbers.

---

## Using ComfyUI for Background Art

The SD pipeline you just set up can generate atmospheric background panels — not sprites, but room backgrounds. This is the fastest path to visual richness without drawing anything by hand.

### What works well

- **Stained glass close-up**: "pixel art stained glass window, church, geometric colored panels, medieval, bold black lead lines, PICO-8 palette"
- **Stone wall texture**: "pixel art stone brick wall texture, seamless tile, grey, dungeon"
- **Atmospheric background**: "pixel art church interior background, gothic arches, candlelight, top-down RPG style"

### Workflow

1. Generate a 512×512 or 1024×512 image via ComfyUI
2. Use it as the `texture` on a `Sprite2D` placed behind walls
3. Set `z_index = -1` so it renders behind everything

### The img2img trick for location consistency

Generate a **base environment image** for each location (e.g. "church nave, top-down pixel art") then use img2img with `denoise=0.4` to make variations — a side chapel that still looks like the same building, or a nighttime version. This is much faster than generating each room from scratch.

---

## Multi-Puzzle Room Design

Richer locations have more than one puzzle. The current single-gate pattern (`enemies cleared + one special press`) can expand in a few directions:

### Sequential puzzles (do A before B unlocks)

```gdscript
# The altar is locked until the candles are lit
var _candles_lit: int = 0
const CANDLES_NEEDED: int = 3

func _on_special_used(char_name, p):
    # Check candle proximity first
    for candle in _candles:
        if candle.try_light(char_name, p.global_position):
            _candles_lit += 1
            _update_hint()
            return
    # Altar only unlocks after all candles
    if _candles_lit >= CANDLES_NEEDED:
        if not _altar_activated and _near_altar(p.global_position):
            _activate_altar()
```

### Distributed puzzles (different characters, different rooms)

Extend the existing character-gate pattern across rooms:
- Quinn solves the organ in the loft (Room A)
- Erin talks down the deacon in the vestibule (Room B)
- Both must be done before the crypt door opens

State lives on `GameManager.level_progress` as usual — `set_level_flag / get_level_flag`. No new system needed.

### Environmental puzzles (affect the room itself)

- Quinn lights candles → room gets brighter (change `PointLight2D` energy)
- Erin opens the curtains → new path revealed (disable a `StaticBody2D`)
- Ben plays the organ → a stone panel vibrates open (tween + collision disable)

These use the same disable-collider + tween pattern already in the codebase five times. The difference is the *trigger* (distance + special) and the *result* (which node changes).

---

## How to Ask Claude for This Work

### Pattern that works well

1. **Layout first, code second.** Write (or have Claude draft) an ASCII floor plan. Review it. Only then ask for the wall code.
2. **One system at a time.** "Add the prop draw functions." Then separately: "Place the props in the church." Then: "Wire up the candle puzzle."
3. **Reference existing code explicitly.** "Use the same `create_tween()` + collider-disable pattern as `_move_barbell()` in `iron_strings_gym.gd`." This gets consistent code.
4. **Scope each task.** "Edit only `old_parish_church.gd` and `placeholder_art.gd`. Don't touch other files."
5. **Ask for a plan before code on complex tasks.** "Before writing code, describe in bullet points how you'd add a three-candle sequential puzzle to the church."

### Prompts that have worked

```
"Add a make_stained_glass_texture(w, h, colors) function to PlaceholderArt.
Divide the space into a 3x4 grid of colored rectangles separated by 1px
black lead lines. The colors array cycles through the grid cells."

"In old_parish_church.gd, add _build_props() called from _ready() after
_build_walls(). Place three Sprite2D candle props at [positions]. Each candle
starts unlit (grey). Quinn pressing Special near one calls _light_candle(i)
which redraws it in warm yellow via queue_redraw(). Track _candles_lit.
Use the existing set_level_flag/get_level_flag pattern to persist state."

"The nave is too sparse. Add two rows of pews (3 pews per row, each 80x18 px)
as StaticBody2D collidable obstacles on either side of the central aisle.
Use PlaceholderArt.make_pew_texture(). Position them so there's a 48px aisle
down the center and 24px clearance from the walls."
```

---

## Priority Order for Church Specifically

1. **ASCII floor plan** — vestibule → nave (with pews) → side chapels → organ loft. Agree on this before any code.
2. **Pew prop** — `make_pew_texture()` in PlaceholderArt + collidable placement in the nave.
3. **Altar prop** — `make_altar_texture()` + placement at nave north end.
4. **Stained glass** — `make_stained_glass_texture()` on east/west nave walls.
5. **Multi-room layout** — expand the `.tscn` wall layout to add the side chapels.
6. **Candle/lighting puzzle** — sequential puzzle replacing the current flat pillar gates.
7. **ComfyUI background** — generate an atmospheric stone arch background panel, drop it in behind everything.

Each step is a separate Claude task. Don't ask for all seven at once.
