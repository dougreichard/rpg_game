extends GutTest

# Stealth/awareness FSM (PATROL -> INVESTIGATE -> CHASE) — see CLAUDE.md
# "Stealth & awareness". Scene-free: reads `EnemyData` "Stealth" tunables off the
# .tres Resources and the FSM threshold/rate consts straight off the 3D Enemy3D
# script's constant map (Enemy3D has no class_name, so we read its consts via
# the Script resource). No node ever enters the tree.

const STEALTH_SPEC := {
	"vision_range": 170.0,
	"vision_angle_deg": 100.0,
	"hearing_range": 90.0,
	"patrol_radius": 80.0,
}

const ALL_ENEMIES := ["grunt", "runner", "brute", "sentry", "boss"]

var _E: Dictionary = load("res://scripts/3d/enemy_3d.gd").get_script_constant_map()

func _c(name: String) -> float:
	return _E[name]

func test_enemy_stealth_tunables_match_claude_md_spec() -> void:
	for id in ALL_ENEMIES:
		var data: EnemyData = load("res://data/enemies/%s.tres" % id)
		for stat in STEALTH_SPEC:
			assert_eq(data.get(stat), STEALTH_SPEC[stat], "%s.%s should match CLAUDE.md spec" % [id, stat])

func test_enemy_fsm_thresholds_match_claude_md_spec() -> void:
	assert_eq(_c("SUSPICION_THRESHOLD"), 0.35, "SUSPICION_THRESHOLD should match CLAUDE.md spec")
	assert_eq(_c("ALERT_THRESHOLD"), 1.0, "ALERT_THRESHOLD should match CLAUDE.md spec")
	assert_eq(_c("SIGHT_GAIN_RATE"), 0.6, "SIGHT_GAIN_RATE should match CLAUDE.md spec")
	assert_eq(_c("ALERT_DECAY_RATE"), 0.25, "ALERT_DECAY_RATE should match CLAUDE.md spec")
	assert_eq(_c("NOISE_ALERT_FLOOR"), 0.4, "NOISE_ALERT_FLOOR should match CLAUDE.md spec")
	assert_eq(_c("PATROL_SPEED_SCALE"), 0.5, "PATROL_SPEED_SCALE should match CLAUDE.md spec")
	assert_eq(_c("PATROL_PAUSE_DURATION"), 1.2, "PATROL_PAUSE_DURATION should match CLAUDE.md spec")
	assert_eq(_c("INVESTIGATE_LOOK_DURATION"), 2.5, "INVESTIGATE_LOOK_DURATION should match CLAUDE.md spec")

func test_noise_alone_can_escalate_patrol_to_investigate() -> void:
	assert_gt(_c("NOISE_ALERT_FLOOR"), _c("SUSPICION_THRESHOLD"),
		"A noise burst alone should be loud enough to push a guard from PATROL into INVESTIGATE")
	assert_lt(_c("NOISE_ALERT_FLOOR"), _c("ALERT_THRESHOLD"),
		"A noise burst alone should NOT snap a guard straight into CHASE — it should investigate first")

func test_alert_gain_outpaces_decay_and_thresholds_are_ordered() -> void:
	assert_gt(_c("SIGHT_GAIN_RATE"), _c("ALERT_DECAY_RATE"),
		"Spotting the player should raise alert faster than losing sight lowers it")
	assert_lt(_c("SUSPICION_THRESHOLD"), _c("ALERT_THRESHOLD"),
		"SUSPICION_THRESHOLD (-> INVESTIGATE) must be lower than ALERT_THRESHOLD (-> CHASE)")
	assert_lt(_c("PATROL_SPEED_SCALE"), 1.0, "Patrolling guards should move slower than their chase speed")

func test_every_enemy_has_positive_stealth_tunables() -> void:
	for id in ALL_ENEMIES:
		var data: EnemyData = load("res://data/enemies/%s.tres" % id)
		assert_gt(data.vision_range, 0.0, "%s.vision_range should be positive" % id)
		assert_gt(data.vision_angle_deg, 0.0, "%s.vision_angle_deg should be positive" % id)
		assert_lt(data.vision_angle_deg, 360.0, "%s.vision_angle_deg should be a forward cone, not omniscience" % id)
		assert_gt(data.hearing_range, 0.0, "%s.hearing_range should be positive" % id)
		assert_gt(data.patrol_radius, 0.0, "%s.patrol_radius should be positive" % id)
