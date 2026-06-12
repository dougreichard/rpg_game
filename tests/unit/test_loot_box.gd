extends GutTest

# Tests LootBox behavior (open, idempotency, character scoping) without
# instantiating a scene. Constructs the node programmatically and removes it
# after each test so GameManager inventory state is never left dirty.

const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const BentSpoonItem: Resource = preload("res://data/items/bent_spoon.tres")

var _box = null
var _saved_inventories: Dictionary = {}

func before_each() -> void:
	_saved_inventories = GameManager.inventories.duplicate(true)
	GameManager.inventories = {}
	_box = LootBoxScript.new()
	_box.setup(BentSpoonItem, Vector2(100.0, 100.0), false)
	add_child_autofree(_box)

func after_each() -> void:
	GameManager.inventories = _saved_inventories

func test_loot_box_starts_closed() -> void:
	assert_false(_box.is_open)

func test_try_open_out_of_range_fails() -> void:
	var result: bool = _box.try_open("Quinn", Vector2(500.0, 500.0))
	assert_false(result, "try_open from far away should return false")
	assert_false(_box.is_open)

func test_try_open_in_range_succeeds() -> void:
	var result: bool = _box.try_open("Quinn", Vector2(100.0, 100.0))
	assert_true(result, "try_open in range should return true")
	assert_true(_box.is_open)

func test_try_open_grants_item() -> void:
	_box.try_open("Evan", Vector2(100.0, 100.0))
	assert_true(GameManager.has_item("Evan", BentSpoonItem.id))

func test_try_open_is_idempotent() -> void:
	_box.try_open("Quinn", Vector2(100.0, 100.0))
	var second: bool = _box.try_open("Erin", Vector2(100.0, 100.0))
	assert_false(second, "second open attempt on same box should return false")

func test_already_open_box_constructed_open() -> void:
	var pre_open_box = LootBoxScript.new()
	pre_open_box.setup(BentSpoonItem, Vector2(200.0, 200.0), true)
	add_child_autofree(pre_open_box)
	assert_true(pre_open_box.is_open, "box constructed with already_open=true should start open")
	var result: bool = pre_open_box.try_open("Quinn", Vector2(200.0, 200.0))
	assert_false(result, "already-open box must not grant again")
