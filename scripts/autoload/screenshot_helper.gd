extends Node

# Dev-only screenshot tool — completely inert during normal play.
# Activate by launching with: godot --path . -- --screenshot
# Simulates ui_accept to navigate title → overworld → character select → level,
# then captures the viewport and saves to user://screenshot.png.
# Physical path is printed so it can be read back by the caller.

const SAVE_PATH := "user://screenshot.png"

# Seconds to wait at each phase before pressing ui_accept or capturing.
const PHASE_DELAYS: Array[float] = [2.5, 2.0, 1.5, 4.5]

var _active: bool = false
var _elapsed: float = 0.0
var _phase: int = 0

func _ready() -> void:
	_active = "--screenshot" in OS.get_cmdline_user_args()
	if not _active:
		set_process(false)
	else:
		print("[ScreenshotHelper] Active — capturing in ~%.0fs" % PHASE_DELAYS.reduce(func(a, b): return a + b))

func _process(delta: float) -> void:
	_elapsed += delta
	if _phase >= PHASE_DELAYS.size():
		return
	if _elapsed < PHASE_DELAYS[_phase]:
		return
	_elapsed = 0.0
	match _phase:
		0, 1, 2:
			_simulate_accept()
		3:
			_capture()
	_phase += 1

func _simulate_accept() -> void:
	var press := InputEventAction.new()
	press.action = "ui_accept"
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = "ui_accept"
	release.pressed = false
	Input.parse_input_event(release)

func _capture() -> void:
	var img := get_viewport().get_texture().get_image()
	if img == null:
		push_error("[ScreenshotHelper] Viewport texture unavailable")
		return
	img.save_png(SAVE_PATH)
	print("[ScreenshotHelper] Saved: ", ProjectSettings.globalize_path(SAVE_PATH))
	get_tree().quit()
