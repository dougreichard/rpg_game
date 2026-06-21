"""Retarget service core (Blender) — conform a rigged GLB to a target rig profile + graft clips.

Standalone + reusable: the Character Farm's rig stage calls this, but you can also retarget ANY
rigged file (a Mixamo/free asset, an old character) into the project's `synty` rig. CPU only — no GPU.

  blender --background --python retarget_char.py -- <in.glb> <out.glb> \
      [--to synty] [--from auto] [--clips <src.glb|->] [--height <m>] [--no-clips]

- `--to`     target profile in rig_profiles.json (default: the file's default_profile = synty).
- `--from`   source profile, or "auto" (sniff bone names). Used to pick the bone_map.
- `--clips`  GLB to graft animation clips from (same target skeleton). Defaults to the target
             profile's `clip_source` (e.g. quinn.glb for synty). "-" or --no-clips = skip grafting.
- `--height` target bbox height in metres (default: profile.target_height_m or unchanged).

THIS FIRST CUT does: source detect + bone RENAME (when bone_map is non-empty) + clip GRAFT for a
COMPATIBLE (same-name) skeleton + normalize (height, feet at floor, centre) + GLB export. Cross-
proportion motion retarget (Mixamo->Synty foot-IK/hip-height bake) is a follow-up; rename+graft is
verbatim-correct when source and target skeletons share bone names (the synty->synty / library case).
"""
import bpy, sys, os, json

argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUT = argv[0], argv[1]


def opt(flag, default=None):
    return argv[argv.index(flag) + 1] if flag in argv else default


HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))   # scripts -> ... -> repo root
PROFILES = json.load(open(os.path.join(HERE, "..", "rig_profiles.json")))

TO = opt("--to", PROFILES.get("default_profile", "synty"))
FROM = opt("--from", "auto")
NO_CLIPS = "--no-clips" in argv
CLIPS = opt("--clips", None)
tp = PROFILES["profiles"].get(TO, {})
HEIGHT = float(opt("--height", tp.get("target_height_m", 0) or 0))

# --- bone signatures for source auto-detect ---
SIGS = {
    "synty":  ["Pelvis", "spine_01", "UpperArm_L", "Thigh_L"],
    "mixamo": ["mixamorig:Hips", "mixamorig:LeftArm"],
    "vrm":    ["J_Bip_C_Hips", "J_Bip_L_UpperArm"],
    "unreal": ["pelvis", "upperarm_l", "thigh_l"],
}


def repo_path(p):
    return p if os.path.isabs(p) else os.path.join(REPO, p)


def armatures():
    return [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]


def bone_names(arm):
    return set(b.name for b in arm.data.bones)


def detect_profile(arm):
    names = bone_names(arm)
    best, score = "raw", 0
    for prof, sig in SIGS.items():
        s = sum(1 for b in sig if b in names)
        if s > score:
            best, score = prof, s
    return best if score else "raw"


# ---- load input ----
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=IN)
arms = armatures()
if not arms:
    print("RETARGET: no armature in input — nothing to do"); sys.exit(1)
target = arms[0]
src_profile = detect_profile(target) if FROM == "auto" else FROM
print(f"RETARGET: in={IN} detected_from={src_profile} to={TO} bones={len(target.data.bones)}")

# ---- bone rename (source -> target), if a map is provided (bone_map is keyed by source profile) ----
bmap_all = tp.get("bone_map", {}) or {}
bmap = bmap_all.get(src_profile, {}) if isinstance(bmap_all, dict) else {}
if bmap and src_profile != TO:
    renamed = 0
    for b in target.data.bones:
        if b.name in bmap:
            b.name = bmap[b.name]; renamed += 1
    print(f"RETARGET: renamed {renamed} bones via {src_profile}->{TO} map")
elif src_profile != TO:
    print(f"RETARGET: no bone_map for {src_profile}->{TO} yet — names left as-is "
          f"(graft/clip compatibility depends on matching names)")

# ---- graft clips from the target skeleton's library (same-name skeleton) ----
clip_src = None if NO_CLIPS else (CLIPS if (CLIPS and CLIPS != "-") else tp.get("clip_source"))
if clip_src:
    clip_src = repo_path(clip_src)
    # drop the input's OWN actions first so the grafted clips keep CLEAN names (else Blender renames
    # the imported library clips to attack.001/walk.001/... on collision — and the game plays by name).
    target.animation_data_clear()
    for a in list(bpy.data.actions):
        bpy.data.actions.remove(a)
    before = set(bpy.data.objects)
    acts_before = set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=clip_src)
    new_objs = [o for o in bpy.data.objects if o not in before]
    grafted = [a for a in bpy.data.actions if a not in acts_before]
    for a in grafted:
        a.use_fake_user = True                       # survive object deletion
    # clear any clips already on the target, then NLA-bind the grafted ones to it
    target.animation_data_clear()
    target.animation_data_create()
    for a in grafted:
        trk = target.animation_data.nla_tracks.new()
        trk.name = a.name
        f0 = int(a.frame_range[0])
        trk.strips.new(a.name, f0, a)
        trk.mute = False
    # delete the clip-source's imported objects (keep only the grafted actions + our target)
    bpy.ops.object.select_all(action="DESELECT")
    for o in new_objs:
        o.select_set(True)
    bpy.ops.object.delete()
    print(f"RETARGET: grafted {len(grafted)} clips from {os.path.basename(clip_src)}: "
          f"{[a.name for a in grafted]}")

# ---- normalize: scale to height, feet at floor (min Y -> 0), centre X/Z ----
def mesh_bounds():
    mn = [1e9] * 3; mx = [-1e9] * 3
    from mathutils import Vector
    for o in bpy.context.scene.objects:
        if o.type != "MESH":
            continue
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            for i in range(3):
                mn[i] = min(mn[i], w[i]); mx[i] = max(mx[i], w[i])
    return mn, mx


if HEIGHT > 0:
    bpy.context.view_layer.objects.active = target
    mn, mx = mesh_bounds()
    h = mx[1] - mn[1]
    if h > 0:
        s = HEIGHT / h
        target.scale = (target.scale[0] * s, target.scale[1] * s, target.scale[2] * s)
        bpy.context.view_layer.update()
        mn, mx = mesh_bounds()
        target.location.x -= (mn[0] + mx[0]) / 2
        target.location.z -= (mn[2] + mx[2]) / 2
        target.location.y -= mn[1]
        print(f"RETARGET: normalized -> height {HEIGHT}m, feet at floor")

# ---- export ----
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_animations=True,
                          export_animation_mode="NLA_TRACKS")
print("RETARGET: saved", OUT)
