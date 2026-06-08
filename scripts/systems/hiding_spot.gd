extends Area2D

# Stealth prop: a crate/shadow/alcove the duo can duck into. While a Player
# overlaps it, Player.is_hidden suppresses guards' vision checks (Enemy._can_see),
# letting the duo wait out a patrol instead of fighting through it.
# No class_name — instantiated via preload()+untyped var (see CLAUDE.md
# class_name-resolution gotcha for fresh scripts, established by AnimalCompanion).

const WIDTH: float = 56.0
const HEIGHT: float = 48.0
const SHADOW_COLOR: Color = Color(0.05, 0.05, 0.08, 0.55)

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
	draw_rect(Rect2(-WIDTH * 0.5, -HEIGHT * 0.5, WIDTH, HEIGHT), SHADOW_COLOR)
