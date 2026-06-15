class_name Level3D
extends Node3D
## Reusable base for 3D levels in the migration. Subclasses implement _build_level()
## using the helpers here (environment, floor/wall boxes, prop placement, player/
## enemy spawns, follow camera). Keeps each level script focused on layout while the
## plumbing (lighting, collision layers, capture) lives here. Logic systems
## (GameManager, quests, save, DialogBox) are reused unchanged.

const PlayerScript: Script = preload("res://scripts/3d/player_3d.gd")
const EnemyScript: Script = preload("res://scripts/3d/enemy_3d.gd")
const CameraRigScript: Script = preload("res://scripts/3d/camera_rig_3d.gd")
const Duo3DScript: Script = preload("res://scripts/3d/duo3d.gd")
const Npc3DScript: Script = preload("res://scripts/3d/npc3d.gd")
const DialogBoxScript: Script = preload("res://scripts/ui/dialog_box.gd")
# UI-stack scripts are loaded at runtime (not preloaded as consts) so they stay
# out of Level3D's parse-time class graph.
const TITLE_3D := "res://scenes/3d/Title3D.tscn"

var player: Node3D = null  # a Player3D (single) or a Duo3D controller
const OVERWORLD_3D := "res://scenes/3d/Overworld3D.tscn"

var location_id: String = ""   # set by subclass; used by dialog-effect helper
var dialog = null              # shared DialogBox (created by make_dialog)
var allow_overworld_exit := true   # the overworld itself disables this
var _shot_frames: int = -1
var _bies_fill: ColorRect = null   # Bies charge bar (levels only)
var _bies_pulse: float = 0.0
var _floor_hw: float = 0.0         # floor half-extents (for walk-out detection)
var _floor_hd: float = 0.0
var _floor_center: Vector3 = Vector3.ZERO
var _returning: bool = false       # guard so the walk-out exit fires once
var multi_room: bool = false       # multi-phase levels exit via a portal, not floor-edge

func _ready() -> void:
	_build_level()
	# Levels get the shared pause/menu stack automatically; the overworld builds
	# its own (with in_overworld=true) inside _build_level.
	if location_id != "":
		build_ui_stack(false)
		_add_exit_hint()
		# Remember which building we're in, so any return to the overworld (walk
		# out, Esc → Quit to Map, or on clear) drops the duo back at its door.
		GameManager.last_location_id = location_id
	if "--capture" in OS.get_cmdline_user_args() or "--capture" in OS.get_cmdline_args():
		_shot_frames = 18
	if "--capture-late" in OS.get_cmdline_user_args() or "--capture-late" in OS.get_cmdline_args():
		_shot_frames = 440

func _add_exit_hint() -> void:
	var cl := CanvasLayer.new(); add_child(cl)
	var l := Label.new()
	l.anchor_left = 1.0; l.anchor_right = 1.0; l.anchor_top = 1.0; l.anchor_bottom = 1.0
	l.offset_left = -200; l.offset_right = -12; l.offset_top = -40; l.offset_bottom = -10
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.text = "Esc — Menu"
	l.add_theme_font_override("font", UITheme.font())
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", UITheme.CREAM)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	cl.add_child(l)

# Build the shared pause menu + its sibling overlays (Achievements / Inventory /
# Quest Log / toast). PauseMenu looks these up by sibling name, so they must all
# be direct children of this level root. GameManager toggles the menu on Esc.
func build_ui_stack(in_overworld: bool) -> void:
	var ach: Node = load("res://scripts/ui/achievements_overlay.gd").new(); ach.name = "AchievementsOverlay"; add_child(ach)
	var inv: Node = load("res://scripts/ui/inventory_overlay.gd").new(); inv.name = "InventoryOverlay"; add_child(inv)
	refresh_duo_inventory_names()
	var ql: Node = load("res://scripts/ui/quest_log_overlay.gd").new(); ql.name = "QuestLogOverlay"; add_child(ql)
	var toast: Node = load("res://scripts/ui/achievement_toast.gd").new(); toast.name = "AchievementToast"; add_child(toast)
	var pm: Node = load("res://scripts/ui/pause_menu.gd").new(); pm.name = "PauseMenu"
	pm.set("in_overworld", in_overworld)
	pm.set("map_scene", OVERWORLD_3D)
	pm.set("title_scene", TITLE_3D)
	pm.set("spoon_scene", "res://scenes/3d/Spoon3D.tscn")
	add_child(pm)
	if not in_overworld:
		_build_bies_bar()

func _build_bies_bar() -> void:
	var cl := CanvasLayer.new(); cl.layer = 6; add_child(cl)
	var w := 240.0
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.09, 0.07, 0.85)
	bg.anchor_left = 0.5; bg.anchor_right = 0.5; bg.anchor_top = 1.0; bg.anchor_bottom = 1.0
	bg.offset_left = -w * 0.5 - 2; bg.offset_right = w * 0.5 + 2; bg.offset_top = -34; bg.offset_bottom = -14
	cl.add_child(bg)
	_bies_fill = ColorRect.new()
	_bies_fill.color = UITheme.GOLD
	_bies_fill.anchor_left = 0.5; _bies_fill.anchor_right = 0.5; _bies_fill.anchor_top = 1.0; _bies_fill.anchor_bottom = 1.0
	_bies_fill.offset_left = -w * 0.5; _bies_fill.offset_right = -w * 0.5; _bies_fill.offset_top = -32; _bies_fill.offset_bottom = -16
	cl.add_child(_bies_fill)
	var lbl := Label.new()
	lbl.text = "BIES"
	lbl.anchor_left = 0.5; lbl.anchor_right = 0.5; lbl.anchor_top = 1.0; lbl.anchor_bottom = 1.0
	lbl.offset_left = -w * 0.5; lbl.offset_right = w * 0.5; lbl.offset_top = -34; lbl.offset_bottom = -14
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", UITheme.font())
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.15, 0.10, 0.07))
	cl.add_child(lbl)

# Override in subclasses: build env, floor, walls, props, spawns.
func _build_level() -> void:
	pass

# --- environment -------------------------------------------------------------
func build_env(bg: Color, ambient: Color, ambient_e: float = 0.55, sun_e: float = 1.15) -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(40.0), 0.0)
	sun.light_energy = sun_e
	sun.shadow_enabled = true
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient
	env.ambient_light_energy = ambient_e
	we.environment = env
	add_child(we)

func point_light(pos: Vector3, color: Color, energy: float, rng: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	add_child(l)

# --- geometry ----------------------------------------------------------------
func floor_box(w: float, d: float, col: Color, center := Vector3.ZERO) -> void:
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(w, 1.0, d)
	cs.shape = bs
	cs.position = Vector3(0, -0.5, 0)
	sb.add_child(cs)
	sb.add_child(box_mesh(Vector3(w, 1.0, d), col, Vector3(0, -0.5, 0)))
	sb.position = center
	add_child(sb)
	_floor_hw = w * 0.5
	_floor_hd = d * 0.5
	_floor_center = center

func wall(center: Vector3, size: Vector3, col: Color) -> void:
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	sb.add_child(cs)
	sb.add_child(box_mesh(size, col, Vector3.ZERO))
	sb.position = center
	add_child(sb)

func box_mesh(size: Vector3, col: Color, ofs: Vector3, emissive: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 1.0
	if emissive > 0.0:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = emissive
	bm.material = mat
	mi.mesh = bm
	mi.position = ofs
	return mi

func prop(path: String, pos: Vector3, yaw: float = 0.0, scale: float = 1.0) -> Node3D:
	var ps: PackedScene = load(path)
	if ps == null:
		return null
	var n := ps.instantiate()
	n.position = pos
	n.rotation.y = yaw
	n.scale = Vector3.ONE * scale
	add_child(n)
	return n

# --- actors ------------------------------------------------------------------
func spawn_player(data: Resource, pos: Vector3, with_camera: bool = true) -> CharacterBody3D:
	var p := CharacterBody3D.new()
	p.set_script(PlayerScript)
	p.set("data", data)
	p.position = pos
	add_child(p)
	player = p
	if with_camera:
		var cam := Camera3D.new()
		cam.set_script(CameraRigScript)
		cam.set("target", p)
		cam.current = true
		add_child(cam)
	return p

# Spawns the active duo (both bodies on screen) + follow camera. Returns the Duo3D
# controller, which levels treat like the "player" (global_position / special_used /
# active_name / set_input_locked all reflect the active body).
func spawn_duo(datas: Array, pos: Vector3, with_camera: bool = true) -> Node3D:
	var duo := Node3D.new()
	duo.set_script(Duo3DScript)
	add_child(duo)
	var cam: Camera3D = null
	if with_camera:
		cam = Camera3D.new()
		cam.set_script(CameraRigScript)
		cam.current = true
		add_child(cam)
	duo.call("setup", datas, pos, cam, self)
	player = duo
	return duo

func spawn_enemy(data: Resource, pos: Vector3, mesh_path: String = "", mesh_scale: float = 1.0, mesh_tint: Color = Color(1, 1, 1, 1)) -> CharacterBody3D:
	var e := CharacterBody3D.new()
	e.set_script(EnemyScript)
	e.set("data", data)
	if mesh_path != "":
		e.set("mesh_path", mesh_path)
	e.set("mesh_scale", mesh_scale)
	e.set("mesh_tint", mesh_tint)
	e.position = pos
	add_child(e)
	return e

# Spawn a reusable Npc3D (mesh + idle/walk + optional wander + speech bubble).
func spawn_npc(key: String, pos: Vector3, yaw: float = PI, quips: Array = [], waypoints: Array = []) -> Node3D:
	var n := Node3D.new()
	n.set_script(Npc3DScript)
	n.set("mesh_key", key)
	n.set("quips", quips)
	n.set("waypoints", waypoints)
	n.set("face_yaw", yaw)
	n.position = pos
	add_child(n)
	return n

# A stealth concealment volume — players inside it can't be seen by enemies.
func add_hiding_spot(pos: Vector3) -> Node3D:
	var h := Area3D.new()
	h.set_script(load("res://scripts/3d/hiding_spot3d.gd"))
	h.position = pos
	add_child(h)
	return h

# A crafting/interaction station (gather → process → assemble). Builds a
# WorkStation3D, parents it, and returns it so the level can configure recipes/
# parts and connect its signals. Drive it from the level's _on_special by calling
# station.try_use(char_name, player.global_position).
func add_station(p_kind: int, pos: Vector3, label: String, best_with: String = "") -> Node3D:
	var s := Area3D.new()
	s.set_script(load("res://scripts/3d/work_station3d.gd"))
	s.call("setup", p_kind, pos, label, best_with)   # set vars before _ready builds visuals
	add_child(s)
	return s

# Point the InventoryOverlay's two tabs at the current duo members. Call after the
# party changes mid-level (e.g. recruiting a second lead) so the newcomer's bag shows.
func refresh_duo_inventory_names() -> void:
	var inv: Node = get_node_or_null("InventoryOverlay")
	if inv == null or player == null:
		return
	var bodies: Array = player.get("bodies") if "bodies" in player else []
	var a: String = bodies[0].active_name() if bodies.size() > 0 else "Quinn"
	var b: String = bodies[1].active_name() if bodies.size() > 1 else ""
	inv.call("setup", a, b)

func enemies_alive() -> int:
	var n := 0
	for c in get_children():
		if c is CharacterBody3D and c.get_script() == EnemyScript:
			n += 1
	return n

func near3(a: Vector3, b: Vector3, reach: float = 2.0) -> bool:
	return Vector2(a.x - b.x, a.z - b.z).length() < reach

# --- dialog plumbing (shared) ------------------------------------------------
func make_dialog() -> Object:
	dialog = DialogBoxScript.new()
	var cl := CanvasLayer.new()
	cl.add_child(dialog)
	add_child(cl)
	if not dialog.closed.is_connected(_on_dialog_closed_default):
		dialog.closed.connect(_on_dialog_closed_default)
	return dialog

func open_dialog(npc: String, col: Color, tree: Dictionary, char_name: String) -> void:
	if dialog == null or (dialog.has_method("is_open") and dialog.is_open()):
		return
	if player != null and player.has_method("set_input_locked"):
		player.set_input_locked(true)
	dialog.open(npc, col, tree, "start", char_name)

# Default effect application: grant_items / set_flag / consume_item, keyed to
# location_id. Subclasses can connect their own handler instead (or also).
func _on_dialog_closed_default(effects: Array) -> void:
	if player != null and player.has_method("set_input_locked"):
		player.set_input_locked(false)
	apply_dialog_effects(effects)

func apply_dialog_effects(effects: Array) -> void:
	var who: String = player.active_name() if (player != null and player.has_method("active_name")) else "Quinn"
	for e in effects:
		if not (e is Dictionary):
			continue
		if e.has("grant_items"):
			for id in e["grant_items"]:
				GameManager.grant_item(who, id)
		if e.has("consume_item"):
			GameManager.consume_item(who, e["consume_item"])
		if e.has("set_flag") and location_id != "":
			GameManager.set_level_flag(location_id, e["set_flag"], e.get("flag_value", true))

# Call from a subclass _unhandled_input to drive dialog paging/choices.
func dialog_input() -> bool:
	if dialog == null or not (dialog.has_method("is_open") and dialog.is_open()):
		return false
	if Input.is_action_just_pressed("ui_accept"):
		if dialog.is_choice_mode():
			dialog.select_choice()
		else:
			dialog.advance()
	elif Input.is_action_just_pressed("ui_up"):
		dialog.move_choice_cursor(-1)
	elif Input.is_action_just_pressed("ui_down"):
		dialog.move_choice_cursor(1)
	return true

# --- HUD labels (shared) -----------------------------------------------------
func make_hud_layer() -> CanvasLayer:
	var cl := CanvasLayer.new()
	add_child(cl)
	return cl

func hud_label(cl: CanvasLayer, y: float, size: int = 22, from_bottom: bool = false) -> Label:
	var l := Label.new()
	l.anchor_left = 0.0
	l.anchor_right = 1.0
	l.offset_left = 40
	l.offset_right = -40
	if from_bottom:
		l.anchor_top = 1.0
		l.anchor_bottom = 1.0
	l.offset_top = y
	l.offset_bottom = y + 70
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UITheme.font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", UITheme.CREAM)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	cl.add_child(l)
	return l

# --- capture (windowed --capture) --------------------------------------------
func _process(d: float) -> void:
	_update_bies_bar(d)
	_check_walk_out()
	if _shot_frames < 0:
		return
	_shot_frames -= 1
	if _shot_frames == 0:
		get_viewport().get_texture().get_image().save_png("res://_arena3d_shot.png")
		print("SHOT_SAVED")
		get_tree().quit()

# Walking off the level floor (out the entrance) — or falling off it — returns to
# the overworld instead of dropping into the void. Levels only (not the overworld).
const EXIT_MARGIN: float = 0.4
const FALL_Y: float = -2.5

func _check_walk_out() -> void:
	if location_id == "" or _returning or player == null or not is_instance_valid(player):
		return
	var p: Vector3 = player.global_position
	# Multi-room levels exit through their lobby portal, not the floor edge (their
	# rooms span many floor boxes) — only the fall-into-void safety net applies.
	var off := p.y < FALL_Y
	if not multi_room and _floor_hw > 0.0:
		off = off \
			or absf(p.x - _floor_center.x) > _floor_hw + EXIT_MARGIN \
			or absf(p.z - _floor_center.z) > _floor_hd + EXIT_MARGIN
	if off:
		return_to_overworld()

func return_to_overworld() -> void:
	if _returning:
		return
	_returning = true
	GameManager.last_location_id = location_id
	get_tree().change_scene_to_file(OVERWORLD_3D)

# --- multi-phase rooms + portals ---------------------------------------------
const Portal3DScript: Script = preload("res://scripts/3d/portal3d.gd")

# Re-aim the follow camera (room-aware framing on a portal transition).
func reframe_camera(dist: float, elev: float) -> void:
	for c in get_children():
		if c is Camera3D and c.has_method("reframe"):
			c.call("reframe", dist, elev)

# Build a room: floor + perimeter walls with gaps on the named sides
# ("n"=-Z, "s"=+Z, "e"=+X, "w"=-X) for doorways. Dress it afterwards relative to
# `center`. Does NOT set the walk-out bounds (multi-room levels use a portal).
func room(center: Vector3, w: float, d: float, floor_col: Color, wall_col: Color, h: float = 3.2, openings: Array = [], gap: float = 3.0, with_floor: bool = true) -> void:
	if with_floor:
		var sb := StaticBody3D.new()
		sb.collision_layer = Combat3D.L_WORLD
		var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
		bs.size = Vector3(w, 1.0, d); cs.shape = bs; cs.position = Vector3(0, -0.5, 0)
		sb.add_child(cs); sb.add_child(box_mesh(Vector3(w, 1.0, d), floor_col, Vector3(0, -0.5, 0)))
		sb.position = center; add_child(sb)
	# walls (split each side around a centred gap if that side is an opening)
	_room_wall_side(center, "n", w, d, h, wall_col, "n" in openings, gap)
	_room_wall_side(center, "s", w, d, h, wall_col, "s" in openings, gap)
	_room_wall_side(center, "e", w, d, h, wall_col, "e" in openings, gap)
	_room_wall_side(center, "w", w, d, h, wall_col, "w" in openings, gap)

func _room_wall_side(center: Vector3, side: String, w: float, d: float, h: float, col: Color, open: bool, gap: float) -> void:
	var horiz: bool = side == "n" or side == "s"
	var span: float = w if horiz else d
	var nz: float = -d * 0.5 if side == "n" else (d * 0.5 if side == "s" else 0.0)
	var nx: float = -w * 0.5 if side == "w" else (w * 0.5 if side == "e" else 0.0)
	if not open:
		var size := Vector3(w + 0.4, h, 0.4) if horiz else Vector3(0.4, h, d + 0.4)
		wall(center + Vector3(nx, h * 0.5, nz), size, col)
		return
	# leave a gap in the middle → two wall segments
	var seg: float = (span - gap) * 0.5
	if seg <= 0.1:
		return
	for s: float in [-1.0, 1.0]:
		var off: float = (gap * 0.5 + seg * 0.5) * s
		if horiz:
			wall(center + Vector3(off, h * 0.5, nz), Vector3(seg, h, 0.4), col)
		else:
			wall(center + Vector3(nx, h * 0.5, off), Vector3(0.4, h, seg), col)

func add_room_portal(pos: Vector3, size: Vector3, dist: float, elev: float) -> void:
	var p: Area3D = Portal3DScript.new()
	p.set("kind", 0)  # REFRAME
	p.set("cam_dist", dist); p.set("cam_elev", elev); p.set("level", self)
	p.position = pos
	add_child(p)
	p.call("setup", size)

func add_exit_portal(pos: Vector3, size: Vector3) -> void:
	var p: Area3D = Portal3DScript.new()
	p.set("kind", 1)  # EXIT
	p.set("level", self)
	p.position = pos
	add_child(p)
	p.call("setup", size)

# A stairwell between floor regions: stepping on it carries the duo to `dest`
# (the next floor's landing) and reframes the camera. Returns the portal so the
# level can lock/unlock it (e.g. gate the climb behind a solved puzzle).
func add_stairwell(pos: Vector3, size: Vector3, dest: Vector3, dist: float, elev: float, locked: bool = false) -> Object:
	var p: Area3D = Portal3DScript.new()
	p.set("kind", 2)  # STAIR
	p.set("dest", dest); p.set("cam_dist", dist); p.set("cam_elev", elev)
	p.set("locked", locked); p.set("level", self)
	p.position = pos
	add_child(p)
	p.call("setup", size)
	return p

func teleport_duo(dest: Vector3) -> void:
	if player != null and player.has_method("teleport_to"):
		player.teleport_to(dest)

# A single shared staircase between two floors (walk-on, both ways): going UP from
# `lo_stairs` lands you in front of the upper stairs (`hi_land`) and reframes to the
# upper floor; going DOWN from `hi_stairs` lands you in front of the lower stairs
# (`lo_land`). Up can be locked behind a puzzle (down is always open). Each landing
# sits just off its stairs so you don't immediately ride back. Returns the UP portal
# so the level can unlock it.
func add_floor_link(lo_stairs: Vector3, lo_land: Vector3, lo_frame: Vector2, hi_stairs: Vector3, hi_land: Vector3, hi_frame: Vector2, col: Color, locked: bool = false) -> Object:
	stairs_mesh(lo_stairs + Vector3(0, 0, 0.5), col)
	stairs_mesh(hi_stairs + Vector3(0, 0, 0.5), col)
	var up := add_stairwell(lo_stairs, Vector3(3, 3, 1.4), hi_land, hi_frame.x, hi_frame.y, locked)
	add_stairwell(hi_stairs, Vector3(3, 3, 1.4), lo_land, lo_frame.x, lo_frame.y, false)
	return up

# Stairwell transition: fade to black, carry the duo + reframe at the dark point,
# fade back. Input is briefly locked so you don't slide off mid-fade.
func stair_transition(dest: Vector3, dist: float, elev: float) -> void:
	if player != null and player.has_method("set_input_locked"):
		player.set_input_locked(true)
	var cl := CanvasLayer.new(); cl.layer = 50; add_child(cl)
	var r := ColorRect.new()
	r.color = Color(0, 0, 0, 0)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(r)
	var tw := create_tween()
	tw.tween_property(r, "color:a", 1.0, 0.18)
	tw.tween_callback(func() -> void:
		teleport_duo(dest)
		reframe_camera(dist, elev))
	tw.tween_interval(0.05)
	tw.tween_property(r, "color:a", 0.0, 0.22)
	tw.tween_callback(func() -> void:
		cl.queue_free()
		if player != null and player.has_method("set_input_locked"):
			player.set_input_locked(false))

# A floor spanning a whole multi-room floor region (so rooms never leave a gap to
# fall through). Unlike floor_box it doesn't set the walk-out bounds.
func region_floor(center: Vector3, w: float, d: float, col: Color) -> void:
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(w, 1.0, d); cs.shape = bs; cs.position = Vector3(0, -0.5, 0)
	sb.add_child(cs); sb.add_child(box_mesh(Vector3(w, 1.0, d), col, Vector3(0, -0.5, 0)))
	sb.position = center; add_child(sb)

# A short flight of steps (visual cue for a stairwell). Climbs +Z, rising `rise`.
func stairs_mesh(base: Vector3, col: Color, steps: int = 5, width: float = 3.0, rise: float = 1.2) -> void:
	for i in steps:
		var h: float = rise * float(i + 1) / float(steps)
		add_child(box_mesh(Vector3(width, h, 0.4), col, base + Vector3(0, h * 0.5, -0.4 * float(i))))

func _update_bies_bar(d: float) -> void:
	if _bies_fill == null or player == null or not player.has_method("bies_charge"):
		return
	var charge: float = player.bies_charge()
	var w := 240.0
	_bies_fill.offset_right = _bies_fill.offset_left + w * clampf(charge, 0.0, 1.0)
	if charge >= 1.0:
		_bies_pulse += d * 6.0
		var t: float = 0.5 + 0.5 * sin(_bies_pulse)
		_bies_fill.color = UITheme.GOLD.lerp(Color(1, 1, 0.7), t)
	else:
		_bies_fill.color = UITheme.GOLD_DIM
