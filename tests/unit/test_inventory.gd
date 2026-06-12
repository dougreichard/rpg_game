extends GutTest

# Tests the GameManager inventory API (grant_item, has_item, consume_item).
# Scene-free: manipulates GameManager.inventories directly and restores it after
# each test so the autoload is never left in a dirty state for subsequent tests.

var _saved_inventories: Dictionary = {}

func before_each() -> void:
	_saved_inventories = GameManager.inventories.duplicate(true)
	GameManager.inventories = {}

func after_each() -> void:
	GameManager.inventories = _saved_inventories

func test_has_item_false_before_grant() -> void:
	assert_false(GameManager.has_item("Quinn", "bent_spoon"))

func test_grant_then_has() -> void:
	GameManager.grant_item("Quinn", "bent_spoon")
	assert_true(GameManager.has_item("Quinn", "bent_spoon"))

func test_grant_is_idempotent() -> void:
	GameManager.grant_item("Evan", "rusty_key")
	GameManager.grant_item("Evan", "rusty_key")
	var inv: Array = GameManager.inventories.get("evan", [])
	assert_eq(inv.count("rusty_key"), 1, "duplicate grant should not add a second entry")

func test_has_item_is_character_scoped() -> void:
	GameManager.grant_item("Quinn", "arcade_token")
	assert_false(GameManager.has_item("Erin", "arcade_token"), "Quinn's item must not appear in Erin's inventory")

func test_consume_removes_item() -> void:
	GameManager.grant_item("Ethan", "security_badge")
	GameManager.consume_item("Ethan", "security_badge")
	assert_false(GameManager.has_item("Ethan", "security_badge"))

func test_consume_missing_item_is_safe() -> void:
	GameManager.consume_item("Ben", "nonexistent_item")
	assert_true(true, "consuming a missing item must not error")

func test_multiple_items_per_character() -> void:
	GameManager.grant_item("Erin", "skeleton_key")
	GameManager.grant_item("Erin", "faded_map")
	assert_true(GameManager.has_item("Erin", "skeleton_key"))
	assert_true(GameManager.has_item("Erin", "faded_map"))

func test_item_collected_signal_emitted_on_grant() -> void:
	watch_signals(GameManager)
	GameManager.grant_item("Quinn", "brass_compass")
	assert_signal_emitted_with_parameters(GameManager, "item_collected", ["Quinn", "brass_compass"])
