"""Animate Tier 0 — build a canonical clip library from existing rigged characters.

Extracts the animation clips from a source character GLB into a LEAN, mesh-free library GLB
(armature + actions only). The retarget service grafts from this library, so new characters get
the game's clips without depending on any one character file.

  blender --background --python make_clip_library.py -- <source.glb> <library.glb> [clip,clip,...]

If a clip name list is given, only those are kept (default: all). Bones are preserved (the clips
bind to them by name), the mesh is removed.
"""
import bpy, sys, os

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, OUT = argv[0], argv[1]
KEEP = set(argv[2].split(",")) if len(argv) > 2 and argv[2] else None

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
arms = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]
if not arms:
    print("CLIPLIB: no armature in", SRC); sys.exit(1)
arm = arms[0]

# delete every non-armature object (mesh, empties) — keep the skeleton the clips bind to
bpy.ops.object.select_all(action="DESELECT")
for o in list(bpy.context.scene.objects):
    if o.type != "ARMATURE":
        o.select_set(True)
bpy.ops.object.delete()

# NLA-bind the (kept) actions to the armature so they export as named glTF animations
actions = [a for a in bpy.data.actions if (KEEP is None or a.name in KEEP)]
arm.animation_data_clear()
arm.animation_data_create()
for a in actions:
    a.use_fake_user = True
    trk = arm.animation_data.nla_tracks.new()
    trk.name = a.name
    trk.strips.new(a.name, int(a.frame_range[0]), a)

bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_animations=True,
                          export_animation_mode="NLA_TRACKS")
print(f"CLIPLIB: {len(actions)} clips -> {OUT}: {sorted(a.name for a in actions)}")
