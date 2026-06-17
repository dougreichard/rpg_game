"""Stage 3.5 (optional) — push an already-reduced/normalized prop toward the true Synty
low-poly look: fewer, chunkier faces + **flat (faceted) shading** (the Synty hallmark —
smooth shading is what reads as "too detailed/realistic"). Does NOT touch the transform
(scale/position/orientation), so it is safe to run on co-registered split parts (e.g. the
organ base/pipes) — they stay aligned. Run it on the committed <slug>.glb in place.

  blender --background --python stylize_prop.py -- <in.glb> <out.glb> [target_tris=9000] [dissolve_deg=8] [shade_deg=35]

shade_deg = angle-based auto-smooth threshold: edges sharper than it read as flat facets
(the Synty cue), gentler ones stay smooth — so flat panels go faceted without making the
whole irregular mesh look busy. Set shade_deg=0 for FULLY flat (chunkiest, can look noisy
on dense organic topology). A light pass (high target, small dissolve, ~35° auto-smooth) is
a *subtle* nudge from a detailed prop; lower target/shade for a blockier read.
"""
import bpy, sys, math

argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUT = argv[0], argv[1]
TARGET = int(argv[2]) if len(argv) > 2 else 9000
ANGLE = float(argv[3]) if len(argv) > 3 else 8.0
SHADE = float(argv[4]) if len(argv) > 4 else 35.0

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
print("in tris:", len(obj.data.polygons))

# 1) a bit more limited dissolve — flatten panels further so the silhouette goes chunkier
d = obj.modifiers.new("planar", "DECIMATE")
d.decimate_type = "DISSOLVE"; d.angle_limit = math.radians(ANGLE)
bpy.ops.object.modifier_apply(modifier=d.name)
# 2) collapse down to a Synty-ish budget
if len(obj.data.polygons) > TARGET:
    c = obj.modifiers.new("collapse", "DECIMATE")
    c.decimate_type = "COLLAPSE"; c.ratio = TARGET / float(len(obj.data.polygons))
    bpy.ops.object.modifier_apply(modifier=c.name)

bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.0008)
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.object.mode_set(mode="OBJECT")

# 3) shading — the main Synty cue. Angle-based auto-smooth keeps big panels flat/faceted
#    while gentle curves stay smooth (avoids the busy look full-flat gives dense organic
#    topology). SHADE=0 → fully faceted.
if SHADE <= 0:
    bpy.ops.object.shade_flat()
else:
    bpy.ops.object.shade_smooth()
    try:
        bpy.ops.object.shade_auto_smooth(angle=math.radians(SHADE))  # Blender 4.1+/5.x
    except Exception as e:
        print("auto_smooth op unavailable, leaving smooth:", e)

# NOTE: deliberately NO transform_apply / rescale / recentre — keep the prop exactly where
# stage 3 put it so split parts stay co-registered.
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB")
print("out tris:", len(obj.data.polygons), "-> saved", OUT)
