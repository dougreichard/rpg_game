"""Stage 3.7 (optional) — split a prop into co-registered material parts by a horizontal
(Z) cut, so each part can take a different flat tint in Godot (e.g. a bench: wood body +
steel rod-rack/tools). Like the organ base/pipes split: NO renormalize, so both parts keep
the shared frame and reassemble at the same pos+scale in the level.

  blender --background --python split_prop.py -- <in.glb> <lower.glb> <upper.glb> <cut_frac>
  cut_frac = height fraction of the Z extent (0..1) where to cut (e.g. 0.58 = just above a
             bench tabletop, so legs+top stay in <lower>, rods/tools go to <upper>).
"""
import bpy, sys
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
IN, LOWER, UPPER, FRAC = argv[0], argv[1], argv[2], float(argv[3])

def load_joined():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=IN)
    ms = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in ms:
        o.select_set(True)
    bpy.context.view_layer.objects.active = ms[0]
    if len(ms) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return obj

# find the cut Z from the joined bounds
probe = load_joined()
zs = [(probe.matrix_world @ v.co).z for v in probe.data.vertices]
CUT = min(zs) + FRAC * (max(zs) - min(zs))
print(f"cut Z = {CUT:.4f}  (frac {FRAC})")

def keep(clear_outer, out):
    obj = load_joined()
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.bisect(plane_co=(0, 0, CUT), plane_no=(0, 0, 1),
                        clear_outer=clear_outer, clear_inner=not clear_outer, use_fill=True)
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print("saved ->", out)

keep(True, LOWER)   # keep below the cut
keep(False, UPPER)  # keep above the cut
