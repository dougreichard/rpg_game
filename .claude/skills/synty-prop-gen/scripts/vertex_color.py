"""Stage 3.6 (optional) — bake multi-colour onto a shape-only prop via VERTEX COLORS, so
it reads multi-tone like a Synty atlas without any texture/UVs. Colours are assigned by
height band (fraction of the prop's Z extent), e.g. a bench: dark-wood legs -> lighter-wood
top -> steel rods/tools. Godot renders them when the material has vertex_color_use_as_albedo
(see Level3D / the level's _vcolor_mat helper). Does NOT change the transform.

  blender --background --python vertex_color.py -- <in.glb> <out.glb> "band1,band2,..."
  each band = "frac:r,g,b" (frac = top of the band, 0..1; last band should be 1.0)
  e.g. "0.55:0.30,0.19,0.11  0.63:0.42,0.28,0.16  1.0:0.55,0.57,0.62"
"""
import bpy, sys
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUT = argv[0], argv[1]
BANDS = []
for tok in argv[2].split():
    frac, rgb = tok.split(":")
    r, g, b = (float(x) for x in rgb.split(","))
    BANDS.append((float(frac), (r, g, b, 1.0)))
BANDS.sort()

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=IN)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
bpy.ops.object.select_all(action="DESELECT")
for o in meshes:
    o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
obj = bpy.context.view_layer.objects.active
me = obj.data

zs = [(obj.matrix_world @ v.co).z for v in me.vertices]
zmin, zmax = min(zs), max(zs)
span = max(zmax - zmin, 1e-6)

# fresh, single POINT-domain byte-colour attribute, set ACTIVE so it is the one COLOR_0
# (a stray extra color attr otherwise exports as white COLOR_0 and Godot reads that).
for a in list(me.color_attributes):
    me.color_attributes.remove(a)
col = me.color_attributes.new(name="Col", type="BYTE_COLOR", domain="POINT")
me.color_attributes.active_color_index = 0
me.color_attributes.render_color_index = 0

def band_color(frac: float):
    for top, rgba in BANDS:
        if frac <= top:
            return rgba
    return BANDS[-1][1]

for v in me.vertices:
    frac = ((obj.matrix_world @ v.co).z - zmin) / span
    col.data[v.index].color = band_color(frac)

bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB",
                          export_all_vertex_colors=False, export_vertex_color="ACTIVE")
print("vertex-coloured", len(BANDS), "bands ->", OUT)
