extends Area3D
## A reusable crafting / interaction station for 3D levels — the gather → process →
## assemble loop behind puzzles like the Pipe Organ Works repair. Three kinds:
##   SOURCE   — a raw-material crate/pile: grants `produces` once, then dims.
##   TOOL     — a workbench (table saw, tuning bench): each `recipes` entry maps an
##              input item id the player carries to an output id (consume → grant).
##   ASSEMBLY — a fixture (the organ): accepts the finished `parts`, consuming each as
##              it's brought; emits `completed` once every part is placed.
## Input stays on the level's existing Special hook — the level keeps a list of
## stations and calls try_use(char_name, player_pos); the station does the range +
## best_with + item checks and owns its marker mesh + floating Label3D prompt.
## No class_name — preload()+untyped, like HidingSpot3D / Portal3D.

signal produced(item_id: String)     # a SOURCE/TOOL handed something over
signal completed                     # an ASSEMBLY received its last part
signal message(text: String)         # transient feedback for the level's HUD hint

enum Kind { SOURCE, TOOL, ASSEMBLY }

var kind: int = Kind.SOURCE
var reach: float = 2.4
var best_with: String = ""           # restrict use to this character (e.g. "Quinn")
var produces: String = ""            # SOURCE output id
var recipes: Array = []              # TOOL: [{ "in": id, "out": id }, ...]
var parts: Array = []                # ASSEMBLY: finished part ids required
var label_text: String = ""          # base prompt shown above the station

var _taken: bool = false             # SOURCE consumed
var _placed: Dictionary = {}         # ASSEMBLY: part id -> true
var _prompt: Label3D = null
var _marker: MeshInstance3D = null

const MARKER_COL := Color(0.95, 0.8, 0.35)

func setup(p_kind: int, pos: Vector3, p_label: String, p_best_with: String = "") -> Object:
	kind = p_kind
	position = pos
	label_text = p_label
	best_with = p_best_with
	return self

func _ready() -> void:
	collision_layer = 0
	collision_mask = Combat3D.L_PLAYER
	monitoring = false        # we poll via try_use, not body_entered
	_make_marker()
	_make_prompt()
	_refresh_prompt()

func _make_marker() -> void:
	_marker = MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(0.5, 0.12, 0.5)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = MARKER_COL
	mat.emission_enabled = true; mat.emission = MARKER_COL; mat.emission_energy_multiplier = 1.4
	bm.material = mat; _marker.mesh = bm
	_marker.position = Vector3(0, 0.06, 0)
	add_child(_marker)

func _make_prompt() -> void:
	_prompt = Label3D.new()
	_prompt.font = UITheme.font()
	_prompt.font_size = 40
	_prompt.outline_size = 14
	_prompt.modulate = UITheme.CREAM
	_prompt.outline_modulate = Color(0, 0, 0, 0.95)
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.no_depth_test = true
	_prompt.fixed_size = true
	_prompt.pixel_size = 0.0012
	_prompt.position = Vector3(0, 1.9, 0)
	add_child(_prompt)

# --- interaction (called from the level's _on_special ladder) ----------------
# `party` is the duo's character names: raw materials are SHARED across the duo
# (whoever picked one up), even though a tool/fixture may be restricted to one
# operator via best_with. Output is granted to the active character.
func try_use(char_name: String, from: Vector3, party: Array = []) -> bool:
	if Vector2(from.x - global_position.x, from.z - global_position.z).length() > reach:
		return false
	var holders: Array = party if not party.is_empty() else [char_name]
	if best_with != "" and char_name != best_with:
		message.emit("%s should handle the %s." % [best_with, label_text.to_lower()])
		return true
	match kind:
		Kind.SOURCE:   return _use_source(char_name)
		Kind.TOOL:     return _use_tool(char_name, holders)
		Kind.ASSEMBLY: return _use_assembly(holders)
	return false

# Returns the first party member carrying item_id, or "" if nobody has it.
func _holder(item_id: String, holders: Array) -> String:
	for who: String in holders:
		if GameManager.has_item(who, item_id):
			return who
	return ""

func _use_source(char_name: String) -> bool:
	if _taken:
		return false
	_taken = true
	GameManager.grant_item(char_name, produces)
	_dim_marker()
	_refresh_prompt()
	message.emit("Picked up: %s" % _disp(produces))
	produced.emit(produces)
	Audio.play("special")
	return true

func _use_tool(char_name: String, holders: Array) -> bool:
	for r: Dictionary in recipes:
		var who: String = _holder(r["in"], holders)
		if who != "":
			GameManager.consume_item(who, r["in"])
			GameManager.grant_item(char_name, r["out"])
			_refresh_prompt()
			message.emit("%s -> %s" % [_disp(r["in"]), _disp(r["out"])])
			produced.emit(r["out"])
			Audio.play("special")
			return true
	message.emit("%s: bring %s here." % [label_text, _recipe_inputs()])
	return true

func _use_assembly(holders: Array) -> bool:
	for p: String in parts:
		if p in _placed:
			continue
		var who: String = _holder(p, holders)
		if who != "":
			GameManager.consume_item(who, p)
			_placed[p] = true
			_refresh_prompt()
			message.emit("Fitted: %s  (%d/%d)" % [_disp(p), _placed.size(), parts.size()])
			produced.emit(p)
			Audio.play("special")
			if is_complete():
				completed.emit()
			return true
	if is_complete():
		return false
	message.emit("%s: still needs %s." % [label_text, _missing_parts()])
	return true

# --- state + restore ---------------------------------------------------------
func is_complete() -> bool:
	return kind == Kind.ASSEMBLY and _placed.size() >= parts.size()

func is_taken() -> bool:
	return _taken

func restore_taken() -> void:
	_taken = true; _dim_marker(); _refresh_prompt()

func restore_part(part_id: String) -> void:
	_placed[part_id] = true; _refresh_prompt()

func placed_count() -> int:
	return _placed.size()

# --- visuals -----------------------------------------------------------------
func _refresh_prompt() -> void:
	match kind:
		Kind.SOURCE:
			_prompt.text = "" if _taken else label_text
			_prompt.visible = not _taken
		Kind.TOOL:
			_prompt.text = label_text
		Kind.ASSEMBLY:
			if is_complete():
				_prompt.text = ""; _prompt.visible = false
			else:
				_prompt.text = "%s  %d/%d" % [label_text, _placed.size(), parts.size()]

func _dim_marker() -> void:
	if _marker == null:
		return
	var mat := ((_marker.mesh as BoxMesh).material as StandardMaterial3D)
	mat.albedo_color = Color(0.3, 0.28, 0.22)
	mat.emission_energy_multiplier = 0.0

# --- helpers -----------------------------------------------------------------
func _recipe_inputs() -> String:
	var names: Array = []
	for r: Dictionary in recipes:
		names.append(_disp(r["in"]))
	return " or ".join(names)

func _missing_parts() -> String:
	var names: Array = []
	for p: String in parts:
		if p not in _placed:
			names.append(_disp(p))
	return ", ".join(names)

func _disp(item_id: String) -> String:
	var res := load("res://data/items/%s.tres" % item_id)
	if res != null and "display_name" in res and res.display_name != "":
		return res.display_name
	return item_id
