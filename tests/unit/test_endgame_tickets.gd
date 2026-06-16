extends GutTest

# Guards the endgame against the soft-lock found during the elaboration pass: the Grand
# Marquee finale requires all five character movie tickets, but three of them were never
# granted in any level. These tests assert every ticket is obtainable (referenced in a
# non-cinema level script — the cinema only *checks* them) and that the new ItemData
# resources all load with matching ids. Pure data/text checks — no scene instantiation.

const ITEM_DIR := "res://data/items/"
const SCRIPT_DIR := "res://scripts/3d/"
const CINEMA := "grand_marquee_cinema3d.gd"

const TICKETS := ["ticket_quinn", "ticket_erin", "ticket_evan", "ticket_ben", "ticket_ethan"]
const DOUG_CLUES := ["faded_photograph", "pressed_flower", "doug_locker_tag", "doug_recording",
	"doug_pocketwatch", "doug_crate_tag", "doug_checkout_card", "doug_photo_strip",
	"doug_flashlight", "doug_carabiner", "doug_vr_log", "doug_flyer"]
const NEW_ITEMS := ["pressed_flower", "boiler_key", "doug_locker_tag", "doug_recording",
	"archive_key", "doug_pocketwatch", "doug_crate_tag", "doug_checkout_card",
	"doug_photo_strip", "doug_flashlight", "doug_carabiner", "doug_vr_log", "doug_flyer"]

func _item(id: String) -> Resource:
	return load(ITEM_DIR + id + ".tres")

# Concatenated source of every level script EXCEPT the cinema (which only checks tickets).
func _non_cinema_source() -> String:
	var out := ""
	var dir := DirAccess.open(SCRIPT_DIR)
	assert_not_null(dir, "scripts/3d should be readable")
	if dir == null:
		return out
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with("3d.gd") and f != CINEMA:
			var fa := FileAccess.open(SCRIPT_DIR + f, FileAccess.READ)
			if fa != null:
				out += fa.get_as_text()
		f = dir.get_next()
	return out

func test_all_tickets_exist_and_ids_match() -> void:
	for t: String in TICKETS:
		var it: Resource = _item(t)
		assert_not_null(it, "%s.tres should load" % t)
		if it != null:
			assert_eq(it.get("id"), t, "%s id should match its filename" % t)

func test_new_items_load_with_matching_ids() -> void:
	for id: String in NEW_ITEMS:
		var it: Resource = _item(id)
		assert_not_null(it, "%s.tres should load" % id)
		if it != null:
			assert_eq(it.get("id"), id, "%s id should match its filename" % id)

func test_doug_clues_exist() -> void:
	for c: String in DOUG_CLUES:
		assert_not_null(_item(c), "%s.tres (Doug clue) should load" % c)

# The soft-lock guard: each ticket must be referenced in a non-cinema level (i.e. granted
# somewhere you can actually reach), or the finale can never be completed.
func test_every_ticket_is_obtainable_outside_the_cinema() -> void:
	var src := _non_cinema_source()
	for t: String in TICKETS:
		assert_true(src.find(t + ".tres") != -1,
			"%s is never referenced in a non-cinema level — endgame soft-lock" % t)

func _file_has(fname: String, needle: String) -> bool:
	var fa := FileAccess.open(SCRIPT_DIR + fname, FileAccess.READ)
	return fa != null and fa.get_as_text().find(needle) != -1

# The pocket lantern is the REQUIRED entry gate for the Underground Tunnels — it must be
# obtainable (granted at the Harbor & Docks), or that level is unreachable.
func test_pocket_lantern_is_obtainable() -> void:
	assert_true(_file_has("harbor_docks3d.gd", "pocket_lantern.tres"),
		"pocket_lantern must be obtainable at the Harbor — it gates the Underground Tunnels")

# Cross-level shortcut keys must have BOTH a source level (grants it) and a use level
# (references it), so they're meaningful and not orphaned.
func test_cross_level_keys_have_source_and_use() -> void:
	var pairs := {
		"boiler_key": ["iron_strings_gym3d.gd", "harbor_docks3d.gd"],   # Gym → Harbor
		"archive_key": ["clocktower3d.gd", "library_archive3d.gd"],     # Clocktower → Library
	}
	for key: String in pairs:
		for fname: String in pairs[key]:
			assert_true(_file_has(fname, key + ".tres"),
				"%s should be referenced in %s (source + use sites)" % [key, fname])
