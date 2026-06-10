# Otis

- **Home tile:** (33, 15) — open grass near The Harbor & Docks
- **Personality:** Salty old sailor, full of stories
- **Quest id:** `otis`
- **Wants:** Brass Compass (`brass_compass`) — **new** item, placed as a
  loot box at `(600, 350)` in The Harbor & Docks
- **Gives back:** Sailor's Knot Bracelet (`sailors_knot_bracelet`) — **new**
  reward item, granted directly via `GameManager.grant_item()` (no loot box)
- **Connection to Uncle Doug:** the compass is engraved "To O., so you always
  find your way home" — a gift from Doug to Otis

## Dialog

### Intro (not_started → active)
1. "Well now, fresh faces! Don't get many of those down by the docks these
   days."
2. "Say -- you wouldn't have spotted an old brass compass lying around the
   harbor, eh?"
3. "Lost it in all the cargo shuffle. Hasn't pointed north right in years,
   but it's mine."
4. "Engraved on the back: 'To O.' -- that's me, Otis. Gift from an old
   friend."
5. "Find it for me and I'll tie you up a proper sailor's knot. Good luck
   charm, that."

### Reminder (active, item not yet found)
1. "Still keeping an eye out for my compass? Probably buried under cargo
   somewhere."

### Turn-in (active, item found — consumes Brass Compass, grants Sailor's
Knot Bracelet)
1. "Ha! There it is. Knew it had to be down here somewhere."
2. "'To O., so you always find your way home.' Doug gave me this, years
   back."
3. "Funny thing to give a sailor whose home IS the docks. But that was
   Doug."
4. "Said everybody needs a way back, even if they don't know they're lost
   yet."
5. "Here -- a sailor's knot, like I promised. Tie it on. Might bring you
   luck, too."

### After (complete)
1. "That compass still doesn't point north. But it points home. Good enough
   for me."
