# Sprite Documentation

Reference docs for every sprite sheet in Hunkle Bunkle. Each file in this
folder describes one sheet: visual design, palette, animation table, and an
AI prompt for generation.

---

## File Organization

```
artwork/sprites/
  README.md             ← this file (style guide + global notes)
  players/              ← one file per playable character
  animals/              ← Evan's animal companions
  enemies/              ← all enemy types + projectiles
  npcs/                 ← level NPCs (Uncle Doug, Mr. Bellows, etc.)
    town/               ← 12 overworld town quest-givers
```

### NPC index

| File | Name | Location | Role |
|------|------|----------|------|
| `uncle_doug.md` | Uncle Doug | Grand Marquee Cinema projection booth | The rescue target; endgame payoff |
| `mr_bellows.md` | Mr. Bellows | Pipe Organ Works Manager's Office | Quinn's boss; tuning key quest |
| `father_aldric.md` | Father Aldric | Old Parish Church altar | Dialog-choice NPC; impression system |
| `librarian.md` | Librarian | Public Library desk | Gate NPC; step aside on Erin Fast Talk |
| `carnival_guard.md` | Carnival Guard | Carnival backstage curtain | Gate NPC; step aside on Erin Fast Talk |
| `town/gus.md` | Gus | Overworld town | Quest: bent spoon (Doug's) |
| `town/moira.md` | Moira | Overworld town | Quest: skeleton key (lent to Doug) |
| `town/reggie.md` | Reggie | Overworld town | Quest: arcade token (Doug built cabinet with him) |
| `town/fanny.md` | Fanny | Overworld town | Quest: Fanny's bottle (Doug's keepsake) |
| `town/penny.md` | Penny | Overworld town | Quest: embroidered handkerchief; gives stitched patch |
| `town/otis.md` | Otis | Overworld town (harbor) | Quest: brass compass (Doug's gift); gives sailor's knot |
| `town/wendell.md` | Wendell | Overworld west fringe | Quest: torn ticket stub |
| `town/clara.md` | Clara | Overworld west fringe | Quest: tangled headphone cable |
| `town/ambrose.md` | Ambrose | Overworld east fringe | Quest: faded treasure map |
| `town/dottie.md` | Dottie | Overworld east fringe | Quest: rabbit's foot keychain |
| `town/tobias.md` | Tobias | Overworld (unlocks after Pipe Organ Works secret) | One-shot; grants spoon 11 |
| `town/agnes.md` | Agnes | Overworld (unlocks after Old Parish Church secret) | One-shot; grants spoon 12 |

---

## Sheet Conventions

- **Canvas:** 640 px wide (10 × 64 px columns). Height = rows × tile height.
- **Tile size:** 64 × 64 px per frame (96 × 64 for wide sprites like the Brute;
  128 × 128 for the Boss).
- **Left-facing is never drawn.** Flip the right-facing row in code
  (`sprite.flip_h`). All sheets omit left-facing rows entirely.
- **Direction convention:** sprites face **right** by default.
  Up/down = away from / toward the camera (top-down view).
- **Unused frames** at the end of a row are fully transparent 64 × 64 tiles.
- **Save location:** `assets/art/sprites/<filename>.png`.

---

## Style Guide

Apply every rule below to ALL sprites — players, animals, enemies, NPCs.

- **Art style:** Clean, high-readability modern pixel art inspired by the
  *Stranger Things: 1984* character-swapping promo aesthetic: crisp silhouettes
  with confident outlines, soft directional shading (2–3 step highlight/shadow
  gradients per shape, not flat fills), grounded slightly-stylised teen-adventure
  character designs. See `gem/quinn.png`, `gem/erin.png`, etc. for the canonical
  fidelity target.
- **Perspective:** Top-down, approximately ¾ overhead. Faces are visible when
  walking toward the camera (full face) and away (back of head only).
- **Palette:** Shared extended ~32-color palette (DESIGN.md §2.0). Build a 2–3
  step shading ramp (base / highlight / shadow) per major shape.
- **Proportions (64 × 64 frame):** Head ≈ 20 px, torso ≈ 20 px, legs ≈ 24 px.
  Characters still occupy one 32 × 32 gameplay tile in-engine; extra resolution
  is for shading/detail.
- **Outline:** `#1A1A22` (soft near-black) on all characters. Interior lines use
  dark palette colors.
- **Background:** Fully transparent on every frame.
- **Eyes:** 4 × 4 px white square, 2 × 2 px dark pupil.
- **Animation timing (default):** 10 fps. Idle/talk: 6–8 fps. Dash/hurt: 12–15 fps.
- **Frame count guidance:**
  - Idle / talk: 6 frames
  - Walk / run: 8 frames (full stride cycle)
  - Attack: 6 frames (windup 2 → strike 1 → recover 3)
  - Special: 8 frames
  - Hurt: 4 frames
  - Death: 8–12 frames
  - Dodge: 5 frames
  - Revive: 8 frames

---

## Combat Arc Visuals (code-drawn, not part of the sprite)

Each player's attack shows a directional fan/arc drawn in code by
`player.gd::_draw_attack_arc()`. This overlay is **not** part of the sprite sheet
— do not include the arc glow in the art itself. The sprite's attack row shows
only the character's body pose and weapon motion. The arc is added on top
in-engine, fading out over the active hit window.

| Character | Arc type | Color | Reach | Arc spread |
|-----------|----------|-------|-------|------------|
| Quinn | Filled wedge | Gold `#FFE04D` | 28 px | 92° |
| Erin | Filled wedge | Orange-red `#F27319` | 22 px | 137° |
| Evan | Filled wedge | Amber `#FFA633` | 32 px | 115° |
| Ben | Filled wedge | Purple `#D94DE6` | 26 px | 172° |
| Ethan | Directional beam | Teal `#33E6D9` | — (ranged) | narrow beam |

Ethan's attack is **ranged** — he fires a projectile and the arc is replaced by a
straight teal beam flash showing the shot direction.

---

## Notes for Art Generation

- Left-facing versions of all walk/run/attack animations are **code-flips** of
  the right-facing row. Do not generate separate left rows.
- All sheets share the extended ~32-color palette (DESIGN.md §2.0). Include
  `"extended vibrant palette (DESIGN.md §2.0), confident outlines, soft
  directional shading with 2–3 step highlight/shadow gradients, no dithering"`
  in every AI prompt.
- See `gem/` for the five player character reference sheets and animal companion
  sheets.
- Place finished sheets in `assets/art/sprites/` and update
  `scripts/systems/sprite_loader.gd` to load from the file path; the
  `PlaceholderArt` functions remain as fallbacks.
