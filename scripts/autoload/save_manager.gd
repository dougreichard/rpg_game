extends Node

const SAVE_PATH: String = "user://savegame.cfg"

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "completed_locations", GameManager.completed_locations)
	cfg.set_value("progress", "unlocked_characters", GameManager.unlocked_characters)
	cfg.set_value("progress", "inventories", GameManager.inventories)
	cfg.set_value("progress", "level_progress", GameManager.level_progress)
	cfg.save(SAVE_PATH)

func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	GameManager.completed_locations = cfg.get_value("progress", "completed_locations", [])
	GameManager.unlocked_characters = cfg.get_value("progress", "unlocked_characters", ["quinn", "erin"])
	GameManager.inventories = cfg.get_value("progress", "inventories", {})
	GameManager.level_progress = cfg.get_value("progress", "level_progress", {})
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
