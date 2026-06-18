extends Level3D
## The Carnival & Fairground (3D) — Quinn + Erin. Multi-room: a combat-free ENTRANCE
## PLAZA (barker Pearl + exit), the MIDWAY (Grunts ×2 + Brute; carousel + photo booth),
## the BACKSTAGE behind Marco's curtain gate (Doug's poster — the lead), and a side
## FUNHOUSE (a lever-sequence prize vault → a library card). Quinn re-belts the carousel
## and fixes the photo booth; Erin talks down Marco (or a backstage pass). Dirt/bright-
## wood surfaces, candy-red trim. Win: midway cleared + ride repaired + backstage opened.

const QUINN := preload("res://data/characters/quinn.tres")
const ERIN := preload("res://data/characters/erin.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const BRUTE := preload("res://data/enemies/brute.tres")
const BackstagePassItem: ItemData = preload("res://data/items/backstage_pass.tres")
const LibraryCardItem: ItemData = preload("res://data/items/library_card.tres")
const PhotoStripItem: ItemData = preload("res://data/items/doug_photo_strip.tres")
const TicketStubItem: ItemData = preload("res://data/items/ticket_stub_torn.tres")

# --- thematic surfaces (dirt / bright wood / candy-red trim) ---
const FLOOR_DIRT := "res://assets/art/tiles/synty_floor_dirt.png"
const FLOOR_GROUND := "res://assets/art/tiles/synty_ground.png"
const WALL_WOOD := "res://assets/art/tiles/synty_wall_wood.png"
const FT_MID := Color(0.85, 0.72, 0.55)
const WT_MID := Color(0.86, 0.5, 0.55)
const FT_PLAZA := Color(0.82, 0.74, 0.6)
const FT_BACK := Color(0.6, 0.5, 0.55)
const WT_BACK := Color(0.55, 0.3, 0.4)
const CORNER_COL := Color(0.85, 0.18, 0.22)   # solid candy-red trim

const WALL_H := 3.4
const REACH := 2.4

# Expanded fairground: midway at origin (24x20), plaza/backstage/funhouse pushed out and
# joined by long stall-lined midway lanes (the old 1-2m stubs are now 4.5-7m).
const PLAZA_C := Vector3(0, 0, 22.0)
const PEARL_POS := Vector3(3.5, 0, 23.5)
const RIDE_POS := Vector3(-3.5, 0.0, 0.0)
const PHOTO_POS := Vector3(5.0, 0.0, 3.0)
const MARCO_POS := Vector3(0.0, 0.0, -12.0)
const GATE_POS := Vector3(0.0, 0.0, -14.0)
const BACK_C := Vector3(0, 0, -22.0)
const POSTER_POS := Vector3(0.0, 0.0, -25.5)
const FUN_C := Vector3(-21.0, 0, 0.0)
const FUN_LEVERS := [Vector3(-21.0, 0, -2.0), Vector3(-21.0, 0, 0.0), Vector3(-21.0, 0, 2.0)]
const FUN_VAULT := Vector3(-23.0, 0, 0.0)
const SIDE_C := Vector3(22.0, 0, 0.0)             # Sideshow Alley (east of the midway)
const POWER_POS := Vector3(10.0, 0.0, -8.0)       # midway power box — Quinn lights up the fair
const FORTUNE_POS := Vector3(20.0, 0.0, 3.0)      # fortune wagon — Erin fast-talks
const GAME_POS := Vector3(24.0, 0.0, -3.0)        # rigged ring-toss stall — Erin

const RIDE_COLORS := [Color(0.9, 0.3, 0.3), Color(0.95, 0.8, 0.3), Color(0.3, 0.7, 0.9), Color(0.5, 0.85, 0.4)]

var _cleared := false
var _enemies_cleared := false
var _ride_repaired := false
var _backstage_talked := false
var _photo_taken := false
var _power_on := false
var _fortune_done := false
var _game_done := false
var _lights: Array = []
var _fun_seq: Array = []
var _fun_open := false
var _spawned := 0
var _marco = null
var _pearl = null
var _carousel: Node3D = null
var _gate: Node3D = null
var _fun_lights: Array = []
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "carnival"
	multi_room = true
	build_env(Color(0.05, 0.04, 0.08), Color(0.55, 0.45, 0.55), 0.6, 0.9)
	point_light(RIDE_POS + Vector3(0, 3.4, 0), Color(1.0, 0.7, 0.8), 2.4, 9.0)
	point_light(PLAZA_C + Vector3(0, 3.0, 0), Color(0.7, 0.8, 1.0), 1.9, 11.0)
	point_light(BACK_C + Vector3(0, 2.8, 0), Color(0.9, 0.5, 0.6), 1.6, 9.0)
	point_light(FUN_C + Vector3(0, 2.6, 0), Color(0.6, 0.9, 0.7), 1.4, 7.0)
	_ground()
	_rooms()
	_tree_ring()
	_carousel_ride()
	_photo_booth()
	_string_lights()
	_stalls()
	_sideshow()
	_funhouse()
	_backstage()
	make_dialog()
	_build_hud()
	prop("res://assets/models/props/ticket_booth.glb", Vector3(-5.0, 0, 24.5), PI)  # plaza ticket kiosk (Prop Farm)
	_carnival_crowd()
	_marco = spawn_npc("bellows", MARCO_POS, PI)     # burly gatekeeper
	_pearl = spawn_npc("congregant_f", PEARL_POS, PI) # plaza barker
	add_exit_portal(PLAZA_C + Vector3(0, 0, 5.0), Vector3(3, 3, 1.4))
	var p := spawn_duo([QUINN, ERIN], PLAZA_C + Vector3(0.0, 0.1, 1.0))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

# A grassy ground plane under the whole fairground footprint (the carnival sits in a park
# clearing) so the area outside the rooms reads as grass, not void.
func _ground() -> void:
	# top at y=-0.1, clearly BELOW the room floors (top y=0) so the two never z-fight.
	add_child(box_mesh(Vector3(76, 0.5, 78), Color(0.5, 0.55, 0.38), Vector3(-4, -0.35, 0.5)))

# A tree/bush border around the fairground perimeter (taller trees peek over the walls for an
# enclosed-park backdrop). Deterministic RNG so it's stable across runs.
func _tree_ring() -> void:
	var town := "res://assets/models/town/"
	var rng := RandomNumberGenerator.new(); rng.seed = 8181
	var kinds := ["tree", "tree", "tree_large", "bush"]
	var z := -32.0
	while z <= 33.0:                                    # east + west borders
		for sx: float in [-30.0, 16.0]:
			# Sideshow Alley pushes east to x~28 around z0 — skip east-ring trees in that band
			# (they'd land in the room) and back the alley further out instead
			if sx > 0 and z > -8.0 and z < 8.0:
				continue
			prop(town + kinds[rng.randi() % kinds.size()] + ".glb",
				Vector3(sx + rng.randf_range(-1.4, 1.4), -0.1, z + rng.randf_range(-1.2, 1.2)), rng.randf() * TAU)
		z += rng.randf_range(2.6, 3.6)
	# back the Sideshow Alley with a tree line just east of its wall (x28)
	var az := -7.0
	while az <= 7.0:
		prop(town + kinds[rng.randi() % kinds.size()] + ".glb",
			Vector3(30.0 + rng.randf_range(-0.8, 0.8), -0.1, az + rng.randf_range(-0.8, 0.8)), rng.randf() * TAU)
		az += rng.randf_range(2.6, 3.4)
	for sz: float in [-32.0, 33.0]:                     # north + south caps
		var x := -30.0
		while x <= 16.0:
			prop(town + kinds[rng.randi() % kinds.size()] + ".glb",
				Vector3(x + rng.randf_range(-1.0, 1.0), -0.1, sz + rng.randf_range(-1.0, 1.0)), rng.randf() * TAU)
			x += rng.randf_range(2.6, 3.6)

func _rooms() -> void:
	# Midway — dirt floor, bright wood walls. Combat. Openings: south (plaza), north
	# (backstage), west (funhouse). Long stall-lined lanes join the outer rooms.
	set_theme(FLOOR_DIRT, WALL_WOOD)
	room(Vector3.ZERO, 24, 20, FT_MID, WT_MID, WALL_H, ["s", "n", "w", "e"], 4.0, true)
	corridor(Vector3(0, 0, 10), "s", 6.0, FT_MID, WT_MID, 4.0, WALL_H, true, CORNER_COL)        # → plaza
	corridor(Vector3(0, 0, -10), "n", 7.0, FT_MID, WT_MID, 4.0, WALL_H, true, CORNER_COL)       # → backstage
	corridor(Vector3(-12, 0, 0), "w", 4.5, FT_MID, WT_MID, 4.0, WALL_H, true, CORNER_COL)       # → funhouse
	corridor(Vector3(12, 0, 0), "e", 4.0, FT_MID, WT_MID, 4.0, WALL_H, true, CORNER_COL)        # → sideshow alley
	# Sideshow Alley — a side plaza off the east of the midway (fortune wagon + rigged game).
	set_theme(FLOOR_GROUND, WALL_WOOD)
	room(SIDE_C, 12, 12, FT_PLAZA, WT_MID, 3.2, ["w"], 4.0, true)
	_gate = _backstage_gate()
	# Plaza — ground floor, wood walls (combat-free). South vestibule = exit.
	set_theme(FLOOR_GROUND, WALL_WOOD)
	room(PLAZA_C, 16, 12, FT_PLAZA, WT_MID, 3.2, ["n", "s"], 4.0, true)
	corridor(PLAZA_C + Vector3(0, 0, 6.0), "s", 2.0, FT_PLAZA, WT_MID, 4.0, 3.2, true, CORNER_COL)
	# Backstage — dim, behind the curtain gate.
	set_theme(FLOOR_DIRT, WALL_WOOD)
	room(BACK_C, 14, 10, FT_BACK, WT_BACK, 3.2, ["s"], 4.0, true)
	# Funhouse — the lever-sequence prize room.
	room(FUN_C, 9, 10, FT_MID, WT_MID, 3.0, ["e"], 4.0, true)

# Marco's curtain gate (between midway and backstage), opened by Erin / a backstage pass.
func _backstage_gate() -> Node3D:
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(4.0, 2.8, 0.3); cs.shape = bs; cs.position = Vector3(0, 1.4, 0)
	sb.add_child(cs); sb.add_child(box_mesh(Vector3(4.0, 2.8, 0.3), Color(0.5, 0.1, 0.15), Vector3(0, 1.4, 0)))
	sb.position = GATE_POS
	add_child(sb)
	return sb

func _carousel_ride() -> void:
	# Generated Synty-style carousel (Prop Farm, painted) parented to a spin node so the whole
	# ride turns once Quinn re-belts it (see _process). Collision stays primitive (none needed —
	# it's a ride you stand near, not on); RIDE_POS proximity drives the repair.
	_carousel = Node3D.new()
	_carousel.position = RIDE_POS
	add_child(_carousel)
	var c: Node3D = load("res://assets/models/props/carousel.glb").instantiate()
	_carousel.add_child(c)

func _photo_booth() -> void:
	prop("res://assets/models/props/photo_booth.glb", PHOTO_POS, PI)   # generated booth (Prop Farm)

func _string_lights() -> void:
	# two strands of bulbs strung across the wider midway (north + south halves). Start DARK —
	# they blaze on once Quinn powers the box (see _set_power_lights).
	for strand_z: float in [7.5, -7.5]:
		for i: int in range(14):
			var t: float = float(i) / 13.0
			var x: float = lerp(-11.0, 11.0, t)
			var y: float = 2.8 + 0.6 * sin(t * PI)
			var bulb := box_mesh(Vector3(0.12, 0.12, 0.12), RIDE_COLORS[i % RIDE_COLORS.size()], Vector3(x, y, strand_z), 0.0)
			add_child(bulb); _lights.append(bulb)

func _set_power_lights(on: bool) -> void:
	for bulb in _lights:
		var m := ((bulb as MeshInstance3D).mesh as BoxMesh).material as StandardMaterial3D
		m.emission_enabled = on
		if on:
			m.emission = m.albedo_color; m.emission_energy_multiplier = 2.0

# Sideshow Alley dressing: Erin's fortune wagon + a rigged ring-toss game stall, plus a power
# box on the midway that Quinn fixes to light the whole fair (and power the carousel).
func _sideshow() -> void:
	prop("res://assets/models/town/power_box.glb", POWER_POS, deg_to_rad(-90))           # Quinn's power box (midway)
	prop("res://assets/models/town/fortune_wagon.glb", FORTUNE_POS + Vector3(0, 0, 1.0), -PI * 0.5)  # Erin's fortune wagon
	prop("res://assets/models/town/fairstall.glb", GAME_POS + Vector3(0, 0, -1.0), 0.0, 0.7)         # rigged game stall
	_floating_label("?", FORTUNE_POS + Vector3(0, 2.6, 0), Color(0.8, 0.6, 1.0))
	_floating_label("PRIZES", GAME_POS + Vector3(0, 2.2, 0), Color(1.0, 0.8, 0.4))

func _stalls() -> void:
	# canopied vendor stalls (baked Synty fairstall) lining the midway + plaza perimeter,
	# facing inward — clear of the carousel(-3.5,0), photo(5,3), enemy spots and the lanes.
	var fs := "res://assets/models/town/fairstall.glb"
	for s: Array in [
		[-9.5, -7.0, 0.0], [9.5, -6.5, PI], [10.0, 5.0, PI * 0.5], [-10.0, 4.5, -PI * 0.5],  # midway
		[-6.0, 18.5, 0.0], [6.0, 18.5, 0.0],                                                  # plaza concessions
	]:
		prop(fs, Vector3(s[0], 0, s[1]), float(s[2]), 0.7)

func _funhouse() -> void:
	# clown-face entrance facade (Prop Farm) at the funhouse's east doorway, facing the midway
	prop("res://assets/models/props/funhouse_facade.glb", Vector3(-16.3, 0, 0), -PI * 0.5)
	for i: int in range(FUN_LEVERS.size()):
		add_child(box_mesh(Vector3(0.2, 0.8, 0.2), Color(0.3, 0.3, 0.34), FUN_LEVERS[i] + Vector3(0, 0.9, 0)))
		var glow := box_mesh(Vector3(0.12, 0.4, 0.12), Color(0.9, 0.3, 0.3), FUN_LEVERS[i] + Vector3(0, 1.3, 0), 1.5)
		add_child(glow)
		_fun_lights.append(glow)
		_floating_label(str(i + 1), FUN_LEVERS[i] + Vector3(0, 1.7, 0), Color(1.0, 0.8, 0.4))
	add_child(box_mesh(Vector3(0.8, 1.2, 0.8), Color(0.5, 0.4, 0.2), FUN_VAULT + Vector3(0, 0.6, 0)))

func _backstage() -> void:
	add_child(box_mesh(Vector3(1.4, 1.8, 0.1), Color(0.85, 0.8, 0.6), POSTER_POS + Vector3(0, 1.8, 0), 0.3))  # Doug poster

# Carnival-goers waiting out the trouble in the safe plaza + sideshow (the roughnecks cleared the
# midway, per Pearl). Animated Synty Kids (distinct meshes) + an adult chaperone, with bubbles.
const KID_QUIPS := [
	"I wanna ride the carousel!", "Cotton candy! Cotton candy!", "Is the funhouse open yet?",
	"Win me a prize!", "When can we go on the rides?", "Those big kids took the midway...",
]
const ADULT_QUIPS := [
	"Stay close -- the midway's not safe yet.", "We'll ride once they clear those toughs out.",
	"Hold my hand in the crowd.", "Two tickets, please.",
]
func _carnival_crowd() -> void:
	# plaza families (combat-free entrance)
	spawn_npc("kid_casual", Vector3(2.0, 0, 18.5), 0.0, KID_QUIPS)   # excited, facing the midway (north)
	spawn_npc("kid_adventure", Vector3(5.0, 0, 20.0), 0.0, KID_QUIPS, [
		Vector3(5.0, 0, 20.0), Vector3(7.0, 0, 25.0), Vector3(4.0, 0, 26.0), Vector3(3.0, 0, 21.0),
	])
	spawn_npc("kid_dress", Vector3(-6.0, 0, 18.5), 0.0, KID_QUIPS, [
		Vector3(-6.0, 0, 18.5), Vector3(-3.0, 0, 18.5), Vector3(-2.5, 0, 20.5), Vector3(-6.5, 0, 20.5),
	])
	spawn_npc("congregant_m", Vector3(3.0, 0, 20.0), PI, ADULT_QUIPS, [
		Vector3(3.0, 0, 20.0), Vector3(5.0, 0, 21.0), Vector3(4.0, 0, 18.5), Vector3(1.5, 0, 19.5),
	])
	# a kid hanging around the sideshow games
	spawn_npc("kid_explorer", Vector3(24.0, 0, 1.5), 0.0, KID_QUIPS, [
		Vector3(24.0, 0, 1.5), Vector3(26.0, 0, 3.0), Vector3(25.5, 0, -1.0), Vector3(23.0, 0, 0.5),
	])

func _floating_label(txt: String, pos: Vector3, col: Color) -> void:
	var l := Label3D.new()
	l.text = txt; l.font = UITheme.font(); l.font_size = 40; l.outline_size = 12
	l.modulate = col; l.outline_modulate = Color(0, 0, 0, 0.95)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.no_depth_test = true
	l.fixed_size = true; l.pixel_size = 0.001; l.position = pos
	add_child(l)

func _spawn_enemies() -> void:
	for spot: Vector3 in [Vector3(-1.5, 0.1, 2.0), Vector3(2.0, 0.1, 1.0)]:
		spawn_enemy(GRUNT, spot, "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(BRUTE, Vector3(0.0, 0.1, -1.5), "res://assets/models/enemies/grunt.glb", 1.45, Color(0.7, 0.55, 0.6)); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_ride_repaired = GameManager.get_level_flag(location_id, "ride_repaired", false)
	_backstage_talked = GameManager.get_level_flag(location_id, "backstage_talked", false)
	_photo_taken = GameManager.get_level_flag(location_id, "photo_taken", false)
	_power_on = GameManager.get_level_flag(location_id, "power_on", false)
	_fortune_done = GameManager.get_level_flag(location_id, "fortune_done", false)
	_game_done = GameManager.get_level_flag(location_id, "game_done", false)
	_fun_open = GameManager.get_level_flag(location_id, "fun_open", false)
	if _power_on: _set_power_lights(true)
	if _backstage_talked: _open_gate(false)
	if _fun_open:
		for f in _fun_lights: f.visible = true
	if _enemies_cleared and _ride_repaired and _backstage_talked:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, PEARL_POS, REACH + 0.6):
		_talk_pearl(char_name); return
	if near3(pp, MARCO_POS, REACH):
		_talk_marco(char_name); return
	# power box (Quinn) — lights the fair + powers the rides
	if not _power_on and near3(pp, POWER_POS, REACH):
		if char_name == "Quinn":
			_power_on = true
			GameManager.set_level_flag(location_id, "power_on", true)
			_set_power_lights(true)
			_hud_hint.text = "Quinn re-wires the junction box — the whole midway blazes to life with light."
			Audio.play("special")
		else:
			_hud_hint.text = "The power box is dead — Quinn could rewire it."
		return
	# fortune wagon (Erin) — fast-talk the fortune teller
	if not _fortune_done and near3(pp, FORTUNE_POS, REACH + 0.6):
		_talk_fortune(char_name); return
	# rigged ring-toss stall (Erin) — call out the rig for a "prize"
	if not _game_done and near3(pp, GAME_POS, REACH):
		_play_game(char_name); return
	# carousel (Quinn) — needs power first, then a re-belt
	if not _ride_repaired and near3(pp, RIDE_POS, REACH + 1.0):
		if char_name != "Quinn":
			_hud_hint.text = "The ride's motor needs Quinn's tools."
		elif not _power_on:
			_hud_hint.text = "The carousel's dead — no power. Find the midway power box (Quinn)."
		else:
			_ride_repaired = true
			GameManager.set_level_flag(location_id, "ride_repaired", true)
			_hud_hint.text = "Quinn re-belts the motor and winds the band-organ — the carousel spins to life."
			Audio.play("special")
		return
	# photo booth (Quinn → Doug strip)
	if not _photo_taken and near3(pp, PHOTO_POS, REACH):
		if char_name == "Quinn":
			_fix_photo(char_name)
		else:
			_hud_hint.text = "The photo booth's jammed — Quinn could coax a print out of it."
		return
	# funhouse lever sequence (optional → library card)
	if not _fun_open:
		for i: int in range(FUN_LEVERS.size()):
			if near3(pp, FUN_LEVERS[i], REACH):
				_try_lever(char_name, i); return

func _talk_pearl(char_name: String) -> void:
	var tree := {"start": {"lines": [
		"A carnival barker leans out of the ticket booth, all teeth and sequins.",
		"Pearl: \"Step right up! Bad news first -- some roughnecks took over the midway and cut my power. Whole fair's gone dark.\"",
		"\"Quinn, sugar, you look handy -- get the power box going, then my carousel and the photo booth. Erin, sweet-talk Marco at the curtain.\"",
		"\"Side alley's got Madame Esme and the ring toss if you've a minute. And the funhouse? Pull the levers in order -- folks always forget it.\""]}}
	GameManager.set_level_flag(location_id, "pearl_met", true)
	open_dialog("Pearl", Color(0.7, 0.5, 0.6), tree, char_name)

func _fix_photo(char_name: String) -> void:
	_photo_taken = true
	GameManager.set_level_flag(location_id, "photo_taken", true)
	GameManager.grant_item(char_name, PhotoStripItem.id)
	open_dialog("Photo Booth", Color(0.4, 0.35, 0.55),
		{"start": {"lines": [
			"Quinn clears the jam and the booth coughs up a forgotten strip of photos.",
			"Four frames: Uncle Doug, grinning, holding a ticket stub -- \"GRAND MARQUEE, opening night.\"",
			"Picked up: Photo-Booth Strip."]}}, char_name)
	Audio.play("special")

# Erin fast-talks the fortune teller → a Doug clue (lore) + a backstage pass (alt route past Marco).
func _talk_fortune(char_name: String) -> void:
	if char_name != "Erin":
		_hud_hint.text = "The fortune teller only deals in 'destiny' — Erin could play along."
		return
	_fortune_done = true
	GameManager.set_level_flag(location_id, "fortune_done", true)
	GameManager.grant_item("Erin", BackstagePassItem.id)
	open_dialog("Madame Esme", Color(0.6, 0.4, 0.7),
		{"start": {"lines": [
			"Erin: \"Read mine. And don't skimp -- I'll know.\" The teller's eyes narrow, then she grins.",
			"Esme: \"A man came through... asked the same of me. Said he was bound for a picture palace -- the Grand Marquee.\"",
			"\"For a performer like you? Take this -- a backstage pass. Esme always tips her own.\"",
			"Picked up: Backstage Pass. (Marco's gate can be skipped now.)"]}}, char_name)
	Audio.play("special")

# Erin calls out the rigged ring-toss → a "prize" that's a worthless torn ticket stub (comedy).
func _play_game(char_name: String) -> void:
	if char_name != "Erin":
		_hud_hint.text = "The ring-toss looks rigged. Erin might talk the barker into a fair throw."
		return
	_game_done = true
	GameManager.set_level_flag(location_id, "game_done", true)
	GameManager.grant_item("Erin", TicketStubItem.id)
	open_dialog("Ring Toss", Color(0.9, 0.6, 0.3),
		{"start": {"lines": [
			"Erin leans in: \"Those pegs are shaved. Give me a fair set or I start telling the crowd.\"",
			"The barker sweats, swaps the rings, and -- ting ting ting -- she clears the board.",
			"\"Grand prize!\" he announces, handing over... a torn ticket stub. Erin squints. \"This isn't even ours.\"",
			"Picked up: Torn Ticket Stub. (Looks like a Marquee ticket. It is not.)"]}}, char_name)
	Audio.play("special")

func _try_lever(char_name: String, i: int) -> void:
	if _fun_lights[i].visible:
		return
	if i == _fun_seq.size():
		_fun_seq.append(i)
		_fun_lights[i].visible = true
		Audio.play("special")
		if _fun_seq.size() == FUN_LEVERS.size():
			_fun_open = true
			GameManager.set_level_flag(location_id, "fun_open", true)
			GameManager.grant_item(char_name, LibraryCardItem.id)
			_hud_hint.text = "The prize cage pops open — among the junk, a real library card. (Found Library Card)"
		else:
			_hud_hint.text = "Lever %d set. Pull them 1, 2, 3." % (i + 1)
	else:
		_fun_seq.clear()
		for f in _fun_lights: f.visible = false
		_hud_hint.text = "A buzzer blares — wrong order. The levers reset."

func _talk_marco(char_name: String) -> void:
	if _backstage_talked:
		open_dialog("Marco", Color(0.4, 0.35, 0.3),
			{"start": {"lines": ["\"All right, you're professionals. You can stay.\"", "\"Whatever that poster means to you, I hope you find him.\""]}}, char_name)
		return
	var has_pass := GameManager.has_item("Quinn", BackstagePassItem.id) or GameManager.has_item("Erin", BackstagePassItem.id)
	if has_pass:
		_backstage_talked = true
		GameManager.set_level_flag(location_id, "backstage_talked", true)
		_open_gate(true)
		open_dialog("Marco", Color(0.4, 0.35, 0.3),
			{"start": {"lines": ["You show a backstage pass. Marco waves you through. \"Should've led with that.\""]}}, char_name)
		return
	var tree := {
		"start": {
			"lines": ["\"Backstage is for performers only. You two don't look like performers.\""],
			"choices": [
				{"text": "\"We're totally in the show.\" (Erin fast-talks)", "best_with": "Erin",
					"next": "erin_wins", "next_alt": "blunt_fail"},
				{"text": "\"We need to get backstage. Now.\"", "next": "blunt_fail"}]},
		"erin_wins": {
			"lines": [
				"Erin: \"Look, I'm totally in the show -- Quinn here is my roadie.\"",
				"Marco squints... then his shoulders drop. \"...Roadie. Sure. Don't touch the rigging.\""],
			"effects": {"set_flag": "backstage_talked", "flag_value": true}},
		"blunt_fail": {
			"lines": [
				"Marco crosses his arms. \"Come back with credentials. Both of you.\"",
				"He's not moving. Erin would have to do the talking."],
			"effects": {"set_flag": "marco_impression", "flag_value": "talked"}},
	}
	open_dialog("Marco", Color(0.4, 0.35, 0.3), tree, char_name)

func _open_gate(animate: bool) -> void:
	(_gate as StaticBody3D).collision_layer = 0
	if animate:
		create_tween().tween_property(_gate, "position:y", -3.0, 0.6)
	else:
		_gate.position.y = -3.0

func _on_dialog_closed_default(effects: Array) -> void:
	super._on_dialog_closed_default(effects)
	if not _backstage_talked and GameManager.get_level_flag(location_id, "backstage_talked", false):
		_backstage_talked = true
		_open_gate(true)

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
	if _ride_repaired and _carousel != null:
		_carousel.rotation.y += d * 0.6
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
	if not _cleared:
		var bits := []
		bits.append("midway " + ("OK" if _enemies_cleared else "..."))
		bits.append("ride " + ("OK" if _ride_repaired else "..."))
		bits.append("backstage " + ("OK" if _backstage_talked else "..."))
		_hud_goal.text = "Clear the midway; Quinn fixes the ride, Erin talks past Marco. (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
	if not _cleared and _enemies_cleared and _ride_repaired and _backstage_talked:
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "CARNIVAL CLEARED!\nThe poster points the way."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
