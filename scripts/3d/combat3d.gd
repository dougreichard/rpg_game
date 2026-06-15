class_name Combat3D
extends RefCounted
## Shared 3D combat helpers for the migration: collision-layer bits + a one-shot
## damage volume. Mirrors the 2D Hitbox/Hurtbox role with Area3D. Bodies (Player3D /
## Enemy3D) carry their layer bit; a strike's Area3D masks the opposing bit.

const L_WORLD: int = 1   # bit 1 — ground/walls (static)
const L_PLAYER: int = 2  # bit 2 — player bodies
const L_ENEMY: int = 4   # bit 3 — enemy bodies

# Spawn a short-lived spherical damage volume at `world_pos`; calls `on_hit(body)`
# once per body whose layer is in `mask`. Self-frees after `life` seconds.
static func strike(node: Node, world_pos: Vector3, radius: float, mask: int,
		on_hit: Callable, life: float = 0.15) -> void:
	var scene := node.get_tree().current_scene
	if not is_instance_valid(scene):
		return
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = mask
	area.monitoring = true
	var cs := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = radius
	cs.shape = sp
	area.add_child(cs)
	scene.add_child(area)
	area.global_position = world_pos
	var struck: Dictionary = {}
	area.body_entered.connect(func(b: Node) -> void:
		if b in struck:
			return
		struck[b] = true
		on_hit.call(b))
	node.get_tree().create_timer(life, false).timeout.connect(func() -> void:
		if is_instance_valid(area):
			area.queue_free())
