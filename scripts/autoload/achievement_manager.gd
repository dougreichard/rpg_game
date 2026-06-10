extends Node

# Achievement system — see CLAUDE.md "Achievements". Loads every
# AchievementData Resource (data/achievements/*.tres), tracks unlock state,
# and listens to existing/new GameManager signals to detect unlock
# conditions. Never reach into level scripts directly — everything routes
# through GameManager's signal bus, same as stealth/inventory.

signal achievement_unlocked(id: String)

# Explicit, ordered list — controls AchievementsOverlay display order.
const ACHIEVEMENT_LIST: Array[AchievementData] = [
	preload("res://data/achievements/welcome_erin.tres"),
	preload("res://data/achievements/welcome_evan.tres"),
	preload("res://data/achievements/welcome_ben.tres"),
	preload("res://data/achievements/welcome_ethan.tres"),
	preload("res://data/achievements/tag_team.tres"),
	preload("res://data/achievements/first_blood.tres"),
	preload("res://data/achievements/boss_slayer.tres"),
	preload("res://data/achievements/got_your_back.tres"),
	preload("res://data/achievements/slow_your_roll.tres"),
	preload("res://data/achievements/loud_and_clear.tres"),
	preload("res://data/achievements/good_boy.tres"),
	preload("res://data/achievements/pack_rat.tres"),
	preload("res://data/achievements/globetrotter.tres"),
	preload("res://data/achievements/curtain_call.tres"),
	preload("res://data/achievements/time_lord.tres"),
	preload("res://data/achievements/menagerie.tres"),
	preload("res://data/achievements/secrets_out.tres"),
	preload("res://data/achievements/complete_set.tres"),
	preload("res://data/achievements/friend_of_the_town.tres"),
]

const TIME_LORD_TARGET: int = 25
const PACK_RAT_TARGET: int = 10
const COMPANION_TYPES: Array[String] = ["frosty", "twinkle", "calvin_coolidge", "william_mary", "lizard"]
const TOWN_QUEST_IDS: Array[String] = [
	"gus", "moira", "reggie", "fanny", "penny", "otis",
	"wendell", "clara", "ambrose", "dottie", "tobias", "agnes",
]
const SPOON_COUNT: int = 12
const SECRET_DESCRIPTION: String = "???"

var achievements: Dictionary = {}  # id -> AchievementData
var unlocked: Dictionary = {}  # id -> bool, persisted via SaveManager

# Persisted progress counters that don't have a single boolean home elsewhere.
var bies_activation_count: int = 0
var companion_types_seen: Dictionary = {}  # companion_name -> true, persisted

func _ready() -> void:
	for data: AchievementData in ACHIEVEMENT_LIST:
		achievements[data.id] = data
	GameManager.location_completed.connect(_on_location_completed)
	GameManager.enemy_defeated.connect(_on_enemy_defeated)
	GameManager.player_revived.connect(_on_player_revived)
	GameManager.companion_summoned.connect(_on_companion_summoned)
	GameManager.level_flag_set.connect(_on_level_flag_set)
	GameManager.item_collected.connect(_on_item_collected)
	GameManager.bies_activated.connect(_on_bies_activated)
	GameManager.characters_swapped.connect(_on_characters_swapped)
	GameManager.noise_emitted.connect(_on_noise_emitted)
	# Run after GameManager._ready()/SaveManager.load_game() so a save that
	# already satisfies a condition (e.g. all 13 locations cleared before
	# this system existed) retroactively unlocks it.
	call_deferred("_check_retroactive")

func is_unlocked(id: String) -> bool:
	return unlocked.get(id, false)

func get_ordered_ids() -> Array[String]:
	var ids: Array[String] = []
	for data: AchievementData in ACHIEVEMENT_LIST:
		ids.append(data.id)
	return ids

func get_display_name(id: String) -> String:
	var data: AchievementData = achievements.get(id)
	if data == null:
		return SECRET_DESCRIPTION
	if data.secret and not is_unlocked(id):
		return SECRET_DESCRIPTION
	return data.display_name

func get_description(id: String) -> String:
	var data: AchievementData = achievements.get(id)
	if data == null:
		return ""
	if data.secret and not is_unlocked(id):
		return "A secret achievement. Keep exploring to discover it."
	return data.description

func get_icon_color(id: String) -> Color:
	var data: AchievementData = achievements.get(id)
	if data == null:
		return Color.WHITE
	if data.secret and not is_unlocked(id):
		return Color(0.3, 0.3, 0.35)
	return data.icon_color

func _unlock(id: String) -> void:
	if unlocked.get(id, false):
		return
	if id not in achievements:
		return
	unlocked[id] = true
	SaveManager.save_game()
	achievement_unlocked.emit(id)

func _on_location_completed(location_id: String) -> void:
	match location_id:
		"pipe_organ_works":
			_unlock("welcome_erin")
		"old_parish_church":
			_unlock("welcome_evan")
		"iron_strings_gym":
			_unlock("welcome_ben")
		"recording_studio":
			_unlock("welcome_ethan")
		"grand_marquee_cinema":
			_unlock("curtain_call")
	if GameManager.completed_locations.size() >= 13:
		_unlock("globetrotter")

func _on_enemy_defeated(_enemy_name: String, is_boss: bool) -> void:
	_unlock("first_blood")
	if is_boss:
		_unlock("boss_slayer")

func _on_player_revived() -> void:
	_unlock("got_your_back")

func _on_companion_summoned(companion_name: String) -> void:
	if companion_name == "frosty":
		_unlock("good_boy")
	if not companion_types_seen.get(companion_name, false):
		companion_types_seen[companion_name] = true
		SaveManager.save_game()
	if companion_types_seen.size() >= COMPANION_TYPES.size():
		_unlock("menagerie")

func _on_level_flag_set(_location_id: String, key: String, value) -> void:
	if key == "secret_revealed" and value:
		_unlock("secrets_out")

func _on_item_collected(_character_name: String, _item_id: String) -> void:
	_check_collectible_achievements()

func _on_bies_activated() -> void:
	_unlock("slow_your_roll")
	bies_activation_count += 1
	SaveManager.save_game()
	if bies_activation_count >= TIME_LORD_TARGET:
		_unlock("time_lord")

func _on_characters_swapped() -> void:
	_unlock("tag_team")

func _on_noise_emitted(_position: Vector2, _radius: float) -> void:
	_unlock("loud_and_clear")

func _check_retroactive() -> void:
	for location_id: String in GameManager.completed_locations:
		_on_location_completed(location_id)
	_check_collectible_achievements()

# Pack Rat / The Complete Set / Friend of the Town all derive from state that
# can be satisfied by several different events (item grants, quest turn-ins),
# so they're re-checked from scratch whenever an item is collected.
func _check_collectible_achievements() -> void:
	var total_items: int = 0
	var spoon_count: int = 0
	for character_key: String in GameManager.inventories:
		var items: Array = GameManager.inventories[character_key]
		total_items += items.size()
		for item_id: String in items:
			if item_id.begins_with("numbered_spoon_"):
				spoon_count += 1
	if total_items >= PACK_RAT_TARGET:
		_unlock("pack_rat")
	if spoon_count >= SPOON_COUNT:
		_unlock("complete_set")

	var all_quests_done: bool = true
	for quest_id: String in TOWN_QUEST_IDS:
		if GameManager.get_level_flag("town", "quest_" + quest_id, "not_started") != "complete":
			all_quests_done = false
			break
	if all_quests_done:
		_unlock("friend_of_the_town")
