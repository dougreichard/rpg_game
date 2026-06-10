class_name AchievementData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_color: Color = Color.WHITE
## Secret achievements show as "???" until unlocked (e.g. "Found all spoons").
@export var secret: bool = false
