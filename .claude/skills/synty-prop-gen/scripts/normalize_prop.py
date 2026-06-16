"""Stage 3 — headless Blender: normalize a generated prop GLB for the game.
Joins to one mesh, applies transforms, welds doubles, recalcs normals, scales to
height 1.0 (rescale in Godot via prop() scale), plants base at floor (min Z -> 0),
centres X/Y, re-exports Y-up glTF.

  /Applications/Blender.app/Contents/MacOS/Blender --background \
      --python normalize_prop.py -- ~/ai/refs/organ_console_lowpoly.glb \
      <repo>/assets/models/props/organ_console.glb
"""
import bpy, sys
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUT = argv[0], argv[1]
TARGET_HEIGHT = 1.0

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=IN)

meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
if not meshes:
    print("NO MESH"); sys.exit(1)

bpy.ops.object.select_all(action="DESELECT")
for o in meshes:
    o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
obj = bpy.context.view_layer.objects.active
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.0005)
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.object.mode_set(mode="OBJECT")

def bounds():
    mn = Vector((1e9, 1e9, 1e9)); mx = Vector((-1e9, -1e9, -1e9))
    for c in obj.bound_box:
        w = obj.matrix_world @ Vector(c)
        mn = Vector((min(mn[i], w[i]) for i in range(3)))
        mx = Vector((max(mx[i], w[i]) for i in range(3)))
    return mn, mx

mn, mx = bounds(); size = mx - mn
print("pre size:", tuple(round(v, 3) for v in size))
obj.scale = (TARGET_HEIGHT / size.z,) * 3
bpy.ops.object.transform_apply(scale=True)

mn, mx = bounds()
ctr = (mn + mx) / 2
obj.location.x -= ctr.x; obj.location.y -= ctr.y; obj.location.z -= mn.z  # centre XY, base at 0
bpy.ops.object.transform_apply(location=True)

bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB")
print("saved ->", OUT)
