class_name EnemyData
extends Resource

@export var enemy_name: String = "Enemy"
@export var max_hp: float = 60.0
@export var move_speed: float = 80.0
@export var attack_damage: float = 12.0
@export var attack_range: float = 40.0
@export var windup_duration: float = 0.6
@export var knockback_force: float = 150.0
@export var sprite_color: Color = Color(0.5, 0.5, 0.5, 1.0)
@export var is_stocky: bool = false

@export_group("Boss")
@export var is_boss: bool = false
@export var slam_damage: float = 0.0
@export var slam_radius: float = 0.0
@export var slam_telegraph_duration: float = 0.0
@export var slam_cooldown: float = 0.0

@export_group("Ranged")
@export var is_ranged: bool = false
@export var projectile_speed: float = 240.0

@export_group("Stealth")
## How far this guard can spot the player straight ahead, inside vision_angle_deg.
@export var vision_range: float = 170.0
## Width of the forward vision cone, in degrees (total, split either side of facing).
@export var vision_angle_deg: float = 100.0
## How close a noisy player action (attack/dash) needs to be to be heard through walls.
@export var hearing_range: float = 90.0
## How far this guard wanders from its spawn point while patrolling.
@export var patrol_radius: float = 80.0
