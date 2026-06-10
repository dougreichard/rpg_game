# Penny

- **Home tile:** (8, 13) — open grass near The Old Parish Church
- **Personality:** Cheerful, crafty young seamstress
- **Quest id:** `penny`
- **Wants:** Embroidered Handkerchief (`embroidered_handkerchief`) — **new**
  item, placed as a loot box at `(480, 460)` in The Old Parish Church
- **Gives back:** Hand-Stitched Patch (`stitched_patch`) — **new** reward
  item, granted directly via `GameManager.grant_item()` (no loot box)
- **Connection to Uncle Doug:** the handkerchief (embroidered with a looping
  "D") was mid-mend for Doug when Penny lost it on her way to return it

## Dialog

### Intro (not_started → active)
1. "Hiya! You two look like you get around. Mind doing me a favor?"
2. "I was mending an old handkerchief for a customer -- an embroidered 'D,'
   very fancy."
3. "I dropped it somewhere in the Old Parish Church on my way to deliver it.
   So clumsy!"
4. "The customer was a sweet old fellow named Doug. Haven't seen him to
   apologize, even."
5. "If you find it among the pews, I'd be ever so grateful. I'll make it
   worth your while!"

### Reminder (active, item not yet found)
1. "Any luck with that handkerchief? Should be somewhere around the pews."

### Turn-in (active, item found — consumes Embroidered Handkerchief, grants
Hand-Stitched Patch)
1. "You found it! Oh, thank you! I felt awful about losing Mr. Doug's
   handkerchief."
2. "Here -- I made this little patch for whoever found it. A gear, since
   Doug loved his tools."
3. "Sew it on somewhere nobody will notice. It's small, but it's something."
4. "If you do see Doug around, tell him I'm sorry -- and that I'll mend it
   properly this time."

### After (complete)
1. "Still hoping to track down Mr. Doug and finish that mending properly.
   Thanks again."
