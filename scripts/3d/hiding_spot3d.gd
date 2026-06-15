extends Area3D
## A 3D hiding spot. While a player body stands inside it, that body's `is_hidden`
## is set so enemy vision can't pick it up (noise still gives you away). Drawn as a
## translucent shadowed volume so the player can see it's a place to slip into.

func _ready() -> void:
	collision_layer = 0
	collision_mask = Combat3D.L_PLAYER
	monitoring = true
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new(); bs.size = Vector3(2.6, 2.2, 2.6)
	cs.shape = bs; cs.position = Vector3(0, 1.1, 0)
	add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(2.6, 2.2, 2.6)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.06, 0.10, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.material = mat; mi.mesh = bm; mi.position = Vector3(0, 1.1, 0)
	add_child(mi)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _on_enter(b: Node) -> void:
	if "is_hidden" in b:
		b.is_hidden = true

func _on_exit(b: Node) -> void:
	if "is_hidden" in b:
		b.is_hidden = false
