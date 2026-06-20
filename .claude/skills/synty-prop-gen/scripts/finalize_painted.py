"""Stage 4 (painted track) — finalize a Hunyuan-PAINTED glb for the game.

KEEP THE PAINTED MESH EXACTLY AS-IS. Hunyuan's paint output is a non-watertight, multi-shell
mesh (thousands of open patch seams). It renders correctly in Godot as delivered, but ANY
geometry processing corrupts it:
  - Limited Dissolve folds faces across the open gaps -> "crushed",
  - normals_make_consistent can't orient a non-manifold mesh -> flips patches inward -> Godot
    culls them -> "holes",
  - auto-smooth writes custom split normals that read as dented on the low-poly result.
(We learned this the hard way — every one of those steps made the bench/barrel look bad.)

So this stage does ONLY the safe, transform/texture/material work the Mac needs:
  - downsize the baked diffuse texture (2048 -> 512: sharp on a low-poly prop, tiny to commit),
  - normalize: scale bbox height to target metres, centre X/Y, base at floor (min up -> 0),
  - matte material: force metallic=0 / roughness=0.9 (Hunyuan leaves metallicFactor unset -> glTF
    default 1.0 -> imports as polished metal in Godot; the diffuse texture carries all the colour).
No dissolve, no normals recalc, no shading change, no weld — geometry is untouched.

  blender --background --python finalize_painted.py -- <painted.glb> <out.glb> [tex=512] [target_height_m=1.0]
"""
import bpy, sys
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
pos = [a for a in argv if not a.startswith("--")]
IN, OUT = pos[0], pos[1]
TEX = int(pos[2]) if len(pos) > 2 else 512
TARGET_HEIGHT = float(pos[3]) if len(pos) > 3 else 1.0   # bbox height in metres (1 unit = 1 m)
PBR = "--pbr" in argv   # keep Hunyuan's baked metallic-roughness map (don't force matte)

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
print("painted tris (kept as-is):", len(obj.data.polygons))

# downsize the baked texture(s) — scale + pack so the GLB export embeds the smaller image
for img in list(bpy.data.images):
    try:
        if max(img.size) > TEX:
            img.scale(TEX, TEX); img.pack()
            print("texture downsized ->", TEX, img.name)
    except Exception as e:
        print("tex skip", img.name, e)

# normalize transform only (geometry untouched)
def bounds():
    mn = [1e9] * 3; mx = [-1e9] * 3
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

# matte Synty material (default): kill the glTF default metallic=1.0 (polished metal) + low roughness
# so the painted prop imports matte (the baked diffuse carries the colour). In --pbr mode, KEEP
# Hunyuan's baked metallic-roughness map/factors instead (full PBR look).
import os
_mr_path = os.path.abspath(IN[:-4] + "_mr.png")   # combined glTF MR map written by the paint stage (gen_mr)
if PBR and os.path.exists(_mr_path):
    # wire the combined metallic-roughness map: glTF G=roughness, B=metallic. Blender's exporter
    # detects Roughness<-Green / Metallic<-Blue of one Non-Color image and writes metallicRoughnessTexture.
    img = bpy.data.images.load(_mr_path); img.colorspace_settings.name = "Non-Color"
    for mat in bpy.data.materials:
        if not (mat.use_nodes and mat.node_tree):
            continue
        bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if not bsdf:
            continue
        nt = mat.node_tree
        tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = img; tex.image.colorspace_settings.name = "Non-Color"
        sep = nt.nodes.new("ShaderNodeSeparateColor")
        nt.links.new(tex.outputs["Color"], sep.inputs["Color"])
        nt.links.new(sep.outputs["Green"], bsdf.inputs["Roughness"])
        nt.links.new(sep.outputs["Blue"], bsdf.inputs["Metallic"])
        print("PBR: packed metallic-roughness map ->", mat.name)
else:
    if PBR:
        print("PBR requested but no _mr.png — falling back to matte (avoids shiny metallic=1.0 default)")
    # matte Synty material: kill the glTF default metallic=1.0 + low roughness (baked diffuse carries colour)
    for mat in bpy.data.materials:
        if not (mat.use_nodes and mat.node_tree):
            continue
        for node in mat.node_tree.nodes:
            if node.type == "BSDF_PRINCIPLED":
                node.inputs["Metallic"].default_value = 0.0
                node.inputs["Roughness"].default_value = 0.9
                print("matte material:", mat.name)

bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB")
print("final tris:", len(obj.data.polygons), "-> saved", OUT)
