extends GutTest

# Tests the DialogTree helper functions (from_pages, resolve_choice).
# Scene-free: loads the script directly, reads its static functions.

const DialogTreeScript = preload("res://scripts/systems/dialog_tree.gd")

func test_from_pages_creates_start_node() -> void:
	var tree: Dictionary = DialogTreeScript.from_pages(["Hello", "World"])
	assert_true(tree.has("start"), "from_pages must create a 'start' node")

func test_from_pages_chain_length() -> void:
	var tree: Dictionary = DialogTreeScript.from_pages(["A", "B", "C"])
	# start -> n1 -> n2; n2 has no 'next'
	assert_eq(tree.size(), 3, "3-page tree should have 3 nodes")

func test_from_pages_last_node_has_no_next() -> void:
	var tree: Dictionary = DialogTreeScript.from_pages(["Only"])
	assert_false(tree["start"].has("next"), "single-page tree's only node should have no next")

func test_from_pages_intermediate_nodes_have_next() -> void:
	var tree: Dictionary = DialogTreeScript.from_pages(["P1", "P2", "P3"])
	assert_true(tree["start"].has("next"))
	var mid: String = tree["start"]["next"]
	assert_true(tree[mid].has("next"))

func test_from_pages_preserves_lines() -> void:
	var tree: Dictionary = DialogTreeScript.from_pages(["First line", "Second line"])
	assert_eq(tree["start"]["lines"], ["First line"])

func test_from_pages_last_node_effects() -> void:
	var fx: Dictionary = {"set_flag": "quest_done", "flag_value": "complete"}
	var tree: Dictionary = DialogTreeScript.from_pages(["Hi"], fx)
	assert_true(tree["start"].has("effects"))
	assert_eq(tree["start"]["effects"].get("set_flag"), "quest_done")

func test_resolve_choice_follows_next_when_best_with_matches() -> void:
	var choice: Dictionary = {"text": "Politely", "best_with": "Quinn", "next": "good_end", "next_alt": "ok_end"}
	var result: String = DialogTreeScript.resolve_choice(choice, "Quinn")
	assert_eq(result, "good_end")

func test_resolve_choice_follows_next_alt_when_best_with_mismatches() -> void:
	var choice: Dictionary = {"text": "Politely", "best_with": "Quinn", "next": "good_end", "next_alt": "ok_end"}
	var result: String = DialogTreeScript.resolve_choice(choice, "Erin")
	assert_eq(result, "ok_end")

func test_resolve_choice_falls_back_to_next_when_no_next_alt() -> void:
	var choice: Dictionary = {"text": "Bluntly", "best_with": "Erin", "next": "annoyed"}
	var result: String = DialogTreeScript.resolve_choice(choice, "Quinn")
	assert_eq(result, "annoyed", "no next_alt means next is always followed regardless of character")

func test_resolve_choice_no_best_with_always_follows_next() -> void:
	var choice: Dictionary = {"text": "Neutral", "next": "neutral_end"}
	var result: String = DialogTreeScript.resolve_choice(choice, "Evan")
	assert_eq(result, "neutral_end")
