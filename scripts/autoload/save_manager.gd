extends Node

# Multi-slot save system. Each slot is an independent ConfigFile under
# user://save_slot_<N>.cfg holding the same "progress" section the original
# single-file savegame.cfg did, plus a "meta" timestamp. user://save_meta.cfg
# tracks which slot was played last (for "Continue") so the title screen can
# jump straight back in without a slot picker.

const SAVE_SLOT_COUNT: int = 3
const META_PATH: String = "user://save_meta.cfg"
const LEGACY_SAVE_PATH: String = "user://savegame.cfg"

# The slot active for this play session. -1 until New Game/Load/Continue
# picks one; save_game() is a no-op until then.
var current_slot: int = -1

func _ready() -> void:
	_migrate_legacy_save()

func slot_path(slot: int) -> String:
	return "user://save_slot_%d.cfg" % slot

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))

func delete_save(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(slot_path(slot))

func get_last_slot() -> int:
	var meta := ConfigFile.new()
	if meta.load(META_PATH) != OK:
		return -1
	return meta.get_value("meta", "last_slot", -1)

# Lightweight read for the title screen's slot picker — does not touch
# GameManager/AchievementManager state.
func get_slot_summary(slot: int) -> Dictionary:
	if not has_save(slot):
		return {"exists": false}
	var cfg := ConfigFile.new()
	if cfg.load(slot_path(slot)) != OK:
		return {"exists": false}
	var completed: Array = cfg.get_value("progress", "completed_locations", [])
	return {
		"exists": true,
		"completed_count": completed.size(),
		"unlocked_characters": cfg.get_value("progress", "unlocked_characters", []),
		"timestamp": cfg.get_value("meta", "timestamp", ""),
		"doug_found": "grand_marquee" in completed,
	}

func save_game() -> void:
	if current_slot < 0:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "completed_locations", GameManager.completed_locations)
	cfg.set_value("progress", "unlocked_characters", GameManager.unlocked_characters)
	cfg.set_value("progress", "inventories", GameManager.inventories)
	cfg.set_value("progress", "level_progress", GameManager.level_progress)
	cfg.set_value("progress", "achievements_unlocked", AchievementManager.unlocked)
	cfg.set_value("progress", "achievements_bies_count", AchievementManager.bies_activation_count)
	cfg.set_value("progress", "achievements_companions_seen", AchievementManager.companion_types_seen)
	cfg.set_value("progress", "achievements_spoon_powers_seen", AchievementManager.spoon_powers_seen)
	cfg.set_value("meta", "timestamp", Time.get_datetime_string_from_system())
	cfg.save(slot_path(current_slot))
	_set_last_slot(current_slot)

func load_game(slot: int) -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(slot_path(slot)) != OK:
		return false
	current_slot = slot
	GameManager.completed_locations = cfg.get_value("progress", "completed_locations", [])
	GameManager.unlocked_characters = cfg.get_value("progress", "unlocked_characters", ["quinn", "erin"])
	GameManager.inventories = cfg.get_value("progress", "inventories", {})
	GameManager.level_progress = cfg.get_value("progress", "level_progress", {})
	AchievementManager.unlocked = cfg.get_value("progress", "achievements_unlocked", {})
	AchievementManager.bies_activation_count = cfg.get_value("progress", "achievements_bies_count", 0)
	AchievementManager.companion_types_seen = cfg.get_value("progress", "achievements_companions_seen", {})
	AchievementManager.spoon_powers_seen = cfg.get_value("progress", "achievements_spoon_powers_seen", {})
	AchievementManager._check_retroactive()
	_set_last_slot(slot)
	return true

# Resets GameManager/AchievementManager to a fresh-start state, adopts `slot`
# as the current slot, and writes it immediately so the slot picker shows it
# as occupied right away.
func start_new_game(slot: int) -> void:
	current_slot = slot
	GameManager.reset_progress()
	save_game()

func _set_last_slot(slot: int) -> void:
	var meta := ConfigFile.new()
	meta.load(META_PATH)
	meta.set_value("meta", "last_slot", slot)
	meta.save(META_PATH)

# One-time migration: if an old single-slot savegame.cfg exists from before
# save slots were introduced, adopt it as Slot 1 so existing progress isn't lost.
func _migrate_legacy_save() -> void:
	if FileAccess.file_exists(META_PATH):
		return
	if not FileAccess.file_exists(LEGACY_SAVE_PATH):
		return
	if has_save(1):
		return
	DirAccess.copy_absolute(LEGACY_SAVE_PATH, slot_path(1))
	_set_last_slot(1)
