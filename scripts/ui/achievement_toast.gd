extends CanvasLayer

# Lightweight slide-in/out toast shown on AchievementManager.achievement_unlocked.
# Sits below PauseMenu/AchievementsOverlay in layer order so it never blocks
# input; PROCESS_MODE_ALWAYS keeps the unlock-moment toast running even if the
# unlock happens to coincide with a pause.

const PANEL_SIZE := Vector2(360.0, 64.0)
const MARGIN: float = 16.0
const ON_SCREEN_X: float = 1280.0 - PANEL_SIZE.x - MARGIN
const OFF_SCREEN_X: float = 1280.0 + MARGIN
const SLIDE_DURATION: float = 0.35
const HOLD_DURATION: float = 3.0
const PANEL_COLOR: Color = UITheme.PANEL_BG
const BORDER_COLOR: Color = UITheme.GOLD_DIM
const TITLE_COLOR: Color = Color(0.95, 0.85, 0.2)
const NAME_COLOR: Color = Color(0.95, 0.95, 0.95)

var _root: Control
var _icon: ColorRect
var _name_label: Label
var _tween: Tween

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	AchievementManager.achievement_unlocked.connect(_on_unlocked)

func _build_ui() -> void:
	_root = Control.new()
	_root.position = Vector2(OFF_SCREEN_X, MARGIN)
	_root.size = PANEL_SIZE
	add_child(_root)

	var panel := ColorRect.new()
	panel.color = PANEL_COLOR
	panel.size = PANEL_SIZE
	_root.add_child(panel)

	var border_w: float = 2.0
	for side_rect: Rect2 in [
		Rect2(Vector2.ZERO, Vector2(PANEL_SIZE.x, border_w)),
		Rect2(Vector2(0.0, PANEL_SIZE.y - border_w), Vector2(PANEL_SIZE.x, border_w)),
		Rect2(Vector2.ZERO, Vector2(border_w, PANEL_SIZE.y)),
		Rect2(Vector2(PANEL_SIZE.x - border_w, 0.0), Vector2(border_w, PANEL_SIZE.y)),
	]:
		var border := ColorRect.new()
		border.color = BORDER_COLOR
		border.position = side_rect.position
		border.size = side_rect.size
		_root.add_child(border)

	_icon = ColorRect.new()
	_icon.position = Vector2(12.0, 16.0)
	_icon.size = Vector2(32.0, 32.0)
	_root.add_child(_icon)

	var title_label := Label.new()
	title_label.text = "ACHIEVEMENT UNLOCKED"
	title_label.position = Vector2(56.0, 8.0)
	title_label.size = Vector2(PANEL_SIZE.x - 64.0, 18.0)
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", TITLE_COLOR)
	_root.add_child(title_label)

	_name_label = Label.new()
	_name_label.position = Vector2(56.0, 28.0)
	_name_label.size = Vector2(PANEL_SIZE.x - 64.0, 28.0)
	_name_label.add_theme_font_size_override("font_size", 18)
	_name_label.add_theme_color_override("font_color", NAME_COLOR)
	_root.add_child(_name_label)

func _on_unlocked(id: String) -> void:
	_icon.color = AchievementManager.get_icon_color(id)
	_name_label.text = AchievementManager.get_display_name(id)
	Audio.play("special")
	_show()

func _show() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_root.position.x = OFF_SCREEN_X
	_tween = create_tween()
	_tween.tween_property(_root, "position:x", ON_SCREEN_X, SLIDE_DURATION)
	_tween.tween_interval(HOLD_DURATION)
	_tween.tween_property(_root, "position:x", OFF_SCREEN_X, SLIDE_DURATION)
