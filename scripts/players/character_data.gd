class_name CharacterData
extends Resource

@export var character_name: String = ""
@export var max_hp: float = 100.0
@export var move_speed: float = 150.0
@export var attack_damage: float = 20.0
@export var attack_cooldown: float = 0.5
@export var dash_distance: float = 120.0
@export var dash_iframe_duration: float = 0.15
@export var special_name: String = ""
@export var sprite_color: Color = Color(1.0, 1.0, 1.0, 1.0)

@export_group("Attack Shape")
@export var attack_reach: float = 24.0
@export var attack_arc_spread: float = 1.8        # full arc angle in radians
@export var attack_arc_color: Color = Color(1.0, 0.88, 0.3, 1.0)
@export var attack_hitbox_size: Vector2 = Vector2(28.0, 8.0)
@export var is_ranged: bool = false
@export var projectile_speed: float = 320.0
