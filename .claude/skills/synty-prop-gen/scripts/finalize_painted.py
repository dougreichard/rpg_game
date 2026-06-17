"""Stage 4 (painted track) — finalize a Hunyuan-PAINTED glb for the game: keep the baked DIFFUSE
texture (real reference colours read well + flat enough for Synty — better than quantising to
vertex colours, which washed out), apply flat/auto-smooth shading (the Synty faceted cue),
downsize the texture (2048 -> 512 keeps it sharp on a low-poly prop but tiny to commit), and
normalize to height 1.0 / base at floor / centred. Preserves UVs + material.

  blender --background --python finalize_painted.py -- <painted.glb> <out.glb> [tex=512] [shade_deg=30] [dissolve_deg=0]
"""
import bpy, sys, math
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUT = argv[0], argv[1]
TEX = int(argv[2]) if len(argv) > 2 else 512
SHADE = float(argv[3]) if len(argv) > 3 else 30.0     # auto-smooth angle; 0 = fully flat, <0 = keep smooth
DISSOLVE = float(argv[4]) if len(argv) > 4 else 0.0   # optional Limited Dissolve (0 = none; UVs are fragile)
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
print("painted tris:", len(obj.data.polygons))

# optional gentle reduce (keeps UVs for coplanar merges only) — off by default
if DISSOLVE > 0:
    d = obj.modifiers.new("planar", "DECIMATE"); d.decimate_type = "DISSOLVE"
    d.angle_limit = math.radians(DISSOLVE)
    bpy.ops.object.modifier_apply(modifier=d.name)
    print("after dissolve:", len(obj.data.polygons))

# recalculate normals -> outside, so Godot (single-sided / back-face culled by default) doesn't
# cull inward-facing faces (Hunyuan paint meshes can have inconsistent winding). Normals-only,
# no remove_doubles, so UVs are untouched.
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.object.mode_set(mode="OBJECT")

# Synty shading cue
if SHADE == 0:
    bpy.ops.object.shade_flat()
elif SHADE > 0:
    bpy.ops.object.shade_smooth()
    try:
        bpy.ops.object.shade_auto_smooth(angle=math.radians(SHADE))
    except Exception as e:
        print("auto_smooth unavailable:", e)

# downsize the baked texture(s) — scale the in-memory buffer + pack so the GLB export embeds
# the smaller image (a glTF-imported image may otherwise re-export at its original resolution)
for img in list(bpy.data.images):
    try:
        if max(img.size) > TEX:
            img.scale(TEX, TEX)
            img.pack()
            print("texture downsized ->", TEX, img.name, tuple(img.size))
    except Exception as e:
        print("tex skip", img.name, e)

def bounds():
    mn = [1e9] * 3; mx = [-1e9] * 3
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
