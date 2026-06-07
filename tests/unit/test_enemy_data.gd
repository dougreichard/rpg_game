extends GutTest

# Spec values from CLAUDE.md's "Enemy stats (starting values)" table —
# regression guard against accidental balance drift in the .tres resources.
const SPEC := {
	"grunt":  {"max_hp": 60.0,  "move_speed": 80.0,  "attack_damage": 12.0, "attack_range": 40.0,  "windup_duration": 0.6},
	"runner": {"max_hp": 30.0,  "move_speed": 170.0, "attack_damage": 8.0,  "attack_range": 30.0,  "windup_duration": 0.3},
	"brute":  {"max_hp": 110.0, "move_speed": 65.0,  "attack_damage": 18.0, "attack_range": 46.0,  "windup_duration": 0.8},
	"sentry": {"max_hp": 45.0,  "move_speed": 50.0,  "attack_damage": 14.0, "attack_range": 220.0, "windup_duration": 0.5},
	"boss":   {"max_hp": 400.0, "move_speed": 55.0,  "attack_damage": 22.0, "attack_range": 50.0,  "windup_duration": 0.7},
}

func test_enemies_match_claude_md_spec_table() -> void:
	for id in SPEC:
		var data: EnemyData = load("res://data/enemies/%s.tres" % id)
		var expected: Dictionary = SPEC[id]
		for stat in expected:
			assert_eq(data.get(stat), expected[stat], "%s.%s should match CLAUDE.md spec" % [id, stat])

func test_sentry_is_ranged_with_a_projectile() -> void:
	var sentry: EnemyData = load("res://data/enemies/sentry.tres")
	assert_true(sentry.is_ranged, "Sentry should be flagged is_ranged")
	assert_gt(sentry.projectile_speed, 0.0, "Sentry should have a positive projectile_speed")
	assert_eq(sentry.projectile_speed, 260.0, "Sentry projectile_speed should match CLAUDE.md spec")

func test_boss_is_flagged_with_telegraphed_aoe_slam() -> void:
	# CLAUDE.md guardrail: "Boss adds AoE slam with a visible wind-up ring/indicator"
	var boss: EnemyData = load("res://data/enemies/boss.tres")
	assert_true(boss.is_boss, "Boss should be flagged is_boss")
	assert_gt(boss.slam_telegraph_duration, 0.0, "Boss slam must have a non-zero telegraph — attacks must be telegraphed")
	assert_eq(boss.slam_damage, 26.0, "Boss slam_damage should match CLAUDE.md spec")
	assert_eq(boss.slam_radius, 110.0, "Boss slam_radius should match CLAUDE.md spec")
	assert_eq(boss.slam_cooldown, 4.0, "Boss slam_cooldown should match CLAUDE.md spec")

func test_runner_is_low_hp_high_speed_brute_is_inverse() -> void:
	# CLAUDE.md: "Runner: ... low health, easy to one-shot but hard to hit."
	# "Brute: slow, ... hits hard and soaks damage"
	var runner: EnemyData = load("res://data/enemies/runner.tres")
	var brute: EnemyData = load("res://data/enemies/brute.tres")
	assert_lt(runner.max_hp, brute.max_hp, "Runner should have less HP than Brute")
	assert_gt(runner.move_speed, brute.move_speed, "Runner should be faster than Brute")
	assert_lt(runner.attack_damage, brute.attack_damage, "Runner should hit softer than Brute")
