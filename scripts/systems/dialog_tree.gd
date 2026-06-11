extends RefCounted

## Shared data shape for branching NPC dialog -- see CLAUDE.md "NPC dialog &
## quests". No class_name -- callers preload() this script and call its
## static funcs on the Script object directly (same convention as
## LootBox/Doorway/HidingSpot, see [[feedback-godot-technical]], and avoids
## the class_name-needs-editor-rescan gotcha for a script with no scene
## footprint). A tree is Dictionary[String, Dictionary], node id -> node:
##
## node = {
##   "lines": Array[String],       # required, paged ("\n" = 2nd line within a page)
##   "next": String,                # optional: auto-advance to this node id
##   "choices": Array[Dictionary],  # optional, mutually exclusive with "next"
##   "effects": Dictionary,         # optional: applied when this node is reached
## }
##
## choice = {
##   "text": String,                # option label shown in the choice list
##   "best_with": String,           # optional character name, e.g. "Quinn"
##   "next": String,                # node id if best_with matches active char
##                                   # (or always, if best_with is absent)
##   "next_alt": String,            # optional node id if it doesn't match
##                                   # (defaults to "next" if absent)
##   "effects": Dictionary,         # optional: applied immediately on selection
## }
##
## effects = {
##   "set_flag": String,            # level_progress flag name
##   "flag_value": Variant,         # default true
##   "consume_item": String,        # item id consumed from whoever holds it
##   "grant_items": Array[String],  # items granted to that same holder
## }

# Builds a linear start -> n1 -> n2 -> ... chain, one node per page. The
# final node gets `last_node_effects` merged in (under "effects") if
# non-empty -- the mechanical converter for plain paged dialog.
static func from_pages(pages: Array, last_node_effects: Dictionary = {}) -> Dictionary:
	var tree: Dictionary = {}
	if pages.is_empty():
		return tree
	for i: int in pages.size():
		var node_id: String = "start" if i == 0 else "n%d" % i
		var node: Dictionary = {"lines": [pages[i]]}
		if i < pages.size() - 1:
			node["next"] = "n%d" % (i + 1)
		elif not last_node_effects.is_empty():
			node["effects"] = last_node_effects
		tree[node_id] = node
	return tree

# Returns the node id a choice should jump to, given which character is
# currently active. If `best_with` is set and doesn't match, falls back to
# `next_alt` (or `next` if `next_alt` isn't provided).
static func resolve_choice(choice: Dictionary, active_character: String) -> String:
	if choice.has("best_with") and choice["best_with"] != active_character and choice.has("next_alt"):
		return choice["next_alt"]
	return choice["next"]
