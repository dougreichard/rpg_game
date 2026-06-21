"""fit_quadruped_rig — bind a generated/painted quadruped BODY to a named quadruped rig.

The Character Farm's `/generate_character template=quadruped` paints a good mesh but ships a
generic UniRig (bone_0..N, no clips). This conforms that body to the project's named quadruped
skeleton by transferring skin weights from a DONOR (the rig reference + its clips) onto the body,
then binding + exporting body + named skeleton + clips + the body's paint.

  blender --background --python fit_quadruped_rig.py -- <donor.glb> <body.glb> <out.glb> [yaw_deg]

- donor.glb : a mesh rigged to the target quadruped skeleton, carrying the clips you want
              (e.g. assets/models/pets/frosty.glb / quadruped_ref.glb). Its skeleton+actions are reused.
- body.glb  : the farm-generated painted mesh to re-rig (its own generic armature is discarded).
- yaw_deg   : optional Y rotation to align the body's facing to the donor before weight transfer
              (0 worked for the farm Hunyuan output; flip 180 if legs/head map backwards).

Method: uniform-scale + recenter body to the donor bbox -> Data Transfer VGROUP_WEIGHTS
(POLYINTERP_NEAREST, active=donor SOURCE -> selected=body DEST, use_create) -> parent_set ARMATURE.
PROVEN locally for Frosty (farm mesh + old-frosty donor). Port to the farm as the quadruped rig stage.
"""
import bpy, sys, math
from mathutils import Vector
a = sys.argv[sys.argv.index("--")+1:]
DONOR, BODY, OUT = a[0], a[1], a[2]
YAW = float(a[3]) if len(a) > 3 else 0.0

def bbox(o):
    pts=[o.matrix_world @ Vector(c) for c in o.bound_box]
    mn=Vector((min(p.x for p in pts),min(p.y for p in pts),min(p.z for p in pts)))
    mx=Vector((max(p.x for p in pts),max(p.y for p in pts),max(p.z for p in pts)))
    return mn,mx,(mn+mx)/2,(mx-mn)

bpy.ops.wm.read_factory_settings(use_empty=True)

# --- donor: armature (named skel + clips) + its reference mesh -----------------
bpy.ops.import_scene.gltf(filepath=DONOR)
donor_arm = next(o for o in bpy.data.objects if o.type=="ARMATURE")
donor_mesh = max([o for o in bpy.data.objects if o.type=="MESH"], key=lambda o: len(o.data.vertices))
dmn,dmx,dctr,ddim = bbox(donor_mesh)

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

# --- align body to donor: optional yaw, uniform scale to donor longest dim, recenter
bpy.context.view_layer.objects.active=body
bpy.ops.object.select_all(action='DESELECT'); body.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
if abs(YAW) > 1e-6:
    body.rotation_euler=(0.0, math.radians(YAW), 0.0)
    bpy.ops.object.transform_apply(rotation=True)
bmn,bmx,bctr,bdim=bbox(body)
s = max(ddim)/max(bdim) if max(bdim)>0 else 1.0
body.scale=(s,s,s); bpy.ops.object.transform_apply(scale=True)
bmn,bmx,bctr,bdim=bbox(body)
body.location += (dctr - bctr); bpy.ops.object.transform_apply(location=True)

# --- transfer skin weights donor_mesh -> body (ACTIVE=source, SELECTED=dest) ----
bpy.ops.object.select_all(action='DESELECT')
donor_mesh.select_set(True); body.select_set(True)
bpy.context.view_layer.objects.active=donor_mesh
bpy.ops.object.data_transfer(
    use_reverse_transfer=False,
    data_type='VGROUP_WEIGHTS',
    vert_mapping='POLYINTERP_NEAREST',
    layers_select_src='ALL', layers_select_dst='NAME', use_create=True)
bpy.context.view_layer.objects.active=body
for m in list(body.modifiers):
    if m.type=="DATA_TRANSFER":
        bpy.ops.object.modifier_apply(modifier=m.name)

# --- bind body to the donor armature (parent_set wires modifier+skin correctly) -
bpy.data.objects.remove(donor_mesh, do_unlink=True)
for m in list(body.modifiers):
    if m.type=="ARMATURE": body.modifiers.remove(m)
body.parent=None
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True); donor_arm.select_set(True)
bpy.context.view_layer.objects.active=donor_arm
bpy.ops.object.parent_set(type='ARMATURE')
bpy.context.view_layer.update()

# --- export body + donor armature + clips --------------------------------------
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True); donor_arm.select_set(True)
bpy.context.view_layer.objects.active=donor_arm
bpy.ops.export_scene.gltf(filepath=OUT, use_selection=True,
    export_animations=True, export_skins=True)
weighted = sum(1 for v in body.data.vertices if any(g.weight > 0 for g in v.groups))
print("FIT_OUT", OUT, "scale", round(s,4), "bodyverts", len(body.data.vertices),
      "weighted", weighted, "vgroups", len(body.vertex_groups),
      "clips", [act.name for act in bpy.data.actions])
