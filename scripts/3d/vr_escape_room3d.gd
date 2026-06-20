extends Level3D
## VR Escape Room (3D) — Quinn + Ethan. Multi-room (neon-grid look kept, no textures):
## a combat-free BOOT CHAMBER (ARIA + exit), the SIM HALL (Grunts + a glitchy Sentry;
## Stage Alpha glitch node + Stage Beta console + a physics-bridge), and a DATA VAULT
## reached by reordering the bridge — Quinn + Ethan co-solve the firewall to recover
## Doug's session log (+ an optional dev console). Quinn patches Alpha; Ethan hacks Beta
## once Alpha is stable (or a VR override chip skips Alpha). Win: enemies + glitch + system hack.

const QUINN := preload("res://data/characters/quinn.tres")
const ETHAN := preload("res://data/characters/ethan.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const SENTRY := preload("res://data/enemies/sentry.tres")
const ChipItem: ItemData = preload("res://data/items/vr_override_chip.tres")
const BiesCharmItem: ItemData = preload("res://data/items/bies_charm.tres")
const VrLogItem: ItemData = preload("res://data/items/doug_vr_log.tres")

const FLOOR_COL := Color(0.07, 0.08, 0.12)
const WALL_COL := Color(0.12, 0.14, 0.22)
const ALPHA_COL := Color(0.35, 0.22, 0.10)
const BETA_COL := Color(0.08, 0.24, 0.26)
const NEON := Color(0.3, 0.8, 1.0)
const WALL_H := 3.2
const REACH := 2.2

# boot/vault pushed out behind longer neon corridors (sim hall kept the same size)
const BOOT_C := Vector3(0, 0, 16.0)
const ARIA_POS := Vector3(0.0, 0.0, 18.0)
const GLITCH_POS := Vector3(-5.0, 0.0, -3.0)
const CONSOLE_POS := Vector3(5.0, 0.0, -3.0)
const BRIDGE := [Vector3(-2.0, 0, 4.0), Vector3(0.0, 0, 4.0), Vector3(2.0, 0, 4.0)]
const BRIDGE_GATE := Vector3(0.0, 0, -8.5)
const VAULT_C := Vector3(0, 0, -16.0)
const FW_QUINN := Vector3(-1.5, 0.0, -18.5)
const FW_ETHAN := Vector3(1.5, 0.0, -18.5)
const DEV_POS := Vector3(-4.0, 0.0, -18.0)

var _cleared := false
var _enemies_cleared := false
var _glitch_repaired := false
var _system_hacked := false
var _bridge_done := false
var _fw_quinn := false
var _fw_ethan := false
var _firewall_open := false
var _dev_done := false
var _bridge_seq: Array = []
var _spawned := 0
var _aria_orb: MeshInstance3D = null
var _aria_bob := 0.0
var _glitch_node: MeshInstance3D = null
var _console_lights: Array = []
var _holos: Array = []
var _bridge_lights: Array = []
var _bridge_wall: Node3D = null
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "vr_room"
	build_env(Color(0.02, 0.02, 0.05), Color(0.35, 0.4, 0.55), 0.5, 0.7)
	multi_room = true
	point_light(Vector3(0, 3.4, 0), NEON, 1.8, 14.0)
	point_light(BOOT_C + Vector3(0, 2.8, 0), NEON, 1.6, 11.0)
	point_light(GLITCH_POS + Vector3(0, 2.0, 0), Color(1.0, 0.6, 0.2), 1.8, 6.0)
	point_light(CONSOLE_POS + Vector3(0, 2.0, 0), Color(0.2, 0.9, 0.9), 1.8, 6.0)
	point_light(VAULT_C + Vector3(0, 2.6, 0), Color(0.5, 0.4, 1.0), 1.6, 9.0)
	_rooms()
	_zone(GLITCH_POS, ALPHA_COL)
	_zone(CONSOLE_POS, BETA_COL)
	_grid_lines()
	_neon_dressing()
	_glitch()
	_console()
	_bridge()
	_firewall()
	_aria()
	add_hiding_spot(Vector3(-7.0, 0, 3.0))
	make_dialog()
	_build_hud()
	add_exit_portal(BOOT_C + Vector3(0, 0, 5.0), Vector3(3, 3, 1.4))
	var p := spawn_duo([QUINN, ETHAN], BOOT_C + Vector3(0.0, 0.1, 1.0))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _rooms() -> void:
	# Neon flat surfaces (no set_theme); corridors get NEON corner posts.
	room(Vector3.ZERO, 18, 16, FLOOR_COL, WALL_COL, WALL_H, ["s", "n"], 3.0, true)         # sim hall
	corridor(Vector3(0, 0, 8), "s", 4.0, FLOOR_COL, WALL_COL, 3.0, WALL_H, true, NEON)         # → boot
	corridor(Vector3(0, 0, -8), "n", 4.0, FLOOR_COL, WALL_COL, 3.0, WALL_H, true, NEON)        # → data vault
	_bridge_wall = _gate_panel(BRIDGE_GATE, WALL_H)
	room(BOOT_C, 12, 8, FLOOR_COL, WALL_COL, WALL_H, ["n", "s"], 3.0, true)                # boot chamber (lobby)
	corridor(BOOT_C + Vector3(0, 0, 4.0), "s", 2.0, FLOOR_COL, WALL_COL, 3.0, WALL_H, true, NEON)
	room(VAULT_C, 12, 8, FLOOR_COL, WALL_COL, WALL_H, ["s"], 3.0, true)                    # data vault

func _gate_panel(pos: Vector3, h: float) -> Node3D:
	var size := Vector3(3.0, h, 0.4)
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = size; cs.shape = bs; cs.position = Vector3(0, h * 0.5, 0)
	sb.add_child(cs); sb.add_child(box_mesh(size, NEON.darkened(0.5), Vector3(0, h * 0.5, 0), 0.5))
	sb.position = pos
	add_child(sb)
	return sb

func _zone(center: Vector3, col: Color) -> void:
	add_child(box_mesh(Vector3(6.0, 0.06, 5.0), col, center + Vector3(0, 0.04, 0.5), 0.4))

func _grid_lines() -> void:
	for i: int in range(9):
		var x: float = -8.0 + float(i) * 2.0
		add_child(box_mesh(Vector3(0.04, 0.02, 16.0), NEON, Vector3(x, 0.06, 0), 0.8))
	for i: int in range(9):   # cross-grid (Z lines) for a full neon floor grid
		var z: float = -8.0 + float(i) * 2.0
		add_child(box_mesh(Vector3(16.0, 0.02, 0.04), NEON, Vector3(0, 0.06, z), 0.8))

# All-emissive neon set-dressing (matches the no-texture VR look): glowing data pylons around the
# sim hall + a few floating holographic cubes (bob in _process).
func _neon_dressing() -> void:
	for p: Vector3 in [Vector3(-8.0, 0, -6.5), Vector3(8.0, 0, -6.5), Vector3(-8.0, 0, 6.5), Vector3(8.0, 0, 6.5)]:
		add_child(box_mesh(Vector3(0.5, WALL_H, 0.5), NEON.darkened(0.2), p + Vector3(0, WALL_H * 0.5, 0), 0.6))
		add_child(box_mesh(Vector3(0.7, 0.2, 0.7), NEON, p + Vector3(0, WALL_H - 0.2, 0), 1.4))   # glowing cap
	for h: Vector3 in [Vector3(-3.0, 2.2, 5.5), Vector3(3.0, 2.6, 5.5), Vector3(0.0, 2.4, -6.5)]:
		var holo := box_mesh(Vector3(0.6, 0.6, 0.6), Color(0.4, 0.9, 1.0), h, 1.2)
		holo.rotation = Vector3(0.6, 0.4, 0.0)
		add_child(holo); _holos.append(holo)

func _glitch() -> void:
	_glitch_node = box_mesh(Vector3(0.8, 0.8, 0.8), Color(1.0, 0.5, 0.2), GLITCH_POS + Vector3(0, 1.2, 0), 1.4)
	add_child(_glitch_node)
	add_child(box_mesh(Vector3(0.2, 1.2, 0.2), Color(0.5, 0.3, 0.15), GLITCH_POS + Vector3(0, 0.6, 0)))

func _console() -> void:
	add_child(box_mesh(Vector3(1.2, 1.0, 0.6), Color(0.1, 0.18, 0.2), CONSOLE_POS + Vector3(0, 0.5, 0)))
	var screen := box_mesh(Vector3(1.0, 0.7, 0.06), Color(0.1, 0.4, 0.42), CONSOLE_POS + Vector3(0, 1.3, 0.3), 0.7)
	screen.rotation.x = deg_to_rad(-12); add_child(screen)
	for i: int in range(3):
		var pip := box_mesh(Vector3(0.16, 0.06, 0.1), Color(0.9, 0.3, 0.25), CONSOLE_POS + Vector3(-0.3 + float(i) * 0.3, 0.95, 0.32), 1.2)
		add_child(pip); _console_lights.append(pip)

func _bridge() -> void:
	# corrupted floating blocks (Quinn reorders 1→2→3 to drop the data-vault gate)
	for i: int in range(BRIDGE.size()):
		var blk := box_mesh(Vector3(0.9, 0.5, 0.9), Color(0.5, 0.3, 0.7), BRIDGE[i] + Vector3(0, 1.0, 0), 0.8)
		add_child(blk); _bridge_lights.append(blk)
		_floating_label(str(i + 1), BRIDGE[i] + Vector3(0, 1.8, 0), NEON)

func _firewall() -> void:
	add_child(box_mesh(Vector3(4.0, 2.6, 0.3), Color(0.6, 0.2, 0.5), VAULT_C + Vector3(0, 1.3, -3.0), 0.7))  # firewall plane
	add_child(box_mesh(Vector3(0.6, 1.0, 0.4), Color(0.7, 0.3, 0.2), FW_QUINN + Vector3(0, 0.5, 0)))          # Quinn node
	add_child(box_mesh(Vector3(0.6, 1.0, 0.4), Color(0.2, 0.4, 0.7), FW_ETHAN + Vector3(0, 0.5, 0)))          # Ethan node
	add_child(box_mesh(Vector3(0.9, 1.0, 0.6), Color(0.15, 0.2, 0.28), DEV_POS + Vector3(0, 0.5, 0)))         # dev console

func _aria() -> void:
	_aria_orb = MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.35; sm.height = 0.7
	var mat := StandardMaterial3D.new()
	mat.albedo_color = NEON; mat.emission_enabled = true; mat.emission = NEON; mat.emission_energy_multiplier = 2.0
	sm.material = mat; _aria_orb.mesh = sm
	_aria_orb.position = ARIA_POS + Vector3(0, 1.6, 0)
	add_child(_aria_orb)

func _floating_label(txt: String, pos: Vector3, col: Color) -> void:
	var l := Label3D.new()
	l.text = txt; l.font = UITheme.font(); l.font_size = 40; l.outline_size = 12
	l.modulate = col; l.outline_modulate = Color(0, 0, 0, 0.95)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.no_depth_test = true
	l.fixed_size = true; l.pixel_size = 0.001; l.position = pos
	add_child(l)

func _spawn_enemies() -> void:
	for spot: Vector3 in [Vector3(-2.0, 0.1, 1.0), Vector3(2.5, 0.1, 0.0)]:
		spawn_enemy(GRUNT, spot, "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(SENTRY, Vector3(0.0, 0.1, -2.0), "res://assets/models/enemies/grunt.glb", 1.0, Color(0.4, 0.9, 0.9)); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_glitch_repaired = GameManager.get_level_flag(location_id, "glitch_repaired", false)
	_system_hacked = GameManager.get_level_flag(location_id, "system_hacked", false)
	_bridge_done = GameManager.get_level_flag(location_id, "bridge_done", false)
	_firewall_open = GameManager.get_level_flag(location_id, "firewall_open", false)
	_dev_done = GameManager.get_level_flag(location_id, "dev_done", false)
	if _glitch_repaired: _stabilise_glitch()
	if _system_hacked: _set_console_solved()
	if _bridge_done:
		for b in _bridge_lights: ((b as MeshInstance3D).mesh as BoxMesh).material.albedo_color = Color(0.3, 0.95, 0.5)
		_open_bridge_gate(false)
	if _enemies_cleared and _glitch_repaired and _system_hacked:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, ARIA_POS, REACH + 0.6): _talk_aria(char_name); return
	# Stage Alpha glitch — Quinn (or a VR override chip skips it)
	if not _glitch_repaired and near3(pp, GLITCH_POS, REACH):
		if char_name == "Quinn":
			_patch_glitch("Quinn patches the physics-glitch node -- Stage Alpha stabilises.")
		elif _party_has(ChipItem.id):
			GameManager.consume_item(_holder(ChipItem.id), ChipItem.id)
			_patch_glitch("The VR override chip force-stabilises Stage Alpha.")
		else:
			_hud_hint.text = "The glitch node needs Quinn's tools (or a VR override chip)."
		return
	# Stage Beta console — Ethan (needs Alpha stable)
	if char_name == "Ethan" and not _system_hacked and near3(pp, CONSOLE_POS, REACH):
		if _glitch_repaired:
			_system_hacked = true
			GameManager.set_level_flag(location_id, "system_hacked", true)
			_set_console_solved()
			_hud_hint.text = "Ethan hacks the Stage Beta console — the simulation unlocks."
			Audio.play("special")
		else:
			_hud_hint.text = "Beta won't accept the hack until Alpha is stable — patch the glitch first."
		return
	# physics-bridge reorder — Quinn (opens the data-vault gate)
	if not _bridge_done:
		for i: int in range(BRIDGE.size()):
			if near3(pp, BRIDGE[i], REACH):
				_try_bridge(char_name, i); return
	# firewall co-solve — Quinn node + Ethan node
	if not _firewall_open and near3(pp, FW_QUINN, REACH):
		if char_name == "Quinn" and not _fw_quinn:
			_fw_quinn = true; GameManager.set_level_flag(location_id, "fw_quinn", true)
			_hud_hint.text = "Quinn braces the firewall's physics layer."; Audio.play("special"); _check_firewall()
		elif char_name != "Quinn":
			_hud_hint.text = "The left node needs Quinn's steadying."
		return
	if not _firewall_open and near3(pp, FW_ETHAN, REACH):
		if char_name == "Ethan" and not _fw_ethan:
			_fw_ethan = true; GameManager.set_level_flag(location_id, "fw_ethan", true)
			_hud_hint.text = "Ethan floods the firewall's logic gate."; Audio.play("special"); _check_firewall()
		elif char_name != "Ethan":
			_hud_hint.text = "The right node needs Ethan's hack."
		return
	# dev console — Ethan (optional → bies charm)
	if _firewall_open and not _dev_done and char_name == "Ethan" and near3(pp, DEV_POS, REACH):
		_dev_done = true; GameManager.set_level_flag(location_id, "dev_done", true)
		GameManager.grant_item(char_name, BiesCharmItem.id)
		_hud_hint.text = "Ethan opens a hidden dev console — a Bies charm patch. (Found Bies Charm)"
		Audio.play("special"); return
	# wrong-character hints
	if char_name != "Ethan" and not _system_hacked and near3(pp, CONSOLE_POS, REACH):
		_hud_hint.text = "The system console needs Ethan's hacking."

func _patch_glitch(msg: String) -> void:
	_glitch_repaired = true
	GameManager.set_level_flag(location_id, "glitch_repaired", true)
	_stabilise_glitch()
	_hud_hint.text = msg
	Audio.play("special")

func _try_bridge(char_name: String, i: int) -> void:
	if char_name != "Quinn":
		_hud_hint.text = "The bridge blocks are a physics glitch — Quinn reorders them."
		return
	if _bridge_seq.has(i):
		return
	if i == _bridge_seq.size():
		_bridge_seq.append(i)
		((_bridge_lights[i] as MeshInstance3D).mesh as BoxMesh).material.albedo_color = Color(0.3, 0.95, 0.5)
		Audio.play("special")
		if _bridge_seq.size() == BRIDGE.size():
			_bridge_done = true
			GameManager.set_level_flag(location_id, "bridge_done", true)
			_open_bridge_gate(true)
			_hud_hint.text = "The bridge resolves into solid geometry — the data vault opens."
		else:
			_hud_hint.text = "Block %d set. Reorder them 1, 2, 3." % (i + 1)
	else:
		_bridge_seq.clear()
		for b in _bridge_lights: ((b as MeshInstance3D).mesh as BoxMesh).material.albedo_color = Color(0.5, 0.3, 0.7)
		_hud_hint.text = "The geometry collapses — blocks reset. Reorder 1, 2, 3."

func _open_bridge_gate(animate: bool) -> void:
	(_bridge_wall as StaticBody3D).collision_layer = 0
	if animate:
		create_tween().tween_property(_bridge_wall, "position:y", -WALL_H, 0.6)
	else:
		_bridge_wall.position.y = -WALL_H

func _check_firewall() -> void:
	if _fw_quinn and _fw_ethan and not _firewall_open:
		_firewall_open = true
		GameManager.set_level_flag(location_id, "firewall_open", true)
		GameManager.grant_item(player.active_name(), VrLogItem.id)
		open_dialog("Firewall", NEON,
			{"start": {"lines": [
				"The firewall dissolves. Behind it, an archived session spools up.",
				"Doug's avatar idles in a rendered cinema lobby -- and the logout never came.",
				"Picked up: Doug's Session Log."]}}, player.active_name())
		Audio.play("special")

func _stabilise_glitch() -> void:
	var m := (_glitch_node.mesh as BoxMesh).material as StandardMaterial3D
	m.albedo_color = Color(0.3, 0.95, 0.5); m.emission = Color(0.3, 0.95, 0.5)

func _set_console_solved() -> void:
	for pip in _console_lights:
		var m := ((pip as MeshInstance3D).mesh as BoxMesh).material as StandardMaterial3D
		m.albedo_color = Color(0.3, 0.95, 0.4); m.emission = m.albedo_color

func _party_has(id: String) -> bool:
	return GameManager.has_item("Quinn", id) or GameManager.has_item("Ethan", id)

func _holder(id: String) -> String:
	return "Quinn" if GameManager.has_item("Quinn", id) else "Ethan"

func _talk_aria(char_name: String) -> void:
	var tree: Dictionary
	if _enemies_cleared and _glitch_repaired and _system_hacked:
		tree = {"start": {"lines": ["\"All stages nominal. Most test subjects don't make it past Beta. Well done.\"",
			"\"...There is one archived session I could not purge. A 'Doug'. You may want the data vault.\""]}}
	elif _glitch_repaired or _system_hacked:
		tree = {"start": {"lines": ["\"Status: Quinn patches Stage Alpha first, then Ethan hacks Stage Beta. Reorder the bridge for the data vault.\""]}}
	else:
		tree = {"start": {"lines": [
			"\"ARIA -- virtual assistant. Alert: two simulation stages are corrupted.\"",
			"\"Quinn: Stage Alpha has a physics-glitch node. Ethan: Stage Beta's console needs a hack once Alpha is stable. Reorder the bridge blocks to reach the data vault -- and mind the firewall: it takes both of you.\""]}}
	open_dialog("ARIA", NEON, tree, char_name)

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	var cl := make_hud_layer()
	_hud_goal = hud_label(cl, 24)
	_hud_hint = hud_label(cl, -70, 22, true)
	_hud_banner = hud_label(cl, 0, 40); _hud_banner.anchor_top = 0.5; _hud_banner.anchor_bottom = 0.5
	_hud_banner.visible = false

func _process(d: float) -> void:
	super._process(d)
	_aria_bob += d
	if _aria_orb != null:
		_aria_orb.position.y = ARIA_POS.y + 1.6 + 0.15 * sin(_aria_bob * 2.0)
	for i: int in range(_holos.size()):   # floating holograms drift + spin
		var hl: Node3D = _holos[i]
		if hl != null:
			hl.position.y += 0.004 * sin(_aria_bob * 1.5 + float(i))
			hl.rotation.y += d * 0.8
	if _glitch_node != null and not _glitch_repaired:
		_glitch_node.position = GLITCH_POS + Vector3(randf_range(-0.05, 0.05), 1.2 + randf_range(-0.05, 0.05), randf_range(-0.05, 0.05))
		_glitch_node.rotation.y += d * 3.0
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
	if not _cleared:
		var bits := []
		bits.append("threats " + ("OK" if _enemies_cleared else "..."))
		bits.append("alpha " + ("OK" if _glitch_repaired else "..."))
		bits.append("beta " + ("OK" if _system_hacked else "..."))
		_hud_goal.text = "Quinn patches Stage Alpha, then Ethan hacks Stage Beta. (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
	if not _cleared and _enemies_cleared and _glitch_repaired and _system_hacked:
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "SIMULATION CLEARED!\nAll stages nominal."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
