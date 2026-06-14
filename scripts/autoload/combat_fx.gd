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

# Soft ground puff — footsteps, dash kick-off, landings, death. Low + outward,
# settles quickly. Warm dust colour by default to match the Synty palette.
func dust(pos: Vector2, count: int = 6, color: Color = Color(0.82, 0.78, 0.68, 0.65),
		power: float = 1.0) -> void:
	var scene := get_tree().current_scene
	if not is_instance_valid(scene):
		return
	var p := CPUParticles2D.new()
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.amount = count
	p.lifetime = 0.45
	p.explosiveness = 0.9
	p.direction = Vector2.UP
	p.spread = 95.0
	p.initial_velocity_min = 14.0 * power
	p.initial_velocity_max = 40.0 * power
	p.gravity = Vector2(0.0, 70.0)
	p.scale_amount_min = 2.0 * power
	p.scale_amount_max = 5.0 * power
	p.color = color
	p.texture = _get_spark_tex()
	scene.add_child(p)
	get_tree().create_timer(0.7, false).timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.queue_free()
	)

# A quick expanding impact ring (a thin Line2D circle that scales up + fades) for
# punchier hit feedback. Self-frees via a tween.
func ring(pos: Vector2, color: Color = Color(1.0, 0.95, 0.6, 0.9), radius: float = 22.0) -> void:
	var scene := get_tree().current_scene
	if not is_instance_valid(scene):
		return
	var r := Line2D.new()
	r.width = 3.0
	r.default_color = color
	r.position = pos
	var pts := PackedVector2Array()
	for i in range(17):
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	r.points = pts
	r.scale = Vector2(0.2, 0.2)
	scene.add_child(r)
	var tw := r.create_tween()
	tw.set_parallel(true)
	tw.tween_property(r, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(r, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(r.queue_free)

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
