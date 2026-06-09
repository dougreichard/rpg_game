extends Area2D

# Stealth prop: a crate/shadow/alcove the duo can duck into. While a Player
# overlaps it, Player.is_hidden suppresses guards' vision checks (Enemy._can_see),
# letting the duo wait out a patrol instead of fighting through it.
# No class_name — instantiated via preload()+untyped var (see CLAUDE.md
# class_name-resolution gotcha for fresh scripts, established by AnimalCompanion).

const WIDTH: float  = 56.0
const HEIGHT: float = 48.0
const CRATE_COLOR:  Color = Color(0.32, 0.24, 0.14, 0.88)
const SHADOW_COLOR: Color = Color(0.02, 0.02, 0.05, 0.62)

func _init() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WIDTH, HEIGHT)
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.is_hidden = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.is_hidden = false

func _draw() -> void:
	var hw: float = WIDTH * 0.5
	var hh: float = HEIGHT * 0.5

	# Shadow pool beneath the crate
	draw_rect(Rect2(-hw, -hh, WIDTH, HEIGHT), SHADOW_COLOR)

	# Crate body
	draw_rect(Rect2(-hw, -hh, WIDTH, HEIGHT), CRATE_COLOR)
	# Crate border (dark wood frame)
	draw_rect(Rect2(-hw, -hh, WIDTH, HEIGHT), CRATE_COLOR.darkened(0.55), false, 2.0)

	# Horizontal plank lines (wood grain / slat joins)
	var plank_col := CRATE_COLOR.darkened(0.3)
	for i: int in [1, 2]:
		var py: float = -hh + HEIGHT * float(i) / 3.0
		draw_line(Vector2(-hw + 2.0, py), Vector2(hw - 2.0, py), plank_col, 1.0)

	# Vertical slat lines — two on each half, evenly spaced
	var slat_col := CRATE_COLOR.darkened(0.22)
	for i: int in [1, 2]:
		var sx: float = -hw + WIDTH * float(i) / 3.0
		draw_line(Vector2(sx, -hh + 2.0), Vector2(sx, hh - 2.0), slat_col, 1.0)

	# Corner bracket nails — small bright dots at each corner
	var nail_col := CRATE_COLOR.lightened(0.4)
	var margin: float = 5.0
	for nx: float in [-hw + margin, hw - margin]:
		for ny: float in [-hh + margin, hh - margin]:
			draw_circle(Vector2(nx, ny), 1.5, nail_col)
