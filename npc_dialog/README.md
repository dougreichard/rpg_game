# NPC Dialog & Quests

This folder documents the townsfolk who wander the **OverworldMap** and the
small fetch-quests they offer. The implementation lives in:

- `scripts/ui/dialog_box.gd` — the paged dialog panel (`open()`/`advance()`/
  `is_open()`/`closed`).
- `scripts/overworld/town_npc.gd` — wander FSM, now carrying `npc_name`,
  `quest_id`, and `color` (for the dialog portrait).
- `scripts/overworld/overworld_map.gd` — `NPC_DATA`/`NPC_DATA_2` (roster +
  home tiles) and `QUESTS`/`QUESTS_2` (dialog pages + item exchange), plus
  the talk/quest state machine (`_talk_to_npc`).

See CLAUDE.md's "NPC dialog & quests" section (under "Architecture & key
systems") for the technical writeup.

## How a quest works

Each NPC tracks one quest, persisted as a string at
`GameManager.level_progress["town"]["quest_<id>"]`:

1. **`not_started`** — talking to the NPC shows their **intro** dialog and
   flips the quest to `active`. **Exception:** if `want_item == ""` (Tobias,
   Agnes), the intro dialog *also* grants `spoon` and `give_item` (if any) and
   jumps straight to `complete` — no `active`/`reminder` step.
2. **`active`** — if any unlocked character is holding `want_item`, talking
   to the NPC shows the **turn_in** dialog, consumes `want_item`, grants
   `give_item` (if any) and `spoon`, and flips the quest to `complete`.
   Otherwise shows the **reminder** dialog.
3. **`complete`** — talking to the NPC shows the **after** dialog forever.

Every one of the 12 quests also grants one `numbered_spoon_NN` item — see
"The numbered spoon set" below.

## Roster

| NPC | Home (overworld tile) | Wants | Gives back | Found in |
|-----|------------------------|-------|------------|----------|
| [Gus](gus.md) | (5, 10) | Bent Spoon | — (lore) | Bellows & Sons Pipe Organ Works |
| [Moira](moira.md) | (16, 5) | Skeleton Key | — (lore) | The Public Library & Archive |
| [Reggie](reggie.md) | (28, 11) | Arcade Token | — (lore) | Zip Line Park |
| [Fanny](fanny.md) | (14, 16) | Fanny's Bottle | — (lore) | The Underground Tunnels |
| [Penny](penny.md) | (8, 13) | Embroidered Handkerchief | Hand-Stitched Patch | The Old Parish Church |
| [Otis](otis.md) | (33, 15) | Brass Compass | Sailor's Knot Bracelet | The Harbor & Docks |
| [Wendell](wendell.md) | (-5, 4) | Torn Ticket Stub | — (lore) | The Carnival & Fairground |
| [Clara](clara.md) | (-5, 12) | Tangled Headphone Cable | — (lore) | The Recording Studio |
| [Ambrose](ambrose.md) | (44, 4) | Faded Treasure Map | — (lore) | The Harbor & Docks |
| [Dottie](dottie.md) | (44, 12) | Lucky Rabbit's Foot Keychain | — (lore) | The Drop |
| [Tobias](tobias.md) | (15, -5) | — (freed, no fetch item) | — (lore) | Bellows & Sons Pipe Organ Works (secret room) |
| [Agnes](agnes.md) | (15, 23) | — (freed, no fetch item) | — (lore) | The Old Parish Church (secret room) |

All six original quest items were either already placed as loot boxes (Gus,
Moira, Reggie, Fanny — reusing existing junk/lore collectibles per CLAUDE.md's
"Junk / lore collectibles" table) or newly added at the time (Penny, Otis —
two new fetch items plus two new reward items, each placed as a loot box in
the relevant location). The six newer NPCs (Wendell, Clara, Ambrose, Dottie,
Tobias, Agnes) reuse junk items that were *already* sitting in other
locations as loot boxes — see CLAUDE.md's "Numbered spoon set" section for
the full mapping. Tobias and Agnes don't fetch anything: they're trapped
behind the Pipe Organ Works' and Old Parish Church's secret passages, and
only appear in town once that passage has been found — talking to them once
both "frees" them and completes their quest.

## A thread through the mystery

Four of the original six quests connect back to **Uncle Doug**: the bent
spoon was his pipe-tapping tool, the skeleton key is stamped with his "D."
mark, the arcade token was custom-cast for him, Fanny's bottle was a keepsake
he gave her "the day before he disappeared," and Penny's handkerchief was
mid-mend for him when she lost it. None of these are hard plot gates — they're
optional flavor that rewards exploration and slowly paints a picture of Doug
as someone the whole town knew and misses.

The six newer NPCs (Wendell, Clara, Ambrose, Dottie, Tobias, Agnes) aren't
part of this Doug thread directly — see "The numbered spoon set" below for
the thread that ties all twelve of them together instead.

## The numbered spoon set

Every one of the 12 town quests — the original six plus Wendell, Clara,
Ambrose, Dottie, Tobias, and Agnes — also hands over one piece of a 12-piece
`numbered_spoon_01` … `numbered_spoon_12` set on completion (`gus`→01,
`moira`→02, `reggie`→03, `fanny`→04, `penny`→05, `otis`→06, `wendell`→07,
`clara`→08, `ambrose`→09, `dottie`→10, `tobias`→11, `agnes`→12). Each spoon's
description is its own riff on Quinn's "Bent spoon... it has a story" line
from the junk-item table, and the set escalates toward an explicit
Easter-egg hint as more are collected — early spoons read as plain flavor
text ("...feels like it's part of a set"), middle spoons plant the payoff
(Reggie name-drops an old arcade cabinet with one bolted to its side), and
the last two spell it out ("One more, and the set's complete...",
"...Definitely a game piece — but for which game?"). Collecting all 12 has
no mechanical gate behind it — it's a pure completionist/lore hook, in the
same spirit as Penny's Hand-Stitched Patch or Otis's Sailor's Knot Bracelet.
