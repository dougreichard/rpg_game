extends Level3D
## The Drop (3D) — Evan + Ethan. Multi-room: a combat-free TOUCHDOWN CLEARING (ex-crew
## Rio + exit), then the SNAG GROVE (Grunt + Runner + Brute) past Evan's wreckage gate.
## Ethan frees the jammed chute; Evan (with the dogs) hauls the fallen mast beam off the
## marquee signal dish; Ethan re-aims the dish → the endgame pointer + Doug's flyer. Two
## optional Ethan hacks (lookout radio, supply drone). Grass/stone surfaces, olive trim.
## Win: enemies cleared + chute hacked + landing cleared.

const EVAN := preload("res://data/characters/evan.tres")
const ETHAN := preload("res://data/characters/ethan.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const RUNNER := preload("res://data/enemies/runner.tres")
const BRUTE := preload("res://data/enemies/brute.tres")
const TreatItem: ItemData = preload("res://data/items/animal_treat.tres")
const BiesCharmItem: ItemData = preload("res://data/items/bies_charm.tres")
const FlyerItem: ItemData = preload("res://data/items/doug_flyer.tres")
const TreasureMapItem: ItemData = preload("res://data/items/faded_treasure_map.tres")

# --- thematic surfaces (grass / dirt / stone, olive trim) ---
const FLOOR_GRASS := "res://assets/art/tiles/synty_floor_grass.png"
const FLOOR_DIRT := "res://assets/art/tiles/synty_floor_dirt.png"
const WALL_STONE := "res://assets/art/tiles/synty_wall_stone.png"
const FT_GROVE := Color(0.66, 0.74, 0.52)
const WT_GROVE := Color(0.6, 0.6, 0.54)
const FT_CLEAR := Color(0.7, 0.76, 0.56)
const CORNER_COL := Color(0.30, 0.34, 0.16)   # solid olive trim

const WALL_H := 3.0
const REACH := 2.4

# Expanded grove: combat grove at origin (24x20), touchdown clearing pushed south and joined
# by a long tree-lined trail; a west crash-site sub-area holds the drop pod.
const CLEAR_C := Vector3(0, 0, 22.0)
const RIO_POS := Vector3(3.5, 0, 23.0)
const WRECK_POS := Vector3(0.0, 0.0, 13.0)             # gate: clearing → grove (mid-trail)
const CHUTE_POS := Vector3(4.0, 0.0, -6.0)
const BEAM_POS := Vector3(-4.0, 0.0, -4.5)
const DISH_POS := Vector3(-4.0, 0.0, -7.0)
const LOOKOUT_POS := Vector3(-8.5, 0.0, -2.0)
const DRONE_POS := Vector3(8.5, 0.0, -2.0)
const POD_C := Vector3(-22.0, 0.0, 0.0)                # crash-site sub-area (west of the grove)

var _cleared := false
var _enemies_cleared := false
var _landing_cleared := false
var _chute_hacked := false
var _beam_done := false
var _dish_aimed := false
var _lookout_done := false
var _drone_done := false
var _pod_done := false
var _spawned := 0
var _rio = null
var _wreck: Node3D = null
var _beam: Node3D = null
var _chute_lights: Array = []
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "the_drop"
	multi_room = true
	build_env(Color(0.05, 0.08, 0.06), Color(0.5, 0.55, 0.45), 0.6, 1.0)
	point_light(Vector3(0, 4.0, 2.0), Color(0.7, 0.85, 0.7), 1.8, 18.0)
	point_light(CLEAR_C + Vector3(0, 2.8, 0), Color(0.8, 0.9, 0.75), 1.8, 11.0)
	point_light(CHUTE_POS + Vector3(0, 2.0, 0), Color(0.4, 0.8, 1.0), 1.4, 5.0)
	point_light(DISH_POS + Vector3(0, 2.0, 0), Color(1.0, 0.8, 0.5), 1.4, 6.0)
	_ground()
	_rooms()
	_forest_ring()
	_tree_line()
	_parachute()
	_wreckage()
	_chute_release()
	_beam_rig()
	_dish()
	_lookout()
	_drone()
	_pod()
	make_dialog()
	_build_hud()
	_rio = spawn_npc("bellows", RIO_POS, PI)
	prop("res://assets/models/town/deck_crate.glb", RIO_POS + Vector3(1.4, 0, 0.3), 0.6)   # Rio's camp crate
	prop("res://assets/models/town/wood_box.glb", RIO_POS + Vector3(-1.3, 0, 0.5), -0.4)
	add_exit_portal(CLEAR_C + Vector3(0, 0, 5.0), Vector3(3, 3, 1.4))
	var p := spawn_duo([EVAN, ETHAN], CLEAR_C + Vector3(0.0, 0.1, 1.0))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _rooms() -> void:
	# Snag grove — grass floor, stone walls. Combat. Openings south (clearing), west (crash site).
	set_theme(FLOOR_GRASS, WALL_STONE)
	room(Vector3.ZERO, 24, 20, FT_GROVE, WT_GROVE, WALL_H, ["s", "w"], 4.0, true)
	corridor(Vector3(0, 0, 10), "s", 6.0, FT_GROVE, WT_GROVE, 4.0, WALL_H, true, CORNER_COL)        # → clearing (long trail)
	corridor(Vector3(-12, 0, 0), "w", 4.0, FT_GROVE, WT_GROVE, 4.0, WALL_H, true, CORNER_COL)       # → crash site
	# Touchdown clearing — combat-free. South vestibule = exit.
	set_theme(FLOOR_DIRT, WALL_STONE)
	room(CLEAR_C, 16, 12, FT_CLEAR, WT_GROVE, WALL_H, ["n", "s"], 4.0, true)
	corridor(CLEAR_C + Vector3(0, 0, 6.0), "s", 2.0, FT_CLEAR, WT_GROVE, 4.0, WALL_H, true, CORNER_COL)
	# Crash-site sub-area — the drop pod (Evan pries it open).
	room(POD_C, 12, 12, FT_GROVE, WT_GROVE, WALL_H, ["e"], 4.0, true)

func _tree_line() -> void:
	# real Synty trees/bushes scattered inside the grove (snags) — clear of the puzzle spots
	var town := "res://assets/models/town/"
	for s: Array in [["tree", -9.0, -7.0], ["tree_large", 9.5, -7.5], ["tree", 10.0, 5.0],
			["tree", -10.0, 6.0], ["bush", -8.0, 2.0], ["bush", 7.0, 4.5], ["tree", 6.0, -8.5]]:
		prop(town + str(s[0]) + ".glb", Vector3(s[1], 0, s[2]), float(s[1]) * 0.6, 1.0)

# A grass ground plane (top y=-0.1, BELOW the room floors so it never z-fights) under the whole
# drop-site footprint, so the area outside the rooms reads as forest floor, not void.
func _ground() -> void:
	add_child(box_mesh(Vector3(56, 0.5, 54), Color(0.42, 0.5, 0.34), Vector3(-8, -0.35, 9.0)))

# A dense tree/bush border around the footprint (it's a forest grove) — taller trees peek over
# the walls for an enclosed-woods backdrop. Deterministic RNG so it's stable across runs.
func _forest_ring() -> void:
	var town := "res://assets/models/town/"
	var rng := RandomNumberGenerator.new(); rng.seed = 7373
	var kinds := ["tree", "tree", "tree_large", "bush"]
	var z := -14.0
	while z <= 32.0:                                    # east + west borders
		for sx: float in [-32.0, 16.0]:
			prop(town + kinds[rng.randi() % kinds.size()] + ".glb",
				Vector3(sx + rng.randf_range(-1.4, 1.4), -0.1, z + rng.randf_range(-1.2, 1.2)), rng.randf() * TAU)
		z += rng.randf_range(2.4, 3.2)
	for sz: float in [-14.0, 32.0]:                     # north + south caps
		var x := -32.0
		while x <= 16.0:
			prop(town + kinds[rng.randi() % kinds.size()] + ".glb",
				Vector3(x + rng.randf_range(-1.0, 1.0), -0.1, sz + rng.randf_range(-1.0, 1.0)), rng.randf() * TAU)
			x += rng.randf_range(2.4, 3.2)

func _parachute() -> void:
	var canopy := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 1.6; sm.height = 1.6; sm.is_hemisphere = true
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.85, 0.5, 0.2); mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sm.material = mat; canopy.mesh = sm; canopy.position = CHUTE_POS + Vector3(0, 2.4, 0)
	add_child(canopy)

func _wreckage() -> void:
	_wreck = StaticBody3D.new()
	(_wreck as StaticBody3D).collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(4.2, 1.8, 1.4); cs.shape = bs; cs.position = Vector3(0, 0.9, 0)
	_wreck.add_child(cs)
	for i: int in range(9):
		var r := box_mesh(Vector3(0.8, 0.7, 0.7), Color(0.3, 0.3, 0.32).darkened(randf() * 0.2),
			Vector3(randf_range(-1.9, 1.9), randf_range(0.3, 1.3), randf_range(-0.4, 0.4)))
		r.rotation = Vector3(randf() * 0.5, randf(), randf() * 0.5)
		_wreck.add_child(r)
	# a couple of Synty supply crates in the debris (sink with the pile when Evan clears it)
	for cs2: Array in [["deck_crate", -1.2, 0.0], ["wood_box", 1.1, 0.3]]:
		var crate: Node3D = load("res://assets/models/town/" + str(cs2[0]) + ".glb").instantiate()
		crate.position = Vector3(cs2[1], 0.3, float(cs2[2])); crate.rotation.y = float(cs2[1])
		_wreck.add_child(crate)
	_wreck.position = WRECK_POS
	add_child(_wreck)

func _chute_release() -> void:
	add_child(box_mesh(Vector3(0.9, 1.0, 0.5), Color(0.2, 0.22, 0.24), CHUTE_POS + Vector3(0, 0.5, 0)))
	for i: int in range(3):
		var pip := box_mesh(Vector3(0.16, 0.06, 0.1), Color(0.9, 0.3, 0.25), CHUTE_POS + Vector3(-0.3 + float(i) * 0.3, 1.0, 0.28), 1.2)
		add_child(pip); _chute_lights.append(pip)

# Fallen comms-mast beam pinning the dish — Evan (with the dogs) hauls it off.
func _beam_rig() -> void:
	_beam = box_mesh(Vector3(4.0, 0.4, 0.4), Color(0.35, 0.3, 0.22), BEAM_POS + Vector3(0, 0.6, 0))
	_beam.rotation.y = deg_to_rad(20)
	add_child(_beam)

# Marquee signal dish — Ethan re-aims it (after the beam's off) → the endgame pointer.
func _dish() -> void:
	prop("res://assets/models/props/signal_dish.glb", DISH_POS, 0.0)   # generated parabolic dish (Prop Farm)

func _lookout() -> void:
	add_child(box_mesh(Vector3(0.6, 1.2, 0.6), Color(0.3, 0.32, 0.28), LOOKOUT_POS + Vector3(0, 0.6, 0)))
	add_child(box_mesh(Vector3(0.1, 0.7, 0.1), Color(0.6, 0.2, 0.2), LOOKOUT_POS + Vector3(0, 1.5, 0), 1.0))  # antenna light

func _drone() -> void:
	prop("res://assets/models/props/supply_drone.glb", DRONE_POS, 0.6)   # crashed supply drone (Prop Farm)

# Crashed drop pod in the west crash-site sub-area — Evan pries the seized hatch open for loot.
func _pod() -> void:
	prop("res://assets/models/props/drop_pod.glb", POD_C, PI * 0.5)   # generated drop pod (Prop Farm)
	_floating_label("?", POD_C + Vector3(0, 2.4, 0), Color(0.8, 0.9, 0.6))

func _floating_label(txt: String, pos: Vector3, col: Color) -> void:
	var l := Label3D.new()
	l.text = txt; l.font = UITheme.font(); l.font_size = 40; l.outline_size = 12
	l.modulate = col; l.outline_modulate = Color(0, 0, 0, 0.95)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.no_depth_test = true
	l.fixed_size = true; l.pixel_size = 0.001; l.position = pos
	add_child(l)

func _spawn_enemies() -> void:
	spawn_enemy(GRUNT, Vector3(-2.0, 0.1, -1.0), "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(RUNNER, Vector3(2.5, 0.1, -1.5), "res://assets/models/enemies/runner.glb"); _spawned += 1
	spawn_enemy(BRUTE, Vector3(0.0, 0.1, -3.0), "res://assets/models/enemies/grunt.glb", 1.45, Color(0.6, 0.55, 0.5)); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_landing_cleared = GameManager.get_level_flag(location_id, "landing_cleared", false)
	_chute_hacked = GameManager.get_level_flag(location_id, "chute_hacked", false)
	_beam_done = GameManager.get_level_flag(location_id, "beam_done", false)
	_dish_aimed = GameManager.get_level_flag(location_id, "dish_aimed", false)
	_lookout_done = GameManager.get_level_flag(location_id, "lookout_done", false)
	_drone_done = GameManager.get_level_flag(location_id, "drone_done", false)
	_pod_done = GameManager.get_level_flag(location_id, "pod_done", false)
	if _landing_cleared: _clear_wreck(false)
	if _chute_hacked: _set_chute_solved()
	if _beam_done and _beam != null: _beam.position.y = -2.0
	if _enemies_cleared and _landing_cleared and _chute_hacked:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, RIO_POS, REACH): _talk_rio(char_name); return
	# wreckage gate (Evan)
	if not _landing_cleared and near3(pp, WRECK_POS, REACH + 0.8):
		if char_name == "Evan":
			_landing_cleared = true
			GameManager.set_level_flag(location_id, "landing_cleared", true)
			_clear_wreck(true)
			_hud_hint.text = "Evan drags the wreckage clear — the snag grove opens."
			Audio.play("special")
		else:
			_hud_hint.text = "The wreckage is too heavy — Evan can shift it."
		return
	# chute release (Ethan)
	if char_name == "Ethan" and not _chute_hacked and near3(pp, CHUTE_POS, REACH):
		_chute_hacked = true
		GameManager.set_level_flag(location_id, "chute_hacked", true)
		_set_chute_solved()
		_hud_hint.text = "Ethan frees the jammed chute release."
		Audio.play("special"); return
	# fallen beam over the dish (Evan + dogs)
	if not _beam_done and near3(pp, BEAM_POS, REACH + 0.8):
		if char_name == "Evan":
			_beam_done = true
			GameManager.set_level_flag(location_id, "beam_done", true)
			if _beam != null: create_tween().tween_property(_beam, "position:y", -2.0, 0.6)
			_hud_hint.text = "Evan whistles the dogs in and together they haul the mast beam off the dish."
			Audio.play("special")
		else:
			_hud_hint.text = "A mast beam pins the dish — Evan and the dogs can haul it off."
		return
	# signal dish (Ethan, after the beam) → endgame pointer + Doug flyer
	if not _dish_aimed and near3(pp, DISH_POS, REACH):
		if not _beam_done:
			_hud_hint.text = "The dish is pinned under the fallen beam — clear it first."
		elif char_name == "Ethan":
			_aim_dish(char_name)
		else:
			_hud_hint.text = "Re-aiming the signal dish needs Ethan's tech."
		return
	# lookout radio jam (Ethan, optional → animal treat)
	if not _lookout_done and char_name == "Ethan" and near3(pp, LOOKOUT_POS, REACH):
		_lookout_done = true; GameManager.set_level_flag(location_id, "lookout_done", true)
		GameManager.grant_item(char_name, TreatItem.id)
		_hud_hint.text = "Ethan jams the lookout's radio — no reinforcements, and a ration pack. (Found Animal Treat)"
		Audio.play("special"); return
	# supply drone crate (Ethan, optional → bies charm)
	if not _drone_done and char_name == "Ethan" and near3(pp, DRONE_POS, REACH):
		_drone_done = true; GameManager.set_level_flag(location_id, "drone_done", true)
		GameManager.grant_item(char_name, BiesCharmItem.id)
		_hud_hint.text = "Ethan cracks the crashed supply drone — a Bies charm inside. (Found Bies Charm)"
		Audio.play("special"); return
	# crashed drop pod (Evan pries the seized hatch, optional → comedic junk)
	if not _pod_done and near3(pp, POD_C, REACH + 0.8):
		if char_name == "Evan":
			_pod_done = true; GameManager.set_level_flag(location_id, "pod_done", true)
			GameManager.grant_item(char_name, TreasureMapItem.id)
			open_dialog("Drop Pod", Color(0.5, 0.5, 0.42),
				{"start": {"lines": [
					"Evan jams his fingers under the seized hatch and peels it open with a groan of metal.",
					"Inside the 'priority supply drop': one (1) faded treasure map, covered in confident X's.",
					"Evan: \"...Huh. Guess somebody mislabeled the crate.\"",
					"Picked up: Faded Treasure Map. (It matches nothing.)"]}}, char_name)
			Audio.play("special")
		else:
			_hud_hint.text = "The pod's hatch is seized shut — Evan could pry it."
		return

func _aim_dish(char_name: String) -> void:
	_dish_aimed = true
	GameManager.set_level_flag(location_id, "dish_aimed", true)
	GameManager.grant_item(char_name, FlyerItem.id)
	open_dialog("Signal Dish", Color(0.5, 0.5, 0.42),
		{"start": {"lines": [
			"Ethan swings the dish around until it locks onto the town's old broadcast tower.",
			"A flyer's been pinned to the rim this whole time: \"THE GRAND MARQUEE -- ONE NIGHT ONLY.\"",
			"Doug's hand in the margin: \"This is where it ends. Come find me.\"",
			"Picked up: Marquee Flyer."]}}, char_name)
	Audio.play("special")

func _clear_wreck(animate: bool) -> void:
	(_wreck as StaticBody3D).collision_layer = 0
	if animate:
		create_tween().tween_property(_wreck, "position:y", -2.0, 0.6)
	else:
		_wreck.position.y = -2.0

func _set_chute_solved() -> void:
	for pip in _chute_lights:
		var m := ((pip as MeshInstance3D).mesh as BoxMesh).material as StandardMaterial3D
		m.albedo_color = Color(0.3, 0.95, 0.4); m.emission = m.albedo_color

func _talk_rio(char_name: String) -> void:
	var tree: Dictionary
	if _enemies_cleared and _landing_cleared and _chute_hacked:
		tree = {"start": {"lines": ["\"That dish you re-aimed -- it locked on the Grand Marquee. His name's on the bill. That's the end of the trail. Go.\""]}}
	elif _landing_cleared or _chute_hacked:
		tree = {"start": {"lines": ["\"Evan clears the wreckage, Ethan frees the chute. And that signal dish under the beam -- re-aim it, it'll point the way.\""]}}
	else:
		tree = {"start": {"lines": [
			"\"Rio. I was crew until I saw the manifest -- I'm not their problem anymore.\"",
			"\"Evan: that wreckage blocks the grove. Ethan: the chute jammed on impact. And there's a signal dish in there, pinned under a mast beam -- worth a look.\""]}}
	GameManager.set_level_flag(location_id, "rio_met", true)
	open_dialog("Rio", Color(0.4, 0.42, 0.36), tree, char_name)

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	build_default_hud()
	_hud_goal = hud_goal; _hud_hint = hud_toast; _hud_banner = hud_ribbon

func _process(d: float) -> void:
	super._process(d)
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
	if not _cleared:
		var bits := []
		bits.append("crew " + ("OK" if _enemies_cleared else "..."))
		bits.append("wreckage " + ("OK" if _landing_cleared else "..."))
		bits.append("chute " + ("OK" if _chute_hacked else "..."))
		_hud_goal.text = "Evan clears the wreckage into the grove; clear the crew, Ethan frees the chute. (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
	if not _cleared and _enemies_cleared and _landing_cleared and _chute_hacked:
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "LANDING CLEAR!\nThe marquee is next."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
