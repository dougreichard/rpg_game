extends Node

const SAVE_PATH: String = "user://savegame.cfg"

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "completed_locations", GameManager.completed_locations)
	cfg.set_value("progress", "unlocked_characters", GameManager.unlocked_characters)
	cfg.set_value("progress", "inventories", GameManager.inventories)
	cfg.set_value("progress", "level_progress", GameManager.level_progress)
	cfg.set_value("progress", "achievements_unlocked", AchievementManager.unlocked)
	cfg.set_value("progress", "achievements_bies_count", AchievementManager.bies_activation_count)
	cfg.set_value("progress", "achievements_companions_seen", AchievementManager.companion_types_seen)
	cfg.save(SAVE_PATH)

func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	GameManager.completed_locations = cfg.get_value("progress", "completed_locations", [])
	GameManager.unlocked_characters = cfg.get_value("progress", "unlocked_characters", ["quinn", "erin"])
	GameManager.inventories = cfg.get_value("progress", "inventories", {})
	GameManager.level_progress = cfg.get_value("progress", "level_progress", {})
	AchievementManager.unlocked = cfg.get_value("progress", "achievements_unlocked", {})
	AchievementManager.bies_activation_count = cfg.get_value("progress", "achievements_bies_count", 0)
	AchievementManager.companion_types_seen = cfg.get_value("progress", "achievements_companions_seen", {})
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
