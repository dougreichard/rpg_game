---
character: Erin
sheet: assets/art/sprites/erin.png
canvas: 640 × 1088 px
tile: 64 × 64 px
rows: 17
---

# Erin — Sprite Sheet

## Visual Design

Teenage, lithe and quick-looking. Fitted dark-green jacket over black jeans,
scuffed sneakers. Short red/auburn hair. No visible weapon — hands are always
slightly raised, ready to talk or move fast. Her fire ability manifests as
small orange flame flickers at her fingertips during combat. Confident,
slightly mischievous expression.

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Jacket | Deep-green | `#2E7D4F` |
| Jacket highlights | Mid-green | `#4FB05C` |
| Jeans | Ink-black | `#1A1A22` |
| Hair | Auburn | `#9C5A2E` |
| Fingertip flame accent | Flame-orange | `#FF9A3C` |
| Skin | Light-tan | `#F2C49B` |
| UI accent | Orange (DESIGN.md §2.1) | `#E6591A` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Small orange flame flicker at fingertips (2 px) |
| 1 | Walk — down | 8 | Light, quick steps |
| 2 | Walk — up | 8 | |
| 3 | Walk — right | 8 | |
| 4 | Run — down | 8 | Near-sprint — she is the fastest character |
| 5 | Run — up | 8 | |
| 6 | Run — right | 8 | Aggressive forward lean, arms pumping |
| 7 | Attack — right | 6 | Fire jab: hand ignites (1–2), strike burst (3), flame fades (4–6). **Wide burst covers 137° — the sprite shows the body pose and flame-hand only; the orange-red arc overlay is drawn in code and must NOT appear in the sheet.** |
| 8 | Special — Fast Talk | 8 | Rapid hand gestures, leaning forward; small speech-bubble pixel glyph above head |
| 9 | Stealth — crouch walk | 6 | Low crouch, slow tiptoeing step cycle; reduced silhouette height |
| 10 | Talking — full body | 6 | Expressive arm gestures |
| 11 | Talking — closeup | 8 | Half-smile, eyebrow arch |
| 12 | Hurt | 4 | Stumble back, hair flicks forward |
| 13 | Death / Down | 10 | Falls forward, flame extinguishes at frame 8 |
| 14 | Revive | 8 | Rolls to hands and knees, pushes up quickly |
| 15 | Dodge / Dash | 5 | Low side-step, lower to ground than Quinn |
| 16 | Hide — enter hiding spot | 6 | Ducks down, brings knees in, silhouette nearly disappears |

## Attack Details

Erin's fire-jab is **short-reach but wide** — a cone burst that fans out
broadly from her striking fist. The orange-red wedge drawn in code is the
widest melee arc of the non-Ben characters. The sprite's attack row should
show the hand igniting and bursting forward; no arc glow in the pixel art.

| Stat | Value |
|------|-------|
| Arc type | Filled wedge (code-drawn) |
| Arc color | Orange-red `#F27319` |
| Reach | 22 px |
| Arc spread | 137° |
| Hitbox size | 38 × 10 px |

## AI Prompt

> Pixel art sprite sheet, clean modern pixel-art style inspired by
> *Stranger Things: 1984*'s character-swap art (see `gem/erin.png` for
> fidelity reference), transparent background. Canvas 640 × 1088 px, 64×64
> tiles, 17 rows × 10 columns. Subject: teenage girl, lithe build, short
> red-auburn hair, dark-green fitted jacket, black jeans, scuffed sneakers.
> Small orange flame flickers at fingertips in idle and attack frames.
> Animations: idle (flame flicker), walk-toward, walk-away, walk-right,
> fast-run-toward, fast-run-away, fast-run-right (aggressive lean),
> fire-jab-attack-right (hand ignites → burst → fades; NO arc glow in sprite),
> fast-talk-special (rapid gestures + speech glyph above head),
> stealth-crouch-tiptoe, talking-full-body, talking-closeup, hurt-stumble-hair-
> flick, death-fall-forward (flame extinguishes), revive-roll-push-up,
> dash-low-sidestep, hide-crouch-disappear. Confident outlines, soft directional
> shading with 2-3 step highlight/shadow gradients, extended vibrant palette
> (DESIGN.md §2.0), no dithering.

## Save Location

`assets/art/sprites/erin.png`
