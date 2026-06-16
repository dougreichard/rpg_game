# Level Elaboration Plan — Hunkle Bunkle

> ## ✅ STATUS: COMPLETE — all 13 levels rebuilt & verified.
> Every level is multi-room with thematic tiling surfaces + corner trim (VR keeps its
> neon grid), the scaled puzzle counts, and a per-level Uncle-Doug clue paid off at the
> Grand Marquee clue-board. Each level was boot-checked and run through a reveal/floor
> physics checklist. 13 new items added (`pressed_flower`, `boiler_key`, `archive_key`,
> the `doug_*` clue trail). New puzzles were assigned to abilities **present in each
> level's duo** (some plan assignments below were reassigned accordingly — noted inline).
> CLAUDE.md is synced. This doc is retained as the design record.

A game-wide pass to make each of the 13 locations feel like a distinct **building
you explore**, not a single themed box: unique surfaces, multi-room layouts joined
by usable corridors, puzzles keyed to each location's theme, an escalating amount of
content as the game progresses, a per-level thread of the **find-Uncle-Doug** story,
and a light web of cross-level **keys**.

> **Working mode:** this doc is approved first; then build **level-by-level** with an
> in-engine capture check after each. The reusable kit (`Level3D` corridors, `room()`,
> `set_theme`, `WorkStation3D`, stealth, NPC/dialog) already exists — this is content
> + layout work on top of it, not new engine systems.
>
> **Decisions locked (from review):** keys are *mostly optional shortcuts + a few
> required gates*; Doug content is a *clue item **plus** a per-level mini-objective*;
> deliver *design-doc-first, then build*.

---

## 0. Principles

1. **Three-layer visual identity** per location (rooms / corridors / corner-trim) — §1.
2. **Lobby convention preserved:** first room is combat-free, holds the dialog NPC + exit.
3. **Puzzles key to the theme** (§6 in the points list): the mechanic *is* the place
   (organ-tuning at the Pipe Works, sound at the Studio, hacking at VR, etc.).
4. **Ability-gating stays meaningful:** each puzzle wants the *specific* active-duo
   ability, so swapping matters.
5. **Escalation:** higher-numbered levels get more rooms, more puzzle steps, more
   dialog branches, and bigger encounters — §2.
6. **Doug through-line:** every level yields one tangible clue **and** a small
   Doug-themed objective that ladders toward the endgame — §3.
7. **Keys web the game together** without creating soft-locks — §4.
8. **Don't lose existing content** — every current puzzle/NPC/flag is preserved or
   extended, never deleted (explicit for the Church, §5.2).

---

## 1. Visual system — three thematic layers

Built and proven in **Pipe Organ Works** (reference implementation). Uses the existing
tiling textures in `assets/art/tiles/` via `Level3D.set_theme()` + the corridor/corner
geometry. Each layer is a separate uniqueness lever:

| Layer | Treatment | Why distinct |
|---|---|---|
| **Room** floor + wall | tiling texture + **warm** tint (`set_theme` before the room) | signature pattern per room *type* (marble entry, wood workshop…) |
| **Corridor** floor + wall | own texture + **cooler/greyer** tint | reads as a *connector*, not a room |
| **Corner posts / trim** | **solid colour** (untextured accent), posts taller than walls | crisp framing; also the seam-clean fix (no coplanar overlap) |

**Rule per level:** pick a textured floor+wall pair for signature rooms, a plainer pair
for corridors, and **one solid accent colour** for corner posts/trim. Vary floors
*within* a building so it reads as a sequence of spaces.

**Texture palette assignment (floor / wall / corner-accent):**

| # | Location | Signature rooms | Corridors | Corner accent |
|---|----------|-----------------|-----------|---------------|
| 1 | Pipe Organ Works | marble+brick (lobby), wood+wood (workshop), tile+stone (loft) | concrete+concrete | dark iron |
| 2 | Old Parish Church | church/marble + stone | stone + stone | dark wood |
| 3 | Iron & Strings Gym | concrete + concrete | concrete + brick | steel |
| 4 | Recording Studio | carpet + concrete | concrete + concrete | matte black |
| 5 | Clocktower | tile + stone | stone + brick | brass |
| 6 | Harbor & Docks | concrete + concrete | dirt + concrete | rusted steel |
| 7 | Library & Archive | carpet + wood | tile + wood | deep green |
| 8 | Carnival | dirt/ground + wood (tinted bright) | ground + wood | candy red/white |
| 9 | Underground Tunnels | concrete + stone | dirt + stone | rust |
| 10 | Zip Line Park | grass + wood | dirt + wood | forest green |
| 11 | VR Escape Room | tile (emissive blue) + neon-grid (keep special) | tile + concrete | cyan glow |
| 12 | The Drop | grass/dirt + stone | dirt + stone | olive |
| 13 | Grand Marquee Cinema | carpet (red) + brick | carpet + concrete | gold |

Notes: **VR** keeps its emissive neon-grid look (textures don't suit it); **Carnival**
leans on bright tints over wood/ground. Enable mipmaps on every texture used (done for
the full set already).

---

## 2. Elaboration curve (points 4 & 5)

Content scales with level number. Targets per tier (a *floor*, not a cap):

| Tier | Levels | Rooms (incl. lobby) | Corridors | **Puzzles** | NPC dialog | Combat |
|------|--------|--------------------|-----------|--------------|-----------|--------|
| **Intro** | 1–4 | 2–4 | 1–3 | **3–4** (teach one ability + 1–2 side puzzles) | 1 NPC, simple tree | small (0–2 rooms) |
| **Mid** | 5–9 | 4–6 (often multi-floor) | 3–5 | **4–6**, multi-ability, ≥1 chained | 1–2 NPCs, branching | medium + first bosses (5) |
| **Late** | 10–13 | 6+ multi-floor/region | 5+ (some are arenas) | **6–8**, chained + a key gate + an optional/bonus | 2–3 NPCs, choice-heavy | large; boss finale (13) |

"Puzzles" counts *distinct interactions*, not steps of one chain (a 3-step craft = 1).
Each puzzle still wants a *specific* active-duo ability, so the extra puzzles deepen
character-swap play rather than padding. At least one puzzle per Mid/Late level is
**optional/bonus** (loot or a shortcut, not required to clear) so the higher counts
reward exploration without lengthening the critical path. Puzzle *types* to draw from,
keyed to theme (§6 of the brief): craft/repair (Quinn), fast-talk/stealth (Erin),
strength/animal (Evan), sound/rhythm (Ben), hack/electronic (Ethan), plus
locked-door/key, timing-gate, multi-step, and pressure/weight or sequence puzzles.

- **Corridors-as-rooms:** in Mid/Late, at least one corridor per level is a *content*
  corridor (a chokepoint fight, a stealth gauntlet, a timing/lock puzzle), not just a link.
- Intro levels stay readable and teach (they each unlock a character).

---

## 3. Uncle Doug through-line (point 7)

Each level delivers **(a)** a collectible **clue** (lore item, short dialog on pickup)
and **(b)** a small **Doug mini-objective** that fits the location. Clues accumulate
toward the Grand Marquee reveal. Reuses the `faded_photograph` pattern + `ItemData`.

| # | Location | Clue item | Doug mini-objective (themed) |
|---|----------|-----------|------------------------------|
| 1 | Pipe Organ Works | `faded_photograph` (exists) | Bellows confirms Doug commissioned the organ repair "before he vanished" |
| 2 | Old Parish Church | pressed flower + dedication card | Find Doug's name in the memorial register (dialog reveal) |
| 3 | Iron & Strings Gym | Doug's gym locker tag | Open his locker (Evan strength) → a note |
| 4 | Recording Studio | reel-to-reel snippet | Restore + play Doug's recorded message (Ben tunes) |
| 5 | Clocktower | engraved pocket-watch back | Wind the watch into the mechanism (Quinn) → time clue |
| 6 | Harbor & Docks | shipping manifest line | Viktor confirms Doug on a manifest; recover the crate tag |
| 7 | Library & Archive | library checkout card (Doug's) | Hack the archive for Doug's borrowed file (Ethan) |
| 8 | Carnival | strip of photo-booth photos | Fix the photo booth (Quinn) → a printed clue |
| 9 | Underground Tunnels | Doug's flashlight w/ scratched note | Open the sealed vault (Evan+Ethan) → the big clue |
| 10 | Zip Line Park | carabiner with initials | Retrieve a clue bag snagged on the high line (Ben timing) |
| 11 | VR Escape Room | corrupted save-file avatar | Recover Doug's VR session log (Quinn+Ethan) |
| 12 | The Drop | torn marquee flyer | Rio confirms the flyer points to the cinema |
| 13 | Grand Marquee Cinema | — (payoff) | All clues assemble; Doug found in the projection booth |

---

## 4. Key & lock map (point 8)

**Mostly optional shortcuts + a few required gates.** Optional keys *skip a puzzle* or
open *bonus* rooms; required keys are always obtainable from an **already-unlocked**
earlier level (overworld revisits prevent soft-locks). Locked doors are themselves a
puzzle (find-the-key, or hack/force as an alternative).

**Required (small set):**
- `pocket_lantern` — Harbor → **Underground** entry gate. *(exists)*
- 5 character `movie_ticket`s — collected across levels → **Grand Marquee** entry. *(exists)*
- `rusty_key` — Underground-internal shortcut/door. *(exists)*

**Optional shortcuts (key found earlier → skips a beat later):**

| Key | Found in | Opens / skips |
|-----|----------|---------------|
| `crowbar` | Harbor | force a stuck crate w/o summoning the dogs |
| `library_card` | (Carnival lost-and-found) | bypass Library desk gate |
| `backstage_pass` | Recording Studio | skip Carnival backstage-guard talk-down |
| `security_badge` | Underground Pump Room | auto-fills one pip of the hatch hack |
| `sheet_music` | Recording Studio | gives Ben the Clocktower bell sequence |
| `tuning_fork` | Clocktower | highlights correct chime in sound puzzles (Studio/Cinema) |
| `vr_override_chip` | Library archive | clears one VR stage instantly |
| `film_reel` | Carnival | half of the Cinema projector repair |
| `spare_clockwork_gear` | Pipe Organ secret nook | speeds Clocktower gear repair |
| **new:** `boiler_key` | Gym boiler room | opens a Harbor shortcut storeroom (bonus loot) |
| **new:** `archive_key` | Clocktower | opens a locked Library stack (bonus + a Doug clue copy) |

Each "found in" item is placed as loot (`box_mesh` crate + `grant_item` in `_on_special`)
and each "opens" door checks `GameManager.has_item(...)` with a non-key fallback
(ability) so it never hard-blocks.

---

## 5. Per-level designs

Format per level: **Surfaces · Rooms/Corridors · Puzzles (theme-keyed, ability) ·
Combat · NPC/Dialog · Doug · Keys (in/out)**. Existing flags/puzzles are **kept**;
new content is marked **(new)**.

### 5.1 Pipe Organ Works (1) — *reference, mostly done*
- **Surfaces:** done (marble lobby / wood workshop / tile-stone loft / concrete corridors / iron trim).
- **Rooms:** lobby, storeroom, workshop, stair alcove, F2 landing/loft, secret nook. Corridors done.
- **Puzzles (4):** gather→mill→assemble organ chain (Quinn); Erin tuning-key fast-talk; secret lever; **(new)** restore power — Quinn flips the breaker panel in the right sequence to wake the workshop tools (sequence puzzle). **Fix:** secret nook never opens — see §6.
- **Doug:** Bellows commission line + `faded_photograph`.
- **Keys:** out → `spare_clockwork_gear` (secret nook, optional, helps Clocktower).

### 5.2 Old Parish Church (2) — *preserve dialogue puzzles (point 3)*
- **Surfaces:** church/marble floor, stone walls; dark-wood trim.
- **Rooms (new layout, same puzzles):** **Nave** (lobby — Father Aldric, exit) → corridor → **Vestry** (Quinn respectful-demeanor beat) → **Crypt** (Erin see-through-deception beat) → small **bell alcove**.
- **Puzzles (4):** *unchanged in spirit* — `quinn_done` (respect earns trust) + `erin_done` (skepticism) gate `secret_revealed`; `father_aldric_impression`. **(new)** light the candle sconces in the correct liturgical order (Quinn, sequence) to open the vestry; **(new)** Erin reads the crypt epitaphs to spot the false plaque (observation) hiding a passage. Distributed across the rooms so it's a walk-and-talk. **No combat** (kept dialogue-heavy).
- **Doug:** memorial register reveal + pressed-flower clue.
- **Keys:** none required. Unlocks **Evan**.

### 5.3 Iron & Strings Gym (3)
- **Surfaces:** concrete floor/walls; steel trim.
- **Rooms:** lobby (front desk NPC) → corridor → **weight floor** (Grunts+Brute) → **cage alcove** (Ben) → **(new) boiler room**.
- **Puzzles (4):** Evan moves the barbell (`barbell_moved`) sealing Ben's cage; **(new)** boiler valve (Quinn) → `boiler_key`; **(new)** Evan holds a weighted floor-plate to keep a gate open while crossing (strength/pressure); **(new, opt)** stack weight plates to the marked total to drop a supply cage (counting/weight — bonus loot).
- **Combat:** Grunts + Brute (medium). **Doug:** locker tag → open locker (Evan).
- **Keys:** out → **`boiler_key`** (optional Harbor shortcut). Unlocks **Ben**.

### 5.4 Recording Studio (4)
- **Surfaces:** carpet floor, acoustic-concrete walls; matte-black trim.
- **Rooms:** lobby → **live room** (Grunts+Runners) → corridor → **control room** (Ethan behind glass).
- **Puzzles (4):** Ben tunes the soundboard (`console_tuned`) → glass booth opens; **(new)** restore Doug's reel (Ben) — also the Doug objective; **(new)** Ethan patches the routing panel to power the booth (hack); **(new, opt)** Ben matches a played-back rhythm to silence a feedback loop (sound, bonus → `backstage_pass`).
- **Doug:** reel snippet plays Doug's voice. **Keys:** out → `backstage_pass`, `sheet_music`. Unlocks **Ethan**.

### 5.5 The Clocktower (5) — *first boss; multi-floor*
- **Surfaces:** tile floor, stone walls; brass trim.
- **Rooms/Floors:** lobby (Hieronymus) → gear floor (escapement puzzle) → belfry (bell sequence) → stair arena with the **clockwork Boss**.
- **Puzzles (5):** Quinn repairs escapement (`gear_repaired`, faster w/ `spare_clockwork_gear`); Ben plays bell sequence (`bells_played`, aided by `tuning_fork`/`sheet_music`); **(new)** Quinn re-meshes a gear train so a platform turns to bridge a gap (mechanism); **(new)** Ben matches the pendulum's tempo to slow it and slip past (timing); **(new, opt)** wind the side weights in order to open the `archive_key` cabinet (sequence, bonus).
- **Combat:** Grunts + **Boss**. **Doug:** pocket-watch back; wind watch (Quinn).
- **Keys:** out → `tuning_fork`, **`archive_key`** (optional Library bonus).

### 5.6 Harbor & Docks (6)
- **Surfaces:** concrete; dirt corridors; rusted-steel trim.
- **Rooms:** lobby (Viktor) → dock yard (Grunts+Runners) → crane platform → **(opt) shortcut storeroom** (via `boiler_key`).
- **Puzzles (5):** Evan/`crowbar` moves container (`container_moved`); **(new)** crane-crank (`crane_crank_handle`) operates the crane; **(new)** Ethan reroutes the dock power to raise the loading ramp (hack); **(new)** Erin fast-talks the harbour guard to drop the chain gate (or sneak the catwalk); **(new, opt)** match the manifest crate numbers to unlock the `pocket_lantern` locker (sequence — gates the required lantern, with a forceable fallback).
- **Doug:** manifest line. **Keys:** in → `boiler_key` (opt); out → **`pocket_lantern` (required → Underground)**, `crowbar`.

### 5.7 Library & Archive (7)
- **Surfaces:** carpet/tile, wood walls; deep-green trim.
- **Rooms:** lobby (librarian) → reading hall (Grunts + **Sentry**) → corridor → restricted archive → **(opt) locked stack** (via `archive_key`).
- **Puzzles (5):** Erin talks past librarian (or `library_card`); Ethan hacks archive terminal (`archive_hacked`); **(new)** stealth corridor past the Sentry's sightline (hiding spots); **(new)** Ethan reshelves/queries the catalog to find the call number that unlocks the stacks (cipher/sequence); **(new, opt)** Quinn repairs the dumbwaiter to reach a `vr_override_chip` on the mezzanine (mechanism, bonus).
- **Doug:** Doug's checkout card → hack for his file. **Keys:** in → `library_card`/`archive_key` (opt); out → `vr_override_chip`.

### 5.8 Carnival & Fairground (8)
- **Surfaces:** dirt/ground, bright wood; candy-red/white trim.
- **Rooms:** lobby (ticket booth) → midway (Grunts ×2 + Brute) → backstage → **funhouse corridor** (content corridor: short timing/dodge gauntlet).
- **Puzzles (5):** Quinn repairs the ride (`ride_repaired`); Erin/`backstage_pass` backstage gate; **(new)** fix photo booth (Quinn) → Doug clue; **(new)** Ben matches the calliope tune to start the carousel (sound); **(new, opt)** the funhouse-corridor lever sequence opens a prize vault holding the `library_card` (timing/sequence, bonus).
- **Doug:** photo-booth strip. **Keys:** out → `library_card` (lost & found), `film_reel`.

### 5.9 Underground Tunnels (9) — *multi-depth, required lantern*
- **Surfaces:** concrete/stone, dirt corridors; rust trim. (Already 3 depths.)
- **Rooms:** keep current — Maintenance lobby (Cyrus) / Junction patrol + hiding / Sealed Vault.
- **Puzzles (5):** keep all — Evan rubble, Ethan 3-pip hatch (badge-assisted), Evan+Ethan vault, `rusty_key` shortcut; **(new)** Ethan reroutes the pump valves to drain a flooded passage (hack/sequence) before the vault.
- **Doug:** flashlight + vault clue (the biggest mid-game beat).
- **Keys:** in → **`pocket_lantern` (required)**, `security_badge` (opt); internal `rusty_key`.

### 5.10 Zip Line Park (10)
- **Surfaces:** grass, wood; forest-green trim.
- **Rooms/platforms:** landing lobby (Lena) → mid platform → high platform; zip corridors between.
- **Puzzles (6):** Ethan hacks panel (`panel_hacked`); Ben timing release (`release_timed`); **(new)** retrieve snagged clue bag (Ben timing); **(new)** Evan tensions/anchors the slack line so a platform can be crossed (strength); **(new)** Ethan re-sequences the three platform locks so the zip cars align (sequence); **(new, opt)** Ben hits the moving target chimes in tempo to drop a supply crate (rhythm/timing, bonus).
- **Combat:** Grunt + Runners ×2. **Doug:** carabiner clue.

### 5.11 VR Escape Room (11)
- **Surfaces:** emissive neon-grid (kept special) + tile.
- **Rooms:** Boot Chamber (ARIA) → Stage Alpha (Quinn glitch repair) → Stage Beta (Ethan hack) → **(opt) bypass** via `vr_override_chip`/Lizard.
- **Puzzles (6):** `glitch_repaired` (Quinn) + `system_hacked` (Ethan); `vr_override_chip`/Lizard bypass; **(new)** recover Doug's session log (Ethan); **(new)** Quinn rebuilds a glitched physics bridge by re-ordering floating blocks (sequence); **(new)** Ben matches the system's boot-chime to authenticate (sound); **(new)** Ethan + Quinn co-solve the firewall (combined-ability, like the Underground vault); **(new, opt)** a hidden dev-room console (Ethan) grants a Bies charm (bonus).
- **Combat:** Grunts ×2 + Sentry. **Doug:** corrupted avatar/log.

### 5.12 The Drop (12)
- **Surfaces:** grass/dirt, stone; olive trim.
- **Rooms:** Touchdown Clearing (Rio) → Snag Grove → landing site; wooded corridors.
- **Puzzles (6):** Evan clears wreckage (`landing_cleared`); Ethan hacks chute (`chute_hacked`); **(new)** Evan + the dogs haul a fallen beam off the path (strength/animal); **(new)** Erin talks the ex-crew lookout into standing down (or stealth the tree line); **(new)** Ethan re-aims the marquee signal dish toward the cinema (hack/aim) — the endgame pointer; **(new, opt)** Ben whistles the grove birds quiet to reveal a stashed `film_reel`/clue (sound, bonus).
- **Combat:** Grunt+Runner+Brute. **Doug:** marquee flyer → endgame pointer.

### 5.13 Grand Marquee Cinema (13) — *endgame, boss, payoff*
- **Surfaces:** red carpet, ornate brick; gold trim.
- **Rooms:** grand lobby (Cecil/Usher) → auditorium → balcony (organ) → backstage arena (**Boss**) → projection booth (**Doug**).
- **Puzzles (7):** Quinn projector (`projector_repaired`, half via `film_reel`); Ben house organ (`organ_played`); **all 5 tickets** required to enter; **(new)** Ethan restores the marquee/house lights circuit (hack); **(new)** Erin talks Cecil/Usher past the velvet rope (or sneak the balcony); **(new)** Ben + Quinn co-tune the organ to the film's reel pitch to sync sound (combined-ability); **(new)** Evan hauls open the jammed backstage door to the boss arena (strength); **(new, opt)** assemble Doug's clue board from all collected clues for the full reveal (collection check, payoff).
- **Doug:** clues assemble; reveal → `Result3D`. **Keys:** in → 5 `movie_ticket`s (required), `film_reel`/`tuning_fork` (opt).

---

## 6. Quality / bug fixes

**Secret-door bug (Pipe Organ loft) — root cause + fix:**
- The pipe hall `room(... ["s"] ...)` builds a **solid full-width north wall at z=-17**.
  The removable `_secret_wall` sits at the *same* z behind it, so the lever drops the
  secret wall but the room's permanent wall still blocks the nook → nook unreachable.
- **Fix:** add a matching `"n"` opening (gap ≈3.0) to the pipe-hall `room()` so its north
  wall has a doorway; size `_secret_wall` to fill *that* gap (≈3.0 w × pipe-hall h),
  abutting (not overlapping) the wall segments. Align the nook `"s"` opening gap to match.
- **Regression guard:** add a **"reveal/open checklist"** — for every door/wall/stair
  that opens on a flag, verify in-engine that (1) the obstruction actually clears
  collision *and* mesh, and (2) the space behind is reachable (no second wall, floor
  present). Run on Pipe Organ now and on each level as built.

**Church preservation (point 3):** §5.2 keeps every existing flag
(`quinn_done`/`erin_done`/`secret_revealed`/`father_aldric_impression`) and the
Aldric dialog tree; rooms are added *around* them.

---

## 7. Implementation sequencing

Built in this order, each ending with a boot + `--capture` check and the reveal-checklist
(**all steps done**):

1. ✅ **Pipe Organ:** secret-door bug fixed (§6) + corridors/surfaces. *(validated the checklist)*
2. ✅ **Intro tier (1–4):** Church, Gym, Studio (+ Pipe Organ) — surfaces, new rooms/clues/keys.
3. ✅ **Mid tier (5–9):** Clocktower, Harbor, Library, Carnival, Underground — multi-room,
   theme puzzles, content corridors, key placements.
4. ✅ **Late tier (10–13):** Zip Line, VR, The Drop, Grand Marquee — largest layouts,
   boss finale, Doug clue-board payoff.
5. ✅ **Cross-level pass:** `CLAUDE.md` location flags + item table + Doug-trail table synced;
   key found-in/opens sites placed (`boiler_key`→Harbor, `archive_key`→Library); required
   gates (`pocket_lantern`, 5 tickets, `rusty_key`) reachable from already-unlocked levels.

Each level keeps mid-level persistence (`level_progress` flags) and the lobby convention.
New items get `data/items/*.tres`; new flags follow the existing naming.
