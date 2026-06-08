class_name InventoryPanel
extends Node2D

# Always-visible programmatic inventory readout — sibling to DuoPanel in the
# HUD. Draws each duo member's collected items as a row of small runtime-
# generated icon swatches (PlaceholderArt.make_item_icon), redrawing whenever
# GameManager.item_collected or characters_swapped fires. Junk items render
# with a dim, desaturated icon and a duller border so players can tell "might
# matter later" from "keepsake" at a glance — see CLAUDE.md "Collectibles &
# Inventory".

const ICON_SIZE: float = 16.0
const ICON_GAP: float = 5.0
const ROW_GAP: float = 24.0
const FUNCTIONAL_BORDER := Color(1.0, 0.85, 0.3, 0.9)
const JUNK_BORDER := Color(0.6, 0.6, 0.66, 0.35)

var _a: Player = null
var _b: Player = null
var _icon_cache: Dictionary = {}

func setup(a: Player, b: Player) -> void:
	_a = a
	_b = b
	GameManager.item_collected.connect(_on_inventory_changed)
	GameManager.characters_swapped.connect(_on_inventory_changed)
	queue_redraw()

func _on_inventory_changed(_a_arg = null, _b_arg = null) -> void:
	queue_redraw()

func _draw() -> void:
	if _a == null or _b == null:
		return
	_draw_row(Vector2.ZERO, _a)
	_draw_row(Vector2(0.0, ROW_GAP), _b)

func _draw_row(pos: Vector2, p: Player) -> void:
	var ids: Array = GameManager.inventories.get(p.data.character_name.to_lower(), [])
	for i: int in range(ids.size()):
		var item: ItemData = load("res://data/items/%s.tres" % ids[i])
		if item == null:
			continue
		var icon_pos: Vector2 = pos + Vector2(i * (ICON_SIZE + ICON_GAP), 0.0)
		var border: Color = JUNK_BORDER if item.is_junk else FUNCTIONAL_BORDER
		draw_texture(_get_icon(item), icon_pos)
		draw_rect(Rect2(icon_pos, Vector2(ICON_SIZE, ICON_SIZE)), border, false, 1.5)

func _get_icon(item: ItemData) -> ImageTexture:
	if item.id not in _icon_cache:
		_icon_cache[item.id] = PlaceholderArt.make_item_icon(item.icon_color, item.is_junk)
	return _icon_cache[item.id]
