"""Transform-only normalize for a painted/coloured GLB: base at floor (min up-axis -> 0),
centred X/Y, scaled to height 1.0 — WITHOUT touching geometry or vertex colours (no dissolve/
collapse/shade). Use on Prop Farm "painted" output, which comes origin-centred + ~2-unit, so
placing it at floor level sinks the bottom half below the floor ("missing parts").

  blender --background --python recenter_glb.py -- <in.glb> <out.glb> [target_height=1.0]
"""
import bpy, sys
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUT = argv[0], argv[1]
TARGET_H = float(argv[2]) if len(argv) > 2 else 1.0

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=IN)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
bpy.ops.object.select_all(action="DESELECT")
for o in meshes:
    o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
obj = bpy.context.view_layer.objects.active
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
# keep the COLOR_0 vertex-colour attribute as the single active one on export
me = obj.data
if me.color_attributes:
    me.color_attributes.active_color_index = 0
    me.color_attributes.render_color_index = 0

def bounds():
    mn = [1e9] * 3; mx = [-1e9] * 3
    for c in obj.bound_box:
        w = obj.matrix_world @ Vector(c)
        for i in range(3):
            mn[i] = min(mn[i], w[i]); mx[i] = max(mx[i], w[i])
    return mn, mx

mn, mx = bounds()
if TARGET_H > 0:
    obj.scale = (TARGET_H / max(mx[2] - mn[2], 1e-6),) * 3
    bpy.ops.object.transform_apply(scale=True)
    mn, mx = bounds()
obj.location.x -= (mn[0] + mx[0]) / 2
obj.location.y -= (mn[1] + mx[1]) / 2
obj.location.z -= mn[2]                       # base on floor
bpy.ops.object.transform_apply(location=True)

bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB",
                          export_all_vertex_colors=False, export_vertex_color="ACTIVE")
print("recentred (base@floor, height %.2f) ->" % TARGET_H, OUT)
