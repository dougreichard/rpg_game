extends GutTest

# Spec values from CLAUDE.md's "Character stats (starting values)" table —
# regression guard against accidental balance drift in the .tres resources.
const SPEC := {
	"quinn": {"max_hp": 120.0, "move_speed": 140.0, "attack_damage": 20.0, "attack_cooldown": 0.5, "dash_distance": 120.0, "dash_iframe_duration": 0.15},
	"erin":  {"max_hp": 90.0,  "move_speed": 180.0, "attack_damage": 15.0, "attack_cooldown": 0.35, "dash_distance": 160.0, "dash_iframe_duration": 0.2},
	"evan":  {"max_hp": 150.0, "move_speed": 120.0, "attack_damage": 28.0, "attack_cooldown": 0.65, "dash_distance": 100.0, "dash_iframe_duration": 0.12},
}

const ALL_CHARACTERS := ["quinn", "erin", "evan", "ben", "ethan"]

func test_quinn_erin_evan_match_claude_md_spec_table() -> void:
	for id in SPEC:
		var data: CharacterData = load("res://data/characters/%s.tres" % id)
		var expected: Dictionary = SPEC[id]
		for stat in expected:
			assert_eq(data.get(stat), expected[stat], "%s.%s should match CLAUDE.md spec" % [id, stat])

func test_evan_is_tankiest_and_hardest_hitting() -> void:
	# CLAUDE.md: "Evan is the slowest but hits hardest and has the most HP"
	var quinn: CharacterData = load("res://data/characters/quinn.tres")
	var erin: CharacterData = load("res://data/characters/erin.tres")
	var evan: CharacterData = load("res://data/characters/evan.tres")
	assert_gt(evan.max_hp, quinn.max_hp, "Evan should have more HP than Quinn")
	assert_gt(evan.max_hp, erin.max_hp, "Evan should have more HP than Erin")
	assert_gt(evan.attack_damage, quinn.attack_damage, "Evan should hit harder than Quinn")
	assert_gt(evan.attack_damage, erin.attack_damage, "Evan should hit harder than Erin")
	assert_lt(evan.move_speed, quinn.move_speed, "Evan should be slower than Quinn")
	assert_lt(evan.move_speed, erin.move_speed, "Evan should be slower than Erin")

func test_erin_is_fastest_and_attacks_most_often() -> void:
	# CLAUDE.md: "Erin is faster and attacks more often"
	var quinn: CharacterData = load("res://data/characters/quinn.tres")
	var erin: CharacterData = load("res://data/characters/erin.tres")
	assert_gt(erin.move_speed, quinn.move_speed, "Erin should be faster than Quinn")
	assert_lt(erin.attack_cooldown, quinn.attack_cooldown, "Erin should attack more often (lower cooldown) than Quinn")

func test_every_character_has_a_name_and_named_special() -> void:
	for id in ALL_CHARACTERS:
		var data: CharacterData = load("res://data/characters/%s.tres" % id)
		assert_ne(data.character_name, "", "%s should have a character_name" % id)
		assert_ne(data.special_name, "", "%s should have a special_name" % id)
		assert_gt(data.max_hp, 0.0, "%s.max_hp should be positive" % id)
		assert_gt(data.move_speed, 0.0, "%s.move_speed should be positive" % id)
		assert_gt(data.attack_cooldown, 0.0, "%s.attack_cooldown should be positive" % id)
