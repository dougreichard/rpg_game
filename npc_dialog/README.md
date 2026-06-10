# NPC Dialog & Quests

This folder documents the townsfolk who wander the **OverworldMap** and the
small fetch-quests they offer. The implementation lives in:

- `scripts/ui/dialog_box.gd` — the paged dialog panel (`open()`/`advance()`/
  `is_open()`/`closed`).
- `scripts/overworld/town_npc.gd` — wander FSM, now carrying `npc_name` and
  `quest_id`.
- `scripts/overworld/overworld_map.gd` — `NPC_DATA` (roster + home tiles) and
  `QUESTS` (dialog pages + item exchange), plus the talk/quest state machine
  (`_talk_to_npc`).

See CLAUDE.md's "NPC dialog & quests" section (under "Architecture & key
systems") for the technical writeup.

## How a quest works

Each NPC tracks one quest, persisted as a string at
`GameManager.level_progress["town"]["quest_<id>"]`:

1. **`not_started`** — talking to the NPC shows their **intro** dialog and
   flips the quest to `active`.
2. **`active`** — if any unlocked character is holding `want_item`, talking
   to the NPC shows the **turn_in** dialog, consumes `want_item`, grants
   `give_item` (if any), and flips the quest to `complete`. Otherwise shows
   the **reminder** dialog.
3. **`complete`** — talking to the NPC shows the **after** dialog forever.

## Roster

| NPC | Home (overworld tile) | Wants | Gives back | Found in |
|-----|------------------------|-------|------------|----------|
| [Gus](gus.md) | (5, 10) | Bent Spoon | — (lore) | Bellows & Sons Pipe Organ Works |
| [Moira](moira.md) | (16, 5) | Skeleton Key | — (lore) | The Public Library & Archive |
| [Reggie](reggie.md) | (28, 11) | Arcade Token | — (lore) | Zip Line Park |
| [Fanny](fanny.md) | (14, 16) | Fanny's Bottle | — (lore) | The Underground Tunnels |
| [Penny](penny.md) | (8, 13) | Embroidered Handkerchief | Hand-Stitched Patch | The Old Parish Church |
| [Otis](otis.md) | (33, 15) | Brass Compass | Sailor's Knot Bracelet | The Harbor & Docks |

All six quest items were either already placed as loot boxes (Gus, Moira,
Reggie, Fanny — reusing existing junk/lore collectibles per CLAUDE.md's
"Junk / lore collectibles" table) or newly added this pass (Penny, Otis —
two new fetch items plus two new reward items, each placed as a loot box in
the relevant location).

## A thread through the mystery

Four of these six quests turn out to connect back to **Uncle Doug**: the
bent spoon was his pipe-tapping tool, the skeleton key is stamped with his
"D." mark, the arcade token was custom-cast for him, Fanny's bottle was a
keepsake he gave her "the day before he disappeared," and Penny's
handkerchief was mid-mend for him when she lost it. None of these are hard
plot gates — they're optional flavor that rewards exploration and slowly
paints a picture of Doug as someone the whole town knew and misses.
