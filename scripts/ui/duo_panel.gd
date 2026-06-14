class_name DuoPanel
extends Node2D

const CHIP_SIZE := Vector2(150.0, 52.0)
const CHIP_GAP: float = 6.0
const SWATCH_RADIUS: float = 15.0
const PULSE_DURATION: float = 0.35
const ACTIVE_BORDER: Color = Color(1.0, 0.85, 0.3, 1.0)
const IDLE_BORDER: Color = Color(0.4, 0.4, 0.46, 0.6)
const BG_COLOR: Color = Color(0.1, 0.1, 0.14, 0.75)

var _a: Player = null
var _b: Player = null
var _pulse_timer: float = 0.0

func setup(a: Player, b: Player) -> void:
	_a = a
	_b = b
	GameManager.characters_swapped.connect(_on_swapped)
	queue_redraw()

func _on_swapped() -> void:
	_pulse_timer = PULSE_DURATION
	queue_redraw()

func _process(delta: float) -> void:
	if _pulse_timer > 0.0:
		_pulse_timer = maxf(_pulse_timer - delta, 0.0)
		queue_redraw()

func _draw() -> void:
	if _a == null or _b == null:
		return
	_draw_chip(Vector2.ZERO, _a, GameManager.active_player == _a)
	_draw_chip(Vector2(0.0, CHIP_SIZE.y + CHIP_GAP), _b, GameManager.active_player == _b)
	_draw_swap_arrow(Vector2(CHIP_SIZE.x + 10.0, CHIP_SIZE.y + CHIP_GAP * 0.5))

func _draw_chip(pos: Vector2, p: Player, active: bool) -> void:
	var border: Color = ACTIVE_BORDER if active else IDLE_BORDER
	var border_width: float = 3.0 if active else 1.5
	if active and _pulse_timer > 0.0:
		var t: float = _pulse_timer / PULSE_DURATION
		border = border.lerp(Color(1.0, 1.0, 1.0, 1.0), t)
		border_width += 2.0 * t
	draw_rect(Rect2(pos, CHIP_SIZE), BG_COLOR)
	draw_rect(Rect2(pos, CHIP_SIZE), border, false, border_width)
	var swatch_center: Vector2 = pos + Vector2(26.0, CHIP_SIZE.y * 0.5)
	draw_circle(swatch_center, SWATCH_RADIUS, p.data.sprite_color)
	draw_arc(swatch_center, SWATCH_RADIUS, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.5), 1.5)
	var font: Font = UITheme.font()
	draw_string(font, pos + Vector2(50.0, 22.0), p.data.character_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	draw_string(font, pos + Vector2(50.0, 39.0), p.data.special_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.8, 0.85))
	if active:
		draw_string(font, pos + Vector2(CHIP_SIZE.x - 46.0, 16.0), "ACTIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, ACTIVE_BORDER)

func _draw_swap_arrow(center: Vector2) -> void:
	var col: Color = Color(0.7, 0.7, 0.78, 0.8)
	var r: float = 9.0
	draw_arc(center, r, 0.0, TAU, 20, col, 1.5)
	draw_line(center + Vector2(-r * 0.4, -r * 0.4), center + Vector2(r * 0.4, r * 0.4), col, 1.5)
	draw_line(center + Vector2(-r * 0.4, r * 0.4), center + Vector2(r * 0.4, -r * 0.4), col, 1.5)
