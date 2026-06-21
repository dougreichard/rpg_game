"""Convert a GLB to FBX (Blender) — preserve mesh, materials/textures, armature+skin, and clips.

A format-only converter so any Prop Farm stage can emit FBX while keeping GLB the canonical internal
format. Textures are embedded into the FBX (path_mode COPY + embed) so the single file is portable
(e.g. for import into AccuRIG / Rigify / other DCC tools).

  blender --background --python to_fbx.py -- <in.glb> <out.fbx>
"""
import bpy, sys, os

argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUT = os.path.abspath(argv[0]), os.path.abspath(argv[1])

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=IN)
bpy.ops.export_scene.fbx(
    filepath=OUT,
    use_selection=False,
    apply_unit_scale=True,
    bake_space_transform=False,
    add_leaf_bones=False,
    use_armature_deform_only=False,
    bake_anim=True,
    bake_anim_use_nla_strips=True,
    bake_anim_use_all_actions=True,
    path_mode="COPY",
    embed_textures=True,
    mesh_smooth_type="FACE",
)
n_arm = sum(1 for o in bpy.data.objects if o.type == "ARMATURE")
n_mesh = sum(1 for o in bpy.data.objects if o.type == "MESH")
print(f"TOFBX_OUT {OUT} meshes={n_mesh} armatures={n_arm} actions={len(bpy.data.actions)}")
