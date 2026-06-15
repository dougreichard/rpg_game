extends GutTest

# Tests the reusable WorkStation3D crafting node (scripts/3d/work_station3d.gd):
# SOURCE grants once, TOOL transforms an input item into an output, the best_with
# gate blocks the wrong character, and ASSEMBLY completes once all parts are fitted.
# Manipulates GameManager.inventories directly and restores it after each test so
# the autoload is never left dirty (mirrors test_inventory.gd).

const Station := preload("res://scripts/3d/work_station3d.gd")

var _saved_inventories: Dictionary = {}

func before_each() -> void:
	_saved_inventories = GameManager.inventories.duplicate(true)
	GameManager.inventories = {}

func after_each() -> void:
	GameManager.inventories = _saved_inventories

func _station(kind: int) -> Area3D:
	var s: Area3D = Station.new()
	s.kind = kind
	add_child_autofree(s)   # triggers _ready (builds marker + prompt)
	return s

func test_source_grants_once() -> void:
	var s := _station(Station.Kind.SOURCE)
	s.produces = "rough_plank"
	assert_true(s.try_use("Quinn", Vector3.ZERO), "in-range source press is handled")
	assert_true(GameManager.has_item("Quinn", "rough_plank"), "source grants its item")
	assert_false(s.try_use("Quinn", Vector3.ZERO), "an emptied source no longer handles the press")

func test_source_out_of_range_ignored() -> void:
	var s := _station(Station.Kind.SOURCE)
	s.produces = "rough_plank"
	assert_false(s.try_use("Quinn", Vector3(50, 0, 0)), "out-of-range press is not handled")
	assert_false(GameManager.has_item("Quinn", "rough_plank"))

func test_tool_transforms_input_to_output() -> void:
	var s := _station(Station.Kind.TOOL)
	s.recipes = [{"in": "rough_plank", "out": "windchest_board"}]
	GameManager.grant_item("Quinn", "rough_plank")
	assert_true(s.try_use("Quinn", Vector3.ZERO))
	assert_false(GameManager.has_item("Quinn", "rough_plank"), "tool consumes the raw input")
	assert_true(GameManager.has_item("Quinn", "windchest_board"), "tool grants the processed output")

func test_tool_without_input_does_not_produce() -> void:
	var s := _station(Station.Kind.TOOL)
	s.recipes = [{"in": "rough_plank", "out": "windchest_board"}]
	assert_true(s.try_use("Quinn", Vector3.ZERO), "press at the bench is still handled (shows a hint)")
	assert_false(GameManager.has_item("Quinn", "windchest_board"), "no output without the input item")

func test_tool_best_with_blocks_wrong_character() -> void:
	var s := _station(Station.Kind.TOOL)
	s.best_with = "Quinn"
	s.recipes = [{"in": "rough_plank", "out": "windchest_board"}]
	GameManager.grant_item("Erin", "rough_plank")
	s.try_use("Erin", Vector3.ZERO)
	assert_true(GameManager.has_item("Erin", "rough_plank"), "the wrong character can't run the tool")
	assert_false(GameManager.has_item("Erin", "windchest_board"))

func test_assembly_completes_when_all_parts_fitted() -> void:
	var s := _station(Station.Kind.ASSEMBLY)
	s.parts = ["windchest_board", "brass_organ_pipe", "trued_gear"]
	for p: String in s.parts:
		GameManager.grant_item("Quinn", p)
	watch_signals(s)
	for _i in range(3):
		s.try_use("Quinn", Vector3.ZERO)
	assert_eq(s.placed_count(), 3, "all three parts fitted")
	assert_true(s.is_complete(), "assembly reports complete")
	assert_signal_emitted(s, "completed", "completed fires on the last part")

func test_assembly_incomplete_with_missing_part() -> void:
	var s := _station(Station.Kind.ASSEMBLY)
	s.parts = ["windchest_board", "brass_organ_pipe"]
	GameManager.grant_item("Quinn", "windchest_board")
	s.try_use("Quinn", Vector3.ZERO)
	assert_eq(s.placed_count(), 1)
	assert_false(s.is_complete(), "still missing a part")
