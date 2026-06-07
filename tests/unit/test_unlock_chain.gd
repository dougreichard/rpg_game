extends GutTest

# CLAUDE.md: "Characters are unlocked in order: Quinn -> Erin -> Evan -> Ben -> Ethan."
# Quinn and Erin start unlocked; each of the first four locations grants the next.
# This only reads the const UNLOCKS_CHARACTER map — never calls complete_location(),
# which would mutate GameManager's live state and write to the player's save file.

func test_unlock_chain_matches_claude_md_order() -> void:
	assert_eq(GameManager.UNLOCKS_CHARACTER.get("pipe_organ_works"), "erin", "Bellows & Sons should unlock Erin")
	assert_eq(GameManager.UNLOCKS_CHARACTER.get("old_parish_church"), "evan", "The Old Parish Church should unlock Evan")
	assert_eq(GameManager.UNLOCKS_CHARACTER.get("iron_strings_gym"), "ben", "Iron & Strings Gym should unlock Ben")
	assert_eq(GameManager.UNLOCKS_CHARACTER.get("recording_studio"), "ethan", "The Recording Studio should unlock Ethan")

func test_unlock_chain_only_grants_each_character_once() -> void:
	var granted: Array = GameManager.UNLOCKS_CHARACTER.values()
	var seen: Dictionary = {}
	for character_id in granted:
		assert_false(seen.has(character_id), "%s should only be granted by one location" % character_id)
		seen[character_id] = true

func test_unlock_chain_never_grants_quinn() -> void:
	# Quinn is the only character the prototype roster starts with that ISN'T
	# also granted by a location (Erin's grant from Bellows & Sons is a deliberate
	# narrative beat — "Unlocks: Erin (found or rescued here)" — that happens to be
	# a no-op against the starting roster, since complete_location() only appends
	# characters not already in unlocked_characters).
	for character_id in GameManager.UNLOCKS_CHARACTER.values():
		assert_ne(character_id, "quinn", "Quinn starts unlocked — no location should grant Quinn")
