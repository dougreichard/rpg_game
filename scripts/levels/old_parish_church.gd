extends Node2D

const LOCATION_ID: String = "old_parish_church"

# Tile-mapped floor palette — cool stone with warm candlelight flecks (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.30, 0.32, 0.36)
const FLOOR_ACCENT_COLOR: Color = Color(0.55, 0.50, 0.40)
const FLOOR_COLS: int = 25
const FLOOR_ROWS: int = 21
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

const GATE_RADIUS: float = 64.0
const QUINN_GATE_POS := Vector2(260.0, 300.0)
const ERIN_GATE_POS  := Vector2(700.0, 300.0)

# Collectibles: Quinn's movie ticket (needed for the Cinema finale) and a lore
# photograph — see CLAUDE.md "Collectibles & Inventory". Both sit in the
# vestibule so the duo finds them on the way in or out.
const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const TicketQuinnItem: ItemData = preload("res://data/items/ticket_quinn.tres")
const FadedPhotoItem: ItemData = preload("res://data/items/faded_photograph.tres")
const TICKET_LOOT_POS := Vector2(280.0, 520.0)
const PHOTO_LOOT_POS  := Vector2(680.0, 520.0)
const LOOT_FLAG_KEYS  := ["ticket_loot_open", "photo_loot_open"]

# Doorway: the level's entrance/exit — see CLAUDE.md "Doorways, camera-follow
# & multi-room levels". The duo spawns beside it in the vestibule; walking
# away and back exits to the overworld at any time, cleared or not.
const DoorwayScript: Script = preload("res://scripts/systems/doorway.gd")
const DOORWAY_POS := Vector2(480.0, 600.0)

# Secret passage: a wall segment at the nave's altar end that looks identical
# to its neighbors but conceals a small organ loft — this location's spec
# line "may contain a pipe organ echoing the starting location" played as a
# quiet, optional lore discovery rather than a mechanical gate. Quinn presses
# Special near the hidden lever to disable the wall's collider and fade its
# sprite, revealing the loft and the organ prop inside.
const LEVER_POS := Vector2(480.0, 160.0)
const LEVER_RADIUS: float = 56.0
const ORGAN_PROP_POS := Vector2(480.0, 75.0)

# Multi-room layout bounding box (vestibule -> nave -> hidden organ loft) —
# a cross-shaped church floor plan. Feeds the camera's pan limits — see
# CLAUDE.md "Doorways, camera-follow & multi-room levels". Recompute if the
# wall layout changes.
const CAMERA_LIMIT_LEFT: int = 184
const CAMERA_LIMIT_TOP: int = 24
const CAMERA_LIMIT_RIGHT: int = 776
const CAMERA_LIMIT_BOTTOM: int = 656
const CAMERA_SMOOTHING_SPEED: float = 5.0

@onready var camera: Camera2D = $Camera2D
@onready var quinn: Player = $Players/Quinn
@onready var erin: Player  = $Players/Erin
@onready var hud: HUD      = $HUD
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label  = $HintOverlay/HintLabel
@onready var _secret_wall: StaticBody2D = $Walls/SecretWall

var _quinn_done: bool = false
var _erin_done: bool  = false
var _secret_revealed: bool = false
var _quinn_sprite: Sprite2D
var _erin_sprite: Sprite2D
var _secret_wall_shape: CollisionShape2D
var _secret_wall_sprite: Sprite2D
var _organ_prop: Sprite2D
var _loot_boxes: Array = []
var _doorway = null

func _ready() -> void:
	_build_floor()
	_build_walls()
	GameManager.register_players(quinn, erin)
	hud.setup(quinn, erin)
	quinn.special_used.connect(_on_special_used)
	erin.special_used.connect(_on_special_used)
	_create_gates()
	_create_secret_passage()
	_create_loot_boxes()
	_create_doorway()
	_setup_camera()
	_restore_progress()

# Camera follows the active character — see CLAUDE.md "Doorways,
# camera-follow & multi-room levels". Smoothing makes the retarget on
# characters_swapped feel natural for free; the pan limits keep the church's
# edges from ever showing past its bounding box.
func _setup_camera() -> void:
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = CAMERA_SMOOTHING_SPEED
	camera.limit_left = CAMERA_LIMIT_LEFT
	camera.limit_top = CAMERA_LIMIT_TOP
	camera.limit_right = CAMERA_LIMIT_RIGHT
	camera.limit_bottom = CAMERA_LIMIT_BOTTOM

# Mid-level progress restoration — see CLAUDE.md "Doorways, camera-follow &
# multi-room levels". Reads back exactly the booleans this level already
# tracks locally, so re-entering after a Doorway exit picks up where the duo
# left off: restore both pillars' solved palettes, the secret passage's open
# state, and the cleared overlay if both were already done.
func _restore_progress() -> void:
	_quinn_done = GameManager.get_level_flag(LOCATION_ID, "quinn_done", false)
	_erin_done = GameManager.get_level_flag(LOCATION_ID, "erin_done", false)
	_secret_revealed = GameManager.get_level_flag(LOCATION_ID, "secret_revealed", false)
	if _quinn_done:
		_quinn_sprite.modulate = Color(0.3, 1.0, 0.3)
	if _erin_done:
		_erin_sprite.modulate = Color(0.3, 1.0, 0.3)
	if _secret_revealed:
		_open_secret_passage(false)
	if _quinn_done and _erin_done:
		hint_label.text = ""
		clear_label.text = "PARISH CLEARED!\n\nPress ENTER for the Map"
		clear_label.visible = true

# Tile-mapped retro floor (Zelda-style two-tone grid), generated at runtime
# via PlaceholderArt to keep the original-IP guarantee — no imported tile art.
func _build_floor() -> void:
	var tile_map := TileMap.new()
	tile_map.name = "Floor"
	tile_map.tile_set = PlaceholderArt.make_level_tileset(FLOOR_BASE_COLOR, FLOOR_ACCENT_COLOR)
	add_child(tile_map)
	move_child(tile_map, 0)
	for x: int in range(FLOOR_COLS):
		for y: int in range(FLOOR_ROWS):
			var variant: Vector2i = FLOOR_TILE_ACCENT if (x + y) % FLOOR_ACCENT_PERIOD == 0 else FLOOR_TILE_PLAIN
			tile_map.set_cell(0, Vector2i(x, y), 0, variant)

# Wall art: a Sprite2D per StaticBody2D wall, sized to its exact
# CollisionShape2D rect and textured via PlaceholderArt.make_wall_texture.
# Iterates whatever StaticBody2D children it finds — the cross-shaped
# vestibule/nave/loft layout needed zero changes here, only more .tscn nodes.
func _build_walls() -> void:
	var wall_color: Color = FLOOR_BASE_COLOR.darkened(0.35)
	for wall in $Walls.get_children():
		if not wall is StaticBody2D:
			continue
		var shape: CollisionShape2D = wall.get_node("CollisionShape2D")
		var rect: RectangleShape2D = shape.shape
		var sprite := Sprite2D.new()
		sprite.texture = PlaceholderArt.make_wall_texture(wall_color, int(rect.size.x), int(rect.size.y))
		wall.add_child(sprite)

func _create_gates() -> void:
	_quinn_sprite = _gate(Color(0.3, 0.5, 0.9), QUINN_GATE_POS)
	_erin_sprite  = _gate(Color(0.9, 0.35, 0.1), ERIN_GATE_POS)

func _gate(color: Color, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = PlaceholderArt.make_gate_texture(color, 40, 64)
	s.position = pos
	add_child(s)
	return s

# The hidden lever and the wall segment it opens — grabs the references
# _build_walls() already textured so _reveal_secret_passage can disable the
# collider and fade the sprite, revealing the loft and the quiet pipe organ
# inside (pure lore/flavor here — no mechanical gate, just the spec's planted
# echo of the starting location).
func _create_secret_passage() -> void:
	_secret_wall_shape = _secret_wall.get_node("CollisionShape2D")
	for child in _secret_wall.get_children():
		if child is Sprite2D:
			_secret_wall_sprite = child
			break
	var lever := Sprite2D.new()
	lever.texture = PlaceholderArt.make_gate_texture(Color(0.45, 0.45, 0.52), 16, 22)
	lever.position = LEVER_POS
	add_child(lever)
	_organ_prop = Sprite2D.new()
	_organ_prop.texture = PlaceholderArt.make_gate_texture(Color(0.5, 0.4, 0.2), 48, 56)
	_organ_prop.position = ORGAN_PROP_POS
	_organ_prop.visible = _secret_revealed
	add_child(_organ_prop)

func _open_secret_passage(animate: bool) -> void:
	_secret_wall_shape.disabled = true
	_organ_prop.visible = true
	if animate:
		var tween := create_tween()
		tween.tween_property(_secret_wall_sprite, "modulate:a", 0.0, 0.6)
	else:
		_secret_wall_sprite.modulate.a = 0.0

func _reveal_secret_passage() -> void:
	_secret_revealed = true
	_open_secret_passage(true)
	Audio.play("special")
	GameManager.set_level_flag(LOCATION_ID, "secret_revealed", true)

func _create_loot_boxes() -> void:
	var ticket_box = LootBoxScript.new()
	ticket_box.setup(TicketQuinnItem, TICKET_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[0], false))
	add_child(ticket_box)
	_loot_boxes.append(ticket_box)

	var photo_box = LootBoxScript.new()
	photo_box.setup(FadedPhotoItem, PHOTO_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[1], false))
	add_child(photo_box)
	_loot_boxes.append(photo_box)

func _create_doorway() -> void:
	_doorway = DoorwayScript.new()
	_doorway.setup(DOORWAY_POS)
	add_child(_doorway)

func _on_special_used(char_name: String) -> void:
	var p: Player = quinn if char_name == "Quinn" else erin
	for i in _loot_boxes.size():
		if _loot_boxes[i].try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[i], true)
			return
	if char_name == "Quinn" and not _secret_revealed and quinn.global_position.distance_to(LEVER_POS) < LEVER_RADIUS:
		_reveal_secret_passage()
		return
	if char_name == "Quinn" and not _quinn_done:
		if quinn.global_position.distance_to(QUINN_GATE_POS) < GATE_RADIUS:
			_quinn_done = true
			_quinn_sprite.modulate = Color(0.3, 1.0, 0.3)
			GameManager.set_level_flag(LOCATION_ID, "quinn_done", true)
	elif char_name == "Erin" and not _erin_done:
		if erin.global_position.distance_to(ERIN_GATE_POS) < GATE_RADIUS:
			_erin_done = true
			_erin_sprite.modulate = Color(0.3, 1.0, 0.3)
			GameManager.set_level_flag(LOCATION_ID, "erin_done", true)
	if _quinn_done and _erin_done and not clear_label.visible:
		hint_label.text = ""
		clear_label.text = "PARISH CLEARED!\n\nPress ENTER for the Map"
		clear_label.visible = true

func _process(_delta: float) -> void:
	if is_instance_valid(GameManager.active_player):
		var active_pos: Vector2 = GameManager.active_player.global_position
		camera.global_position = active_pos
		if _doorway.check(active_pos):
			_exit_to_overworld()
			return
	_update_hint()
	if _quinn_done and _erin_done and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location(LOCATION_ID)
		get_tree().change_scene_to_file("res://scenes/overworld/OverworldMap.tscn")

# Doorway-triggered exit — distinct from the clear-overlay's "press ENTER"
# exit above. Per the established pattern, the duo can walk out at any time,
# cleared or not; complete_location is idempotent, so calling it here when
# already cleared never double-grants.
func _exit_to_overworld() -> void:
	if _quinn_done and _erin_done:
		GameManager.complete_location(LOCATION_ID)
	get_tree().change_scene_to_file("res://scenes/overworld/OverworldMap.tscn")

func _update_hint() -> void:
	var active := GameManager.active_player
	if not is_instance_valid(active) or (_quinn_done and _erin_done):
		hint_label.text = ""
		return
	if active == quinn and not _quinn_done:
		var d: float = quinn.global_position.distance_to(QUINN_GATE_POS)
		hint_label.text = "Press G — Quinn's HA calms the congregation" if d < GATE_RADIUS + 48.0 \
						else "Quinn: cross the nave to the BLUE pillar  [ G to use HA ]"
	elif active == erin and not _erin_done:
		var d: float = erin.global_position.distance_to(ERIN_GATE_POS)
		hint_label.text = "Press G — Erin debates the gatekeeper" if d < GATE_RADIUS + 48.0 \
						else "Erin: cross the nave to the RED pillar  [ G to use Fast Talk ]"
	elif _quinn_done and not _erin_done:
		hint_label.text = "Swap to Erin [ TAB ]  →  cross to the RED pillar"
	elif not _quinn_done and _erin_done:
		hint_label.text = "Swap to Quinn [ TAB ]  →  cross to the BLUE pillar"
	else:
		hint_label.text = ""
