"""Graft several same-skeleton clips onto a character GLB at once — additively (keep mesh + every
other clip). Like add_clip.py but multi-clip + renames each source action to a role name. Use when a
single source GLB carries multiple clips on the SAME skeleton as the target (no retarget needed).

  blender --background --python graft_clips.py -- <target.glb> <source.glb> <out.glb> Src=role [Src2=role2 ...]

e.g. ... -- frosty.glb new_dog.glb frosty.glb Bite=bite Sit=sit   (keeps frosty's idle/run/walk, adds bite+sit)
A role that already exists on the target is REPLACED (idempotent). Only animation data is touched.
"""
import bpy, sys, os

argv = sys.argv[sys.argv.index("--") + 1:]
TARGET, SOURCE, OUT = argv[0], argv[1], argv[2]
MAP = dict(p.split("=", 1) for p in argv[3:])   # {source_action_name: role_name}

# NOTE: use this only when source and target share the SAME skeleton (verify bone names match
# externally first) — by-name NLA graft, no retarget. Blender 5.x dropped Action.fcurves (slotted
# actions), so the old per-clip bone-overlap guard is omitted; identical-rig is the precondition.

bpy.ops.wm.read_factory_settings(use_empty=True)

# 1) target character (mesh + skeleton + existing clips + accessories)
bpy.ops.import_scene.gltf(filepath=os.path.abspath(TARGET))
arm = next((o for o in bpy.context.scene.objects if o.type == "ARMATURE"), None)
if arm is None:
    print("GRAFT: no armature in target"); sys.exit(1)
target_bones = set(b.name for b in arm.data.bones)
roles = set(MAP.values())
# drop any prior clips with the target role names (idempotent replace), keep the rest
for a in list(bpy.data.actions):
    if a.name in roles:
        bpy.data.actions.remove(a)
keep = list(bpy.data.actions)

# 2) import the source clips
before_objs = set(bpy.data.objects)
acts_before = set(bpy.data.actions)
bpy.ops.import_scene.gltf(filepath=os.path.abspath(SOURCE))
new_objs = [o for o in bpy.data.objects if o not in before_objs]
new_acts = [a for a in bpy.data.actions if a not in acts_before]

grafted = []
for src_name, role in MAP.items():
    act = next((a for a in new_acts if a.name == src_name), None)
    if act is None:
        print(f"GRAFT: source has no action '{src_name}' (have {[a.name for a in new_acts]})"); sys.exit(2)
    print(f"GRAFT: '{src_name}'->'{role}'")
    act.name = role
    grafted.append(act)

# 3) drop the source objects (keep the actions), NLA-bind ALL clips back onto the target armature
for a in keep + grafted:
    a.use_fake_user = True
bpy.ops.object.select_all(action="DESELECT")
for o in new_objs:
    o.select_set(True)
bpy.ops.object.delete()

final = keep + grafted
arm.animation_data_clear(); arm.animation_data_create()
for a in final:
    trk = arm.animation_data.nla_tracks.new(); trk.name = a.name
    trk.strips.new(a.name, int(a.frame_range[0]), a)

bpy.ops.export_scene.gltf(filepath=os.path.abspath(OUT), export_format="GLB",
                          export_animations=True, export_animation_mode="NLA_TRACKS")
print(f"GRAFT: {os.path.basename(TARGET)} -> {len(final)} clips "
      f"(added {sorted(a.name for a in grafted)}): {sorted(a.name for a in final)}")
