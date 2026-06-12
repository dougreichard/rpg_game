extends GutTest

# Tests quest data shape and state-machine assumptions.
# Scene-free: reads QuestData consts and GameManager.level_progress directly.

const QuestData = preload("res://scripts/systems/quest_data.gd")

var _saved_progress: Dictionary = {}

func before_each() -> void:
	_saved_progress = GameManager.level_progress.duplicate(true)

func after_each() -> void:
	GameManager.level_progress = _saved_progress

func test_town_quest_ids_count() -> void:
	assert_eq(QuestData.TOWN_QUEST_IDS.size(), 12, "there should be exactly 12 town quests")

func test_every_town_quest_has_a_data_entry() -> void:
	for qid: String in QuestData.TOWN_QUEST_IDS:
		var q: Dictionary = QuestData.get_quest(qid)
		assert_false(q.is_empty(), "quest '%s' must have a QUESTS/QUESTS_2 entry" % qid)

func test_every_quest_has_required_keys() -> void:
	for qid: String in QuestData.TOWN_QUEST_IDS:
		var q: Dictionary = QuestData.get_quest(qid)
		assert_true(q.has("want_item"), "quest '%s' must have want_item key" % qid)
		assert_true(q.has("spoon"),     "quest '%s' must have spoon key" % qid)

func test_every_quest_spoon_is_numbered() -> void:
	for qid: String in QuestData.TOWN_QUEST_IDS:
		var spoon_id: String = QuestData.get_quest(qid).get("spoon", "")
		assert_true(spoon_id.begins_with("numbered_spoon_"), "quest '%s' spoon id should be numbered_spoon_NN, got '%s'" % [qid, spoon_id])

func test_quest_flag_initial_state() -> void:
	var state: String = GameManager.get_level_flag(QuestData.TOWN_ID, "quest_gus", "not_started")
	assert_eq(state, "not_started", "fresh quest flag should default to not_started")

func test_quest_flag_set_and_read() -> void:
	GameManager.set_level_flag(QuestData.TOWN_ID, "quest_gus", "active")
	assert_eq(GameManager.get_level_flag(QuestData.TOWN_ID, "quest_gus", "not_started"), "active")

func test_quest_state_progression() -> void:
	GameManager.set_level_flag(QuestData.TOWN_ID, "quest_moira", "not_started")
	assert_eq(GameManager.get_level_flag(QuestData.TOWN_ID, "quest_moira", "not_started"), "not_started")
	GameManager.set_level_flag(QuestData.TOWN_ID, "quest_moira", "active")
	assert_eq(GameManager.get_level_flag(QuestData.TOWN_ID, "quest_moira", "not_started"), "active")
	GameManager.set_level_flag(QuestData.TOWN_ID, "quest_moira", "complete")
	assert_eq(GameManager.get_level_flag(QuestData.TOWN_ID, "quest_moira", "not_started"), "complete")

func test_npc_data_covers_all_quest_ids() -> void:
	var all_npc_quest_ids: Array = []
	for npc: Dictionary in QuestData.NPC_DATA + QuestData.NPC_DATA_2:
		all_npc_quest_ids.append(npc["quest_id"])
	for qid: String in QuestData.TOWN_QUEST_IDS:
		assert_true(qid in all_npc_quest_ids, "quest '%s' must map to an NPC" % qid)
