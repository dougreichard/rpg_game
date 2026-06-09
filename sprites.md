# Sprites

## How to Use This File

Each section describes one sprite sheet. Use the **AI Prompt** block to
generate the art, then refine frame-by-frame. Save each sheet to
`assets/art/sprites/<filename>.png`.

**Mirroring rule:** Walking/running *left* is never drawn — flip the *right*
animation in code. This halves movement animation work. All sheets omit
left-facing rows entirely.

**Sheet layout:** Each animation occupies one horizontal row of **10 frames**
(unused frames at the row end are fully transparent). Sheet width = **320 px**
(10 × 32). Sheet height = number of animations × 32 (or × tile height for
larger sprites).

**Direction convention:** Sprites face **right** by default. Up/down
animations face away from / toward the camera (top-down view).

---

## Style Guide

Apply every rule below to ALL sprites — players, animals, enemies, NPCs.
Consistency here is what makes the game feel like one world.

- **Art style:** Tintin/Hergé *ligne claire* — bold, clean black outlines
  (1 px), flat cel-shaded fills, almost no internal shading (one highlight
  dot or shadow band maximum per shape).
- **Perspective:** Top-down, approximately ¾ overhead. Characters are seen
  slightly from above; faces are visible when walking toward the camera (full
  face) and when walking away (back of head only).
- **Palette:** Shared 16-color limited palette across ALL sprites. The PICO-8
  palette is recommended: `#000000 #1D2B53 #7E2553 #008751 #AB5236 #5F574F
  #C2C3C7 #FFF1E8 #FF004D #FFA300 #FFEC27 #00E436 #29ADFF #83769C #FF77A8
  #FFCCAA`. Each character section maps their design to specific palette slots.
- **Proportions (32 × 32 px):** Head ≈ 10 px tall, torso ≈ 10 px, legs ≈ 12 px.
  Characters should read clearly at this size; avoid fine detail that
  disappears at scale.
- **Outline:** 1 px black (#000000) silhouette on all characters. Interior
  lines (eyes, clothing folds) in a dark palette color rather than pure black.
- **Background:** Fully transparent on every frame.
- **Eyes:** 2 × 2 px white square with 1 × 1 dark pupil. Keep them
  expressive — this is the primary face-reading device at this resolution.
- **Animation timing (default):** 10 fps. Idle/talk: 6–8 fps.
  Dash/hurt: 12–15 fps.
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

## Player Characters

### Quinn

**Visual:** Teenage, slim build. All-black outfit: wide-brim hat, round
wire-frame glasses, long coat, work boots. Brass wrench tucked in belt loop.
British mod-spy-meets-workshop-apprentice. Pale skin, dark brown hair hidden
under hat. Moves with quiet, purposeful confidence.

**Palette slots:** Black (#000000) coat/hat, dark grey (#5F574F) coat lining,
off-white (#FFF1E8) skin, brass (#FFA300) wrench, grey glasses rim.

**Sprite sheet:** 17 rows × 32 px = **320 × 544 px**

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Subtle coat sway, blink at frame 4 |
| 1 | Walk — down (toward camera) | 8 | Full stride, coat swings gently |
| 2 | Walk — up (away from camera) | 8 | Back of head; hat brim visible |
| 3 | Walk — right | 8 | Profile; coat flares slightly at back |
| 4 | Run — down | 8 | Faster stride, coat billows |
| 5 | Run — up | 8 | |
| 6 | Run — right | 8 | Forward lean, coat streams behind |
| 7 | Attack — right | 6 | Wrench swing: reach back (1–2), strike (3), recover (4–6) |
| 8 | Special — HA laugh | 8 | Arms wide, head back, mouth open; shockwave ripple radiates outward frames 5–8 |
| 9 | Talking — full body | 6 | Gesturing hands, slight forward lean |
| 10 | Talking — closeup | 8 | Head and shoulders only; eyebrow raises, mouth moves |
| 11 | Hurt | 4 | Recoil backward, hat tilts |
| 12 | Death / Down | 10 | Slow crumple; ends flat, coat spread |
| 13 | Revive | 8 | Rises from floor, shakes head, adjusts hat |
| 14 | Dodge / Dash | 5 | Low lunge right, coat streaming behind |
| 15 | Repair / Interact | 8 | Crouching, wrench in both hands, turning motion |
| 16 | Doorway operate | 6 | Reaches forward with both hands, pushes, steps through |

**AI Prompt:**
> Pixel art sprite sheet, Tintin ligne claire style, transparent background.
> Canvas 320 × 544 px, 32×32 tiles, 17 rows × 10 columns. Subject: teenage
> figure, slim build, all-black wide-brim hat, round wire-frame glasses, long
> black coat, black work boots, brass wrench in belt. Pale skin, dark brown
> hair hidden under hat. Animations (one per row, left to right): idle
> (coat sway, blink), walk-toward, walk-away, walk-right, run-toward,
> run-away, run-right, wrench-swing-attack-right (reach back → strike →
> recover), HA-laugh-special (arms wide, shockwave ripple radiates out),
> talking-full-body, talking-closeup (head + shoulders), hurt-recoil (hat
> tilts), death-crumple, revive-rise (adjusts hat), dash-right, crouch-repair
> (wrench turning), doorway-push (reaches forward, steps through). Bold 1px
> black outlines, flat colors, 16-color PICO-8 palette, no anti-aliasing,
> no dithering.

**Save to:** `assets/art/sprites/quinn.png`

---

### Erin

**Visual:** Teenage, lithe and quick-looking. Fitted dark-green jacket over
black jeans, scuffed sneakers. Short red/auburn hair. No visible weapon —
hands are always slightly raised, ready to talk or move fast. Her fire
ability manifests as small orange flame flickers at her fingertips during
combat. Confident, slightly mischievous expression.

**Palette slots:** Dark green (#008751) jacket, black (#000000) jeans,
auburn (#AB5236 lightened) hair, orange (#FFA300) flame accent,
off-white (#FFF1E8) skin.

**Sprite sheet:** 17 rows × 32 px = **320 × 544 px**

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Small orange flame flicker at fingertips (2 px) |
| 1 | Walk — down | 8 | Light, quick steps |
| 2 | Walk — up | 8 | |
| 3 | Walk — right | 8 | |
| 4 | Run — down | 8 | Near-sprint — she is the fastest character |
| 5 | Run — up | 8 | |
| 6 | Run — right | 8 | Aggressive forward lean, arms pumping |
| 7 | Attack — right | 6 | Fire jab: hand ignites (1–2), strike burst (3), flame fades (4–6) |
| 8 | Special — Fast Talk | 8 | Rapid hand gestures, leaning forward; small speech-bubble pixel glyph above head |
| 9 | Stealth — crouch walk | 6 | Low crouch, slow tiptoeing step cycle; reduced silhouette height |
| 10 | Talking — full body | 6 | Expressive arm gestures |
| 11 | Talking — closeup | 8 | Half-smile, eyebrow arch |
| 12 | Hurt | 4 | Stumble back, hair flicks forward |
| 13 | Death / Down | 10 | Falls forward, flame extinguishes at frame 8 |
| 14 | Revive | 8 | Rolls to hands and knees, pushes up quickly |
| 15 | Dodge / Dash | 5 | Low side-step, lower to ground than Quinn |
| 16 | Hide — enter hiding spot | 6 | Ducks down, brings knees in, silhouette nearly disappears |

**AI Prompt:**
> Pixel art sprite sheet, Tintin ligne claire style, transparent background.
> Canvas 320 × 544 px, 32×32 tiles, 17 rows × 10 columns. Subject: teenage
> girl, lithe build, short red-auburn hair, dark-green fitted jacket, black
> jeans, scuffed sneakers. Small orange flame flickers at fingertips in idle
> and attack frames. Animations: idle (flame flicker), walk-toward, walk-away,
> walk-right, fast-run-toward, fast-run-away, fast-run-right (aggressive lean),
> fire-jab-attack-right (hand ignites → burst → fades), fast-talk-special
> (rapid gestures + speech glyph above head), stealth-crouch-tiptoe, talking-
> full-body, talking-closeup, hurt-stumble-hair-flick, death-fall-forward
> (flame extinguishes), revive-roll-push-up, dash-low-sidestep, hide-crouch-
> disappear. Bold 1px black outlines, flat colors, 16-color PICO-8 palette,
> no anti-aliasing.

**Save to:** `assets/art/sprites/erin.png`

---

### Evan

**Visual:** Teenage, noticeably broader and bigger than other characters —
he is the tank. Casual: worn olive/khaki t-shirt, cargo shorts, hiking boots.
Fists are his weapons (no tool). Often has an animal visible nearby in idle.
Warm, open face with strong jaw. Super-strength reads in exaggerated flexing
during heavy-lift animations. Slowest character but hits hardest.

**Palette slots:** Olive/khaki (#AB5236 desaturated) t-shirt, brown (#5F574F)
cargo shorts, warm skin (#FFCCAA + #AB5236 blend), worn boot brown.

**Sprite sheet:** 17 rows × 32 px = **320 × 544 px**

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Hands at sides; Frosty the dog sits at his feet (visible at bottom 8 px of tile) |
| 1 | Walk — down | 8 | Wide, confident stride |
| 2 | Walk — up | 8 | |
| 3 | Walk — right | 8 | |
| 4 | Run — down | 8 | Heavy run — slowest of all characters |
| 5 | Run — up | 8 | |
| 6 | Run — right | 8 | |
| 7 | Attack — right | 6 | Straight punch: fist extends past tile edge on frame 3 |
| 8 | Special — Animal call | 8 | Two-finger whistle (1–4), then pointing gesture (5–8); small paw-print glyph emits |
| 9 | Lift / Shove | 8 | Crouches and grabs (1–3), heaves upward (4–6), releases (7–8) — for heavy puzzle props |
| 10 | Talking — full body | 6 | Big arm gestures; slightly loud personality reads in the pose |
| 11 | Talking — closeup | 8 | |
| 12 | Hurt | 4 | Barely flinches — small stumble only |
| 13 | Death / Down | 10 | Slow, heavy fall; takes longer than other characters |
| 14 | Revive | 8 | Rolls, one knee, stands with effort |
| 15 | Dodge / Dash | 5 | Shortest dash of all characters |
| 16 | Brace / Hold | 6 | Feet wide, arms spread, leaning into something — used for two-point puzzle holds |

**AI Prompt:**
> Pixel art sprite sheet, Tintin ligne claire style, transparent background.
> Canvas 320 × 544 px, 32×32 tiles, 17 rows × 10 columns. Subject: teenage
> boy, broad/muscular build (visibly larger than other characters), worn olive
> khaki t-shirt, brown cargo shorts, hiking boots, warm skin tone. White
> schnoodle dog (Frosty) visible at his feet in idle frame. Animations: idle
> (dog at feet), walk-toward, walk-away, walk-right, heavy-run-toward,
> heavy-run-away, heavy-run-right, straight-punch-right (fist extends beyond
> tile), animal-call-whistle-point (paw glyph emits), heavy-lift-shove
> (crouches → heaves → releases), talking-full-body (big gestures),
> talking-closeup, hurt-slight-flinch, death-heavy-slow-fall, revive-knee-stand,
> short-dash-right, brace-wide-stance. Bold 1px black outlines, flat colors,
> 16-color PICO-8 palette, no anti-aliasing.

**Save to:** `assets/art/sprites/evan.png`

---

### Ben

**Visual:** Teenage, medium build, full bard energy. Patchwork jacket
(multiple muted colors sewn together — the classic bard coat), dark trousers,
worn ankle boots. Electric keytar always slung across his body; it glows
faintly cyan at the keys during attacks and specials. Messy mid-brown hair,
easy smile. Musical note and sound-wave pixel glyphs appear during attacks
and specials.

**Palette slots:** Patchwork jacket uses several slots (blue, green, red
patches — one per palette color), dark grey (#5F574F) trousers, grey/black
keytar body with cyan (#29ADFF) glowing keys, mid-brown hair (#AB5236).

**Sprite sheet:** 17 rows × 32 px = **320 × 544 px**

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Keytar resting; fingers tap keys; small musical note glyph floats upward |
| 1 | Walk — down | 8 | Keytar sways with step |
| 2 | Walk — up | 8 | |
| 3 | Walk — right | 8 | |
| 4 | Run — down | 8 | Keytar tucked under arm while running |
| 5 | Run — up | 8 | |
| 6 | Run — right | 8 | |
| 7 | Attack — right | 6 | Keytar swing: raise over shoulder (1–2), swing forward (3), follow-through (4–6) |
| 8 | Special — AoE musical wave | 8 | Plants feet, plays hard; concentric sound-wave rings radiate outward frames 4–8; note glyphs scatter |
| 9 | Perfect Pitch listen | 6 | Tilts head, hand cupped to ear; musical note glyphs appear above head |
| 10 | Talking — full body | 6 | Enthusiastic, big gestures |
| 11 | Talking — closeup | 8 | Wide grin, eyebrows active |
| 12 | Hurt | 4 | Recoil; keytar swings wildly |
| 13 | Death / Down | 10 | Falls; keytar clatters down beside him at frame 7 |
| 14 | Revive | 8 | Rolls up; grabs keytar first, then stands |
| 15 | Dodge / Dash | 5 | |
| 16 | Perform — crowd address | 8 | Full-body performance pose; arms out, slight sway; note glyphs everywhere |

**AI Prompt:**
> Pixel art sprite sheet, Tintin ligne claire style, transparent background.
> Canvas 320 × 544 px, 32×32 tiles, 17 rows × 10 columns. Subject: teenage
> boy, medium build, multi-color patchwork jacket (each patch a different
> palette color), dark trousers, ankle boots, messy brown hair. Electric
> keytar slung across body with glowing cyan keys. Musical note and sound-wave
> pixel glyphs appear in attack and special frames. Animations: idle (finger
> tap, floating note glyph), walk-toward, walk-away, walk-right, run-toward
> (keytar tucked), run-away, run-right, keytar-club-swing-attack,
> aoe-musical-wave-special (planted stance, concentric rings + note scatter),
> perfect-pitch-listen (hand to ear, notes above head), talking-full-body,
> talking-closeup (wide grin), hurt-recoil-keytar-swings, death-fall-keytar-
> clatters-beside, revive-grab-keytar-first, dash-right, crowd-address-perform
> (arms out, swaying). Bold 1px black outlines, flat colors, 16-color PICO-8
> palette, no anti-aliasing.

**Save to:** `assets/art/sprites/ben.png`

---

### Ethan

**Visual:** Teenage, wiry/lean build. Tech-casual: grey hoodie, dark navy
cargo pants with gadget-stuffed pockets, sneakers. Always has a small glowing
device in hand or clipped to belt — like a cross between a phone and a hacking
tool. Dark-blue rectangular AR glasses (simple dark-blue rectangles at this
resolution). Short neat dark hair. Efficient, purposeful movements. Cyan
data-stream glyphs appear during hack specials.

**Palette slots:** Grey (#C2C3C7) hoodie, dark navy (#1D2B53) cargo pants,
cyan (#29ADFF) device glow and AR-glasses tint, dark hair (#1D2B53).

**Sprite sheet:** 17 rows × 32 px = **320 × 544 px**

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Glances at device; screen pulses cyan every 3 frames |
| 1 | Walk — down | 8 | Device at side |
| 2 | Walk — up | 8 | |
| 3 | Walk — right | 8 | |
| 4 | Run — down | 8 | Device pocketed while running |
| 5 | Run — up | 8 | |
| 6 | Run — right | 8 | |
| 7 | Attack — right | 6 | Gadget zap: extends device (1–2), energy burst emits (3), recover (4–6) |
| 8 | Special — Hack | 8 | Stops; both hands on device; rapid typing; cyan digit glyphs radiate outward frames 4–8 |
| 9 | Panel interact | 6 | Crouching at panel; device plugged in; progress glyph above head |
| 10 | Talking — full body | 6 | Device in hand; gestures with it |
| 11 | Talking — closeup | 8 | AR glasses faintly lit; thoughtful expression |
| 12 | Hurt | 4 | Device briefly flies out of hand; scrambles to catch it |
| 13 | Death / Down | 10 | Falls; device screen goes dark at final frame |
| 14 | Revive | 8 | Recovers; checks device screen first thing |
| 15 | Dodge / Dash | 5 | |
| 16 | Lizard summon | 6 | Holds device up, beeps (1–3); small green lizard appears on arm (4–6) |

**AI Prompt:**
> Pixel art sprite sheet, Tintin ligne claire style, transparent background.
> Canvas 320 × 544 px, 32×32 tiles, 17 rows × 10 columns. Subject: teenage
> boy, lean wiry build, grey hoodie, dark navy cargo pants with gadget pockets,
> sneakers, short dark hair, dark-blue rectangular AR glasses. Small glowing
> cyan hacking device always in hand or clipped to belt. Cyan digit/data-stream
> glyphs appear during hack and attack frames. Animations: idle (device glance,
> cyan pulse), walk-toward, walk-away, walk-right, run-toward (device pocketed),
> run-away, run-right, gadget-zap-attack-right (extends device, energy burst),
> hack-special (rapid typing, digit glyphs radiate), panel-crouch-interact
> (plugged in, progress glyph), talking-full-body (device in hand), talking-
> closeup (AR glasses lit), hurt-drops-device, death-screen-goes-dark, revive-
> checks-device-first, dash-right, lizard-summon (lizard appears on arm). Bold
> 1px black outlines, flat colors, 16-color PICO-8 palette, no anti-aliasing.

**Save to:** `assets/art/sprites/ethan.png`

---

## Animal Companions

### Frosty — Schnoodle (Schnauzer/Poodle mix)

**Visual:** Medium-small dog, fluffy white fur. Schnauzer facial structure
(slightly blocky muzzle) with poodle fluffiness. Always alert and eager.
General-purpose combat companion — charges enemies, headbutts, returns.

**Palette slots:** Near-white (#FFF1E8) fur, pink (#FF77A8) tongue/inner ears,
dark dot eyes, black nose.

**Sprite sheet:** 11 rows × 32 px = **320 × 352 px**

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Tail wag (3-frame loop); head-tilt at frame 5 |
| 1 | Trot — down | 8 | |
| 2 | Trot — up | 8 | |
| 3 | Trot — right | 8 | |
| 4 | Gallop — down | 8 | |
| 5 | Gallop — up | 8 | |
| 6 | Gallop — right | 8 | |
| 7 | Charge / Headbutt attack | 6 | Low sprint (1–3), head-down ram (4), bounce back (5–6) |
| 8 | Hurt | 4 | Yip and stumble |
| 9 | Death / Down | 8 | Lies flat; tail stops |
| 10 | Return to owner | 6 | Happy trot, tail high |

**AI Prompt:**
> Pixel art sprite sheet, Tintin style, transparent background. Canvas
> 320 × 352 px, 32×32 tiles, 11 rows × 10 columns. Subject: small fluffy
> white dog, Schnauzer/Poodle mix, slightly blocky muzzle, round dark eyes,
> pink tongue visible in active frames. Animations: idle (tail wag, head
> tilt), trot-toward, trot-away, trot-right, gallop-toward, gallop-away,
> gallop-right, headbutt-charge-attack (low sprint → head-down ram → bounce
> back), hurt-stumble-yip, death-lie-flat (tail stops), happy-return-trot
> (tail high). Bold 1px black outlines, flat colors, 16-color PICO-8 palette.

**Save to:** `assets/art/sprites/frosty.png`

---

### Twinkle — Pomeranian

**Visual:** Very small dog — noticeably smaller than Frosty. Round fluffy
ball of cream-colored fur. Distinctive and non-negotiable: perpetually
blank/cloudy eyes (she is blind), single prominent snaggle tooth visible
even at rest, slightly wobbly stance. She looks ridiculous. That is the
point. Her bark is her weapon.

**Palette slots:** Cream (#FFF1E8) fur, tiny dark eye dots (barely visible —
cloudy), ivory snaggle tooth, tiny pink tongue.

**Sprite sheet:** 9 rows × 32 px = **320 × 288 px**

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Tiny wobble; snaggle tooth always visible; cloudy eyes |
| 1 | Trot — down | 6 | Legs are so short this looks ridiculous |
| 2 | Trot — right | 6 | |
| 3 | Bark / Distract | 8 | Full-body bark: bounces with each bark, mouth wide, snaggle tooth prominent, concentric sound rings emit |
| 4 | Return trot | 6 | Same as trot-right; code flips |
| 5 | Hurt | 4 | Tiny stumble; indignant expression |
| 6 | Death / Down | 6 | Flops over; one tiny leg points up |
| 7 | Sniff | 4 | Nose to ground; tail straight up |
| 8 | Annoyed | 4 | Sits; turns head away — used after failed actions |

**AI Prompt:**
> Pixel art sprite sheet, Tintin style, transparent background. Canvas
> 320 × 288 px, 32×32 tiles, 9 rows × 10 columns. Subject: very small, round,
> extremely fluffy cream-colored Pomeranian — noticeably smaller than Frosty.
> Cloudy/blank eyes (she is blind), single prominent snaggle tooth always
> visible, slightly wobbly unsteady stance. Comedic proportions encouraged.
> Animations: idle (tiny wobble, snaggle tooth, cloudy eyes), trot-toward,
> trot-right, full-body-bark (bouncing, mouth wide, sound rings emit), return-
> trot, hurt-tiny-stumble-indignant, death-flop-leg-up, nose-to-ground-sniff,
> annoyed-head-turn. Bold 1px black outlines, flat colors, 16-color PICO-8
> palette.

**Save to:** `assets/art/sprites/twinkle.png`

---

### William & Mary — Rabbits (always a pair)

**Visual:** Always together on the same sheet — every frame contains both
rabbits. William is slightly larger and looks curious/adventurous; Mary is
calmer and more compact. William: grey-and-white. Mary: mostly white. They
are never split; the code always treats them as a unit.

**Palette slots:** Mid-grey (#5F574F) William main fur, off-white (#FFF1E8)
Mary, pink inner ears (#FF77A8), dark dot eyes.

**Sprite sheet:** 8 rows × 32 px = **320 × 256 px** — both rabbits fit
side-by-side in each 32 × 32 tile (they are small).

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle — pair | 6 | Nose-twitch loop; William looks around, Mary is still |
| 1 | Hop — down (pair) | 8 | Synchronized hopping gait |
| 2 | Hop — right (pair) | 8 | |
| 3 | Brace / Hold — right (pair) | 6 | Both pressed against an object, pushing; feet dug in |
| 4 | William — squeeze through gap | 6 | William low-crawls sideways through narrow gap; Mary waits behind |
| 5 | Reunite | 6 | William returns; nose-bump with Mary |
| 6 | Hurt — pair | 4 | Both startle; ears flat |
| 7 | Death / Down — pair | 8 | Both lie flat simultaneously |

**AI Prompt:**
> Pixel art sprite sheet, Tintin style, transparent background. Canvas
> 320 × 256 px, 32×32 tiles, 8 rows × 10 columns. Subject: TWO rabbits
> present together in every frame — William (slightly larger, grey-and-white,
> alert adventurous look) and Mary (smaller, mostly white, calm). Animations:
> idle-pair (nose twitch, William looks around), hop-toward-pair, hop-right-pair,
> brace-push-pair (both feet dug in against object edge), william-solo-squeeze-
> through-gap (low sideways crawl; Mary waits), reunite-nose-bump, hurt-startle-
> pair (ears flat), death-lie-flat-pair. Both rabbits visible in every row.
> Bold 1px black outlines, flat colors, 16-color PICO-8 palette.

**Save to:** `assets/art/sprites/william_and_mary.png`

---

### Calvin & Coolidge — Great Pyrenees (always a pair)

**Visual:** Two large, white, fluffy mountain dogs — significantly bigger than
Frosty. Calvin is slightly heavier-set (the charger); Coolidge is slightly
leaner (the brace/pusher). Both have the characteristic Great Pyrenees
lion-like mane and heavy paws. Imposing at rest; devastating in a charge.
Always together; code never separates them.

**Palette slots:** White (#FFF1E8) main coat, light grey (#C2C3C7) mane depth
shading, dark eyes and nose, pink tongue.

**Sprite sheet:** 9 rows × 32 px = **320 × 288 px** — note: if 32×32 is too
cramped for two large dogs, use 48 × 32 px tiles (sheet becomes 480 × 288 px).

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle — pair | 6 | Both stand side by side; slow breath; tails sway |
| 1 | Walk — down (pair) | 8 | Heavy, dignified gait |
| 2 | Walk — right (pair) | 8 | |
| 3 | Calvin charge attack | 6 | Calvin sprints hard, shoulder-first slam; Coolidge follows behind |
| 4 | Coolidge brace / push | 6 | Coolidge plants wide, leans hard into large object; Calvin flanks |
| 5 | Dual charge — split | 8 | Calvin breaks left, Coolidge breaks right simultaneously — two-target charge |
| 6 | Hurt — pair | 4 | Both flinch; manes ripple |
| 7 | Death / Down — pair | 8 | Both lie flat; manes spread wide |
| 8 | Return to Evan | 6 | Trot back side by side; tails up |

**AI Prompt:**
> Pixel art sprite sheet, Tintin style, transparent background. Canvas
> 320 × 288 px, 32×32 tiles, 9 rows × 10 columns. Subject: TWO large white
> Great Pyrenees dogs always together in every frame — Calvin (heavier-set,
> charger) and Coolidge (slightly leaner, braces). Both have lion-like manes
> and heavy paws, visibly larger than Frosty. Animations: idle-pair (slow
> breath, tail sway), heavy-walk-toward-pair, heavy-walk-right-pair, calvin-
> shoulder-charge (Calvin sprints ahead, Coolidge follows), coolidge-brace-
> push (Coolidge wide-planted against object, Calvin flanks), dual-charge-split
> (both break in opposite directions simultaneously), hurt-flinch-mane-ripple-
> pair, death-lie-flat-manes-spread-pair, return-trot-pair (tails up). Both
> dogs in every frame. Bold 1px black outlines, flat colors, 16-color PICO-8
> palette.

**Save to:** `assets/art/sprites/calvin_and_coolidge.png`

---

### Guinea Pigs — Crowd (unnamed, numerous)

**Visual:** A scurrying group of 3–4 guinea pigs per frame. Small round
bodies, short legs, varied colorings (brown, white, tan — classic guinea pig
tri-color). Their purpose is crowd-cover chaos — filling a floor with
distracting scurrying motion — so animations emphasize mass movement.

**Palette slots:** Brown (#AB5236), white (#FFF1E8), tan (#FFCCAA) varied
across the 3–4 individuals, tiny dark eyes.

**Sprite sheet:** 6 rows × 32 px = **320 × 192 px**

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle scatter | 6 | 4 guinea pigs milling, randomly oriented; slight position shifts each frame |
| 1 | Scurry — right | 8 | Rapid little legs; group moves as a loose cluster |
| 2 | Scurry — down | 8 | |
| 3 | Flood — panic scatter | 8 | Group explodes outward from center — used on summon/release |
| 4 | Calm — regroup | 6 | Pigs slow and cluster back together |
| 5 | Death | 6 | All four roll onto backs; tiny legs up |

**Save to:** `assets/art/sprites/guinea_pigs.png`

---

### Lizard — Wall Climber (unnamed)

**Visual:** Medium gecko/skink type — slim, not large. Tail approximately
1.5× body length. Olive-green with darker stripe markings. Primary purpose
is vertical traversal (scaling walls and pipes the duo cannot reach), so the
climb animation is the hero animation for this sprite.

**Palette slots:** Olive green (#008751 desaturated), dark stripe markings
(#5F574F), tiny yellow eye (#FFEC27).

**Sprite sheet:** 7 rows × 32 px = **320 × 224 px**

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 4 | Tongue flick; toe-pads pressed flat |
| 1 | Walk — right (ground) | 6 | Low-slung crawl; limbs alternate |
| 2 | Climb — upward | 8 | Belly flat on vertical surface (viewed from side); limbs alternate; tail swings for balance |
| 3 | Perch / Hold | 4 | Stationary on elevated surface; tail curled — used when holding at target switch |
| 4 | Target reached | 4 | Tail flick, head nod — success signal to Ethan |
| 5 | Descend | 8 | Climb animation reversed; head pointing down |
| 6 | Flee / Scatter | 4 | Rapid sprint away |

**Save to:** `assets/art/sprites/lizard.png`

---

## Enemies

### Grunt

**Visual:** Stocky, anonymous aggressor. Worn jacket, heavy boots, gloves.
Face partly obscured by a bandana or cap brim — deliberately generic threat.
Carries a blunt weapon (pipe or bat) in one hand. Should read instantly as
"enemy" at 32 × 32 from the silhouette alone.

**Palette slots:** Dark grey (#5F574F) jacket, navy (#1D2B53) trousers,
red (#FF004D) bandana accent.

**Sprite sheet:** 8 rows × 32 px = **320 × 256 px**

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Patrol / Idle | 6 | Slow walk-in-place; glances left and right |
| 1 | Chase — right | 8 | Purposeful walk toward target |
| 2 | Windup — telegraph | 6 | Raises weapon overhead; holds at frame 5–6 (the visible tell) |
| 3 | Strike — right | 4 | Weapon comes down fast |
| 4 | Recover | 4 | Weapon low; briefly exposed |
| 5 | Hurt | 4 | Staggers back |
| 6 | Death | 8 | Crumples; weapon drops beside him |
| 7 | Alert scan | 4 | Head turns slowly to scan; used for stealth vision-cone context |

**Save to:** `assets/art/sprites/grunt.png`

---

### Runner

**Visual:** Smaller and leaner than the Grunt — built for speed, not power.
Tracksuit or lightweight athletic gear. No visible weapon — attacks with
quick jabs and kicks. A slightly manic, coiled energy even in idle. Fastest
enemy; lowest health.

**Palette slots:** Cyan (#29ADFF) tracksuit (visually distinct from Grunt's
grey at a glance), white stripe accent, dark boots.

**Sprite sheet:** 8 rows × 32 px = **320 × 256 px**

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Patrol / Idle | 6 | Bounces on heels; quick darting eyes |
| 1 | Sprint — right | 8 | Very fast, aggressive forward lean — distinct from Grunt's walk |
| 2 | Windup | 4 | Short and sharp — noticeably less warning than the Grunt |
| 3 | Strike | 3 | Quick jab or kick — fastest strike |
| 4 | Recover | 4 | Darts back to distance |
| 5 | Hurt | 3 | Small stumble; bounces back fast |
| 6 | Death | 6 | Falls quickly — shorter animation than Grunt |
| 7 | Dash-in | 5 | Signature charge move: low sprint burst before striking |

**Save to:** `assets/art/sprites/runner.png`

---

### Brute

**Visual:** Massive — noticeably wider and taller than all other characters.
Gym-wear: tank top, track pants, worn trainers. Big bouncer energy. Slow but
every movement has weight — arms visibly thick even at 32 × 32. Primary
enemy in Iron & Strings Gym. Hits hardest of all enemies; slowest windup but
heaviest damage.

**Sprite tile: 48 × 32 px** (wider than standard to give the silhouette room).

**Palette slots:** Dark red (#7E2553) tank top, grey (#C2C3C7) track pants,
warm skin (#FFCCAA + #AB5236).

**Sprite sheet:** 8 rows × 48 px = **480 × 256 px** (10 frames × 48 px wide)

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Patrol / Idle | 6 | Slow sway; arms loose; weight visible |
| 1 | Chase — right | 8 | Heavy lumbering walk; slowest enemy by spec |
| 2 | Windup — telegraph | 8 | Long, exaggerated arm-raise; hold at frame 7–8 (the spec's 0.8s tell) |
| 3 | Strike | 4 | Overhead slam; massive impact |
| 4 | Recover | 6 | Slow to reset — the exploitable window |
| 5 | Hurt | 4 | Barely reacts; small stumble |
| 6 | Death | 10 | Massive slow fall — camera shake fires in code when this plays |
| 7 | Stagger | 4 | Pushed back, arms flail — used when hit by an animal charger |

**Save to:** `assets/art/sprites/brute.png`

---

### Sentry

**Visual:** Upright vigilant posture — like a security guard. Dark uniform
jacket, peaked cap. Holds a ranged weapon: a dart pistol or futuristic zapper
(read-as-weapon but non-realistic — this is not a firearm). Used in The
Library & Archive and The VR Escape Room. Measured, methodical movements.

**Palette slots:** Navy (#1D2B53) uniform, dark cap, orange (#FFA300) weapon
accent (makes it read clearly), white (#FFF1E8) gloves.

**Sprite sheet:** 8 rows × 32 px = **320 × 256 px**

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Patrol | 6 | Measured formal walk-in-place; head scans |
| 1 | Chase — right | 8 | Approaches to attack range, then holds |
| 2 | Windup — take aim | 6 | Raises weapon; plants feet; the telegraph |
| 3 | Fire — right | 4 | Short decisive shot; muzzle flash at frame 2 |
| 4 | Recover | 4 | Returns weapon to ready position |
| 5 | Hurt | 4 | Stumble; holds weapon |
| 6 | Death | 8 | Falls; weapon drops |
| 7 | Alert scan | 4 | Head and weapon sweep — vision-cone context |

**Save to:** `assets/art/sprites/sentry.png`

---

### Projectile — Sentry Shot

**Visual:** Small fast-moving bolt or energy disc. Cyan/orange glow. Just a
spin or pulse loop — this is on-screen for a fraction of a second.

**Sprite tile: 16 × 16 px.** Sheet: **160 × 16 px** (10 frames × 16 px).

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Fly | 4 | Spinning or pulsing glow loop |

**Save to:** `assets/art/sprites/projectile_sentry.png`

---

### Boss — Clockwork Guardian

**Visual:** Large mechanical figure — armored, angular, clearly constructed.
Gear motifs: visible spinning gears on shoulders or chest plate. Single
glowing red eye. Conveys mass and power. Appears as the Clocktower guardian
and the Grand Marquee Cinema's final guardian — same sprite, both roles.
Use **64 × 64 px tiles** for presence.

**Palette slots:** Iron grey (#5F574F) armor, gold (#FFA300) gear accents,
red (#FF004D) glowing eye, off-white (#FFF1E8) AoE warning ring outline.

**Sprite sheet:** 10 rows × 64 px = **640 × 640 px** (10 frames × 64 px wide)

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Shoulder gears visibly spinning; eye pulses red |
| 1 | Chase — right | 8 | Slow, ground-shaking advance |
| 2 | Windup — melee | 6 | Heavy arm raises; eye brightens to full red |
| 3 | Strike — melee | 4 | Heavy downward slam |
| 4 | Recover | 4 | |
| 5 | AoE telegraph | 8 | Plants both feet; eye blazes; arms spread wide (the in-game expanding ring is drawn in code, but this pose sells the tell) |
| 6 | AoE slam | 6 | Both fists down; shockwave implied frames 4–6 |
| 7 | AoE recover | 6 | Rises back to standing; gears still spinning |
| 8 | Hurt | 4 | Staggers; armor dents slightly |
| 9 | Death | 12 | Gear-by-gear wind-down; collapses slowly; eye dims and goes dark at final frame |

**Save to:** `assets/art/sprites/boss.png`

---

## NPCs

### Uncle Doug

**Visual:** Middle-aged man — balding on top with a trim greying stubble beard, stocky
build,  glasses on a chain. Rumpled collared shirt and slacks: he did
not dress for an adventure. Warm and slightly bewildered expression. Found in
the projection booth at the end of The Grand Marquee Cinema.

**Sprite sheet:** 4 rows × 32 px = **320 × 128 px**

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Adjusts glasses; nervous glance around |
| 1 | Wave / Relief | 8 | Waves with both arms; wide relieved smile — the rescue payoff moment |
| 2 | Talking — full body | 6 | |
| 3 | Talking — closeup | 8 | Glasses slightly askew; warm and thankful expression |

**Save to:** `assets/art/sprites/uncle_doug.png`

---

### Librarian

**Visual:** Strict, formal. Reading glasses on the end of the nose. Hair in a
tight bun. Cardigan over a collared shirt. Carries a large hardcover book or
a stamp at all times. The desk-blocker NPC in The Public Library & Archive.
Her "step aside" animation is the payoff for Erin's Fast Talk.

**Sprite sheet:** 4 rows × 32 px = **320 × 128 px**

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Stamps books; glasses gleam; expression severe |
| 1 | Refuse | 6 | Shakes head firmly; points back the way the duo came |
| 2 | Talked-down / Step aside | 8 | Sighs visibly; packs up book; steps to the side |
| 3 | Talking — closeup | 6 | Severe at frame 1; softens slightly by frame 6 (Fast Talk worked) |

**Save to:** `assets/art/sprites/librarian.png`

---

### Carnival Guard

**Visual:** Theatrical — this is a fairground so the guard wears an
old-fashioned circus-uniform: red jacket with gold braid, black trousers,
flat cap with a badge. Broad-shouldered but not genuinely threatening —
more jobsworth bouncer than actual danger. Guards the backstage curtain at
The Carnival & Fairground.

**Sprite sheet:** 4 rows × 32 px = **320 × 128 px**

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Arms crossed; tapping foot |
| 1 | Refuse | 6 | Shakes head; one hand out in stop-gesture |
| 2 | Convinced / Step aside | 8 | Looks surprised (frame 3), then amused (frame 5), then waves through and steps out of the way |
| 3 | Talking — closeup | 6 | Skeptical expression; gold-braid cap badge visible |

**Save to:** `assets/art/sprites/carnival_guard.png`

---

## Notes for Art Generation

- **Left-facing versions of all walk/run/attack animations are code-flips of
  the right-facing row.** Do not generate separate left rows.
- **All sheets share the 16-color PICO-8 palette.** When prompting an AI tool,
  include: `"16-color PICO-8 palette, no anti-aliasing, no dithering"` to
  enforce the constraint.
- **Unused frames at the end of a row are transparent** — if an animation has
  fewer than 10 frames, pad the remaining columns with fully transparent 32×32
  tiles.
- **Place finished sheets in** `assets/art/sprites/` and update
  `scripts/systems/placeholder_art.gd` to load from the file path instead of
  generating procedurally — the `PlaceholderArt` functions remain as fallbacks
  for any sprite not yet replaced.
