class_name Hurtbox
extends Area2D

signal hit(damage: float, knockback: Vector2)

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if not area is Hitbox:
		return
	var dir: Vector2 = (global_position - area.global_position).normalized()
	hit.emit(area.damage, dir * area.knockback_force)
