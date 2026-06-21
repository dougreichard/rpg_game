"""fit_quadruped_rig — bind a generated/painted quadruped BODY to a named quadruped rig.

The Character Farm's `/generate_character template=quadruped` paints a good mesh but ships a
generic UniRig (bone_0..N, no clips). This conforms that body to the project's named quadruped
skeleton + clips from a DONOR, then exports body + named skeleton + clips + the body's paint.

  blender --background --python fit_quadruped_rig.py -- <donor.glb> <body.glb> <out.glb> [yaw_deg]

- donor.glb : a mesh rigged to the target quadruped skeleton, carrying the clips you want
              (e.g. assets/models/pets/frosty.glb). Its skeleton + actions are reused.
- body.glb  : the farm-generated painted mesh to re-rig (its own generic armature is discarded).
- yaw_deg   : optional Y rotation to align the body's facing to the donor (0 worked for Hunyuan output;
              flip 180 if legs/head map backwards).

METHOD — skeleton-fit (v2): the donor skeleton is reused for its clips, but FIRST it is **per-axis
scaled** to the new body's bounding box, so the leg/spine bones actually span THIS body's proportions
(a tall Great Dane vs a short schnoodle). Without this, a tall dog gets the donor's short legs and the
run clip collapses. Weights: try bone-heat auto-weights from the fitted skeleton (geometry-aware);
fall back to nearest-surface projection from the per-axis-scaled donor mesh (bone-heat often fails on
non-manifold generated meshes). The donor clips ride along (same per-bone rotation curves, now on a
correctly-proportioned skeleton). PROVEN to fix the Great Dane stress case vs the old uniform-reuse.

Blender 5.x note: data_transfer is ACTIVE(source)->SELECTED(dest); parent_set is what emits a glTF skin.
"""
import bpy, sys, math
from mathutils import Vector
a = sys.argv[sys.argv.index("--")+1:]
DONOR, BODY, OUT = a[0], a[1], a[2]
YAW = float(a[3]) if len(a) > 3 else 0.0


def bbox(objs):
    mn=Vector((1e9,)*3); mx=Vector((-1e9,)*3)
    for o in objs:
        for c in o.bound_box:
            w=o.matrix_world@Vector(c)
            for i in range(3): mn[i]=min(mn[i],w[i]); mx[i]=max(mx[i],w[i])
    return mn,mx,(mn+mx)/2,(mx-mn)


bpy.ops.wm.read_factory_settings(use_empty=True)

# --- donor: armature (named skel + clips) + its reference mesh -----------------
bpy.ops.import_scene.gltf(filepath=DONOR)
donor_arm = next(o for o in bpy.data.objects if o.type=="ARMATURE")
donor_mesh = max([o for o in bpy.data.objects if o.type=="MESH"], key=lambda o: len(o.data.vertices))

# --- body: the farm-painted mesh (discard its generic armature) ----------------
before=set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=BODY)
imp=[o for o in bpy.data.objects if o not in before]
body=max([o for o in imp if o.type=="MESH"], key=lambda o: len(o.data.vertices))
for o in imp:
    if o.type=="ARMATURE": bpy.data.objects.remove(o, do_unlink=True)
body.parent=None
for m in list(body.modifiers):
    if m.type=="ARMATURE": body.modifiers.remove(m)
body.vertex_groups.clear()
bpy.context.view_layer.objects.active=body
bpy.ops.object.select_all(action='DESELECT'); body.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
if abs(YAW) > 1e-6:
    body.rotation_euler=(0.0, math.radians(YAW), 0.0)
    bpy.ops.object.transform_apply(rotation=True)

# --- PER-AXIS fit the donor (arm + its mesh) to the body's bbox; body keeps true size
bmn,bmx,bctr,bdim = bbox([body])
dmn,dmx,dctr,ddim = bbox([donor_mesh])
sx = bdim.x/ddim.x if ddim.x>1e-5 else 1.0
sy = bdim.y/ddim.y if ddim.y>1e-5 else 1.0
sz = bdim.z/ddim.z if ddim.z>1e-5 else 1.0
bpy.ops.object.select_all(action='DESELECT')
donor_arm.select_set(True); bpy.context.view_layer.objects.active=donor_arm
donor_arm.scale=(sx,sy,sz)
bpy.ops.object.transform_apply(scale=True)   # bakes into bones + skinned donor mesh
dmn,dmx,dctr,ddim = bbox([donor_mesh])
donor_arm.location += (bctr - dctr); bpy.ops.object.transform_apply(location=True)
print("FIT: per-axis donor scale = %.3f,%.3f,%.3f" % (sx,sy,sz))

# --- weights: bone-heat from the fitted skeleton, else nearest-surface projection
weighted_ok = False
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True); donor_arm.select_set(True)
bpy.context.view_layer.objects.active=donor_arm
try:
    bpy.ops.object.parent_set(type='ARMATURE_AUTO')
    weighted_ok = any(v.groups for v in body.data.vertices)
except Exception as e:
    print("FIT: bone-heat failed:", e)
print("FIT: bone-heat auto-weights ok =", weighted_ok)

if not weighted_ok:
    if body.parent: body.parent=None
    for m in list(body.modifiers):
        if m.type=="ARMATURE": body.modifiers.remove(m)
    body.vertex_groups.clear()
    bpy.ops.object.select_all(action='DESELECT')
    donor_mesh.select_set(True); body.select_set(True)
    bpy.context.view_layer.objects.active=donor_mesh
    bpy.ops.object.data_transfer(use_reverse_transfer=False, data_type='VGROUP_WEIGHTS',
        vert_mapping='POLYINTERP_NEAREST', layers_select_src='ALL', layers_select_dst='NAME', use_create=True)
    bpy.context.view_layer.objects.active=body
    for m in list(body.modifiers):
        if m.type=="DATA_TRANSFER": bpy.ops.object.modifier_apply(modifier=m.name)
    bpy.ops.object.select_all(action='DESELECT')
    body.select_set(True); donor_arm.select_set(True)
    bpy.context.view_layer.objects.active=donor_arm
    bpy.ops.object.parent_set(type='ARMATURE')
    print("FIT: used nearest-surface projection weights")

# --- export body + donor armature + clips --------------------------------------
bpy.data.objects.remove(donor_mesh, do_unlink=True)
bpy.context.view_layer.update()
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True); donor_arm.select_set(True)
bpy.context.view_layer.objects.active=donor_arm
bpy.ops.export_scene.gltf(filepath=OUT, use_selection=True, export_animations=True, export_skins=True)
weighted = sum(1 for v in body.data.vertices if any(g.weight > 0 for g in v.groups))
print("FIT_OUT", OUT, "weighted", weighted, "/", len(body.data.vertices),
      "clips", [act.name for act in bpy.data.actions])
