class_name Hitbox
extends Area2D

signal hit_landed

@export var damage: float = 10.0
@export var knockback_force: float = 200.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		hit_landed.emit()
