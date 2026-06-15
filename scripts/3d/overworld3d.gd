extends Level3D
## 3D Overworld — a walkable Synty city. The active duo strolls a central avenue
## lined with building shells (one per location). Approach a building and press G to
## enter its 3D level (if unlocked); locked ones show their requirement. Completion
## state comes from GameManager.completed_locations. Esc/quit from a level returns
## here. Built from the City pack kit baked to assets/models/town/.

const TOWN := "res://assets/models/town/"
const QUINN := preload("res://data/characters/quinn.tres")
const ERIN := preload("res://data/characters/erin.tres")
const SPACING := 20.0
const ZOFF := 12.0          # building rows at z = ±ZOFF
# big office towers scaled down so footprints fit the block; shops stay 1.0
const BLD_SCALE := {"bld_round": 0.7, "bld_round3": 0.7, "bld_octagon": 0.7,
	"bld_office_large": 0.75, "bld_square": 0.8, "bld_square3": 0.8, "bld_office_small": 0.85}
const DOOR_INSET := 4.0     # interaction point pulled toward the avenue
const INTERACT := 4.5
const GROUND := Color(0.28, 0.30, 0.26)

# id, display name, 3D scene, unlock requirement, building glb
const LOCS := [
	{"id": "pipe_organ_works", "name": "Pipe Organ Works", "scene": "res://scenes/3d/PipeOrganWorks3D.tscn", "req": "", "glb": "shop_01"},
	{"id": "old_parish_church", "name": "Old Parish Church", "scene": "res://scenes/3d/Church3D.tscn", "req": "pipe_organ_works", "glb": "bld_octagon"},
	{"id": "iron_strings_gym", "name": "Iron & Strings Gym", "scene": "res://scenes/3d/IronStringsGym3D.tscn", "req": "old_parish_church", "glb": "shop_02"},
	{"id": "recording_studio", "name": "Recording Studio", "scene": "res://scenes/3d/RecordingStudio3D.tscn", "req": "iron_strings_gym", "glb": "shop_03"},
	{"id": "clocktower", "name": "The Clocktower", "scene": "res://scenes/3d/Clocktower3D.tscn", "req": "recording_studio", "glb": "bld_square"},
	{"id": "harbor_docks", "name": "Harbor & Docks", "scene": "res://scenes/3d/HarborDocks3D.tscn", "req": "recording_studio", "glb": "shop_04"},
	{"id": "library", "name": "Library & Archive", "scene": "res://scenes/3d/LibraryArchive3D.tscn", "req": "recording_studio", "glb": "bld_office_small"},
	{"id": "carnival", "name": "Carnival & Fairground", "scene": "res://scenes/3d/Carnival3D.tscn", "req": "recording_studio", "glb": "shop_05"},
	{"id": "underground", "name": "Underground Tunnels", "scene": "res://scenes/3d/UndergroundTunnels3D.tscn", "req": "recording_studio", "glb": "shop_06"},
	{"id": "zip_line", "name": "Zip Line Park", "scene": "res://scenes/3d/ZipLinePark3D.tscn", "req": "recording_studio", "glb": "bld_round"},
	{"id": "vr_room", "name": "VR Escape Room", "scene": "res://scenes/3d/VrEscapeRoom3D.tscn", "req": "recording_studio", "glb": "bld_square3"},
	{"id": "the_drop", "name": "The Drop", "scene": "res://scenes/3d/TheDrop3D.tscn", "req": "vr_room", "glb": "shop_corner"},
	{"id": "grand_marquee", "name": "Grand Marquee Cinema", "scene": "res://scenes/3d/GrandMarqueeCinema3D.tscn", "req": "the_drop", "glb": "bld_office_large"},
	{"id": "gimme_dat_spoon", "name": "Gimme Dat Spoon", "scene": "res://scenes/3d/Spoon3D.tscn", "req": "grand_marquee", "glb": "bld_round3"},
]

var _doors: Array = []     # {id, name, scene, req, pos}
var _hud_prompt: Label = null
var _hud_title: Label = null

func _build_level() -> void:
	allow_overworld_exit = false   # we ARE the overworld
	build_env(Color(0.55, 0.72, 0.92), Color(0.7, 0.74, 0.78), 0.75, 1.25)
	floor_box(180.0, 90.0, GROUND)
	_avenue()
	_buildings()
	make_dialog()
	_build_hud()
	var p := spawn_duo([QUINN, ERIN], Vector3(_col_x(0) - SPACING, 0.1, 0.0))
	p.special_used.connect(_on_special)
	# pull the follow camera back for a town overview
	for c in get_children():
		if c is Camera3D and c.has_method("reframe"):
			c.call("reframe", 16.0, 46.0)

func _num_cols() -> int:
	return (LOCS.size() + 1) / 2

func _col_x(c: int) -> float:
	return (float(c) - float(_num_cols() - 1) / 2.0) * SPACING

# --- city dressing -----------------------------------------------------------
func _avenue() -> void:
	var x0: float = _col_x(0) - SPACING
	var x1: float = _col_x(_num_cols() - 1) + SPACING
	var x: float = x0
	while x <= x1:
		# two-lane road down the avenue (z = ±2.5)
		_tile("road", Vector3(x, 0.02, -2.5))
		_tile("road", Vector3(x, 0.02, 2.5))
		# sidewalks flanking the road
		_tile("sidewalk", Vector3(x, 0.01, -7.5))
		_tile("sidewalk", Vector3(x, 0.01, 7.5))
		x += 5.0

func _tile(key: String, pos: Vector3) -> void:
	prop(TOWN + key + ".glb", pos, 0.0, 1.0)

func _buildings() -> void:
	for i in LOCS.size():
		var loc: Dictionary = LOCS[i]
		var col: int = i / 2
		var north: bool = (i % 2) == 0
		var x: float = _col_x(col)
		var z: float = -ZOFF if north else ZOFF
		var yaw: float = 0.0 if north else PI         # face the avenue
		var door := Vector3(x, 0.0, z + (DOOR_INSET if north else -DOOR_INSET))
		var bscale: float = BLD_SCALE.get(loc["glb"], 1.0)
		prop(TOWN + loc["glb"] + ".glb", Vector3(x, 0.0, z), yaw, bscale)
		_crosswalk(x, north)
		_street_dressing(x, north)
		_name_billboard(loc, Vector3(x, 0.0, z + (2.0 if north else -2.0)))
		_doors.append({"id": loc["id"], "name": loc["name"], "scene": loc["scene"], "req": loc["req"], "pos": door})

func _crosswalk(x: float, north: bool) -> void:
	# a crossing tile + plaza connecting the sidewalk to the door
	var zc: float = -5.0 if north else 5.0
	_tile("road_crossing", Vector3(x, 0.02, zc))
	_tile("sidewalk", Vector3(x, 0.015, (-9.0 if north else 9.0)))

func _street_dressing(x: float, north: bool) -> void:
	var zs: float = -7.5 if north else 7.5
	var props := ["bench", "planter", "hydrant", "trashcan", "mailbox", "potplant"]
	var key: String = props[int(abs(x)) % props.size()]
	prop(TOWN + key + ".glb", Vector3(x + 2.5, 0.0, zs), 0.0 if north else PI, 1.0)

func _name_billboard(loc: Dictionary, pos: Vector3) -> void:
	var unlocked: bool = _is_unlocked(loc["req"])
	var done: bool = loc["id"] in GameManager.completed_locations
	var lbl := Label3D.new()
	lbl.text = loc["name"] + ("  ✓" if done else ("" if unlocked else "  🔒"))
	lbl.font = UITheme.font(); lbl.font_size = 40; lbl.outline_size = 14
	lbl.modulate = UITheme.GOLD if done else (UITheme.CREAM if unlocked else Color(0.55, 0.55, 0.6))
	lbl.outline_modulate = Color(0, 0, 0, 0.95)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = false
	lbl.fixed_size = true; lbl.pixel_size = 0.0013
	lbl.position = pos + Vector3(0, 3.4, 0)
	add_child(lbl)

func _is_unlocked(req: String) -> bool:
	return req == "" or req in GameManager.completed_locations

# --- interaction -------------------------------------------------------------
func _on_special(_char_name: String) -> void:
	var near := _nearest_door()
	if near.is_empty():
		return
	if _is_unlocked(near["req"]):
		get_tree().change_scene_to_file(near["scene"])
	else:
		Audio.play("hurt")

func _nearest_door() -> Dictionary:
	var pp: Vector3 = player.global_position
	var best := {}
	var best_d := INTERACT
	for d in _doors:
		var dist: float = Vector2(pp.x - d["pos"].x, pp.z - d["pos"].z).length()
		if dist < best_d:
			best_d = dist; best = d
	return best

# --- HUD ---------------------------------------------------------------------
func _build_hud() -> void:
	var cl := make_hud_layer()
	_hud_title = hud_label(cl, 22, 26)
	_hud_title.text = "HUNKLE BUNKLE — find Uncle Doug.  Walk up to a building, press G to enter. Tab swaps."
	_hud_prompt = hud_label(cl, 0, 30); _hud_prompt.anchor_top = 0.5; _hud_prompt.anchor_bottom = 0.5
	_hud_prompt.offset_top = 120; _hud_prompt.offset_bottom = 180

func _process(d: float) -> void:
	super._process(d)
	var near := _nearest_door()
	if near.is_empty():
		_hud_prompt.text = ""
		return
	if near["id"] in GameManager.completed_locations:
		_hud_prompt.text = "%s  ✓ cleared — press G to revisit" % near["name"]
		_hud_prompt.add_theme_color_override("font_color", UITheme.GOLD)
	elif _is_unlocked(near["req"]):
		_hud_prompt.text = "%s — press G to enter" % near["name"]
		_hud_prompt.add_theme_color_override("font_color", UITheme.CREAM)
	else:
		_hud_prompt.text = "%s — 🔒 locked (clear %s first)" % [near["name"], _req_name(near["req"])]
		_hud_prompt.add_theme_color_override("font_color", Color(0.7, 0.6, 0.6))

func _req_name(req: String) -> String:
	for loc in LOCS:
		if loc["id"] == req:
			return loc["name"]
	return req
