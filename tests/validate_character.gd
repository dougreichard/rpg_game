# Headless Godot validation for a generated/retargeted character GLB — confirms it imports the way
# the game expects (Skeleton3D + AnimationPlayer with the 9 clips player_3d.gd/enemy_3d.gd play).
#
#   godot --headless -s tests/validate_character.gd -- <path-to.glb>
#
# Accepts a res:// path (imported asset) or an absolute/OS path (a fresh GLB from the Prop Farm,
# loaded at runtime via GLTFDocument). Exits 0 on PASS, 1 on FAIL.
extends SceneTree

const NEED := ["idle", "walk", "run", "attack", "dash", "down", "hurt", "sit", "special"]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("usage: godot --headless -s tests/validate_character.gd -- <path.glb>")
		quit(2)
		return
	var path: String = args[0]
	var scene := _load(path)
	if scene == null:
		printerr("FAIL: could not load ", path)
		quit(1)
		return

	var ok := true
	var skel := _find(scene, "Skeleton3D") as Skeleton3D
	if skel == null:
		printerr("FAIL: no Skeleton3D")
		ok = false
	else:
		print("Skeleton3D: ", skel.get_bone_count(), " bones (root: ", skel.get_bone_name(0), ")")

	var anim := _find(scene, "AnimationPlayer") as AnimationPlayer
	if anim == null:
		printerr("FAIL: no AnimationPlayer")
		ok = false
	else:
		print("clips: ", anim.get_animation_list())
		for n in NEED:
			if not anim.has_animation(n):
				printerr("FAIL: missing clip '", n, "'")
				ok = false

	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _load(path: String) -> Node:
	if path.begins_with("res://"):
		var ps = ResourceLoader.load(path)
		return ps.instantiate() if ps is PackedScene else null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return null
	return doc.generate_scene(state)


func _find(node: Node, cls: String) -> Node:
	if node.is_class(cls):
		return node
	for c in node.get_children():
		var r := _find(c, cls)
		if r != null:
			return r
	return null
