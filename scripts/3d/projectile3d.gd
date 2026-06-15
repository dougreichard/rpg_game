extends Area3D
## A simple 3D enemy projectile (Sentry shots). Travels in a straight line, damages
## the player on contact, and despawns on a wall or after its lifetime. Layers: no
## body of its own; mask hits players (L_PLAYER) and world (L_WORLD).

var velocity: Vector3 = Vector3.ZERO
var damage: float = 14.0
var life: float = 2.5

func setup(dir: Vector3, speed: float, dmg: float) -> void:
	velocity = dir.normalized() * speed
	damage = dmg

func _ready() -> void:
	collision_layer = 0
	collision_mask = Combat3D.L_PLAYER | Combat3D.L_WORLD
	monitoring = true
	var cs := CollisionShape3D.new()
	var sp := SphereShape3D.new(); sp.radius = 0.25
	cs.shape = sp
	add_child(cs)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.22; sm.height = 0.44
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 0.2)
	mat.emission_enabled = true; mat.emission = Color(1.0, 0.5, 0.2); mat.emission_energy_multiplier = 2.0
	sm.material = mat; mi.mesh = sm
	add_child(mi)
	body_entered.connect(_on_body)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()

func _on_body(b: Node) -> void:
	if b.has_method("take_damage"):
		b.take_damage(damage, velocity.normalized())
	queue_free()
