extends CanvasLayer

# Manages scene transitions with a fade-to-black / fade-in effect.
# Replace all get_tree().change_scene_to_file() / reload_current_scene() with:
#   TransitionManager.change_scene("res://path/to/scene.tscn")
#   TransitionManager.reload_scene()

const FADE_DURATION: float = 0.28

var _overlay: ColorRect
var _busy: bool = false
var _target_path: String = ""
var _reloading: bool = false

func _ready() -> void:
	layer = 99
	process_mode = Node.PROCESS_MODE_ALWAYS

	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.size = Vector2(1280.0, 720.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	_target_path = path
	_reloading = false
	_fade_out()

func reload_scene() -> void:
	if _busy:
		return
	_busy = true
	_reloading = true
	_fade_out()

func _fade_out() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, FADE_DURATION)
	tween.tween_callback(_switch_scene)

func _switch_scene() -> void:
	if _reloading:
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file(_target_path)
	_fade_in()

func _fade_in() -> void:
	# Defer one frame so the new scene is fully loaded before fading in.
	await get_tree().process_frame
	var tween: Tween = create_tween()
	tween.tween_property(_overlay, "color:a", 0.0, FADE_DURATION)
	tween.tween_callback(func() -> void: _busy = false)
