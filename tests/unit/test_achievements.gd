extends GutTest

# CLAUDE.md: the achievement system has 12-20 achievements, a mix of secret
# and visible, each backed by a data/achievements/*.tres AchievementData
# Resource and listed in AchievementManager.ACHIEVEMENT_LIST. This only reads
# the const list and .tres Resources directly — never mutates
# AchievementManager.unlocked or calls SaveManager, so it can't corrupt
# user://savegame.cfg.

func test_achievement_count_in_spec_range() -> void:
	var count: int = AchievementManager.ACHIEVEMENT_LIST.size()
	assert_between(count, 12, 20, "Should have 12-20 achievements per CLAUDE.md spec")

func test_achievement_ids_unique_and_non_empty() -> void:
	var seen: Dictionary = {}
	for data: AchievementData in AchievementManager.ACHIEVEMENT_LIST:
		assert_ne(data.id, "", "Achievement id should not be empty")
		assert_false(seen.has(data.id), "Achievement id '%s' should be unique" % data.id)
		seen[data.id] = true

func test_achievement_fields_populated() -> void:
	for data: AchievementData in AchievementManager.ACHIEVEMENT_LIST:
		assert_ne(data.display_name, "", "%s should have a display_name" % data.id)
		assert_ne(data.description, "", "%s should have a description" % data.id)

func test_achievement_file_matches_its_id() -> void:
	for data: AchievementData in AchievementManager.ACHIEVEMENT_LIST:
		var path: String = data.resource_path
		var file_name: String = path.get_file().get_basename()
		assert_eq(file_name, data.id, "File '%s' should be named after its id" % path)

func test_has_both_secret_and_visible_achievements() -> void:
	var secret_count: int = 0
	var visible_count: int = 0
	for data: AchievementData in AchievementManager.ACHIEVEMENT_LIST:
		if data.secret:
			secret_count += 1
		else:
			visible_count += 1
	assert_gt(secret_count, 0, "Should have at least one secret achievement")
	assert_gt(visible_count, 0, "Should have at least one visible achievement")

func test_achievements_dictionary_keyed_by_id() -> void:
	# AchievementManager._ready() populates `achievements` from ACHIEVEMENT_LIST.
	for data: AchievementData in AchievementManager.ACHIEVEMENT_LIST:
		assert_true(AchievementManager.achievements.has(data.id), "achievements dict should contain '%s'" % data.id)
		assert_eq(AchievementManager.achievements[data.id], data)

func test_get_ordered_ids_matches_list_size() -> void:
	var ids: Array[String] = AchievementManager.get_ordered_ids()
	assert_eq(ids.size(), AchievementManager.ACHIEVEMENT_LIST.size())

func test_secret_achievement_hides_name_and_description_until_unlocked() -> void:
	for data: AchievementData in AchievementManager.ACHIEVEMENT_LIST:
		if data.secret and not AchievementManager.is_unlocked(data.id):
			assert_eq(AchievementManager.get_display_name(data.id), AchievementManager.SECRET_DESCRIPTION)
			assert_ne(AchievementManager.get_description(data.id), data.description)
			return
	fail_test("Expected at least one locked secret achievement to test against")
