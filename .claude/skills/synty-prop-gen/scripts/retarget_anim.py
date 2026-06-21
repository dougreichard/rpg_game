"""Animate Tier 1 (Blender) — retarget an external animation onto the Synty skeleton.

Bakes a source clip (Mixamo FBX/GLB, BVH, AMASS, ...) onto the project's Synty skeleton via the
source->synty bone map in rig_profiles.json, producing one game-ready clip (named to a role) that
can be added to the clip library. In-place by default (the game moves bodies in code).

  blender --background --python retarget_anim.py -- <source_anim> <out.glb> \
      [--role walk] [--from auto] [--target-skel <synty_clips.glb>] [--keep-root]

Approach: Copy-Rotation (+ Copy-Location on Hips) constraints from each source bone to its mapped
Synty bone, then bake. Exact when source and target share a rest pose (the synty->synty self-test);
cross-proportion sources (Mixamo) get the rotations right but may need foot-IK/hip cleanup later.
"""
import bpy, sys, os, json

argv = sys.argv[sys.argv.index("--") + 1:]
SRC_FILE, OUT = argv[0], argv[1]


def opt(flag, d=None):
    return argv[argv.index(flag) + 1] if flag in argv else d


HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
PROFILES = json.load(open(os.path.join(HERE, "..", "rig_profiles.json")))
TO = "synty"
ROLE = opt("--role", None)
FROM = opt("--from", "auto")
KEEP_ROOT = "--keep-root" in argv
TARGET_SKEL = opt("--target-skel", os.path.join(REPO, PROFILES["profiles"][TO]["clip_source"]))

SIGS = {"synty": ["Pelvis", "spine_01", "Thigh_L"], "mixamo": ["mixamorig:Hips"],
        "vrm": ["J_Bip_C_Hips"], "unreal": ["pelvis", "thigh_l"]}
ROOT = "Pelvis"   # synty root/hip bone (copy-location + in-place strip target)


def imp(path):
    before = set(bpy.data.objects)
    ext = os.path.splitext(path)[1].lower()
    if ext == ".bvh":
        bpy.ops.import_anim.bvh(filepath=path, update_scene_fps=False)
    elif ext in (".fbx",):
        bpy.ops.import_scene.fbx(filepath=path)
    else:
        bpy.ops.import_scene.gltf(filepath=path)
    objs = [o for o in bpy.data.objects if o not in before]
    arm = next((o for o in objs if o.type == "ARMATURE"), None)
    return arm, objs


def detect(arm):
    names = set(b.name for b in arm.data.bones)
    best, sc = "raw", 0
    for p, sig in SIGS.items():
        s = sum(1 for b in sig if b in names)
        if s > sc:
            best, sc = p, s
    return best if sc else "raw"


bpy.ops.wm.read_factory_settings(use_empty=True)
# target Synty skeleton (clear its library clips → clean bake target)
tgt, _ = imp(TARGET_SKEL)
tgt.animation_data_clear()
# source animation
src, _ = imp(SRC_FILE)
if src is None:
    print("RETARGET-ANIM: no armature in source"); sys.exit(1)
src_profile = detect(src) if FROM == "auto" else FROM
src_action = (src.animation_data.action if src.animation_data else None) or \
             (bpy.data.actions[0] if bpy.data.actions else None)
if src.animation_data is None:
    src.animation_data_create()
src.animation_data.action = src_action
ROLE = ROLE or (src_action.name if src_action else "clip")
print(f"RETARGET-ANIM: src={os.path.basename(SRC_FILE)} from={src_profile} role={ROLE} "
      f"action={src_action.name if src_action else None}")

# source_bone -> synty_bone map (identity for synty->synty); invert to synty_bone -> source_bone
if src_profile == TO:
    inv = {b.name: b.name for b in src.data.bones if tgt.data.bones.get(b.name)}
else:
    fwd = (PROFILES["profiles"][TO].get("bone_map", {}) or {}).get(src_profile, {})
    inv = {syn: srcb for srcb, syn in fwd.items()}
print(f"RETARGET-ANIM: mapped {len(inv)} bones")

# constraints: each target bone copies its mapped source bone (rotation; +location on Hips)
bpy.context.view_layer.objects.active = tgt
bpy.ops.object.mode_set(mode="POSE")
for syn_bone, src_bone in inv.items():
    pb = tgt.pose.bones.get(syn_bone)
    if pb is None or src.pose.bones.get(src_bone) is None:
        continue
    c = pb.constraints.new("COPY_ROTATION")
    c.target = src; c.subtarget = src_bone
    if syn_bone == ROOT:
        cl = pb.constraints.new("COPY_LOCATION")
        cl.target = src; cl.subtarget = src_bone

f0 = int(src_action.frame_range[0]); f1 = int(src_action.frame_range[1])
bpy.context.scene.frame_start = f0; bpy.context.scene.frame_end = f1
bpy.ops.pose.select_all(action="SELECT")
bpy.ops.nla.bake(frame_start=f0, frame_end=f1, only_selected=False, visual_keying=True,
                 clear_constraints=True, clear_parents=False, use_current_action=True, bake_types={"POSE"})
baked = tgt.animation_data.action
baked.name = ROLE
print(f"RETARGET-ANIM: baked '{ROLE}' frames {f0}-{f1}, fcurves={len(baked.fcurves)}")

# in-place: drop Hips horizontal translation (keep vertical bob)
if not KEEP_ROOT:
    for fc in [fc for fc in baked.fcurves if fc.data_path == 'pose.bones["%s"].location' % ROOT and fc.array_index in (0, 2)]:
        baked.fcurves.remove(fc)
    print("RETARGET-ANIM: stripped %s X/Z translation (in-place)" % ROOT)

# keep only target + baked clip; export
bpy.ops.object.mode_set(mode="OBJECT")
bpy.ops.object.select_all(action="DESELECT")
for o in [o for o in bpy.data.objects if o is not tgt]:
    o.select_set(True)
bpy.ops.object.delete()
baked.use_fake_user = True
tgt.animation_data_clear(); tgt.animation_data_create()
trk = tgt.animation_data.nla_tracks.new(); trk.name = ROLE
trk.strips.new(ROLE, int(baked.frame_range[0]), baked)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_animations=True,
                          export_animation_mode="NLA_TRACKS")
print("RETARGET-ANIM: saved", OUT)
