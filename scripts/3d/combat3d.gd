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

# A one-shot 3D hit-spark burst at `pos` (the 2D CombatFX sparks don't render in 3D).
# Cheap GPUParticles3D, billboarded + additive, self-frees. Call where damage lands.
static func spark(node: Node, pos: Vector3, color: Color, count: int = 10) -> void:
	var scene := node.get_tree().current_scene
	if not is_instance_valid(scene):
		return
	var p := GPUParticles3D.new()
	p.amount = count
	p.lifetime = 0.45
	p.one_shot = true
	p.explosiveness = 1.0
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 80.0
	pm.initial_velocity_min = 2.5
	pm.initial_velocity_max = 5.5
	pm.gravity = Vector3(0, -9.0, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	pm.color = color
	p.process_material = pm
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.13, 0.13)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = color
	sm.emission_enabled = true
	sm.emission = color
	sm.emission_energy_multiplier = 3.0
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sm.billboard_keep_scale = true
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mesh.material = sm
	p.draw_pass_1 = mesh
	scene.add_child(p)
	p.global_position = pos
	p.emitting = true
	node.get_tree().create_timer(0.9, false).timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.queue_free())
