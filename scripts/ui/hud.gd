class_name HUD
extends CanvasLayer

@onready var bar_a: ProgressBar = $Panel/BarA
@onready var bar_b: ProgressBar = $Panel/BarB
@onready var bies_bar: ProgressBar = $Panel/BiasBar
@onready var label_a: Label = $Panel/LabelA
@onready var label_b: Label = $Panel/LabelB
@onready var bies_label: Label = $Panel/BiasLabel
@onready var duo_panel: Node = $DuoPanel
@onready var inventory_panel: Node = $InventoryPanel
@onready var inventory_overlay: Node = $InventoryOverlay
@onready var revive_indicator: Node = $ReviveIndicator

var _a: Player = null
var _b: Player = null

func setup(a: Player, b: Player) -> void:
	_a = a
	_b = b
	label_a.add_theme_font_size_override("font_size", 8)
	label_b.add_theme_font_size_override("font_size", 8)
	bies_label.add_theme_font_size_override("font_size", 8)
	a.hp_changed.connect(_on_a_hp)
	b.hp_changed.connect(_on_b_hp)
	a.bies_charge_changed.connect(_on_bies_charge)
	b.bies_charge_changed.connect(_on_bies_charge)
	GameManager.characters_swapped.connect(_on_swapped)
	bar_a.max_value = a.data.max_hp
	bar_a.value = a.data.max_hp
	bar_b.max_value = b.data.max_hp
	bar_b.value = b.data.max_hp
	bies_bar.max_value = 1.0
	bies_bar.value = 0.0
	duo_panel.call("setup", a, b)
	inventory_panel.call("setup", a, b)
	inventory_overlay.call("setup", a.data.character_name, b.data.character_name)
	revive_indicator.call("setup", a, b)
	_update_active_labels()

func _on_a_hp(current: float, _maximum: float) -> void:
	bar_a.value = current

func _on_b_hp(current: float, _maximum: float) -> void:
	bar_b.value = current

func _on_bies_charge(charge: float) -> void:
	bies_bar.value = charge

func _on_swapped() -> void:
	if not is_instance_valid(GameManager.active_player):
		return
	bies_bar.value = GameManager.active_player.bies_charge
	_update_active_labels()

func _process(_delta: float) -> void:
	if bies_bar.value >= 1.0:
		var t: float = Time.get_ticks_msec() / 1000.0
		var pulse: float = 0.55 + 0.45 * sin(t * 8.0)
		bies_bar.modulate = Color(1.0, pulse, 0.2, 1.0)
	else:
		bies_bar.modulate = Color.WHITE

func _update_active_labels() -> void:
	var a_active: bool = GameManager.active_player == _a
	label_a.text = ("> " if a_active else "  ") + _a.data.character_name
	label_b.text = ("  " if a_active else "> ") + _b.data.character_name
