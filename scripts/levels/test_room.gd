extends Node2D

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/enemies/Runner.tscn")

@onready var quinn: Player = $Players/Quinn
@onready var erin: Player = $Players/Erin
@onready var hud: HUD = $HUD
@onready var enemies_node: Node2D = $Enemies

func _ready() -> void:
	GameManager.register_players(quinn, erin)
	hud.setup(quinn, erin)
	_spawn_initial_enemies()

func _spawn_initial_enemies() -> void:
	_spawn(GRUNT_SCENE,  Vector2(860.0, 340.0))
	_spawn(GRUNT_SCENE,  Vector2(950.0, 380.0))
	_spawn(RUNNER_SCENE, Vector2(820.0, 300.0))

func _spawn(scene: PackedScene, pos: Vector2) -> void:
	var enemy: Enemy = scene.instantiate()
	enemy.position = pos
	enemies_node.add_child(enemy)
