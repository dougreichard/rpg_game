class_name Projectile
extends Hitbox

const RADIUS: float = 6.0
const LIFETIME: float = 2.5
const COLOR: Color = Color(1.0, 0.55, 0.15, 1.0)
const _SPRITE_PATH: String = "res://assets/art/sprites/projectile_sentry.png"
const _FLY_FRAMES: int = 4
const _FLY_FPS: float = 12.0
const _TILE: int = 32

var velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0
var _use_sprite: bool = false

func _ready() -> void:
	super._ready()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	_try_load_sprite()

func _try_load_sprite() -> void:
	if not ResourceLoader.exists(_SPRITE_PATH):
		return
	var tex: Texture2D = load(_SPRITE_PATH)
	if tex == null:
		return
	var img: Image = tex.get_image()
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("fly")
	sf.set_animation_loop("fly", true)
	sf.set_animation_speed("fly", _FLY_FPS)
	for i in range(_FLY_FRAMES):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * _TILE, 0, _TILE, _TILE)
		sf.add_frame("fly", at)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = sf
	sprite.play("fly")
	add_child(sprite)
	_use_sprite = true

func _physics_process(delta: float) -> void:
	position += velocity * delta
	_age += delta
	if _age >= LIFETIME:
		queue_free()

func _draw() -> void:
	if _use_sprite:
		return
	draw_circle(Vector2.ZERO, RADIUS, COLOR)

func _on_area_entered(area: Area2D) -> void:
	super._on_area_entered(area)
	if area is Hurtbox:
		queue_free()
