"""Stage 3 — headless Blender: REDUCE + normalize a generated prop GLB for the game.

Reduction order matters for hard-surface Synty props:
  1. **Limited Dissolve** (planar decimate, angle limit) — merges near-coplanar faces,
     keeping flats flat and edges crisp. Far cleaner than pure quadric collapse, which
     distorts flat panels (that's what made early props look lumpy).
  2. Optional **Collapse** cap — only if still over the face budget after dissolving.
Then: weld doubles, recalc normals, apply angle-based **auto-smooth** (the Synty faceted
look — big panels flat, gentle curves smooth), scale to height 1.0 (rescale in Godot), base
at floor (min Z -> 0), centre X/Y, re-export Y-up glTF. Feed it the RAW Hunyuan mesh. Output
is one-pass Synty-ready (no separate stylize step needed).

  blender --background --python normalize_prop.py -- <in.glb> <out.glb> \
      [angle_deg=6] [face_cap=0] [precollapse=300000] [shade_deg=30] [target_height_m=1.0]

Tune for the Synty count/look: set face_cap (e.g. 5000) to push the budget down; lower
shade_deg for chunkier facets (0 = fully flat, <0 = keep smooth/realistic).
"""
import bpy, sys, math

argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUT = argv[0], argv[1]
ANGLE = float(argv[2]) if len(argv) > 2 else 6.0    # limited-dissolve / planar angle (deg)
# Default lowered 12->6 (2026-06-17): 12deg is silhouette-safe on flat-panel props (the bench
# survives it) but over-merges THIN/CYLINDRICAL features (saw teeth, cables, organ pipes),
# whose dense small-angle facets get dissolved away. 6deg is near-lossless on flat panels and
# preserves thin features far better; push lower per-prop for very fine tubes. Manage the tri
# budget with FACE_CAP/stylize, not by raising this angle.
FACE_CAP = int(argv[3]) if len(argv) > 3 else 0      # collapse cap after dissolve (0 = none)
# Pre-collapse cap: Limited Dissolve is O(faces) and *thrashes* on dense meshes full of
# thin/curved features (e.g. cylindrical rods/pipes — varying normals merge nothing), which
# made a 1M-face bench take 25+ min. A gentle quadric collapse FIRST bounds the dissolve's
# input so its cost is predictable, while still leaving plenty for dissolve to flatten. Arg
# 4 sets the cap (0 = skip); default 300k catches the pathological raw meshes only.
PRECOLLAPSE = int(argv[4]) if len(argv) > 4 else 300000
SHADE = float(argv[5]) if len(argv) > 5 else 30.0   # auto-smooth angle (deg); 0 = flat, <0 = smooth
TARGET_HEIGHT = float(argv[6]) if len(argv) > 6 else 1.0  # real-world bbox height in metres (1 unit = 1 m)

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

# 0) pre-collapse cap — bound the dissolve input so it can't thrash on a huge/thin-feature
#    mesh. Gentle (only kicks in well above PRECOLLAPSE), so the silhouette is preserved and
#    dissolve still does the real flat-merging work.
if PRECOLLAPSE and len(obj.data.polygons) > PRECOLLAPSE:
    pc = obj.modifiers.new("precollapse", "DECIMATE")
    pc.decimate_type = "COLLAPSE"
    pc.ratio = PRECOLLAPSE / float(len(obj.data.polygons))
    bpy.ops.object.modifier_apply(modifier=pc.name)
    print("after pre-collapse:", len(obj.data.polygons))

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

# 3) shading — the main Synty cue. Angle-based auto-smooth: big panels read flat/faceted,
#    gentle curves stay smooth (full-smooth looks too realistic; full-flat looks busy on
#    organic topology). SHADE=0 → fully faceted; SHADE<0 → keep smooth.
if SHADE == 0:
    bpy.ops.object.shade_flat()
elif SHADE > 0:
    bpy.ops.object.shade_smooth()
    try:
        bpy.ops.object.shade_auto_smooth(angle=math.radians(SHADE))  # Blender 4.1+/5.x
    except Exception as e:
        print("auto_smooth op unavailable, leaving smooth:", e)

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
