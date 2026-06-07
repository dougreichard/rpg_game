class_name Projectile
extends Hitbox

const RADIUS: float = 6.0
const LIFETIME: float = 2.5
const COLOR: Color = Color(1.0, 0.55, 0.15, 1.0)

var velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0

func _ready() -> void:
	super._ready()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)

func _physics_process(delta: float) -> void:
	position += velocity * delta
	_age += delta
	if _age >= LIFETIME:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)

func _on_area_entered(area: Area2D) -> void:
	super._on_area_entered(area)
	if area is Hurtbox:
		queue_free()
