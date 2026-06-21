extends Level3D
## 3D Overworld — a walkable Synty city. The active duo strolls a central avenue
## lined with building shells (one per location). Approach a building and press G to
## enter its 3D level (if unlocked); locked ones show their requirement. Completion
## state comes from GameManager.completed_locations. Esc/quit from a level returns
## here. Built from the City pack kit baked to assets/models/town/.

const TOWN := "res://assets/models/town/"
const QUINN := preload("res://data/characters/quinn.tres")
const ERIN := preload("res://data/characters/erin.tres")
# Overworld duo is drawn from who's actually unlocked (in unlock order), so a fresh
# game shows Quinn alone until Bellows & Sons unlocks Erin, etc.
const CHARS := {
	"quinn": QUINN,
	"erin": ERIN,
	"evan": preload("res://data/characters/evan.tres"),
	"ben": preload("res://data/characters/ben.tres"),
	"ethan": preload("res://data/characters/ethan.tres"),
}
# Stacked-boulevard grid: 3 rows of buildings ALL facing +Z (the camera looks -Z),
# each with an E-W boulevard on its +Z front; a central park fills the middle slot.
const COL_X := [-44.0, -22.0, 0.0, 22.0, 44.0]   # 5 columns
const ROW_Z := [-46.0, -18.0, 10.0]              # 3 building rows (back -> front)
const BLVD_Z := [-38.0, -10.0, 18.0]             # boulevard in front (+Z) of each row
const CROSS_X := [-11.0, 11.0]                   # N-S cross-streets (inner only; L/R are green)
const PARK_SLOT := Vector2i(1, 2)                # middle row, centre column = the park
# Building slots (row, col) in LOCS order — 14 buildings, the park slot skipped.
const SLOTS := [
	Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
	Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 3), Vector2i(1, 4),
	Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3), Vector2i(2, 4),
]
# big office towers scaled down so footprints fit the block; shops stay 1.0
const BLD_SCALE := {"bld_round": 0.7, "bld_round3": 0.7, "bld_octagon": 0.7,
	"bld_office_large": 0.75, "bld_square": 0.8, "bld_square3": 0.8, "bld_office_small": 0.85,
	"courthouse": 0.85, "subway_entrance": 1.3, "carousel": 2.5,
	"organ_works_bld": 1.7, "studio_bld": 1.2}
const DOOR_INSET := 5.0     # interaction point pulled toward the boulevard
const INTERACT := 4.5
const GROUND := Color(0.30, 0.42, 0.26)   # grassy town green
const ROAD_COL := Color(0.22, 0.22, 0.25) # solid blacktop (no Synty road-tile lane lines)
const LANE_COL := Color(0.85, 0.84, 0.72) # painted lane dashes
const SW_COL := Color(0.60, 0.60, 0.63)   # sidewalk
const SW_W := 2.5                         # sidewalk width (was a full 5m Synty tile)
const BLDG_SETBACK := 6.0                 # push buildings back so fronts clear the sidewalk

# id, display name, 3D scene, unlock requirement, building glb
const LOCS := [
	{"id": "pipe_organ_works", "name": "Pipe Organ Works", "scene": "res://scenes/3d/PipeOrganWorks3D.tscn", "req": "", "glb": "organ_works_bld"},
	{"id": "old_parish_church", "name": "Old Parish Church", "scene": "res://scenes/3d/Church3D.tscn", "req": "pipe_organ_works", "glb": "church"},
	{"id": "iron_strings_gym", "name": "Iron & Strings Gym", "scene": "res://scenes/3d/IronStringsGym3D.tscn", "req": "old_parish_church", "glb": "gym_bld"},
	{"id": "recording_studio", "name": "Recording Studio", "scene": "res://scenes/3d/RecordingStudio3D.tscn", "req": "iron_strings_gym", "glb": "studio_bld"},
	{"id": "clocktower", "name": "The Clocktower", "scene": "res://scenes/3d/Clocktower3D.tscn", "req": "recording_studio", "glb": "courthouse"},
	{"id": "harbor_docks", "name": "Harbor & Docks", "scene": "res://scenes/3d/HarborDocks3D.tscn", "req": "recording_studio", "glb": "warehouse"},
	{"id": "library", "name": "Library & Archive", "scene": "res://scenes/3d/LibraryArchive3D.tscn", "req": "recording_studio", "glb": "cityhall"},
	{"id": "carnival", "name": "Carnival & Fairground", "scene": "res://scenes/3d/Carnival3D.tscn", "req": "recording_studio", "glb": "carousel"},
	{"id": "underground", "name": "Underground Tunnels", "scene": "res://scenes/3d/UndergroundTunnels3D.tscn", "req": "recording_studio", "glb": "subway_entrance"},
	{"id": "zip_line", "name": "Zip Line Park", "scene": "res://scenes/3d/ZipLinePark3D.tscn", "req": "recording_studio", "glb": "zipline_tower"},
	{"id": "vr_room", "name": "VR Escape Room", "scene": "res://scenes/3d/VrEscapeRoom3D.tscn", "req": "recording_studio", "glb": "vr_bld", "yaw": -PI / 2.0},
	{"id": "the_drop", "name": "The Drop", "scene": "res://scenes/3d/TheDrop3D.tscn", "req": "vr_room", "glb": "chopshop"},
	{"id": "grand_marquee", "name": "Grand Marquee Cinema", "scene": "res://scenes/3d/GrandMarqueeCinema3D.tscn", "req": "the_drop", "glb": "cinema_bld"},
	{"id": "gimme_dat_spoon", "name": "Arcade", "scene": "res://scenes/3d/AlsRooftopGarden3D.tscn", "req": "grand_marquee", "glb": "arcade", "yaw": 0.0},
]

# Some locations also need an item in hand, not just an unlock. The Underground
# Tunnels are pitch black — you need the pocket lantern (found at the Harbor & Docks).
const ITEM_GATE := {
	"underground": {"item": "pocket_lantern", "hint": "you'll need a lantern (try the Harbor & Docks)"},
}
const ALL_CHARS := ["quinn", "erin", "evan", "ben", "ethan"]

const NPC_REACH := 3.2
const NPC_MESHES := ["bellows", "congregant_m", "congregant_f", "aldric", "uncle_doug"]
# Atmospheric idle barks for the town quest-givers (one NPC speaks at a time — see the
# static bark gate in npc3d.gd). Drawn from at random; kept generic so any NPC can say any.
const TOWN_QUIPS := [
	"Any word on Uncle Doug?",
	"Strange folks about lately.",
	"You lot aren't from around here.",
	"Mind how you go.",
	"Heard a racket down the tunnels.",
	"Spare a minute for an old soul?",
	"Town's not what it was.",
	"They say he just... vanished.",
	"Careful past the docks.",
	"Lovely day for a stroll, eh?",
	"Got a job for you, if you're keen.",
	"Keep your wits about you.",
]

var _doors: Array = []     # {id, name, scene, req, pos}
var _npcs: Array = []      # {quest_id, name, color, pos, node}
var _hud_prompt: Label = null
var _hud_title: Label = null

func _build_level() -> void:
	allow_overworld_exit = false   # we ARE the overworld
	build_env(Color(0.55, 0.72, 0.92), Color(0.7, 0.74, 0.78), 0.75, 1.25)
	floor_box(160.0, 130.0, GROUND)
	_streets()
	_park()
	_buildings()
	_foliage()
	_boundary()
	_spawn_town_npcs()
	make_dialog()
	_build_hud()
	# Returning from a level drops the duo back outside the building they just exited;
	# a fresh arrival (title) starts near — but not on — the first level (Pipe Organ Works).
	var start := _slot_pos(SLOTS[0]) + Vector3(5.0, 0.1, DOOR_INSET + 3.0)
	var ret: String = GameManager.last_location_id
	# Continue from the title: no in-session return id, so fall back to the last
	# building visited (persisted) and resume the duo at its door.
	if ret == "":
		ret = GameManager.last_building_visited
	if ret != "":
		for d2 in _doors:
			if d2["id"] == ret:
				start = d2["pos"] + Vector3(0.0, 0.1, 2.0)
				break
		GameManager.last_location_id = ""
	var p := spawn_duo(_overworld_duo(), start)
	p.special_used.connect(_on_special)
	# pull the follow camera back for the wider grid town overview
	for c in get_children():
		if c is Camera3D and c.has_method("reframe"):
			c.call("reframe", 13.5, 52.0)
	build_ui_stack(true)   # pause menu + overlays (Esc opens it)
	Audio.play_music("overworld")   # the walkable city theme
	# First-ever arrival in the overworld: a silly title card + Quinn intro barks (one-shot).
	if ret == "" and GameManager.completed_locations.is_empty() \
			and not GameManager.get_level_flag("meta", "intro_seen", false):
		GameManager.set_level_flag("meta", "intro_seen", true)
		_play_intro(p)

# One-shot opening: a cinematic "Based on Actual Events" card, then Quinn's intro
# speech bubbles. Fire-and-forget coroutine; never blocks the build.
func _play_intro(duo: Node) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	var card := Label.new()
	card.text = "Based on Actual Events"
	card.add_theme_font_override("font", UITheme.font())
	card.add_theme_font_size_override("font_size", 46)
	card.add_theme_color_override("font_color", UITheme.GOLD)
	card.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	card.add_theme_constant_override("outline_size", 14)
	card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.modulate.a = 0.0
	layer.add_child(card)
	var tin := create_tween()
	tin.tween_property(card, "modulate:a", 1.0, 0.7)
	await get_tree().create_timer(2.8).timeout
	var tout := create_tween()
	tout.tween_property(card, "modulate:a", 0.0, 0.8)
	await tout.finished
	layer.queue_free()
	# Quinn's barks above the active body.
	var body: Node3D = duo.bodies[duo.active] if duo != null and not duo.bodies.is_empty() else null
	if body == null:
		return
	var bub := Label3D.new()
	bub.font = UITheme.font()
	bub.font_size = 48
	bub.outline_size = 16
	bub.modulate = UITheme.CREAM
	bub.outline_modulate = Color(0, 0, 0, 0.95)
	bub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bub.no_depth_test = true
	bub.fixed_size = true
	bub.pixel_size = 0.0011
	bub.position = Vector3(0.0, 2.6, 0.0)
	body.add_child(bub)
	for line: String in ["Hi, I'm Quinn", "Now where is Uncle Doug?", "What a crock!"]:
		if not is_instance_valid(bub):
			return
		bub.text = line
		await get_tree().create_timer(2.0).timeout
	if is_instance_valid(bub):
		bub.queue_free()

# The strolling duo = the first (up to two) unlocked characters, in unlock order.
# Quinn alone at the start; Quinn+Erin once Bellows & Sons is done; and so on.
func _overworld_duo() -> Array:
	var duo: Array = []
	# prefer the duo from the location just played (only those still valid/unlocked)…
	for name: String in GameManager.last_level_duo:
		if name in CHARS and name in GameManager.unlocked_characters and CHARS[name] not in duo:
			duo.append(CHARS[name])
		if duo.size() >= 2:
			break
	# …else fall back to the first two unlocked (fresh boot / no last duo)
	if duo.is_empty():
		for name: String in GameManager.unlocked_characters:
			if name in CHARS:
				duo.append(CHARS[name])
			if duo.size() >= 2:
				break
	if duo.is_empty():
		duo.append(QUINN)
	return duo

func _slot_pos(slot: Vector2i) -> Vector3:
	return Vector3(COL_X[slot.y], 0.0, ROW_Z[slot.x])

# --- streets: 3 E-W boulevards + N-S cross-streets ---------------------------
# Tile heights stagger so layers never z-fight: ground 0 < sidewalk .04 < road .06.
const XMIN := -56.0
const XMAX := 56.0
const ZMIN := -52.0
const ZMAX := 26.0

func _streets() -> void:
	# Solid blacktop strips (box_mesh) so there are no mis-oriented Synty lane lines.
	# Distinct, well-separated heights per layer avoid z-fighting: N-S cross-streets
	# (top 0.04) sit below the E-W boulevards (top 0.07) so the boulevards read cleanly
	# across the intersections; dashes/crosswalks float clearly above their road.
	# roads stay inside the play area (±RX) so they never run under the outer tree border
	var rx: float = PLAY_X - 2.0
	for cx: float in CROSS_X:
		_road_ns(cx, PLAY_Z_BACK + 1.0, PLAY_Z_FRONT - 1.0, 6.0, 0.04, 0.055)
	for bz: float in BLVD_Z:
		_road_ew(bz, -rx, rx, 7.0, 0.07, 0.10)
		# narrow solid sidewalks flanking the boulevard, broken where the cross-streets cross
		_sidewalk_ew(bz - 4.75, -rx, rx)   # building-side walk
		_sidewalk_ew(bz + 5.5, -rx, rx)    # far-side walk

# Draw an E-W sidewalk strip in segments, leaving a gap where each N-S cross-street runs.
func _sidewalk_ew(z: float, x0: float, x1: float) -> void:
	var cur: float = x0
	for cx: float in CROSS_X:   # CROSS_X is left-to-right
		var gap0: float = cx - 4.0
		var gap1: float = cx + 4.0
		if gap0 > cur:
			add_child(box_mesh(Vector3(gap0 - cur, 0.08, SW_W), SW_COL, Vector3((cur + gap0) * 0.5, 0.04, z)))
		cur = maxf(cur, gap1)
	if cur < x1:
		add_child(box_mesh(Vector3(x1 - cur, 0.08, SW_W), SW_COL, Vector3((cur + x1) * 0.5, 0.04, z)))

func _road_ew(z: float, x0: float, x1: float, w: float, top_y: float, dash_y: float) -> void:
	add_child(box_mesh(Vector3(x1 - x0, 0.12, w), ROAD_COL, Vector3((x0 + x1) * 0.5, top_y - 0.06, z)))
	var x: float = x0 + 2.5
	while x < x1:
		add_child(box_mesh(Vector3(1.6, 0.02, 0.18), LANE_COL, Vector3(x, dash_y, z)))
		x += 4.0

func _road_ns(x: float, z0: float, z1: float, w: float, top_y: float, dash_y: float) -> void:
	add_child(box_mesh(Vector3(w, 0.12, z1 - z0), ROAD_COL, Vector3(x, top_y - 0.06, (z0 + z1) * 0.5)))
	var z: float = z0 + 2.5
	while z < z1:
		add_child(box_mesh(Vector3(0.18, 0.02, 1.6), LANE_COL, Vector3(x, dash_y, z)))
		z += 4.0

# A zebra crosswalk (white bars) across the E-W boulevard in front of a building door.
func _crosswalk(x: float, z: float) -> void:
	for i in 4:
		add_child(box_mesh(Vector3(0.4, 0.02, 2.6), LANE_COL, Vector3(x - 1.2 + float(i) * 0.8, 0.12, z)))

func _tile(key: String, pos: Vector3) -> void:
	prop(TOWN + key + ".glb", pos, 0.0, 1.0)

func _buildings() -> void:
	# Every building faces +Z (yaw 0) toward the locked −Z camera. Each sits at its grid
	# slot; its door + plaza + name billboard go on the +Z front, toward its boulevard.
	for i in LOCS.size():
		var loc: Dictionary = LOCS[i]
		var base: Vector3 = _slot_pos(SLOTS[i])
		var x: float = base.x
		var z: float = base.z
		var bscale: float = BLD_SCALE.get(loc["glb"], 1.0)
		# push the building mesh back so its +Z front clears the sidewalk; the door,
		# sidewalk, billboard and dressing stay keyed to the slot's front (z).
		var place: Vector3 = base - Vector3(0, 0, BLDG_SETBACK)
		# Most meshes are baked facing +Z; a few (Prop-Farm buildings) need a per-entry
		# yaw override so their front faces the −Z camera.
		var byaw: float = loc.get("yaw", 0.0)
		prop(TOWN + loc["glb"] + ".glb", place, byaw, bscale)
		if loc["id"] == "clocktower":
			_add_clock_tower(place, 0.0)
		# Big "ARCADE" sign mounted on the games-hall front (keeps the Gimme Dat
		# Spoon surprise — it just reads as an arcade until you go in).
		if loc["id"] == "gimme_dat_spoon":
			prop(TOWN + "arcade_sign.glb", place + Vector3(0, 5.6, 4.2), 0.0, 1.0)
		_entry_plaza(x, z)
		_entry_dressing(x, z)
		_name_billboard(loc, Vector3(x, 0.0, z + 2.0))
		_doors.append({"id": loc["id"], "name": loc["name"], "scene": loc["scene"], "req": loc["req"],
			"pos": Vector3(x, 0.0, z + DOOR_INSET)})

# An entrance plaza patch on the (continuous) building-side sidewalk + a crosswalk.
func _entry_plaza(x: float, rz: float) -> void:
	add_child(box_mesh(Vector3(6.0, 0.09, SW_W + 1.0), SW_COL, Vector3(x, 0.05, rz + 3.25)))
	_crosswalk(x, rz + 8.0)   # zebra crossing over the boulevard

func _entry_dressing(x: float, rz: float) -> void:
	# a flanking prop + a planter/bush at the entrance (on the sidewalk band ~rz+3.25)
	var props := ["bench", "planter", "hydrant", "trashcan", "mailbox", "potplant"]
	prop(TOWN + props[int(abs(x) + abs(rz)) % props.size()] + ".glb", Vector3(x + 3.5, 0.0, rz + 3.3), PI, 1.0)
	prop(TOWN + "flowerbed.glb", Vector3(x - 3.2, 0.0, rz + 3.3))

# The Clocktower reuses the CityHall courthouse mesh (like the Library) and gets a
# clock tower built on top from primitives: a taller central shaft (tinted to match
# the courthouse stone), a cornice, a roof + finial, and a clock face with hands on
# the front (+Z, toward the camera). The shaft is set back ~1/5 of the courthouse
# depth from the front.
const CT_BODY := Color(0.85, 0.76, 0.50)   # courthouse stone tone
const CT_CREAM := Color(0.93, 0.91, 0.84)
const CT_ROOF := Color(0.27, 0.25, 0.30)
const CT_GOLD := Color(0.82, 0.66, 0.28)
const CT_DARK := Color(0.12, 0.12, 0.14)
const CT_DEPTH := 9.7   # CityHall footprint depth

func _add_clock_tower(base: Vector3, yaw: float) -> void:
	var t := Node3D.new()
	t.position = base
	t.rotation.y = yaw
	add_child(t)
	var bh: float = 4.6   # CityHall roof height; embed the shaft slightly into it
	var top: float = bh + 6.4
	var bz: float = -CT_DEPTH * 0.2   # set the shaft back ~1/5 of the courthouse depth
	t.add_child(box_mesh(Vector3(3.6, 6.8, 3.6), CT_BODY, Vector3(0, bh + 3.0, bz)))          # shaft
	t.add_child(box_mesh(Vector3(4.1, 0.5, 4.1), CT_CREAM, Vector3(0, top, bz)))              # cornice
	t.add_child(box_mesh(Vector3(3.4, 1.3, 3.4), CT_ROOF, Vector3(0, top + 0.9, bz)))         # roof
	t.add_child(box_mesh(Vector3(0.3, 1.4, 0.3), CT_GOLD, Vector3(0, top + 2.1, bz)))         # finial
	# clock on the shaft's front (+Z) face, upper third
	var cy: float = bh + 4.3
	var cz: float = bz + 1.85
	t.add_child(box_mesh(Vector3(2.6, 2.6, 0.12), CT_DARK, Vector3(0, cy, cz)))               # bezel
	t.add_child(box_mesh(Vector3(2.2, 2.2, 0.14), CT_CREAM, Vector3(0, cy, cz + 0.02)))       # face
	for i in 4:   # 4 hour ticks (12/3/6/9)
		var a: float = float(i) * PI * 0.5
		t.add_child(box_mesh(Vector3(0.16, 0.16, 0.16), CT_DARK,
			Vector3(sin(a) * 0.9, cy + cos(a) * 0.9, cz + 0.12)))
	var hour := Node3D.new(); hour.position = Vector3(0, cy, cz + 0.16); hour.rotation.z = deg_to_rad(-60); t.add_child(hour)
	hour.add_child(box_mesh(Vector3(0.16, 0.85, 0.1), CT_DARK, Vector3(0, 0.42, 0)))
	var minute := Node3D.new(); minute.position = Vector3(0, cy, cz + 0.18); minute.rotation.z = deg_to_rad(110); t.add_child(minute)
	minute.add_child(box_mesh(Vector3(0.12, 1.15, 0.1), CT_DARK, Vector3(0, 0.57, 0)))

# --- central park (middle-row centre slot, fronting boulevard B) -------------
const PARK_C := Vector3(0.0, 0.0, -18.0)   # park centre (= ROW_Z[1], COL_X[2])

func _park() -> void:
	# grass lawn (3x3 tiles), fountain centre, gazebo + pond to the back, a ring of
	# trees, benches facing the fountain, park lamps + flower beds.
	for gx in [-5.0, 0.0, 5.0]:
		for gz in [-10.0, -5.0, 0.0]:   # tiles are 5x5 with origin at a corner
			prop(TOWN + "grass.glb", PARK_C + Vector3(gx, 0.02, gz), 0.0, 1.0)   # lift off the ground plane
	# everything kept within x ±7 (clear of the cross-streets at ±11) and z north of
	# the boulevard (road north edge ≈ -13.5), so nothing lands in the street.
	prop(TOWN + "fountain.glb", PARK_C, 0.0)
	prop(TOWN + "pond.glb", PARK_C + Vector3(0.0, 0.0, -7.0))           # behind the fountain
	prop(TOWN + "gazebo.glb", PARK_C + Vector3(-5.5, 0.0, -3.0), deg_to_rad(30))
	prop(TOWN + "tree_large.glb", PARK_C + Vector3(5.5, 0.0, -3.0))
	for a in 8:   # ring of trees (centred north of the boulevard; skip any on a road)
		var ang: float = float(a) * TAU / 8.0
		var tp: Vector3 = PARK_C + Vector3(sin(ang) * 6.5, 0.0, -3.0 + cos(ang) * 6.5)
		if not _on_road(tp.x, tp.z):
			prop(TOWN + "tree.glb", tp, 0.0)
	for bx in [-3.0, 3.0]:   # benches facing the fountain
		prop(TOWN + "bench.glb", PARK_C + Vector3(bx, 0.0, 3.0), PI)
	for c in [Vector3(-6, 0, 2), Vector3(6, 0, 2), Vector3(-6, 0, -8), Vector3(6, 0, -8)]:
		prop(TOWN + "park_lamp.glb", PARK_C + c)
		prop(TOWN + "flowerbed.glb", PARK_C + c + Vector3(1.2, 0, 0))

# --- foliage scatter on the green areas (never on roads/buildings/park) ------
func _foliage() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x70A11   # deterministic
	# inside the town: fill the green medians + the (now road-free) left/right strips
	var placed := 0
	for _n in 400:
		if placed >= 130:
			break
		var x: float = rng.randf_range(XMIN + 2.0, XMAX - 2.0)
		var z: float = rng.randf_range(ZMIN + 2.0, ZMAX - 2.0)
		if _on_road(x, z) or _near_building(x, z) or _in_park(x, z):
			continue
		var kind: String = ["tree", "tree", "bush", "bush", "flowerbed", "tree_large"][rng.randi() % 6]
		prop(TOWN + kind + ".glb", Vector3(x, 0.0, z), rng.randf() * TAU)
		placed += 1
	_outer_foliage(rng)

# Dense tree/foliage border in the green ring OUTSIDE the town (beyond the boundary).
func _outer_foliage(rng: RandomNumberGenerator) -> void:
	var bands := [
		[-76.0, -56.0, -62.0, 38.0],   # left  (beyond the boulevard ends at ±51)
		[56.0, 76.0, -62.0, 38.0],     # right
		[-76.0, 76.0, -64.0, -54.0],   # back
		[-76.0, 76.0, 28.0, 40.0],     # front
	]
	for b: Array in bands:
		for _n in 60:
			var x: float = rng.randf_range(b[0], b[1])
			var z: float = rng.randf_range(b[2], b[3])
			var kind: String = ["tree", "tree_large", "tree", "bush"][rng.randi() % 4]
			prop(TOWN + kind + ".glb", Vector3(x, 0.0, z), rng.randf() * TAU)

func _on_road(x: float, z: float) -> bool:
	for bz: float in BLVD_Z:
		if absf(z - bz) < 7.0:   # boulevard (±3.5) + its flanking sidewalks
			return true
	for cx: float in CROSS_X:
		if absf(x - cx) < 5.0:
			return true
	return false

func _near_building(x: float, z: float) -> bool:
	for slot: Vector2i in SLOTS:
		var p: Vector3 = _slot_pos(slot)
		if absf(x - p.x) < 9.0 and z < p.z + 9.0 and z > p.z - 11.0:
			return true
	return false

func _in_park(x: float, z: float) -> bool:
	return Vector2(x - PARK_C.x, z - PARK_C.z).length() < 14.0

# --- boundary: invisible walls keep the duo inside the town -------------------
const PLAY_X := 53.0
const PLAY_Z_BACK := -50.0
const PLAY_Z_FRONT := 24.0

func _boundary() -> void:
	var h := 4.0
	var midz: float = (PLAY_Z_BACK + PLAY_Z_FRONT) * 0.5
	var dz: float = PLAY_Z_FRONT - PLAY_Z_BACK + 2.0
	_barrier(Vector3(-PLAY_X, h * 0.5, midz), Vector3(1.0, h, dz))
	_barrier(Vector3(PLAY_X, h * 0.5, midz), Vector3(1.0, h, dz))
	_barrier(Vector3(0, h * 0.5, PLAY_Z_BACK), Vector3(PLAY_X * 2.0 + 2.0, h, 1.0))
	_barrier(Vector3(0, h * 0.5, PLAY_Z_FRONT), Vector3(PLAY_X * 2.0 + 2.0, h, 1.0))

func _barrier(center: Vector3, size: Vector3) -> void:
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new(); bs.size = size
	cs.shape = bs; sb.add_child(cs)
	sb.position = center
	add_child(sb)

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

# --- town NPC quest-givers ---------------------------------------------------
# Place the 12 quest-givers along the avenue edges (offset from building doors).
# Tobias/Agnes only appear once their gating secret has been found.
func _spawn_town_npcs() -> void:
	var i := 0
	for data: Dictionary in QuestData.NPC_DATA + QuestData.NPC_DATA_2:
		var req: Dictionary = data.get("requires_flag", {})
		if not req.is_empty() and not GameManager.get_level_flag(req["location"], req["flag"], false):
			i += 1
			continue
		# cluster the quest-givers across the central park frontage (facing +Z / camera)
		var x: float = -40.0 + float(i) * 7.3
		var z: float = -6.0 if i % 2 == 0 else -14.0
		var pos := Vector3(x, 0.0, z)
		var node := spawn_npc(NPC_MESHES[i % NPC_MESHES.size()], pos, 0.0,
			TOWN_QUIPS, _npc_waypoints(pos, z))
		_npcs.append({"quest_id": data["quest_id"], "name": data["name"], "color": data["color"], "pos": pos, "node": node})
		i += 1

# A small loop along the sidewalk around the NPC's spot (stays off the road, which runs
# z = ±2.5..±5). Kept tight so the quest-giver never strays far from its post.
func _npc_waypoints(pos: Vector3, z: float) -> Array:
	var out: float = 1.2 if z > 0.0 else -1.2   # drift toward the building side, not the road
	return [
		pos,
		pos + Vector3(2.6, 0.0, out * 0.4),
		pos + Vector3(0.4, 0.0, out),
		pos + Vector3(-2.4, 0.0, out * 0.3),
	]

func _nearest_npc() -> Dictionary:
	var pp: Vector3 = player.global_position
	var best := {}
	var best_d := NPC_REACH
	for n in _npcs:
		var np: Vector3 = _npc_pos(n)
		var dist: float = Vector2(pp.x - np.x, pp.z - np.z).length()
		if dist < best_d:
			best_d = dist; best = n
	return best

# The NPC's live position (it wanders), falling back to its spawn pos if freed.
func _npc_pos(n: Dictionary) -> Vector3:
	var node = n["node"]
	return node.global_position if (node != null and is_instance_valid(node)) else n["pos"]

# Halt whichever NPC the player is standing next to (so it waits to be talked to);
# let the rest keep wandering.
func _update_npc_pause(active_node) -> void:
	for n in _npcs:
		var node = n["node"]
		if node != null and is_instance_valid(node):
			node.set("paused", node == active_node and active_node != null)

func _talk_npc(npc: Dictionary) -> void:
	var quest: Dictionary = QuestData.get_quest(npc["quest_id"])
	if quest.is_empty():
		return
	var state: String = GameManager.get_level_flag(QuestData.TOWN_ID, "quest_" + npc["quest_id"], "not_started")
	var tree: Dictionary
	match state:
		"complete":
			tree = quest["after"]
		"active":
			tree = quest["turn_in"] if _find_holder(quest["want_item"]) != "" else quest["reminder"]
		_:
			tree = quest["intro"]
	open_dialog(npc["name"], npc["color"], tree, player.active_name())

func _find_holder(item_id: String) -> String:
	for character_name in GameManager.unlocked_characters:
		if GameManager.has_item(character_name, item_id):
			return character_name
	return ""

# Town quest effects apply against TOWN_ID and the item's actual holder (overrides
# Level3D's location_id-keyed default).
func apply_dialog_effects(effects: Array) -> void:
	for fx in effects:
		if not (fx is Dictionary):
			continue
		var holder: String = player.active_name().to_lower()
		if fx.has("consume_item"):
			var found: String = _find_holder(fx["consume_item"])
			if found != "":
				holder = found
				GameManager.consume_item(holder, fx["consume_item"])
		for item_id: String in fx.get("grant_items", []):
			GameManager.grant_item(holder, item_id)
		if fx.has("set_flag"):
			GameManager.set_level_flag(QuestData.TOWN_ID, fx["set_flag"], fx.get("flag_value", true))

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- interaction -------------------------------------------------------------
func _on_special(_char_name: String) -> void:
	if dialog.is_open():
		return
	var npc := _nearest_npc()
	if not npc.is_empty():
		Audio.play("ui_select")
		_talk_npc(npc)
		return
	var near := _nearest_door()
	if near.is_empty():
		return
	if not _is_unlocked(near["req"]):
		Audio.play("hurt"); return
	if _gate_missing(near["id"]) != "":
		Audio.play("hurt")
		_hud_prompt.text = "%s — %s" % [near["name"], _gate_missing(near["id"])]
		_hud_prompt.add_theme_color_override("font_color", Color(0.85, 0.7, 0.45))
		return
	get_tree().change_scene_to_file(near["scene"])

# Returns the gate hint if this location needs an item nobody is carrying, else "".
func _gate_missing(loc_id: String) -> String:
	if loc_id not in ITEM_GATE:
		return ""
	var gate: Dictionary = ITEM_GATE[loc_id]
	for ch: String in ALL_CHARS:
		if GameManager.has_item(ch, gate["item"]):
			return ""
	return gate["hint"]

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
	if dialog != null and dialog.is_open():
		_hud_prompt.text = ""   # don't show the activation prompt over the dialog box
		return
	var npc := _nearest_npc()
	_update_npc_pause(npc.get("node"))   # the one you're next to holds still to talk
	if not npc.is_empty():
		var state: String = GameManager.get_level_flag(QuestData.TOWN_ID, "quest_" + npc["quest_id"], "not_started")
		var tag: String = "  ✓" if state == "complete" else ("  !" if state == "active" else "")
		_hud_prompt.text = "Talk to %s%s — press G" % [npc["name"], tag]
		_hud_prompt.add_theme_color_override("font_color", UITheme.CREAM)
		return
	var near := _nearest_door()
	if near.is_empty():
		_hud_prompt.text = ""
		return
	var gate_hint: String = _gate_missing(near["id"]) if _is_unlocked(near["req"]) else ""
	if gate_hint != "":
		_hud_prompt.text = "%s — %s" % [near["name"], gate_hint]
		_hud_prompt.add_theme_color_override("font_color", Color(0.85, 0.7, 0.45))
	elif near["id"] in GameManager.completed_locations:
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
