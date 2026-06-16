extends Level3D
## The Recording Studio (3D) — Quinn + Ben. Multi-room: a combat-free LOBBY (producer
## Sasha + exit), the LIVE ROOM (Grunts + Runners; mic stands, Doug's reel-to-reel, a
## feedback panel), and the CONTROL ROOM (Ethan sealed in the glass booth + the dead
## soundboard). Quinn repairs the patch bay to power the console; Ben then re-tunes it
## to slide the booth open and free Ethan (unlocks him). Carpet / acoustic-concrete
## surfaces, matte-black trim. Win = floor cleared + console tuned; the reel (Doug) and
## the feedback panel (bonus) are optional.

const QUINN := preload("res://data/characters/quinn.tres")
const BEN := preload("res://data/characters/ben.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const RUNNER := preload("res://data/enemies/runner.tres")
const TicketEthanItem: ItemData = preload("res://data/items/ticket_ethan.tres")
const SheetMusicItem: ItemData = preload("res://data/items/sheet_music_page.tres")
const BackstageItem: ItemData = preload("res://data/items/backstage_pass.tres")
const ReelItem: ItemData = preload("res://data/items/doug_recording.tres")

# --- thematic surfaces (carpet / acoustic concrete / matte-black trim) ---
const FLOOR_CARPET := "res://assets/art/tiles/synty_floor_carpet.png"
const FLOOR_TILE := "res://assets/art/tiles/synty_floor_tile.png"
const WALL_CONCRETE := "res://assets/art/tiles/synty_wall_concrete.png"
const FT_STUDIO := Color(0.70, 0.64, 0.72)
const WT_STUDIO := Color(0.72, 0.70, 0.74)
const FT_CONTROL := Color(0.74, 0.76, 0.80)
const CORNER_COL := Color(0.08, 0.08, 0.10)   # solid matte-black trim

const WALL_H := 3.2
const REACH := 2.2

const LOBBY_C := Vector3(0, 0, 13.0)
const SASHA_POS := Vector3(3.5, 0, 14.5)
const REEL_POS := Vector3(5.5, 0, -3.0)
const FEEDBACK_POS := Vector3(-5.5, 0, 3.0)
const CONTROL_C := Vector3(0, 0, -13.0)
const CONSOLE_POS := Vector3(1.5, 0, -11.5)
const PATCH_POS := Vector3(4.0, 0, -15.0)
const ETHAN_POS := Vector3(-3.0, 0, -15.0)
const DOOR_POS := Vector3(-0.9, 0.0, -13.0)

const ETHAN_QUIPS := [
	"Every channel's inverted -- retune it from the console!",
	"Runners flank -- don't let them split you up!",
	"The board's dead -- Quinn, find the patch bay!",
	"Two hours under a mixing desk. Two HOURS.",
]

var _cleared := false
var _enemies_cleared := false
var _patch_repaired := false
var _console_tuned := false
var _reel_played := false
var _feedback_silenced := false
var _ethan_freed := false
var _spawned := 0
var _ethan = null
var _sasha = null
var _door: Node3D = null
var _console_lights: Array = []
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "recording_studio"
	multi_room = true
	build_env(Color(0.05, 0.05, 0.07), Color(0.45, 0.43, 0.5), 0.5, 0.9)
	point_light(Vector3(0, 3.0, 0.0), Color(0.8, 0.75, 0.9), 2.0, 13.0)
	point_light(LOBBY_C + Vector3(0, 2.8, 0), Color(0.85, 0.8, 0.9), 1.9, 11.0)
	point_light(ETHAN_POS + Vector3(0, 2.6, 0), Color(0.5, 0.9, 0.8), 1.8, 6.0)        # booth glow
	point_light(CONSOLE_POS + Vector3(0, 1.6, 0.5), Color(0.4, 0.7, 1.0), 1.4, 5.0)    # console glow
	_rooms()
	_acoustic_foam()
	_booth()
	_console()
	_patch_bay()
	_reel_machine()
	_feedback_panel()
	_mic_stand(Vector3(3.5, 0, -3.0))
	_mic_stand(Vector3(4.5, 0, 1.5))
	make_dialog()
	_build_hud()
	_ethan = spawn_npc("ethan", ETHAN_POS, deg_to_rad(60), ETHAN_QUIPS)
	_ethan.set("yell_min", 4.0); _ethan.set("yell_max", 8.0)
	_sasha = spawn_npc("congregant_f", SASHA_POS, PI)
	add_exit_portal(LOBBY_C + Vector3(0, 0, 5.0), Vector3(3, 3, 1.4))
	var p := spawn_duo([QUINN, BEN], LOBBY_C + Vector3(0.0, 0.1, 1.0))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _rooms() -> void:
	# Live room — carpet floor, concrete (acoustic) walls. Combat. Openings: south
	# (lobby), north (control room).
	set_theme(FLOOR_CARPET, WALL_CONCRETE)
	room(Vector3.ZERO, 14, 16, FT_STUDIO, WT_STUDIO, WALL_H, ["s", "n"], 3.0, true)
	corridor(Vector3(0, 0, 8), "s", 1.0, FT_STUDIO, WT_STUDIO, 3.0, WALL_H, true, CORNER_COL)    # → lobby (1 m gap)
	corridor(Vector3(0, 0, -8), "n", 1.0, FT_STUDIO, WT_STUDIO, 3.0, WALL_H, true, CORNER_COL)   # → control (1 m gap)
	# Lobby — carpet, concrete. Combat-free entry; south vestibule = exit.
	set_theme(FLOOR_CARPET, WALL_CONCRETE)
	room(LOBBY_C, 12, 8, FT_STUDIO, WT_STUDIO, 3.2, ["n", "s"], 3.0, true)
	corridor(LOBBY_C + Vector3(0, 0, 4.0), "s", 2.0, FT_STUDIO, WT_STUDIO, 3.0, 3.2, true, CORNER_COL)
	# Control room — tile floor, concrete walls (the booth + console).
	set_theme(FLOOR_TILE, WALL_CONCRETE)
	room(CONTROL_C, 12, 8, FT_CONTROL, WT_STUDIO, 3.2, ["s"], 3.0, true)

func _acoustic_foam() -> void:
	for i: int in range(6):
		var z: float = -6.0 + float(i) * 2.0
		var c: Color = Color(0.13, 0.12, 0.15) if i % 2 == 0 else Color(0.18, 0.17, 0.2)
		add_child(box_mesh(Vector3(0.12, 1.6, 1.4), c, Vector3(7.0 - 0.25, 1.8, z)))

func _booth() -> void:
	# glass booth in the back-left of the control room; a sliding door rises when tuned.
	_glass(Vector3(-0.8, 1.4, -15.0), Vector3(0.12, 2.8, 4.0))         # side glass (along Z)
	_glass(Vector3(-3.4, 1.4, -13.0), Vector3(4.8, 2.8, 0.12))         # front glass (along X)
	add_child(box_mesh(Vector3(4.6, 0.05, 3.8), Color(0.16, 0.20, 0.22), Vector3(-3.2, 0.04, -15.0)))
	_door = _glass(DOOR_POS, Vector3(0.12, 2.8, 1.8))

func _glass(pos: Vector3, size: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.75, 0.85, 0.22)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.4; mat.roughness = 0.1
	bm.material = mat; mi.mesh = bm; mi.position = pos
	add_child(mi)
	return mi

func _console() -> void:
	prop("res://assets/models/props/desk.glb", CONSOLE_POS, 0.0)
	var surf := box_mesh(Vector3(2.4, 0.08, 0.9), Color(0.14, 0.14, 0.17), CONSOLE_POS + Vector3(0, 1.0, 0))
	surf.rotation.x = deg_to_rad(-18)
	add_child(surf)
	for i: int in range(8):
		var x: float = -1.0 + float(i) * 0.28
		var lite := box_mesh(Vector3(0.12, 0.04, 0.12), Color(0.9, 0.25, 0.2), CONSOLE_POS + Vector3(x, 1.12, 0.0), 1.5)
		lite.rotation.x = deg_to_rad(-18)
		add_child(lite)
		_console_lights.append(lite)

# Patch bay — a dead rack Quinn rewires to power the console.
func _patch_bay() -> void:
	add_child(box_mesh(Vector3(0.5, 1.8, 1.2), Color(0.16, 0.16, 0.2), PATCH_POS + Vector3(0, 0.9, 0)))
	for i: int in range(6):
		var y: float = 0.5 + float(i) * 0.22
		add_child(box_mesh(Vector3(0.12, 0.08, 0.9), Color(0.5, 0.35, 0.15), PATCH_POS + Vector3(0.28, y, 0)))  # patch cables

# Doug's reel-to-reel — Ben restores it to hear Doug's message.
func _reel_machine() -> void:
	add_child(box_mesh(Vector3(1.4, 0.9, 0.8), Color(0.2, 0.18, 0.16), REEL_POS + Vector3(0, 0.45, 0)))
	for sx: float in [-0.35, 0.35]:
		var reel := MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 0.28; cm.bottom_radius = 0.28; cm.height = 0.08
		var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.45, 0.3, 0.2)
		cm.material = mat; reel.mesh = cm; reel.rotation.x = deg_to_rad(90)
		reel.position = REEL_POS + Vector3(sx, 1.0, 0.1)
		add_child(reel)

# Feedback panel — a squealing monitor wedge Ben can silence (optional → backstage pass).
func _feedback_panel() -> void:
	add_child(box_mesh(Vector3(0.9, 0.6, 0.7), Color(0.15, 0.15, 0.18), FEEDBACK_POS + Vector3(0, 0.3, 0)))
	add_child(box_mesh(Vector3(0.7, 0.1, 0.5), Color(0.8, 0.3, 0.2), FEEDBACK_POS + Vector3(0, 0.65, 0.1), 1.2))

func _mic_stand(pos: Vector3) -> void:
	var pole := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 0.03; cm.bottom_radius = 0.03; cm.height = 1.7
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.1, 0.1, 0.12); mat.metallic = 0.6
	cm.material = mat; pole.mesh = cm; pole.position = pos + Vector3(0, 0.85, 0)
	add_child(pole)
	add_child(box_mesh(Vector3(0.18, 0.12, 0.12), Color(0.08, 0.08, 0.1), pos + Vector3(0, 1.6, 0)))

func _spawn_enemies() -> void:
	spawn_enemy(GRUNT, Vector3(2.5, 0.1, 1.0), "res://assets/models/enemies/grunt.glb"); _spawned += 1
	for spot: Vector3 in [Vector3(-2.0, 0.1, 2.0), Vector3(3.0, 0.1, -2.0)]:
		spawn_enemy(RUNNER, spot, "res://assets/models/enemies/runner.glb"); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_patch_repaired = GameManager.get_level_flag(location_id, "patch_repaired", false)
	_console_tuned = GameManager.get_level_flag(location_id, "console_tuned", false)
	_reel_played = GameManager.get_level_flag(location_id, "reel_played", false)
	_feedback_silenced = GameManager.get_level_flag(location_id, "feedback_silenced", false)
	if _console_tuned:
		_open_door(false); _set_console_solved(); _ethan_freed = true; _ethan.set("quips", [])
	if _enemies_cleared and _console_tuned:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	# patch bay → powers the console (Quinn)
	if not _patch_repaired and near3(pp, PATCH_POS, REACH):
		if char_name == "Quinn":
			_repair_patch()
		else:
			_hud_hint.text = "The patch bay's a rat's nest of dead cables — Quinn's repair job."
		return
	# soundboard tune → frees Ethan (Ben), once powered
	if char_name == "Ben" and not _console_tuned and near3(pp, CONSOLE_POS, REACH):
		if _patch_repaired:
			_tune_console(char_name)
		else:
			_hud_hint.text = "The board's dead — Quinn needs to power it from the patch bay first."
		return
	if not _console_tuned and near3(pp, CONSOLE_POS, REACH):
		_hud_hint.text = "The soundboard needs Ben's ear — swap to Ben."; return
	# Doug's reel (Ben)
	if not _reel_played and near3(pp, REEL_POS, REACH):
		if char_name == "Ben":
			_play_reel(char_name)
		else:
			_hud_hint.text = "The old reel-to-reel is tangled — Ben can thread and play it."
		return
	# feedback panel (Ben, optional → backstage pass)
	if not _feedback_silenced and near3(pp, FEEDBACK_POS, REACH):
		if char_name == "Ben":
			_silence_feedback(char_name)
		else:
			_hud_hint.text = "That monitor's screaming feedback — Ben can find the frequency."
		return
	if near3(pp, ETHAN_POS, REACH + 1.2):
		_talk_ethan(char_name); return
	if near3(pp, SASHA_POS, REACH + 0.6):
		_talk_sasha(char_name); return

func _repair_patch() -> void:
	_patch_repaired = true
	GameManager.set_level_flag(location_id, "patch_repaired", true)
	for lite in _console_lights:
		((lite as MeshInstance3D).mesh as BoxMesh).material.albedo_color = Color(0.95, 0.7, 0.2)
	_hud_hint.text = "Quinn rewires the patch bay — the soundboard hums to life. Now Ben's ear."
	Audio.play("special")

func _tune_console(char_name: String) -> void:
	_console_tuned = true
	_ethan_freed = true
	GameManager.set_level_flag(location_id, "console_tuned", true)
	_set_console_solved()
	_open_door(true)
	GameManager.grant_item(char_name, TicketEthanItem.id)
	GameManager.grant_item(char_name, SheetMusicItem.id)
	_ethan.set("quips", [])
	_ethan.call("say", "Door's opening! Finally!")
	_hud_hint.text = "Ben re-tunes the board. The booth slides open — Ethan's free! (Found Ethan's ticket + a sheet-music page)"
	Audio.play("special")

func _play_reel(char_name: String) -> void:
	_reel_played = true
	GameManager.set_level_flag(location_id, "reel_played", true)
	GameManager.grant_item(char_name, ReelItem.id)
	open_dialog("Doug's Reel", Color(0.5, 0.45, 0.55),
		{"start": {"lines": [
			"Ben threads the tape and rolls it. Static, then a voice -- Uncle Doug's.",
			"Doug (recording): \"...if you're hearing this, I've gone somewhere I can't easily come back from. The tower keeps the time, but it's the cinema that keeps the--\"",
			"The tape snaps. Ben pockets the reel. \"Cut off. But he was leaving a trail.\"",
			"Picked up: Doug's Reel."]}}, char_name)
	Audio.play("special")

func _silence_feedback(char_name: String) -> void:
	_feedback_silenced = true
	GameManager.set_level_flag(location_id, "feedback_silenced", true)
	GameManager.grant_item(char_name, BackstageItem.id)
	_hud_hint.text = "Ben nails the feedback frequency and kills it. Behind the wedge: a backstage pass. (Found Backstage Pass)"
	Audio.play("special")

func _set_console_solved() -> void:
	for lite in _console_lights:
		((lite as MeshInstance3D).mesh as BoxMesh).material.albedo_color = Color(0.3, 0.95, 0.4)
		((lite as MeshInstance3D).mesh as BoxMesh).material.emission = Color(0.3, 0.95, 0.4)

func _open_door(animate: bool) -> void:
	var to := DOOR_POS + Vector3(0, WALL_H, 0)
	if animate:
		create_tween().tween_property(_door, "position", to, 0.6)
	else:
		_door.position = to

func _talk_ethan(char_name: String) -> void:
	var tree: Dictionary
	if _ethan_freed:
		tree = {"start": {"lines": [
			"\"Door's opening! I've been crouched under this mixing desk for two hours.\"",
			"\"Their whole setup was reversed on purpose. Someone knew what they were doing.\"",
			"\"Here -- take this sheet-music page. Found it taped under the console. Means nothing to me; might to Ben.\""]}}
	elif _enemies_cleared:
		tree = {"start": {"lines": ["\"The board's dead -- Quinn, the patch bay! Then Ben re-tunes it. The door's locked from this side.\""]}}
	else:
		tree = {"start": {"lines": [
			"\"Quinn! Ben! Can you hear me?! The soundboard is scrambled -- every channel's inverted and the power's cut.\"",
			"\"Clear the room first. The runners like to flank -- don't let them split you up.\""]}}
	open_dialog("Ethan", Color(0.38, 0.52, 0.45), tree, char_name)

func _talk_sasha(char_name: String) -> void:
	var tree := {"start": {"lines": [
		"A frazzled producer clutches a clipboard at the front desk.",
		"Sasha: \"They trashed the live room and locked your tech friend in the booth. Cut the power to the board, too.\"",
		"\"Quinn -- the patch bay in the control room is shredded. Fix that and Ben can re-tune the console.\"",
		"\"Doug? He cut a tape here, months back. Old reel-to-reel's still in the live room if you want to hear it.\""]}}
	GameManager.set_level_flag(location_id, "sasha_met", true)
	open_dialog("Sasha", Color(0.6, 0.5, 0.6), tree, char_name)

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	var cl := make_hud_layer()
	_hud_goal = hud_label(cl, 24)
	_hud_goal.text = "Clear the studio; Quinn powers the patch bay, Ben tunes the board to free Ethan. (G interact, Tab swap)"
	_hud_hint = hud_label(cl, -70, 22, true)
	_hud_banner = hud_label(cl, 0, 40); _hud_banner.anchor_top = 0.5; _hud_banner.anchor_bottom = 0.5
	_hud_banner.visible = false

func _process(_d: float) -> void:
	super._process(_d)
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
		_hud_hint.text = "Studio clear! Quinn fixes the patch bay, then Ben tunes the console."
		if _ethan != null and not _ethan_freed:
			_ethan.call("say", "Patch bay, then the console!")
	if not _cleared and _enemies_cleared and _console_tuned:
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "STUDIO CLEARED!\nEthan joins the crew!"
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
