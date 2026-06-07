extends Node2D

# Tile-mapped floor palette — cool stone with warm candlelight flecks (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.30, 0.32, 0.36)
const FLOOR_ACCENT_COLOR: Color = Color(0.55, 0.50, 0.40)
const FLOOR_COLS: int = 20
const FLOOR_ROWS: int = 12
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

const GATE_RADIUS: float = 64.0
const QUINN_GATE_POS := Vector2(200.0, 180.0)
const ERIN_GATE_POS  := Vector2(440.0, 180.0)

@onready var quinn: Player = $Players/Quinn
@onready var erin: Player  = $Players/Erin
@onready var hud: HUD      = $HUD
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label  = $HintOverlay/HintLabel

var _quinn_done: bool = false
var _erin_done: bool  = false
var _quinn_sprite: Sprite2D
var _erin_sprite: Sprite2D

func _ready() -> void:
	_build_floor()
	GameManager.register_players(quinn, erin)
	hud.setup(quinn, erin)
	quinn.special_used.connect(_on_special_used)
	erin.special_used.connect(_on_special_used)
	_create_gates()


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
func _create_gates() -> void:
	_quinn_sprite = _gate(Color(0.3, 0.5, 0.9), QUINN_GATE_POS)
	_erin_sprite  = _gate(Color(0.9, 0.35, 0.1), ERIN_GATE_POS)

func _gate(color: Color, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = PlaceholderArt.make_gate_texture(color, 40, 64)
	s.position = pos
	add_child(s)
	return s

func _on_special_used(char_name: String) -> void:
	if char_name == "Quinn" and not _quinn_done:
		if quinn.global_position.distance_to(QUINN_GATE_POS) < GATE_RADIUS:
			_quinn_done = true
			_quinn_sprite.modulate = Color(0.3, 1.0, 0.3)
	elif char_name == "Erin" and not _erin_done:
		if erin.global_position.distance_to(ERIN_GATE_POS) < GATE_RADIUS:
			_erin_done = true
			_erin_sprite.modulate = Color(0.3, 1.0, 0.3)
	if _quinn_done and _erin_done:
		hint_label.text = ""
		clear_label.text = "PARISH CLEARED!\n\nPress ENTER for the Map"
		clear_label.visible = true

func _process(_delta: float) -> void:
	_update_hint()
	if _quinn_done and _erin_done and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location("old_parish_church")
		get_tree().change_scene_to_file("res://scenes/overworld/OverworldMap.tscn")

func _update_hint() -> void:
	var active := GameManager.active_player
	if not is_instance_valid(active) or (_quinn_done and _erin_done):
		hint_label.text = ""
		return
	if active == quinn and not _quinn_done:
		var d: float = quinn.global_position.distance_to(QUINN_GATE_POS)
		hint_label.text = "Press G — Quinn's HA calms the congregation" if d < GATE_RADIUS + 48.0 \
						else "Quinn: approach the BLUE pillar  [ G to use HA ]"
	elif active == erin and not _erin_done:
		var d: float = erin.global_position.distance_to(ERIN_GATE_POS)
		hint_label.text = "Press G — Erin debates the gatekeeper" if d < GATE_RADIUS + 48.0 \
						else "Erin: approach the RED pillar  [ G to use Fast Talk ]"
	elif _quinn_done and not _erin_done:
		hint_label.text = "Swap to Erin [ TAB ]  →  approach the RED pillar"
	elif not _quinn_done and _erin_done:
		hint_label.text = "Swap to Quinn [ TAB ]  →  approach the BLUE pillar"
	else:
		hint_label.text = ""
