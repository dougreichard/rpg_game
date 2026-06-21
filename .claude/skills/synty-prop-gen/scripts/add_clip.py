"""Add ONE animation clip to a character GLB — ADDITIVELY (keep every other clip + the mesh).

Step 2 of the /add_clip pipeline (step 1 = retarget_anim.py bakes an external clip onto the canonical
Synty skeleton, named `role`). This APPENDS that role clip onto a target character:
  - REPLACES only `role` (idempotent — re-run with same role swaps just that clip),
  - PRESERVES every other clip (incl. each lead's unique 'special'),
  - touches ONLY animation data → the mesh + joined/weighted accessories are untouched,
  - SKIPS (writes no output) if the target isn't the Synty rig (clip bones don't match its bones).

  blender --background --python add_clip.py -- <target.glb> <role_clip.glb> <role> <out.glb>
"""
import bpy, sys, os

argv = sys.argv[sys.argv.index("--") + 1:]
TARGET, ROLECLIP, ROLE, OUT = argv[0], argv[1], argv[2], argv[3]


def _clip_bones(action):
    bs = set()
    for fc in action.fcurves:
        if fc.data_path.startswith('pose.bones["'):
            bs.add(fc.data_path.split('"')[1])
    return bs


bpy.ops.wm.read_factory_settings(use_empty=True)

# 1) target character (mesh + skeleton + existing clips + accessories)
bpy.ops.import_scene.gltf(filepath=os.path.abspath(TARGET))
arm = next((o for o in bpy.context.scene.objects if o.type == "ARMATURE"), None)
if arm is None:
    print("ADDCLIP: no armature in target"); sys.exit(1)
target_bones = set(b.name for b in arm.data.bones)

# existing actions = the target's clips; drop any prior `role` (idempotent replace), keep the rest
for a in list(bpy.data.actions):
    if a.name == ROLE:
        bpy.data.actions.remove(a)
keep = list(bpy.data.actions)

# 2) import the role-clip source (one clip named ROLE on the Synty skeleton)
before_objs = set(bpy.data.objects)
acts_before = set(bpy.data.actions)
bpy.ops.import_scene.gltf(filepath=os.path.abspath(ROLECLIP))
new_objs = [o for o in bpy.data.objects if o not in before_objs]
new_acts = [a for a in bpy.data.actions if a not in acts_before]
role_act = next((a for a in new_acts if a.name == ROLE), new_acts[0] if new_acts else None)
if role_act is None:
    print("ADDCLIP: no clip found in role source"); sys.exit(1)
role_act.name = ROLE

# sanity: does the clip drive bones THIS character actually has? (skip non-Synty targets)
rb = _clip_bones(role_act)
match = len(rb & target_bones)
print(f"ADDCLIP: role '{ROLE}' clip bones={len(rb)} match-on-{os.path.basename(TARGET)}={match}/{len(rb)}")
if rb and match < max(1, len(rb) // 2):
    print("ADDCLIP: SKIP — target shares too few bones with the clip (not the Synty rig). No output written.")
    sys.exit(3)

# 3) drop the role source's objects (keep the action), then NLA-bind ALL clips back to the target
for a in keep + [role_act]:
    a.use_fake_user = True
bpy.ops.object.select_all(action="DESELECT")
for o in new_objs:
    o.select_set(True)
bpy.ops.object.delete()

final = keep + [role_act]
arm.animation_data_clear(); arm.animation_data_create()
for a in final:
    trk = arm.animation_data.nla_tracks.new(); trk.name = a.name
    trk.strips.new(a.name, int(a.frame_range[0]), a)

bpy.ops.export_scene.gltf(filepath=os.path.abspath(OUT), export_format="GLB",
                          export_animations=True, export_animation_mode="NLA_TRACKS")
print(f"ADDCLIP: {os.path.basename(TARGET)} -> {len(final)} clips (added '{ROLE}'): "
      f"{sorted(a.name for a in final)}")
print("ADDCLIP: saved", OUT)
