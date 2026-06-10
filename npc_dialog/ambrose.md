# Ambrose

- **Home tile:** (44, 4) — open grass padding east of the map, beyond The
  Harbor & Docks
- **Personality:** Amateur cartographer, endlessly fascinated by maps that go
  nowhere
- **Quest id:** `ambrose`
- **Wants:** Faded Treasure Map (`faded_treasure_map`) — already placed as a
  loot box at The Harbor & Docks
- **Gives back:** nothing named — the reward is the story
- **Spoon reward:** Spoon No. 9 (`numbered_spoon_09`)

## Dialog

### Intro (not_started → active)
1. "Ah, travelers! I'm an amateur cartographer. Maps fascinate me, even bad
   ones."
2. "I heard tell of a faded treasure map down at the Harbor & Docks. Useless,
   but--"
3. "--I'd love to study it anyway. The X's never line up with anything, but
   still!"

### Reminder (active, item not yet found)
1. "Any luck with that treasure map? Probably stuffed in a crate down at the
   docks."

### Turn-in (active, item found — consumes Faded Treasure Map, grants Spoon
No. 9)
1. "Wonderful! Let's see... yes, these landmarks match NOTHING. Fascinating."
2. "Hold on -- something was folded inside it. A spoon, numbered '9'."
3. "Maybe X marked this spot after all. Here, it's yours -- I'm keeping the
   map."

### After (complete)
1. "Still cross-referencing that map against, well, reality. Slow going."
