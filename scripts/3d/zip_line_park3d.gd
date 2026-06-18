extends Level3D
## Zip Line Park (3D) — Ethan + Ben. Multi-room: a combat-free LANDING (warden Lena +
## exit), the MID PLATFORM (Grunt + 2 Runners; Ethan's control panel + lock-sequence +
## winch), and the HIGH PLATFORM (Ben's timed release + the snagged clue bag + a rhythm
## crate), reached once Ethan re-sequences the platform locks. Ethan restores power and
## aligns the locks; Ben catches the TIMING windows (press G while the pulse reads OPEN).
## Grass/wood surfaces, forest-green trim. Win: enemies cleared + panel hacked + release timed.

const ETHAN := preload("res://data/characters/ethan.tres")
const BEN := preload("res://data/characters/ben.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const RUNNER := preload("res://data/enemies/runner.tres")
const TreatItem: ItemData = preload("res://data/items/animal_treat.tres")
const BiesCharmItem: ItemData = preload("res://data/items/bies_charm.tres")
const CarabinerItem: ItemData = preload("res://data/items/doug_carabiner.tres")

# --- thematic surfaces (grass / wood / forest-green trim) ---
const FLOOR_GRASS := "res://assets/art/tiles/synty_floor_grass.png"
const FLOOR_DIRT := "res://assets/art/tiles/synty_floor_dirt.png"
const WALL_WOOD := "res://assets/art/tiles/synty_wall_wood.png"
const FT_PARK := Color(0.74, 0.82, 0.66)
const WT_PARK := Color(0.72, 0.6, 0.42)
const CORNER_COL := Color(0.10, 0.30, 0.15)   # solid forest-green trim

const PULSE_SPEED := 2.4
const PULSE_OPEN := 0.82
const WALL_H := 2.8
const REACH := 2.2

const LANDING_C := Vector3(0, 0, 13.0)
const LENA_POS := Vector3(3.0, 0, 13.5)
const PANEL_POS := Vector3(-4.0, 0.0, -2.0)
const LOCKS := [Vector3(4.0, 0, -4.0), Vector3(4.0, 0, -2.0), Vector3(4.0, 0, 0.0)]
const WINCH_POS := Vector3(-6.0, 0, 3.0)
const LOCK_GATE := Vector3(0.0, 0, -8.5)
const HIGH_C := Vector3(0, 0, -14.0)
# zip-line rider path (cable deck points, trolley hangs just under the cable): high -> mid -> low
const ZIP_TOP := Vector3(0, 4.6, -15.0)
const ZIP_MID := Vector3(0, 3.4, -2.0)
const ZIP_LOW := Vector3(-6.0, 2.2, 6.0)
const ZIP_HANG := Vector3(0, -0.32, 0)
const RELEASE_POS := Vector3(0.0, 0.0, -15.5)
const CLUE_POS := Vector3(-3.5, 0.0, -16.5)
const RHYTHM_POS := Vector3(3.5, 0.0, -16.5)

var _cleared := false
var _enemies_cleared := false
var _panel_hacked := false
var _locks_done := false
var _release_timed := false
var _clue_taken := false
var _winch_done := false
var _rhythm_done := false
var _lock_seq: Array = []
var _spawned := 0
var _pulse := 0.0
var _lena = null
var _panel_lights: Array = []
var _lock_lights: Array = []
var _release_light: MeshInstance3D = null
var _zip_rider: Node3D = null    # trolley that sits on the high cable, ready, and zips on release
var _lock_wall: Node3D = null
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_pulse: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "zip_line"
	multi_room = true
	build_env(Color(0.53, 0.70, 0.90), Color(0.62, 0.66, 0.68), 0.95, 1.5)  # daytime park sky
	point_light(Vector3(0, 3.4, 0), Color(0.9, 1.0, 0.95), 2.0, 16.0)
	point_light(LANDING_C + Vector3(0, 2.6, 0), Color(0.85, 1.0, 0.9), 1.8, 11.0)
	point_light(PANEL_POS + Vector3(0, 2.0, 0), Color(0.4, 0.7, 1.0), 1.4, 5.0)
	point_light(RELEASE_POS + Vector3(0, 2.0, 0), Color(1.0, 0.7, 0.4), 1.4, 6.0)
	_rooms()
	_towers()
	_ziplines()
	_zip_rider = prop("res://assets/models/props/zip_trolley.glb", ZIP_TOP + ZIP_HANG, 0.0, 0.6)  # ready on the high cable
	_panel()
	_locks()
	_winch()
	_release()
	_high_extras()
	_set_dressing()
	_forest_ring()
	make_dialog()
	_build_hud()
	_lena = spawn_npc("congregant_f", LENA_POS, PI)
	add_exit_portal(LANDING_C + Vector3(0, 0, 5.0), Vector3(3, 3, 1.4))
	var p := spawn_duo([ETHAN, BEN], LANDING_C + Vector3(0.0, 0.1, 1.0))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _rooms() -> void:
	# Mid platform — grass, wood rails. Combat. Openings: south (landing), north (high).
	set_theme(FLOOR_GRASS, WALL_WOOD)
	room(Vector3.ZERO, 16, 16, FT_PARK, WT_PARK, WALL_H, ["s", "n"], 3.0, true)
	corridor(Vector3(0, 0, 8), "s", 1.0, FT_PARK, WT_PARK, 3.0, WALL_H, true, CORNER_COL)        # → landing
	corridor(Vector3(0, 0, -8), "n", 1.0, FT_PARK, WT_PARK, 3.0, WALL_H, true, CORNER_COL)       # → high
	_lock_wall = _gate_panel(LOCK_GATE, WALL_H)
	# Landing — grass (combat-free). South vestibule = exit.
	set_theme(FLOOR_GRASS, WALL_WOOD)
	room(LANDING_C, 12, 8, FT_PARK, WT_PARK, WALL_H, ["n", "s"], 3.0, true)
	corridor(LANDING_C + Vector3(0, 0, 4.0), "s", 2.0, FT_PARK, WT_PARK, 3.0, WALL_H, true, CORNER_COL)
	# High platform — dirt landing pad up top.
	set_theme(FLOOR_DIRT, WALL_WOOD)
	room(HIGH_C, 12, 10, FT_PARK, WT_PARK, WALL_H, ["s"], 3.0, true)

func _gate_panel(pos: Vector3, h: float) -> Node3D:
	var size := Vector3(3.0, h, 0.4)
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = size; cs.shape = bs; cs.position = Vector3(0, h * 0.5, 0)
	sb.add_child(cs); sb.add_child(box_mesh(size, WT_PARK, Vector3(0, h * 0.5, 0), 0.0, wall_tex))
	sb.position = pos
	add_child(sb)
	return sb

func _towers() -> void:
	_tower(Vector3(-6.0, 0, 6.0), 2.2, Color(0.4, 0.5, 0.4))
	_tower(Vector3(0.0, 0, -2.0), 3.4, Color(0.35, 0.45, 0.55))
	_tower(HIGH_C + Vector3(0, 0, -1.0), 4.6, Color(0.5, 0.45, 0.35))

func _tower(pos: Vector3, h: float, _col: Color) -> void:
	# Generated timber zip-line tower (synty-prop-gen, painted) — visual-only over the room
	# floor. Mesh is ~4.5m tall; scale to this tower's height so the deck sits near h (where
	# the cables attach). (yaw 0; verify deck facing in-engine.)
	prop("res://assets/models/props/zip_tower.glb", pos, 0.0, h / 4.5)

func _ziplines() -> void:
	_cable(Vector3(-6.0, 2.2, 6.0), Vector3(0.0, 3.4, -2.0))
	_cable(Vector3(0.0, 3.4, -2.0), HIGH_C + Vector3(0, 4.6, -1.0))

func _cable(a: Vector3, b: Vector3) -> void:
	var mid := (a + b) * 0.5
	var line := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 0.03; cm.bottom_radius = 0.03; cm.height = a.distance_to(b)
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.1, 0.1, 0.1); mat.metallic = 0.5
	cm.material = mat; line.mesh = cm
	line.position = mid
	line.look_at_from_position(mid, b, Vector3.UP)
	line.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
	add_child(line)

func _panel() -> void:
	prop("res://assets/models/props/zip_control_panel.glb", PANEL_POS, 0.0)  # Ethan's hack kiosk (painted)
	for i: int in range(3):
		var pip := box_mesh(Vector3(0.16, 0.06, 0.1), Color(0.85, 0.25, 0.2), PANEL_POS + Vector3(-0.3 + float(i) * 0.3, 1.0, 0.28), 1.2)
		add_child(pip)
		_panel_lights.append(pip)

func _locks() -> void:
	for i: int in range(LOCKS.size()):
		add_child(box_mesh(Vector3(0.3, 0.9, 0.3), Color(0.3, 0.3, 0.34), LOCKS[i] + Vector3(0, 0.45, 0)))
		var glow := box_mesh(Vector3(0.18, 0.18, 0.18), Color(0.85, 0.3, 0.3), LOCKS[i] + Vector3(0, 1.0, 0), 1.5)
		add_child(glow); _lock_lights.append(glow)
		_floating_label(str(i + 1), LOCKS[i] + Vector3(0, 1.4, 0), Color(0.7, 0.9, 1.0))

func _winch() -> void:
	prop("res://assets/models/props/zip_winch.glb", WINCH_POS, 0.0)  # generated cable winch (painted)

func _release() -> void:
	prop("res://assets/models/props/zip_release.glb", RELEASE_POS, 0.0)  # generated signal/gate post (painted)
	# staged trolley resting beside the release station (its grounded base reads fine here)
	prop("res://assets/models/props/zip_trolley.glb", RELEASE_POS + Vector3(1.2, 0, 0.4), 0.6)
	_release_light = box_mesh(Vector3(0.3, 0.3, 0.12), Color(0.6, 0.6, 0.2), RELEASE_POS + Vector3(0, 1.1, 0.22), 1.0)
	add_child(_release_light)

func _high_extras() -> void:
	# the snagged clue bag (on the high line) + a rhythm-rig crate
	add_child(box_mesh(Vector3(0.5, 0.5, 0.5), Color(0.4, 0.55, 0.35), CLUE_POS + Vector3(0, 1.6, 0), 0.4))
	add_child(box_mesh(Vector3(0.7, 0.7, 0.7), Color(0.45, 0.4, 0.25), RHYTHM_POS + Vector3(0, 0.35, 0)))

func _forest_ring() -> void:
	# a denser tree/bush border OUTSIDE the room walls (taller trees peek over the 2.8m walls
	# for an enclosed-park backdrop). Deterministic RNG so it's stable across runs.
	var town := "res://assets/models/town/"
	var rng := RandomNumberGenerator.new(); rng.seed = 4242
	var kinds := ["tree", "tree", "tree_large", "bush"]
	var xb := 11.0
	var z := -22.0
	while z <= 21.0:                                   # east + west borders
		for sx: float in [-xb, xb]:
			prop(town + kinds[rng.randi() % kinds.size()] + ".glb",
				Vector3(sx + rng.randf_range(-1.0, 1.0), 0.0, z + rng.randf_range(-1.2, 1.2)), rng.randf() * TAU)
		z += rng.randf_range(2.6, 3.6)
	for sz: float in [-23.0, 22.0]:                    # north + south caps
		var x := -xb
		while x <= xb:
			prop(town + kinds[rng.randi() % kinds.size()] + ".glb",
				Vector3(x + rng.randf_range(-1.0, 1.0), 0.0, sz + rng.randf_range(-1.0, 1.0)), rng.randf() * TAU)
			x += rng.randf_range(2.6, 3.6)

func _play_zip() -> void:
	# the ready trolley zips the cable: high deck -> mid deck -> low deck
	if _zip_rider == null:
		return
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(_zip_rider, "position", ZIP_MID + ZIP_HANG, 1.2).set_ease(Tween.EASE_IN)
	tw.tween_property(_zip_rider, "position", ZIP_LOW + ZIP_HANG, 1.2).set_ease(Tween.EASE_OUT)

func _set_dressing() -> void:
	# Outdoor-park dressing from the Synty town pack (scale 1.0, like the overworld), placed
	# around each area's perimeter — clear of the puzzle spots, paths, spawn/exit and towers.
	# [kind, x, z, yaw_deg]
	var town := "res://assets/models/town/"
	var items := [
		# --- mid platform (room 16x16 @ origin; avoid panel/locks/winch/towers/corridors) ---
		["tree_large", 6.6, 6.6, 20], ["tree", 6.6, -6.6, 120], ["tree", -6.6, -6.6, 210],
		["bush", 6.9, 2.0, 0], ["bush", 6.9, -2.5, 0], ["bush", -6.9, -4.5, 0], ["bush", 2.6, 6.9, 0],
		["park_lamp", 6.8, 6.8, 0], ["park_lamp", -6.8, 6.8, 0], ["street_sign", -6.6, 7.0, 90],
		# --- landing (lobby, room 12x8 @ z=13; Lena + exit) ---
		["bench", -3.0, 13.0, 180], ["tree", 5.0, 15.6, 40], ["tree", -5.0, 15.6, 300],
		["flowerbed", 5.0, 10.6, 0], ["planter", -5.0, 10.6, 0], ["park_lamp", 5.2, 15.6, 0],
		["street_sign", 4.6, 16.2, 200],
		# --- high platform (room 12x10 @ z=-14; avoid release/clue/rhythm/tower) ---
		["tree", 5.0, -17.6, 60], ["tree", -5.0, -17.6, 250], ["tree", 5.0, -10.6, 140],
		["bush", -5.0, -14.0, 0], ["bush", 5.0, -13.6, 0], ["park_lamp", 5.2, -17.6, 0],
	]
	for it: Array in items:
		prop(town + str(it[0]) + ".glb", Vector3(it[1], 0.0, it[2]), deg_to_rad(it[3]), 1.0)

func _floating_label(txt: String, pos: Vector3, col: Color) -> void:
	var l := Label3D.new()
	l.text = txt; l.font = UITheme.font(); l.font_size = 40; l.outline_size = 12
	l.modulate = col; l.outline_modulate = Color(0, 0, 0, 0.95)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.no_depth_test = true
	l.fixed_size = true; l.pixel_size = 0.001; l.position = pos
	add_child(l)

func _spawn_enemies() -> void:
	spawn_enemy(GRUNT, Vector3(0.0, 0.1, 0.5), "res://assets/models/enemies/grunt.glb"); _spawned += 1
	for spot: Vector3 in [Vector3(-2.5, 0.1, -1.0), Vector3(2.5, 0.1, 1.0)]:
		spawn_enemy(RUNNER, spot, "res://assets/models/enemies/runner.glb"); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_panel_hacked = GameManager.get_level_flag(location_id, "panel_hacked", false)
	_locks_done = GameManager.get_level_flag(location_id, "locks_done", false)
	_release_timed = GameManager.get_level_flag(location_id, "release_timed", false)
	_clue_taken = GameManager.get_level_flag(location_id, "clue_taken", false)
	_winch_done = GameManager.get_level_flag(location_id, "winch_done", false)
	_rhythm_done = GameManager.get_level_flag(location_id, "rhythm_done", false)
	if _panel_hacked: _set_panel_solved()
	if _locks_done:
		for g in _lock_lights: ((g as MeshInstance3D).mesh as BoxMesh).material.albedo_color = Color(0.3, 0.95, 0.4)
		_open_lock_gate(false)
	if _release_timed and _release_light != null:
		((_release_light.mesh as BoxMesh).material as StandardMaterial3D).albedo_color = Color(0.3, 0.95, 0.4)
		if _zip_rider != null: _zip_rider.position = ZIP_LOW + ZIP_HANG   # already zipped down

	if _enemies_cleared and _panel_hacked and _release_timed:
		_win(false)

func _open() -> bool:
	return abs(sin(_pulse)) > PULSE_OPEN

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, LENA_POS, REACH): _talk_lena(char_name); return
	# Ethan: control panel (power)
	if char_name == "Ethan" and not _panel_hacked and near3(pp, PANEL_POS, REACH):
		_panel_hacked = true
		GameManager.set_level_flag(location_id, "panel_hacked", true)
		_set_panel_solved()
		_hud_hint.text = "Power restored! Now align the platform locks, then Ben times the release up top."
		Audio.play("special"); return
	# Ethan: platform-lock sequence (1→2→3) → opens the gate to the High Platform
	if not _locks_done:
		for i: int in range(LOCKS.size()):
			if near3(pp, LOCKS[i], REACH):
				_try_lock(char_name, i); return
	# Ethan: winch (optional → animal treat)
	if not _winch_done and near3(pp, WINCH_POS, REACH):
		if char_name == "Ethan":
			_winch_done = true
			GameManager.set_level_flag(location_id, "winch_done", true)
			GameManager.grant_item(char_name, TreatItem.id)
			_hud_hint.text = "Ethan winches the slack line taut — a supply pouch rolls down. (Found Animal Treat)"
			Audio.play("special")
		else:
			_hud_hint.text = "The winch motor's locked out — Ethan can drive it."
		return
	# Ben: high release (timing)
	if char_name == "Ben" and _panel_hacked and not _release_timed and near3(pp, RELEASE_POS, REACH):
		if _open():
			_release_timed = true
			GameManager.set_level_flag(location_id, "release_timed", true)
			((_release_light.mesh as BoxMesh).material as StandardMaterial3D).albedo_color = Color(0.3, 0.95, 0.4)
			_hud_hint.text = "Perfect timing! The high line releases."; _play_zip()
			Audio.play("special")
		else:
			_hud_hint.text = "Mistimed — wait for the window to read OPEN, then press G."
			Audio.play("hurt")
		return
	# Ben: snagged clue bag (timing → Doug carabiner)
	if char_name == "Ben" and not _clue_taken and near3(pp, CLUE_POS, REACH):
		if _open():
			_clue_taken = true
			GameManager.set_level_flag(location_id, "clue_taken", true)
			GameManager.grant_item(char_name, CarabinerItem.id)
			open_dialog("Snagged Bag", Color(0.4, 0.55, 0.4),
				{"start": {"lines": [
					"Ben swings out on the beat and snatches the bag off the high line.",
					"Inside: a climbing carabiner filed 'D.H.', and a map corner ringed around the Grand Marquee.",
					"Picked up: Doug's Carabiner."]}}, char_name)
			Audio.play("special")
		else:
			_hud_hint.text = "The bag's swinging — Ben has to grab it on the beat (press G when OPEN)."
		return
	# Ben: rhythm crate (optional → bies charm)
	if char_name == "Ben" and not _rhythm_done and near3(pp, RHYTHM_POS, REACH):
		if _open():
			_rhythm_done = true
			GameManager.set_level_flag(location_id, "rhythm_done", true)
			GameManager.grant_item(char_name, BiesCharmItem.id)
			_hud_hint.text = "Ben hits the chimes on the beat — a supply crate drops. (Found Bies Charm)"
			Audio.play("special")
		else:
			_hud_hint.text = "Hit the rig on the beat — press G when the window reads OPEN."
		return
	# wrong-character / not-yet hints
	if char_name == "Ben" and not _panel_hacked and near3(pp, RELEASE_POS, REACH):
		_hud_hint.text = "The line's dead — Ethan must restore power at the Mid panel first."
	elif char_name != "Ethan" and not _panel_hacked and near3(pp, PANEL_POS, REACH):
		_hud_hint.text = "The control panel needs Ethan's hacking."

func _try_lock(char_name: String, i: int) -> void:
	if char_name != "Ethan":
		_hud_hint.text = "The platform locks are electronic — Ethan re-sequences them."
		return
	if _lock_seq.has(i):
		return
	if i == _lock_seq.size():
		_lock_seq.append(i)
		((_lock_lights[i] as MeshInstance3D).mesh as BoxMesh).material.albedo_color = Color(0.3, 0.95, 0.4)
		Audio.play("special")
		if _lock_seq.size() == LOCKS.size():
			_locks_done = true
			GameManager.set_level_flag(location_id, "locks_done", true)
			_open_lock_gate(true)
			_hud_hint.text = "Locks aligned — the gate to the High Platform opens."
		else:
			_hud_hint.text = "Lock %d set. Sequence them 1, 2, 3." % (i + 1)
	else:
		_lock_seq.clear()
		for g in _lock_lights: ((g as MeshInstance3D).mesh as BoxMesh).material.albedo_color = Color(0.85, 0.3, 0.3)
		_hud_hint.text = "Out of sequence — the locks reset. Try 1, 2, 3."

func _open_lock_gate(animate: bool) -> void:
	(_lock_wall as StaticBody3D).collision_layer = 0
	if animate:
		create_tween().tween_property(_lock_wall, "position:y", -WALL_H, 0.6)
	else:
		_lock_wall.position.y = -WALL_H

func _set_panel_solved() -> void:
	for pip in _panel_lights:
		var m := ((pip as MeshInstance3D).mesh as BoxMesh).material as StandardMaterial3D
		m.albedo_color = Color(0.3, 0.95, 0.4); m.emission = m.albedo_color

func _talk_lena(char_name: String) -> void:
	var tree: Dictionary
	if _enemies_cleared and _panel_hacked and _release_timed:
		tree = {"start": {"lines": ["\"Lines fully restored. Unusual technique on that timing window -- but it worked.\""]}}
	elif _panel_hacked:
		tree = {"start": {"lines": ["\"Ethan: align the platform locks 1-2-3 to open the high gate. Then Ben catches the timed release up top.\""]}}
	else:
		tree = {"start": {"lines": [
			"\"Safety briefing: all riders clip in. Someone cut the release power and scrambled the platform locks -- lines are dead.\"",
			"\"Ethan: the Mid panel restores power, then sequence the locks. Ben: up top, the release and a snagged bag both want a timed grab -- press G when the ring pulses green.\""]}}
	open_dialog("Lena", Color(0.45, 0.55, 0.5), tree, char_name)

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	var cl := make_hud_layer()
	_hud_goal = hud_label(cl, 24)
	_hud_pulse = hud_label(cl, 84, 26)
	_hud_hint = hud_label(cl, -70, 22, true)
	_hud_banner = hud_label(cl, 0, 40); _hud_banner.anchor_top = 0.5; _hud_banner.anchor_bottom = 0.5
	_hud_banner.visible = false

func _process(d: float) -> void:
	super._process(d)
	_pulse += d * PULSE_SPEED
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
	if not _cleared:
		var bits := []
		bits.append("riders " + ("OK" if _enemies_cleared else "..."))
		bits.append("panel " + ("OK" if _panel_hacked else "..."))
		bits.append("locks " + ("OK" if _locks_done else "..."))
		bits.append("release " + ("OK" if _release_timed else "..."))
		_hud_goal.text = "Ethan hacks the panel + aligns the locks; Ben times the release. (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
		_update_pulse_hud()
	if not _cleared and _enemies_cleared and _panel_hacked and _release_timed:
		_win(true)

func _update_pulse_hud() -> void:
	# show the timing bar once power's on and there's still a timed grab to make
	if not _panel_hacked or (_release_timed and _clue_taken and _rhythm_done):
		_hud_pulse.text = ""
		return
	var mag: float = abs(sin(_pulse))
	var filled := int(round(mag * 10.0))
	var bar := "▮".repeat(filled) + "▯".repeat(10 - filled)
	if _open():
		_hud_pulse.text = "TIMING WINDOW  [%s]  ● OPEN — press G!" % bar
		_hud_pulse.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	else:
		_hud_pulse.text = "TIMING WINDOW  [%s]  ○ wait" % bar
		_hud_pulse.add_theme_color_override("font_color", UITheme.CREAM)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""; _hud_pulse.text = ""
	_hud_banner.text = "PARK ONLINE!\nThe lines run again."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
