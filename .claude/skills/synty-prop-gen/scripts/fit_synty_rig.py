"""Synty rig fit (Blender) — the SYNTY path of the Character Farm.

UniRig emits an unlabeled, variable skeleton (bone_N), so for the GAME we don't use it: we rig the
mesh to the project's OWN canonical Synty skeleton (49 bones from synty_clips.glb) + graft the 9 game
clips, so the result is drop-in for player_3d.gd / enemy_3d.gd. Skinning v1 = Blender automatic
weights (decent for low-poly); a UniRig-skin upgrade is a future option.

  blender --background --python fit_synty_rig.py -- <mesh.glb> <out.glb> [--skeleton <clips.glb>] [--height 1.7]

Robust to a rigged input (unparents + drops its armature, keeps the mesh). Co-scales the canonical
skeleton and the mesh to the target height, feet at floor, centred, then auto-skins.
"""
import bpy, sys, os
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
def opt(f, d=None): return argv[argv.index(f) + 1] if f in argv else d
IN = os.path.abspath(argv[0]); OUT = os.path.abspath(argv[1])
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
SKEL = os.path.abspath(opt("--skeleton", os.path.join(REPO, "assets", "animations", "synty_clips.glb")))
HEIGHT = float(opt("--height", 1.7))


def world_bounds(objs):
    mn = [1e9] * 3; mx = [-1e9] * 3
    for o in objs:
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            for i in range(3):
                mn[i] = min(mn[i], w[i]); mx[i] = max(mx[i], w[i])
    return mn, mx


def fit_to_height(objs):
    """Scale a group so its height (Y) == HEIGHT, feet at Y=0, centred on X/Z."""
    mn, mx = world_bounds(objs)
    h = mx[1] - mn[1]
    if h <= 0:
        return
    s = HEIGHT / h
    for o in objs:
        o.scale = tuple(v * s for v in o.scale)
    bpy.context.view_layer.update()
    mn, mx = world_bounds(objs)
    for o in objs:
        o.location.x -= (mn[0] + mx[0]) / 2
        o.location.z -= (mn[2] + mx[2]) / 2
        o.location.y -= mn[1]
    bpy.context.view_layer.update()


bpy.ops.wm.read_factory_settings(use_empty=True)

# 1) canonical Synty skeleton (+ 9 clips as NLA tracks)
b0 = set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=SKEL)
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE" and o not in b0)

# 2) the mesh — drop any armature it carries, keep the mesh geometry
b1 = set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=IN)
imported = [o for o in bpy.data.objects if o not in b1]
meshes = [o for o in imported if o.type == "MESH"]
if not meshes:
    print("FIT: no mesh in input"); sys.exit(1)
for o in meshes:                       # unparent (keep transform) in case it was rigged
    if o.parent:
        mw = o.matrix_world.copy(); o.parent = None; o.matrix_world = mw
for o in imported:                     # delete the input's own armature/empties
    if o.type != "MESH":
        bpy.data.objects.remove(o, do_unlink=True)
# join meshes into one
bpy.ops.object.select_all(action="DESELECT")
for o in meshes:
    o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
mesh = bpy.context.view_layer.objects.active

# 3) co-scale skeleton + mesh to target height, feet at floor, centred (so bones sit inside the mesh)
fit_to_height([arm])
fit_to_height([mesh])
for o in (arm, mesh):
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    o.select_set(False)

# 4) auto-skin: parent mesh -> armature with automatic (bone-heat) weights
bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True); arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.parent_set(type="ARMATURE_AUTO")
print(f"FIT: skinned mesh ({len(mesh.data.polygons)} tris) to {len(arm.data.bones)} Synty bones; "
      f"clips={[t.name for t in (arm.animation_data.nla_tracks if arm.animation_data else [])]}")

# 5) export (armature + skinned mesh + the grafted clips)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_animations=True,
                          export_animation_mode="NLA_TRACKS")
print("FIT: saved", OUT)
