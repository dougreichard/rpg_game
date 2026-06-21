extends Level3D
## Al's Rooftop Garden — the Arcade's interior (reached by entering the "Arcade"
## building once Uncle Doug is found). A combat-free, dusk-lit rooftop jazz club:
## Al (cool jazz musician) greets you, Uncle Doug holds court at a bistro table
## (post-rescue, relaxed), Fred & Ginger sway on the dance floor, and a cabinet
## launches the real game — Gimme Dat Spoon. Stays after all 12 spoons are in,
## but Doug's dialogue flips to a celebratory state. No combat, no overworld slot.

const QUINN := preload("res://data/characters/quinn.tres")
const BEN := preload("res://data/characters/ben.tres")

const REACH := 2.6
const AL_POS := Vector3(0.0, 0.0, -6.0)
const DOUG_POS := Vector3(-7.0, 0.0, 1.0)
const FRED_POS := Vector3(5.4, 0.0, -1.0)
const GINGER_POS := Vector3(7.0, 0.0, -1.0)
const SPOON_POS := Vector3(8.0, 0.0, 4.5)
const EXIT_POS := Vector3(0.0, 0.0, 8.0)

# warm dusk deck + trim
const DECK := Color(0.42, 0.32, 0.24)
const PARAPET := Color(0.30, 0.26, 0.24)
const TRIM := Color(0.85, 0.62, 0.30)

var _al: Node3D = null
var _doug: Node3D = null
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _ready() -> void:
	super._ready()
	# We're reached THROUGH the Arcade building, so a return to the overworld (and a
	# Continue from the title) should resume at the Arcade door, not "als_rooftop".
	GameManager.last_location_id = "gimme_dat_spoon"
	GameManager.last_building_visited = "gimme_dat_spoon"
	SaveManager.save_game()

func _build_level() -> void:
	location_id = "als_rooftop"
	multi_room = false
	walls_visible = false   # rooftop: the parapet is built by hand, no boxed-in walls
	build_env(Color(0.07, 0.06, 0.13), Color(0.55, 0.45, 0.5), 0.7, 0.7)   # dusk sky
	# warm club lighting
	point_light(Vector3(0, 4.5, -6.0), Color(1.0, 0.8, 0.45), 2.6, 12.0)    # stage wash
	point_light(Vector3(-7, 3.2, 1.0), Color(1.0, 0.85, 0.6), 1.8, 8.0)     # Doug's table
	point_light(Vector3(6, 3.2, -1.0), Color(0.9, 0.7, 1.0), 1.6, 8.0)      # dance floor
	point_light(Vector3(8, 3.0, 4.5), Color(0.5, 0.9, 1.0), 1.6, 6.0)       # cabinet glow
	_deck()
	_garden()
	_stage()
	_tables()
	_string_lights()
	_spoon_cabinet()
	make_dialog()
	_build_hud()
	# NPCs — Al (host), Doug (seated), Fred & Ginger (a dancing pair facing each other)
	_al = spawn_npc("bellows", AL_POS, 0.0, ["A-one, a-two...", "Welcome to the rooftop, cats.", "Smoooth.", "♪ doo-bee-doo ♪"])
	_doug = spawn_npc("uncle_doug", DOUG_POS, 0.0, [], [], "sit")
	spawn_npc("fred", FRED_POS, PI / 2.0, [])      # Fred — tux + top hat, faces Ginger (+X)
	spawn_npc("ginger", GINGER_POS, -PI / 2.0, [])  # Ginger — red dress + red hair, faces Fred (-X)
	add_exit_portal(EXIT_POS + Vector3(0, 0, 1.5), Vector3(3, 3, 1.4))
	var p := spawn_duo([QUINN, BEN], EXIT_POS + Vector3(0.0, 0.1, -1.5))
	p.special_used.connect(_on_special)
	build_ui_stack(true)
	Audio.play_music("jazz")
	GameManager.spoon_arcade_entered.emit()   # found the "hidden arcade" — Al's place

# --- geometry ----------------------------------------------------------------
func _deck() -> void:
	floor_box(26, 20, DECK)
	# low parapet around the edge (gap at the south for the exit)
	var h := 1.1
	add_child(box_mesh(Vector3(26, h, 0.4), PARAPET, Vector3(0, h * 0.5, -10.0)))   # north
	add_child(box_mesh(Vector3(0.4, h, 20), PARAPET, Vector3(-13.0, h * 0.5, 0)))   # west
	add_child(box_mesh(Vector3(0.4, h, 20), PARAPET, Vector3(13.0, h * 0.5, 0)))    # east
	add_child(box_mesh(Vector3(9, h, 0.4), PARAPET, Vector3(-8.5, h * 0.5, 10.0)))  # south-left
	add_child(box_mesh(Vector3(9, h, 0.4), PARAPET, Vector3(8.5, h * 0.5, 10.0)))   # south-right

func _garden() -> void:
	# potted greenery + flower beds along the parapet; a couple of small trees in corners
	for spot: Array in [[-12.0, -8.0], [12.0, -8.0], [-12.0, 7.0], [12.0, 7.0]]:
		prop("res://assets/models/town/tree.glb", Vector3(spot[0], 0, spot[1]), 0.0, 0.8)
	for spot: Array in [[-10.0, -9.0], [-4.0, -9.2], [4.0, -9.2], [10.0, -9.0], [-12.2, -2.0], [12.2, -2.0], [-12.2, 3.0], [12.2, 3.0]]:
		prop("res://assets/models/town/flowerbed.glb", Vector3(spot[0], 0, spot[1]), 0.0)
	for spot: Array in [[-9.0, -8.5], [9.0, -8.5], [-11.5, 5.0], [11.5, 5.0]]:
		prop("res://assets/models/town/planter.glb", Vector3(spot[0], 0, spot[1]), 0.0)
	prop("res://assets/models/town/gazebo.glb", Vector3(-10.0, 0, -6.0), deg_to_rad(30))   # corner bar gazebo

func _stage() -> void:
	# small raised stage for Al at the north end
	add_child(box_mesh(Vector3(7.0, 0.35, 3.0), Color(0.22, 0.18, 0.2), Vector3(0, 0.18, -7.0)))
	add_child(box_mesh(Vector3(7.2, 0.12, 3.2), TRIM, Vector3(0, 0.4, -7.0), 0.4))   # lit stage lip
	# a backdrop band shell
	add_child(box_mesh(Vector3(7.0, 3.0, 0.3), Color(0.15, 0.13, 0.16), Vector3(0, 1.5, -8.3)))

func _tables() -> void:
	# bistro tables (Doug's + a couple of empties), reuse picnic tables + seats
	prop("res://assets/models/town/picnic_table.glb", Vector3(-7.0, 0, 0.0), 0.0, 0.8)   # Doug's table
	prop("res://assets/models/town/picnic_table.glb", Vector3(-3.0, 0, 5.0), deg_to_rad(20), 0.8)
	prop("res://assets/models/town/picnic_table.glb", Vector3(2.0, 0, 6.0), deg_to_rad(-15), 0.8)

func _string_lights() -> void:
	# warm fairy lights strung along the north parapet + lamp posts
	for i in 9:
		var x := -11.0 + float(i) * 2.75
		add_child(box_mesh(Vector3(0.18, 0.18, 0.18), Color(1.0, 0.85, 0.5), Vector3(x, 2.4, -9.9), 1.0))
	prop("res://assets/models/town/park_lamp.glb", Vector3(-11.5, 0, -1.0), 0.0)
	prop("res://assets/models/town/park_lamp.glb", Vector3(11.5, 0, -1.0), 0.0)

func _spoon_cabinet() -> void:
	# the cabinet that launches Gimme Dat Spoon (keeps its name a surprise — labelled "PLAY")
	add_child(box_mesh(Vector3(1.2, 2.0, 1.0), Color(0.15, 0.12, 0.2), SPOON_POS + Vector3(0, 1.0, 0)))
	add_child(box_mesh(Vector3(1.0, 0.7, 0.1), Color(0.4, 0.9, 1.0), SPOON_POS + Vector3(0, 1.4, 0.5), 0.9))  # glowing screen
	var lbl := Label3D.new()
	lbl.text = "▶ PLAY"
	lbl.font = UITheme.font(); lbl.font_size = 40; lbl.outline_size = 14
	lbl.modulate = UITheme.CREAM; lbl.outline_modulate = Color(0, 0, 0, 0.95)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED; lbl.no_depth_test = true
	lbl.fixed_size = true; lbl.pixel_size = 0.0012
	lbl.position = SPOON_POS + Vector3(0, 2.5, 0)
	add_child(lbl)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	var pp: Vector3 = player.global_position
	if near3(pp, AL_POS, REACH): _talk_al(char_name); return
	if near3(pp, DOUG_POS, REACH): _talk_doug(char_name); return
	if near3(pp, SPOON_POS, REACH): _enter_spoon(); return

func _talk_al(char_name: String) -> void:
	GameManager.set_level_flag(location_id, "al_met", true)
	open_dialog("Al", Color(0.4, 0.3, 0.45), {"start": {"lines": [
		"\"Heyyy. Al's the name — jazz is the game. Welcome to the rooftop.\"",
		"\"Your uncle's been holdin' court at that table. Go on, say hi.\"",
		"\"And that cabinet over there? Little number called Gimme Dat Spoon. Round up all twelve spoons from the folks in town and you'll really shine, dig?\""]}}, char_name)

func _talk_doug(char_name: String) -> void:
	GameManager.set_level_flag(location_id, "doug_talked", true)
	var tree: Dictionary
	if _spoons_held() >= 12:
		tree = {"start": {"lines": [
			"\"All twelve spoons! HA! You magnificent thing.\"",
			"\"Pull up a chair — the search is over, the band's swingin', and your uncle's buyin'.\"",
			"\"Couldn't be prouder of the whole crew.\""]}}
	else:
		var done: int = GameManager.completed_locations.size()
		tree = {"start": {"lines": [
			"\"There you are! You actually did it — pulled the family back together.\"",
			"\"Quinn, Erin, Evan, Ben, Ethan... and you. %d places turned upside down to find me.\"" % done,
			"\"There's a daft little tradition up here: twelve numbered spoons, one from each of the town folk. Round 'em all up and Al lets you play for real.\"",
			"\"Go on. Find the spoons. I'll be right here — finally relaxing.\""]}}
	open_dialog("Uncle Doug", Color(0.55, 0.45, 0.35), tree, char_name)

func _enter_spoon() -> void:
	get_tree().change_scene_to_file("res://scenes/3d/Spoon3D.tscn")

func _spoons_held() -> int:
	var n := 0
	for i in range(1, 13):
		var id := "numbered_spoon_%02d" % i
		for ch: String in GameManager.unlocked_characters:
			if GameManager.has_item(ch, id):
				n += 1
				break
	return n

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD ---------------------------------------------------------------------
func _build_hud() -> void:
	build_default_hud()
	_hud_goal = hud_goal; _hud_hint = hud_toast; _hud_banner = hud_ribbon
	_hud_goal.text = "Al's Rooftop Garden\nTalk to Al & Uncle Doug · ▶ PLAY at the cabinet"

func _process(d: float) -> void:
	super._process(d)
	var pp: Vector3 = player.global_position if player != null else Vector3.ZERO
	if near3(pp, SPOON_POS, REACH):
		_hud_hint.text = "Gimme Dat Spoon — press G to play"
	elif near3(pp, AL_POS, REACH):
		_hud_hint.text = "Talk to Al — press G"
	elif near3(pp, DOUG_POS, REACH):
		_hud_hint.text = "Talk to Uncle Doug — press G"
