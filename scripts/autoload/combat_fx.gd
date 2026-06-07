extends Node

var _trauma: float = 0.0
var _time: float = 0.0
var _spark_tex: ImageTexture = null

const TRAUMA_DECAY: float = 3.0
const MAX_SHAKE_PX: float = 6.0

func shake(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)

func sparks(pos: Vector2, color: Color, count: int = 8) -> void:
	var scene := get_tree().current_scene
	if not is_instance_valid(scene):
		return
	var p := CPUParticles2D.new()
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.amount = count
	p.lifetime = 0.35
	p.explosiveness = 0.95
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = 50.0
	p.initial_velocity_max = 140.0
	p.gravity = Vector2(0.0, 320.0)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	p.color = color
	p.texture = _get_spark_tex()
	scene.add_child(p)
	get_tree().create_timer(0.6, false).timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.queue_free()
	)

func _get_spark_tex() -> ImageTexture:
	if _spark_tex == null:
		var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_spark_tex = ImageTexture.create_from_image(img)
	return _spark_tex

func _process(delta: float) -> void:
	if _trauma <= 0.0:
		return
	_trauma = maxf(_trauma - TRAUMA_DECAY * delta, 0.0)
	_time += delta
	var cam := get_viewport().get_camera_2d()
	if not is_instance_valid(cam):
		_trauma = 0.0
		return
	if _trauma <= 0.0:
		cam.offset = Vector2.ZERO
		return
	var t2 := _trauma * _trauma
	cam.offset = Vector2(
		sin(_time * 37.0) * t2 * MAX_SHAKE_PX,
		sin(_time * 53.0) * t2 * MAX_SHAKE_PX
	)
