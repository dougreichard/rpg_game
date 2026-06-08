extends GutTest

# Stealth/awareness FSM (PATROL -> INVESTIGATE -> CHASE) — see CLAUDE.md
# "Stealth & awareness". Stays scene-free like the rest of this suite: reads
# `EnemyData` "Stealth" export-group tunables straight off the .tres Resources,
# and the Enemy FSM's threshold/rate consts straight off the Enemy class (the
# same "load a Resource / read a const" pattern test_enemy_data.gd and
# test_unlock_chain.gd already use) — no scene instantiation, no Enemy node
# ever enters the tree, so GameManager/SaveManager state stays untouched.

const STEALTH_SPEC := {
	"vision_range": 170.0,
	"vision_angle_deg": 100.0,
	"hearing_range": 90.0,
	"patrol_radius": 80.0,
}

const ALL_ENEMIES := ["grunt", "runner", "brute", "sentry", "boss"]

func test_enemy_stealth_tunables_match_claude_md_spec() -> void:
	for id in ALL_ENEMIES:
		var data: EnemyData = load("res://data/enemies/%s.tres" % id)
		for stat in STEALTH_SPEC:
			assert_eq(data.get(stat), STEALTH_SPEC[stat], "%s.%s should match CLAUDE.md spec" % [id, stat])

func test_enemy_fsm_thresholds_match_claude_md_spec() -> void:
	# CLAUDE.md: "Crossing SUSPICION_THRESHOLD (~35% alert) escalates PATROL ->
	# INVESTIGATE; reaching ALERT_THRESHOLD (100%) escalates straight into CHASE"
	assert_eq(Enemy.SUSPICION_THRESHOLD, 0.35, "SUSPICION_THRESHOLD should match CLAUDE.md spec")
	assert_eq(Enemy.ALERT_THRESHOLD, 1.0, "ALERT_THRESHOLD should match CLAUDE.md spec")
	# CLAUDE.md: "Sight fills an _alert_meter toward ALERT_THRESHOLD at
	# SIGHT_GAIN_RATE; losing sight decays it at ALERT_DECAY_RATE"
	assert_eq(Enemy.SIGHT_GAIN_RATE, 0.6, "SIGHT_GAIN_RATE should match CLAUDE.md spec")
	assert_eq(Enemy.ALERT_DECAY_RATE, 0.25, "ALERT_DECAY_RATE should match CLAUDE.md spec")
	# CLAUDE.md: "raises a PATROL/INVESTIGATE guard's alert to at least
	# NOISE_ALERT_FLOOR (40%)"
	assert_eq(Enemy.NOISE_ALERT_FLOOR, 0.4, "NOISE_ALERT_FLOOR should match CLAUDE.md spec")
	# CLAUDE.md: "_tick_patrol ... at PATROL_SPEED_SCALE (half normal move_speed
	# — patrols amble, they don't rush), pausing for PATROL_PAUSE_DURATION"
	assert_eq(Enemy.PATROL_SPEED_SCALE, 0.5, "PATROL_SPEED_SCALE should match CLAUDE.md spec")
	assert_eq(Enemy.PATROL_PAUSE_DURATION, 1.2, "PATROL_PAUSE_DURATION should match CLAUDE.md spec")
	# CLAUDE.md: "the guard walks to the last spot it ... saw or heard the
	# player, lingers for INVESTIGATE_LOOK_DURATION, then stands down to PATROL"
	assert_eq(Enemy.INVESTIGATE_LOOK_DURATION, 2.5, "INVESTIGATE_LOOK_DURATION should match CLAUDE.md spec")

func test_noise_alone_can_escalate_patrol_to_investigate() -> void:
	# A noise burst floors alert at NOISE_ALERT_FLOOR (40%), which sits ABOVE
	# SUSPICION_THRESHOLD (35%) — meaning a noise alone (no sighting needed) is
	# enough to kick a guard from PATROL straight to INVESTIGATE. This is the
	# load-bearing relationship behind Twinkle's bark distraction (and noise in
	# general): a lure has to be loud enough to actually pull a guard's
	# attention, not just nudge it.
	assert_gt(Enemy.NOISE_ALERT_FLOOR, Enemy.SUSPICION_THRESHOLD,
		"A noise burst alone should be loud enough to push a guard from PATROL into INVESTIGATE")
	assert_lt(Enemy.NOISE_ALERT_FLOOR, Enemy.ALERT_THRESHOLD,
		"A noise burst alone should NOT be enough to snap a guard straight into CHASE — it should investigate first")

func test_alert_gain_outpaces_decay_and_thresholds_are_ordered() -> void:
	# CLAUDE.md: "combat must stay readable" — a guard that notices the player
	# should become suspicious faster than a guard that loses sight calms down,
	# otherwise sighting the player would feel inconsequential.
	assert_gt(Enemy.SIGHT_GAIN_RATE, Enemy.ALERT_DECAY_RATE,
		"Spotting the player should raise alert faster than losing sight lowers it")
	assert_lt(Enemy.SUSPICION_THRESHOLD, Enemy.ALERT_THRESHOLD,
		"SUSPICION_THRESHOLD (-> INVESTIGATE) must be lower than ALERT_THRESHOLD (-> CHASE) for the escalation ladder to make sense")
	# CLAUDE.md: "patrols amble, they don't rush"
	assert_lt(Enemy.PATROL_SPEED_SCALE, 1.0, "Patrolling guards should move slower than their normal chase speed")

func test_every_enemy_has_positive_stealth_tunables() -> void:
	for id in ALL_ENEMIES:
		var data: EnemyData = load("res://data/enemies/%s.tres" % id)
		assert_gt(data.vision_range, 0.0, "%s.vision_range should be positive" % id)
		assert_gt(data.vision_angle_deg, 0.0, "%s.vision_angle_deg should be positive" % id)
		assert_lt(data.vision_angle_deg, 360.0, "%s.vision_angle_deg should be less than a full circle (it's a forward cone, not omniscience)" % id)
		assert_gt(data.hearing_range, 0.0, "%s.hearing_range should be positive" % id)
		assert_gt(data.patrol_radius, 0.0, "%s.patrol_radius should be positive" % id)
