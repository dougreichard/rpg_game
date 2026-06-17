"""Stage 3 — headless Blender: REDUCE + normalize a generated prop GLB for the game.

Reduction order matters for hard-surface Synty props:
  1. **Limited Dissolve** (planar decimate, angle limit) — merges near-coplanar faces,
     keeping flats flat and edges crisp. Far cleaner than pure quadric collapse, which
     distorts flat panels (that's what made early props look lumpy).
  2. Optional **Collapse** cap — only if still over the face budget after dissolving.
Then: weld doubles, recalc normals, scale to height 1.0 (rescale in Godot), base at
floor (min Z -> 0), centre X/Y, re-export Y-up glTF. Feed it the RAW Hunyuan mesh.

  blender --background --python normalize_prop.py -- <in.glb> <out.glb> [angle_deg=12] [face_cap=0]
"""
import bpy, sys, math

argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUT = argv[0], argv[1]
ANGLE = float(argv[2]) if len(argv) > 2 else 12.0   # limited-dissolve / planar angle (deg)
FACE_CAP = int(argv[3]) if len(argv) > 3 else 0      # collapse cap after dissolve (0 = none)
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
print("raw tris:", len(obj.data.polygons))

# 1) limited dissolve (planar) — the main reduction; keeps the silhouette + hard edges
d = obj.modifiers.new("planar", "DECIMATE")
d.decimate_type = "DISSOLVE"
d.angle_limit = math.radians(ANGLE)
bpy.ops.object.modifier_apply(modifier=d.name)
print("after dissolve:", len(obj.data.polygons))

# 2) optional collapse cap, only if still dense
if FACE_CAP and len(obj.data.polygons) > FACE_CAP:
    c = obj.modifiers.new("collapse", "DECIMATE")
    c.decimate_type = "COLLAPSE"
    c.ratio = max(0.02, FACE_CAP / float(len(obj.data.polygons)))
    bpy.ops.object.modifier_apply(modifier=c.name)
    print("after collapse:", len(obj.data.polygons))

bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.0005)
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.object.mode_set(mode="OBJECT")

def bounds():
    mn = [1e9] * 3; mx = [-1e9] * 3
    from mathutils import Vector
    for c in obj.bound_box:
        w = obj.matrix_world @ Vector(c)
        for i in range(3):
            mn[i] = min(mn[i], w[i]); mx[i] = max(mx[i], w[i])
    return mn, mx

mn, mx = bounds(); size = [mx[i] - mn[i] for i in range(3)]
obj.scale = (TARGET_HEIGHT / size[2],) * 3
bpy.ops.object.transform_apply(scale=True)
mn, mx = bounds()
obj.location.x -= (mn[0] + mx[0]) / 2
obj.location.y -= (mn[1] + mx[1]) / 2
obj.location.z -= mn[2]
bpy.ops.object.transform_apply(location=True)

bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB")
print("final tris:", len(obj.data.polygons), "-> saved", OUT)
