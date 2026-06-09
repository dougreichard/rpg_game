#!/usr/bin/env python3
"""
Hunkle Bunkle custom tileset generator.
Produces assets/art/tiles/hb_tiles.png — 192x128 px (12 cols x 8 rows of 16x16 tiles).
Loaded by PlaceholderArt.make_hb_tileset() in Godot (scaled 2x at runtime -> 32x32).

Terrain rows (y-coord in atlas_coords):
  0  STONE    - Old Parish Church, Clocktower, Library & Archive
  1  WORKSHOP - Pipe Organ Works, Iron & Strings Gym
  2  WOOD     - Recording Studio, Carnival & Fairground
  3  OUTDOOR  - Zip Line Park, The Drop
  4  TUNNEL   - Underground Tunnels
  5  DOCK     - Harbor & Docks
  6  CARPET   - Grand Marquee Cinema
  7  CYBER    - VR Escape Room (main Boot Chamber floor only)

Tile columns: 0=primary plain, 1=accent, 2-11=variants.
"""
from PIL import Image
import os, math

TILE = 16
COLS = 12
ROWS = 8
W = COLS * TILE   # 192
H = ROWS * TILE   # 128

# ── Palette ──────────────────────────────────────────────────────────────────

def c(r, g, b): return (r, g, b, 255)

# STONE
S_BASE  = c(148,144,140); S_DARK  = c( 88, 85, 82)
S_LIGHT = c(185,180,173); S_MORT  = c( 62, 60, 58)
S_ACC   = c(178,155, 95); S_MOSS  = c( 72, 95, 55)
S_WET   = c( 95,105,115)

# WORKSHOP
W_BASE  = c(155,125, 90); W_DARK  = c( 95, 72, 48)
W_LIGHT = c(198,165,118); W_MORT  = c( 68, 52, 38)
W_ACC   = c(205,158, 38); W_METAL = c(105,105,108)
W_GRATE = c( 72, 72, 76)

# WOOD
O_BASE  = c(158,108, 60); O_DARK  = c(102, 68, 32)
O_LIGHT = c(198,148, 92); O_GRAIN = c(132, 90, 48)
O_STAGE = c( 88, 58, 28); O_KNOT  = c( 72, 48, 22)

# OUTDOOR
T_BASE  = c(108, 92, 65); T_DARK  = c( 65, 52, 35)
T_LIGHT = c(148,128, 92); T_GRASS = c( 75,105, 52)
T_STONE = c(115,110,100); T_SAND  = c(178,158,118)
T_GRAV  = c(122,116,105)

# TUNNEL
U_BASE  = c( 52, 48, 44); U_DARK  = c( 28, 26, 24)
U_LIGHT = c( 82, 76, 70); U_DAMP  = c( 38, 52, 52)
U_RUST  = c( 92, 48, 28); U_GRATE = c( 58, 56, 52)

# DOCK
D_BASE  = c(112,115,112); D_DARK  = c( 68, 70, 68)
D_LIGHT = c(152,155,148); D_WOOD  = c(138,112, 78)
D_WET   = c( 78, 88, 92); D_ASPH  = c( 62, 62, 65)
D_PAINT = c(218,180, 38)

# CARPET / THEATER
P_RED   = c(138, 28, 28); P_DARK  = c( 88, 16, 16)
P_LIGHT = c(172, 52, 52); P_GOLD  = c(188,152, 48)
P_CREAM = c(212,202,182); P_MARB  = c(198,194,188)
P_VEIN  = c(148,145,152)

# CYBER
Y_BASE  = c( 16, 20, 52); Y_DARK  = c(  8, 10, 32)
Y_CYAN  = c(  0,192,192); Y_DIM   = c(  0,108,130)
Y_GLOW  = c( 72,228,228); Y_CORR  = c(195, 38,118)
Y_VOID  = c(  4,  4, 12)

# ── Draw primitives ───────────────────────────────────────────────────────────

def blank(fill=(0,0,0,255)):
    return Image.new('RGBA', (TILE, TILE), fill)

def pt(img, x, y, col):
    if 0 <= x < TILE and 0 <= y < TILE:
        img.putpixel((x, y), col)

def hline(img, x0, x1, y, col):
    for x in range(max(0,x0), min(TILE,x1+1)):
        pt(img, x, y, col)

def vline(img, x, y0, y1, col):
    for y in range(max(0,y0), min(TILE,y1+1)):
        pt(img, x, y, col)

def rect(img, x0, y0, w, h, col):
    for dy in range(h):
        for dx in range(w):
            pt(img, x0+dx, y0+dy, col)

def border(img, col):
    hline(img, 0, TILE-1, 0, col)
    hline(img, 0, TILE-1, TILE-1, col)
    vline(img, 0, 0, TILE-1, col)
    vline(img, TILE-1, 0, TILE-1, col)

# ── Shared helpers ────────────────────────────────────────────────────────────

def ashlar(img):
    for y in range(0, TILE, 8):
        hline(img, 0, TILE-1, y, S_MORT)
    for row in range(2):
        offs = 4 if row % 2 == 1 else 0
        for x in range(-offs, TILE, 8):
            if x >= 0:
                vline(img, x, row*8+1, row*8+7, S_MORT)

def concrete_seams(img, col):
    for y in [4, 8, 12]:
        hline(img, 0, TILE-1, y, col)

def plank_h(img, base, grain, dark, n=3):
    ph = TILE // n
    for p in range(n):
        y0 = p * ph
        hline(img, 0, TILE-1, y0, dark)
        for gy in range(y0+1, y0+ph):
            if (gy - y0) % 3 == 1:
                hline(img, 0, TILE-1, gy, grain)
    for y in range(n*ph, TILE):
        hline(img, 0, TILE-1, y, base)

def plank_v(img, base, grain, dark, n=3):
    pw = TILE // n
    for p in range(n):
        x0 = p * pw
        vline(img, x0, 0, TILE-1, dark)
        for gx in range(x0+1, x0+pw):
            if (gx - x0) % 3 == 1:
                vline(img, gx, 0, TILE-1, grain)

def grid_lines(img, step, col):
    for i in range(0, TILE, step):
        hline(img, 0, TILE-1, i, col)
        vline(img, i, 0, TILE-1, col)

# ── Row 0: STONE ─────────────────────────────────────────────────────────────

def stone_tiles():
    tiles = []

    # 0 — plain ashlar
    t = blank(S_BASE)
    ashlar(t)
    tiles.append(t)

    # 1 — ashlar with amber diamond inlay
    t = blank(S_BASE)
    ashlar(t)
    cx, cy = 4, 4
    for r in range(3):
        hline(t, cx-r, cx+r, cy-(2-r), S_ACC)
        hline(t, cx-r, cx+r, cy+(2-r), S_ACC)
    tiles.append(t)

    # 2 — cracked ashlar
    t = blank(S_BASE)
    ashlar(t)
    for i in range(6):
        pt(t, 3+i, 5+i, S_DARK)
    tiles.append(t)

    # 3 — worn/lighter centre
    t = blank(S_BASE)
    ashlar(t)
    rect(t, 5, 1, 5, 5, S_LIGHT)
    tiles.append(t)

    # 4 — iron bolt corners
    t = blank(S_BASE)
    ashlar(t)
    for bx, by in [(2,2),(1,2),(2,1),(10,10),(11,10),(10,11)]:
        pt(t, bx, by, S_DARK)
    tiles.append(t)

    # 5 — smooth flagstone bevel
    t = blank(S_LIGHT)
    rect(t, 0, 0, TILE, 1, S_MORT)
    rect(t, 0, 0, 1, TILE, S_MORT)
    rect(t, 0, TILE-1, TILE, 1, S_BASE)
    rect(t, TILE-1, 0, 1, TILE, S_BASE)
    tiles.append(t)

    # 6 — heavy mortar
    t = blank(S_DARK)
    for y in range(0, TILE, 8):
        rect(t, 0, y, TILE, 2, S_MORT)
    for x in range(0, TILE, 6):
        rect(t, x, 0, 1, TILE, S_MORT)
    for by in range(2):
        for bx in range(-((by%2)*4), TILE, 6):
            if bx >= 0 and bx+1 < TILE:
                rect(t, bx+1, by*8+2, min(4, TILE-bx-1), 4, S_BASE)
    tiles.append(t)

    # 7 — rough noise
    t = blank(S_BASE)
    for x,y in [(1,2),(3,5),(5,1),(7,3),(9,6),(11,1),(2,8),(4,11),(6,9),(8,12),(10,7),(12,10),(1,13),(5,14)]:
        if x<TILE and y<TILE: pt(t, x, y, S_DARK)
    for x,y in [(0,4),(4,0),(8,5),(2,10),(6,14),(10,12),(14,2),(12,7)]:
        if x<TILE and y<TILE: pt(t, x, y, S_LIGHT)
    tiles.append(t)

    # 8 — mossy corner
    t = blank(S_BASE)
    ashlar(t)
    for x,y in [(12,1),(13,1),(12,2),(14,2),(13,3),(11,2),(14,3),(13,4)]:
        if x<TILE and y<TILE: pt(t, x, y, S_MOSS)
    tiles.append(t)

    # 9 — cross-joint accent
    t = blank(S_BASE)
    ashlar(t)
    hline(t, 5, 9, 4, S_MORT)
    vline(t, 7, 2, 6, S_MORT)
    tiles.append(t)

    # 10 — wet stone
    t = blank(S_WET)
    for y in range(0, TILE, 8): hline(t, 0, TILE-1, y, S_DARK)
    for row in range(2):
        offs = 4 if row % 2 == 1 else 0
        for x in range(-offs, TILE, 8):
            if x >= 0:
                vline(t, x, row*8+1, row*8+7, S_DARK)
    pt(t, 4, 2, S_LIGHT); pt(t, 5, 2, S_LIGHT)
    tiles.append(t)

    # 11 — polished bevel
    t = blank(S_BASE)
    for i in range(2):
        hline(t, 0, TILE-1, i, S_LIGHT)
        vline(t, i, 0, TILE-1, S_LIGHT)
        hline(t, 0, TILE-1, TILE-1-i, S_DARK)
        vline(t, TILE-1-i, 0, TILE-1, S_DARK)
    tiles.append(t)

    return tiles

# ── Row 1: WORKSHOP ───────────────────────────────────────────────────────────

def workshop_tiles():
    tiles = []

    # 0 — plain concrete
    t = blank(W_BASE)
    concrete_seams(t, W_MORT)
    tiles.append(t)

    # 1 — concrete with amber stripe
    t = blank(W_BASE)
    concrete_seams(t, W_MORT)
    hline(t, 4, 11, 6, W_ACC); hline(t, 4, 11, 7, W_ACC)
    tiles.append(t)

    # 2 — cracked concrete (Y-crack)
    t = blank(W_BASE)
    hline(t, 0, TILE-1, 8, W_MORT)
    for i in range(5): pt(t, 8-i, i, W_DARK)
    for i in range(5): pt(t, 8+i, 4+i, W_DARK)
    for i in range(4): pt(t, 8-i, 4+i, W_DARK)
    tiles.append(t)

    # 3 — worn patch
    t = blank(W_BASE)
    concrete_seams(t, W_MORT)
    rect(t, 4, 10, 6, 4, W_LIGHT)
    tiles.append(t)

    # 4 — hazard stripe (top band)
    t = blank(W_BASE)
    for x in range(TILE):
        pt(t, x, 0, W_ACC if (x//3)%2==0 else W_BASE)
        pt(t, x, 1, W_ACC if (x//3)%2==0 else W_BASE)
    concrete_seams(t, W_MORT)
    tiles.append(t)

    # 5 — running-bond brick
    t = blank(W_MORT)
    for by in range(2):
        y0 = by * 8 + 1
        offs = 4 if by == 1 else 0
        for bx in range(-offs, TILE, 8):
            if bx >= 0 and bx+1 < TILE:
                rect(t, bx+1, y0, min(6, TILE-bx-1), 5, W_BASE)
    tiles.append(t)

    # 6 — dark weathered brick
    t = blank(W_MORT)
    for by in range(2):
        y0 = by * 8 + 1
        offs = 4 if by == 1 else 0
        for bx in range(-offs, TILE, 8):
            if bx >= 0 and bx+1 < TILE:
                rect(t, bx+1, y0, min(6, TILE-bx-1), 5, W_DARK)
    tiles.append(t)

    # 7 — metal grating
    t = blank(W_GRATE)
    for i in range(0, TILE, 3):
        hline(t, 0, TILE-1, i, W_DARK)
        vline(t, i, 0, TILE-1, W_DARK)
    tiles.append(t)

    # 8 — iron floor plate with rivets and centre cross
    t = blank(W_METAL)
    border(t, W_DARK)
    for rx,ry in [(2,2),(TILE-3,2),(2,TILE-3),(TILE-3,TILE-3)]:
        pt(t, rx, ry, W_DARK); pt(t, rx+1, ry, W_LIGHT)
    hline(t, 1, TILE-2, 7, W_DARK); hline(t, 1, TILE-2, 8, W_LIGHT)
    vline(t, 7, 1, TILE-2, W_DARK); vline(t, 8, 1, TILE-2, W_LIGHT)
    tiles.append(t)

    # 9 — sawdust floor
    t = blank(W_LIGHT)
    for x,y in [(1,3),(4,1),(7,4),(10,2),(13,5),(2,7),(5,9),(8,6),(11,8),(0,11),(3,13),(6,10),(9,12),(12,11),(14,13),(1,14)]:
        if x<TILE and y<TILE: pt(t, x, y, W_MORT)
    tiles.append(t)

    # 10 — stained dark concrete
    t = blank(W_DARK)
    concrete_seams(t, W_MORT)
    tiles.append(t)

    # 11 — panel bevel
    t = blank(W_BASE)
    hline(t, 0, TILE-1, 0, W_LIGHT); vline(t, 0, 0, TILE-1, W_LIGHT)
    hline(t, 0, TILE-1, TILE-1, W_DARK); vline(t, TILE-1, 0, TILE-1, W_DARK)
    tiles.append(t)

    return tiles

# ── Row 2: WOOD ───────────────────────────────────────────────────────────────

def wood_tiles():
    tiles = []

    # 0 — plain 3-plank horizontal
    t = blank(O_BASE)
    plank_h(t, O_BASE, O_GRAIN, O_DARK)
    tiles.append(t)

    # 1 — lighter planks
    t = blank(O_LIGHT)
    plank_h(t, O_LIGHT, O_BASE, O_GRAIN)
    tiles.append(t)

    # 2 — knot plank
    t = blank(O_BASE)
    plank_h(t, O_BASE, O_GRAIN, O_DARK)
    for x,y in [(7,7),(8,7),(9,7),(7,8),(9,8),(7,9),(8,9),(9,9)]:
        pt(t, x, y, O_KNOT)
    pt(t, 8, 8, O_DARK)
    tiles.append(t)

    # 3 — dark stained
    t = blank(O_STAGE)
    plank_h(t, O_STAGE, O_DARK, O_KNOT)
    tiles.append(t)

    # 4 — light ash plank
    t = blank(O_LIGHT)
    for p in range(3):
        y0 = p * (TILE//3)
        hline(t, 0, TILE-1, y0, O_BASE)
        for gy in range(y0+1, y0+(TILE//3)):
            if (gy-y0) % 4 == 1:
                hline(t, 0, TILE-1, gy, O_BASE)
    tiles.append(t)

    # 5 — offset plank ends
    t = blank(O_BASE)
    for p in range(3):
        y0 = p * (TILE//3)
        hline(t, 0, TILE-1, y0, O_DARK)
        offs = 4 if p % 2 == 1 else 0
        x1 = offs % TILE
        x2 = (8 + offs) % TILE
        vline(t, x1, y0+1, y0+(TILE//3)-1, O_DARK)
        vline(t, x2, y0+1, y0+(TILE//3)-1, O_DARK)
    tiles.append(t)

    # 6 — stage dark with nails
    t = blank(O_STAGE)
    plank_h(t, O_STAGE, O_DARK, O_KNOT)
    for nx,ny in [(2, TILE//6), (TILE-3, TILE//6 + TILE//3)]:
        if nx<TILE and ny<TILE: pt(t, nx, ny, O_DARK)
    tiles.append(t)

    # 7 — parquet diagonal squares
    t = blank(O_BASE)
    for y in range(TILE):
        for x in range(TILE):
            pt(t, x, y, O_LIGHT if (x+y)%8 < 4 else O_GRAIN)
    grid_lines(t, 4, O_DARK)
    tiles.append(t)

    # 8 — rough sawn
    t = blank(O_BASE)
    for y in range(0, TILE, 2):
        hline(t, 0, TILE-1, y, O_GRAIN if y%4==0 else O_BASE)
    hline(t, 0, TILE-1, 5, O_DARK)
    hline(t, 0, TILE-1, 10, O_DARK)
    tiles.append(t)

    # 9 — polished with seam shadow
    t = blank(O_BASE)
    hline(t, 0, TILE-1, 0, O_LIGHT); vline(t, 0, 0, TILE-1, O_LIGHT)
    hline(t, 0, TILE-1, TILE-1, O_DARK); vline(t, TILE-1, 0, TILE-1, O_DARK)
    for p in range(3):
        hline(t, 0, TILE-1, p*(TILE//3), O_DARK)
    tiles.append(t)

    # 10 — alternating wide/narrow
    t = blank(O_BASE)
    y = 0
    for i, w in enumerate([5, 3, 5, 3]):
        col = O_BASE if i % 2 == 0 else O_LIGHT
        rect(t, 0, y, TILE, w, col)
        hline(t, 0, TILE-1, y, O_DARK)
        y += w
    tiles.append(t)

    # 11 — herringbone
    t = blank(O_GRAIN)
    for y in range(TILE):
        for x in range(TILE):
            pt(t, x, y, O_BASE if (x//4+y//4)%2==0 else O_LIGHT)
    grid_lines(t, 4, O_DARK)
    tiles.append(t)

    return tiles

# ── Row 3: OUTDOOR ────────────────────────────────────────────────────────────

def outdoor_tiles():
    tiles = []

    # 0 — plain dry dirt
    t = blank(T_BASE)
    for x,y in [(2,3),(5,1),(8,4),(11,2),(14,5),(1,8),(4,11),(7,7),(10,9),(13,12),(3,14),(6,13)]:
        if x<TILE and y<TILE: pt(t, x, y, T_DARK)
    tiles.append(t)

    # 1 — dirt with pebbles
    t = blank(T_BASE)
    for px,py in [(3,4),(9,2),(6,10),(12,7),(2,12)]:
        rect(t, px, py, 2, 2, T_STONE)
    for x,y in [(1,7),(5,6),(11,9),(13,3),(7,13)]:
        if x<TILE and y<TILE: pt(t, x, y, T_DARK)
    tiles.append(t)

    # 2 — sparse grass tufts
    t = blank(T_BASE)
    for x,y in [(1,2),(2,2),(1,1),(8,5),(9,5),(8,4),(3,11),(4,11),(13,8),(14,9)]:
        if x<TILE and y<TILE: pt(t, x, y, T_GRASS)
    tiles.append(t)

    # 3 — gravel
    t = blank(T_GRAV)
    cols3 = [T_DARK, T_STONE, T_LIGHT]
    gravel_pts = [(0,2),(3,0),(6,3),(9,1),(12,4),(1,5),(4,7),(7,5),(10,8),(13,6),(2,9),(5,12),(8,10),(11,13),(14,11),(0,14),(3,13),(9,14),(12,15)]
    for i,(x,y) in enumerate(gravel_pts):
        if x<TILE and y<TILE: pt(t, x, y, cols3[i%3])
    tiles.append(t)

    # 4 — lush grass
    t = blank(T_BASE)
    for y in range(TILE):
        for x in range(TILE):
            if (x*3+y*7)%11 < 4:
                pt(t, x, y, T_GRASS)
    tiles.append(t)

    # 5 — rocky flat stones
    t = blank(T_BASE)
    for sx,sy,sw,sh in [(1,2,6,4),(9,8,5,4),(4,12,4,2)]:
        rect(t, sx, sy, sw, sh, T_STONE)
    tiles.append(t)

    # 6 — worn path (lighter band)
    t = blank(T_BASE)
    rect(t, 3, 0, 10, TILE, T_LIGHT)
    vline(t, 3, 0, TILE-1, T_DARK)
    vline(t, 12, 0, TILE-1, T_DARK)
    tiles.append(t)

    # 7 — loose dark soil
    t = blank(T_DARK)
    for x,y in [(1,1),(2,1),(1,2),(6,4),(7,4),(6,3),(12,2),(13,3),(3,9),(4,8),(9,11),(10,10)]:
        if x<TILE and y<TILE: pt(t, x, y, T_BASE)
    tiles.append(t)

    # 8 — sandy/sawdust
    t = blank(T_SAND)
    for x,y in [(2,4),(5,2),(8,5),(11,1),(13,7),(1,9),(4,12),(7,10),(10,13),(14,3),(3,14),(12,11)]:
        if x<TILE and y<TILE: pt(t, x, y, T_LIGHT)
    tiles.append(t)

    # 9 — bark/mulch
    t = blank(T_DARK)
    for row in range(4):
        hline(t, 0, TILE-1, row*4, T_BASE)
        offs = 5 if row%2==1 else 0
        for x in range(-offs, TILE, 6):
            if x >= 0:
                vline(t, x, row*4+1, row*4+3, T_BASE)
    tiles.append(t)

    # 10 — packed earth with embedded stones
    t = blank(T_BASE)
    for sx,sy,sw,sh in [(2,2,3,2),(8,5,3,2),(5,10,4,2),(12,12,2,2)]:
        rect(t, sx, sy, sw, sh, T_STONE)
    tiles.append(t)

    # 11 — outdoor bevel border
    t = blank(T_BASE)
    hline(t, 0, TILE-1, 0, T_LIGHT); vline(t, 0, 0, TILE-1, T_LIGHT)
    hline(t, 0, TILE-1, TILE-1, T_DARK); vline(t, TILE-1, 0, TILE-1, T_DARK)
    tiles.append(t)

    return tiles

# ── Row 4: TUNNEL ─────────────────────────────────────────────────────────────

def tunnel_tiles():
    tiles = []

    # 0 — plain dark rough stone
    t = blank(U_BASE)
    for x,y in [(1,3),(4,1),(7,4),(10,2),(13,5),(2,8),(5,10),(8,7),(11,9),(0,12),(3,14),(9,13)]:
        if x<TILE and y<TILE: pt(t, x, y, U_DARK)
    for x,y in [(0,1),(6,3),(12,0),(3,7),(9,11),(14,6)]:
        if x<TILE and y<TILE: pt(t, x, y, U_LIGHT)
    tiles.append(t)

    # 1 — dark stone with glint
    t = blank(U_BASE)
    for x,y in [(2,2),(5,5),(9,1),(13,8),(1,11),(7,13)]:
        if x<TILE and y<TILE: pt(t, x, y, U_DARK)
    pt(t, 4, 3, U_LIGHT); pt(t, 5, 3, U_LIGHT)
    tiles.append(t)

    # 2 — crumbled corners
    t = blank(U_BASE)
    for x,y in [(0,0),(1,0),(0,1),(TILE-1,0),(TILE-2,0),(TILE-1,1),(0,TILE-1),(1,TILE-1),(0,TILE-2)]:
        pt(t, x, y, U_DARK)
    tiles.append(t)

    # 3 — damp/wet stone
    t = blank(U_DAMP)
    for x,y in [(3,1),(7,4),(11,2),(1,7),(5,10),(9,8),(13,11),(2,13)]:
        if x<TILE and y<TILE: pt(t, x, y, U_LIGHT)
    pt(t, 6, 2, U_LIGHT); pt(t, 7, 2, U_LIGHT)
    tiles.append(t)

    # 4 — rusted grating
    t = blank(U_GRATE)
    for i in range(0, TILE, 4):
        hline(t, 0, TILE-1, i, U_RUST)
        vline(t, i, 0, TILE-1, U_RUST)
    for y in range(1, TILE, 4):
        for x in range(1, TILE, 4):
            pt(t, x, y, U_DARK)
    tiles.append(t)

    # 5 — puddle
    t = blank(U_BASE)
    rect(t, 3, 4, 10, 8, U_DAMP)
    pt(t, 6, 6, U_LIGHT); pt(t, 7, 6, U_LIGHT)
    tiles.append(t)

    # 6 — cave floor noise
    t = blank(U_BASE)
    for y in range(TILE):
        for x in range(TILE):
            v = (x*5+y*3)%7
            if v==0: pt(t, x, y, U_DARK)
            elif v==6: pt(t, x, y, U_LIGHT)
    tiles.append(t)

    # 7 — mossy dark stone
    t = blank(U_BASE)
    for x,y in [(1,2),(2,1),(3,3),(12,2),(13,1),(11,3),(1,13),(2,14),(3,12),(12,13)]:
        if x<TILE and y<TILE: pt(t, x, y, c(55,75,45))
    tiles.append(t)

    # 8 — dusty dark
    t = blank(U_DARK)
    for x,y in [(2,2),(5,5),(8,2),(11,4),(3,8),(7,9),(10,12),(13,10),(1,14),(6,13)]:
        if x<TILE and y<TILE: pt(t, x, y, U_BASE)
    tiles.append(t)

    # 9 — pipe cross-section
    t = blank(U_BASE)
    rect(t, 5, 5, 6, 6, U_GRATE)
    rect(t, 6, 6, 4, 4, U_DARK)
    hline(t, 0, TILE-1, 7, U_GRATE); hline(t, 0, TILE-1, 8, U_GRATE)
    vline(t, 7, 0, TILE-1, U_GRATE); vline(t, 8, 0, TILE-1, U_GRATE)
    tiles.append(t)

    # 10 — deep shadow corner fade
    t = blank(U_DARK)
    for i in range(6):
        hline(t, 0, i, i, U_BASE)
        vline(t, i, 0, i, U_BASE)
    tiles.append(t)

    # 11 — muddy ground
    t = blank(c(45,38,28))
    for x,y in [(1,3),(4,1),(7,4),(10,2),(3,8),(6,6),(9,9),(12,7),(2,12),(5,11)]:
        if x<TILE and y<TILE: pt(t, x, y, U_DARK)
    for x,y in [(0,5),(3,3),(6,0),(9,5),(12,4),(2,10),(7,12),(13,9)]:
        if x<TILE and y<TILE: pt(t, x, y, c(70,55,42))
    tiles.append(t)

    return tiles

# ── Row 5: DOCK ───────────────────────────────────────────────────────────────

def dock_tiles():
    tiles = []

    # 0 — dock planks (vertical grain)
    t = blank(D_WOOD)
    plank_v(t, D_WOOD, c(105,80,48), c(88,68,42))
    tiles.append(t)

    # 1 — lighter dock planks
    t = blank(c(155,125,88))
    plank_v(t, c(155,125,88), c(125,98,62), c(80,60,32))
    tiles.append(t)

    # 2 — wet dock planks
    t = blank(D_WET)
    plank_v(t, D_WET, c(60,72,75), D_DARK)
    pt(t, 5, 5, D_LIGHT); pt(t, 6, 5, D_LIGHT)
    tiles.append(t)

    # 3 — dock with bolt corners
    t = blank(D_WOOD)
    plank_v(t, D_WOOD, c(105,80,48), c(88,68,42))
    for bx,by in [(2,2),(TILE-3,2),(2,TILE-3),(TILE-3,TILE-3)]:
        pt(t, bx, by, D_DARK); pt(t, bx+1, by, D_LIGHT)
    tiles.append(t)

    # 4 — concrete pier bevel
    t = blank(D_BASE)
    hline(t, 0, TILE-1, 0, D_LIGHT); vline(t, 0, 0, TILE-1, D_LIGHT)
    hline(t, 0, TILE-1, TILE-1, D_DARK); vline(t, TILE-1, 0, TILE-1, D_DARK)
    hline(t, 0, TILE-1, 8, D_DARK)
    tiles.append(t)

    # 5 — asphalt
    t = blank(D_ASPH)
    for x,y in [(1,2),(4,5),(7,1),(10,3),(13,6),(2,8),(5,11),(8,9),(11,12),(0,14),(3,13),(9,10),(12,14)]:
        if x<TILE and y<TILE: pt(t, x, y, c(50,50,52))
    tiles.append(t)

    # 6 — cracked asphalt
    t = blank(D_ASPH)
    for i in range(7): pt(t, 4+i, 5, c(50,50,52))
    for i in range(5):
        if 5+i < TILE and 6+i < TILE: pt(t, 5+i, 6+i, c(50,50,52))
    tiles.append(t)

    # 7 — painted yellow line
    t = blank(D_BASE)
    hline(t, 0, TILE-1, 6, D_PAINT)
    hline(t, 0, TILE-1, 7, D_PAINT)
    hline(t, 0, TILE-1, 8, (D_PAINT[0]//2, D_PAINT[1]//2, D_PAINT[2]//2, 255))
    tiles.append(t)

    # 8 — rubber anti-slip diamond grip
    t = blank(D_DARK)
    for y in range(TILE):
        for x in range(TILE):
            if (x+y)%4==0 or (x-y)%4==0:
                pt(t, x, y, D_BASE)
    tiles.append(t)

    # 9 — metal grid grating
    t = blank(D_DARK)
    for i in range(0, TILE, 4):
        hline(t, 0, TILE-1, i, D_BASE)
        vline(t, i, 0, TILE-1, D_BASE)
    tiles.append(t)

    # 10 — wet concrete sheen
    t = blank(D_WET)
    hline(t, 3, 10, 4, D_LIGHT)
    hline(t, 3, 10, 5, D_LIGHT)
    tiles.append(t)

    # 11 — edge band
    t = blank(D_BASE)
    for i in range(3): hline(t, 0, TILE-1, i, D_LIGHT)
    tiles.append(t)

    return tiles

# ── Row 6: CARPET / THEATER ───────────────────────────────────────────────────

def carpet_tiles():
    tiles = []

    # 0 — plain red carpet pile
    t = blank(P_RED)
    for y in range(0, TILE, 2):
        hline(t, 0, TILE-1, y, P_DARK)
    tiles.append(t)

    # 1 — woven cross-hatch
    t = blank(P_RED)
    for y in range(0, TILE, 3): hline(t, 0, TILE-1, y, P_DARK)
    for x in range(0, TILE, 3): vline(t, x, 0, TILE-1, P_DARK)
    tiles.append(t)

    # 2 — worn/faded centre
    t = blank(P_RED)
    for y in range(0, TILE, 2): hline(t, 0, TILE-1, y, P_DARK)
    rect(t, 4, 4, 8, 8, P_LIGHT)
    tiles.append(t)

    # 3 — gold dot border
    t = blank(P_RED)
    for y in range(0, TILE, 2): hline(t, 0, TILE-1, y, P_DARK)
    for x in range(0, TILE, 4): pt(t, x, 0, P_GOLD); pt(t, x, TILE-1, P_GOLD)
    for y in range(0, TILE, 4): pt(t, 0, y, P_GOLD); pt(t, TILE-1, y, P_GOLD)
    tiles.append(t)

    # 4 — compass rose medallion
    t = blank(P_RED)
    for y in range(0, TILE, 2): hline(t, 0, TILE-1, y, P_DARK)
    cx, cy = 8, 8
    hline(t, cx-3, cx+3, cy, P_GOLD)
    vline(t, cx, cy-3, cy+3, P_GOLD)
    for dx,dy in [(cx-2,cy-2),(cx+2,cy-2),(cx-2,cy+2),(cx+2,cy+2)]:
        if dx<TILE and dy<TILE: pt(t, dx, dy, P_GOLD)
    tiles.append(t)

    # 5 — cream foyer tile quartered
    t = blank(P_CREAM)
    border(t, c(160,152,135))
    hline(t, 1, TILE-2, TILE//2, c(180,172,155))
    vline(t, TILE//2, 1, TILE-2, c(180,172,155))
    tiles.append(t)

    # 6 — plain marble
    t = blank(P_MARB)
    for i in range(2):
        hline(t, 0, TILE-1, i, P_CREAM)
        vline(t, i, 0, TILE-1, P_CREAM)
    hline(t, 0, TILE-1, TILE-1, P_VEIN); vline(t, TILE-1, 0, TILE-1, P_VEIN)
    tiles.append(t)

    # 7 — marble with diagonal vein
    t = blank(P_MARB)
    for i in range(TILE):
        h = i // 2
        pt(t, i, h, P_VEIN)
        if h+1 < TILE: pt(t, i, h+1, P_CREAM)
    tiles.append(t)

    # 8 — gold-trim marble tile
    t = blank(P_MARB)
    border(t, P_GOLD)
    tiles.append(t)

    # 9 — ornate floor cross motif
    t = blank(P_DARK)
    cx, cy = 8, 8
    hline(t, cx-5, cx+5, cy, P_GOLD)
    vline(t, cx, cy-5, cy+5, P_GOLD)
    for dx,dy in [(cx-3,cy-3),(cx+3,cy-3),(cx-3,cy+3),(cx+3,cy+3)]:
        if dx<TILE and dy<TILE: pt(t, dx, dy, P_GOLD)
    border(t, P_GOLD)
    tiles.append(t)

    # 10 — checkerboard red/dark
    t = blank(P_RED)
    for y in range(TILE):
        for x in range(TILE):
            if (x//4+y//4)%2==1: pt(t, x, y, P_DARK)
    tiles.append(t)

    # 11 — theater runner with gold edge trim
    t = blank(P_RED)
    for y in range(0, TILE, 2): hline(t, 0, TILE-1, y, P_DARK)
    hline(t, 0, TILE-1, 1, P_GOLD)
    hline(t, 0, TILE-1, TILE-2, P_GOLD)
    tiles.append(t)

    return tiles

# ── Row 7: CYBER / VR ─────────────────────────────────────────────────────────

def cyber_tiles():
    tiles = []

    # 0 — cyan grid on dark
    t = blank(Y_BASE)
    grid_lines(t, 4, Y_DIM)
    for i in range(0, TILE, 4): pt(t, i, 0, Y_CYAN)
    for i in range(0, TILE, 4): pt(t, 0, i, Y_CYAN)
    tiles.append(t)

    # 1 — dense circuit grid
    t = blank(Y_BASE)
    for i in range(0, TILE, 2): hline(t, 0, TILE-1, i, Y_DARK)
    for i in range(0, TILE, 4): vline(t, i, 0, TILE-1, Y_DIM)
    for x,y in [(4,4),(12,4),(4,12),(12,12),(8,0),(0,8)]:
        if x<TILE and y<TILE: pt(t, x, y, Y_CYAN)
    tiles.append(t)

    # 2 — circuit L-route trace
    t = blank(Y_BASE)
    grid_lines(t, 4, Y_DARK)
    hline(t, 2, 10, 6, Y_CYAN)
    vline(t, 10, 6, 12, Y_CYAN)
    hline(t, 4, 10, 12, Y_CYAN)
    pt(t, 2, 6, Y_GLOW); pt(t, 4, 12, Y_GLOW)
    tiles.append(t)

    # 3 — glowing junction node
    t = blank(Y_BASE)
    grid_lines(t, 4, Y_DARK)
    rect(t, 6, 6, 4, 4, Y_CYAN)
    rect(t, 7, 7, 2, 2, Y_GLOW)
    hline(t, 0, 5, 8, Y_DIM); hline(t, 10, TILE-1, 8, Y_DIM)
    vline(t, 8, 0, 5, Y_DIM); vline(t, 8, 10, TILE-1, Y_DIM)
    tiles.append(t)

    # 4 — corrupted magenta blocks
    t = blank(Y_BASE)
    grid_lines(t, 4, Y_DARK)
    rect(t, 1, 1, 4, 3, Y_CORR)
    rect(t, 9, 5, 3, 4, Y_CORR)
    rect(t, 2, 9, 5, 3, Y_DIM)
    tiles.append(t)

    # 5 — void (deepest dark)
    t = blank(Y_VOID)
    tiles.append(t)

    # 6 — void with edge glow
    t = blank(Y_VOID)
    hline(t, 0, TILE-1, 0, Y_DIM)
    vline(t, 0, 0, TILE-1, Y_DIM)
    tiles.append(t)

    # 7 — data stream scanlines
    t = blank(Y_BASE)
    for y in range(0, TILE, 2):
        hline(t, 0, TILE-1, y, Y_DIM if y%4==0 else Y_DARK)
    hline(t, 0, TILE-1, 6, Y_CYAN)
    hline(t, 0, TILE-1, 7, Y_DIM)
    tiles.append(t)

    # 8 — energy platform (glowing border)
    t = blank(Y_BASE)
    grid_lines(t, 4, Y_DARK)
    border(t, Y_CYAN)
    tiles.append(t)

    # 9 — portal rings
    t = blank(Y_DARK)
    cx, cy = 8, 8
    for r in [6, 4, 2]:
        for step in range(24):
            a = step * math.pi / 12.0
            px = int(cx + r * math.cos(a))
            py = int(cy + r * math.sin(a))
            if 0<=px<TILE and 0<=py<TILE:
                pt(t, px, py, Y_CYAN if r==4 else Y_DIM)
    pt(t, cx, cy, Y_GLOW)
    tiles.append(t)

    # 10 — glitch displaced rows
    t = blank(Y_BASE)
    for i in range(0, TILE, 4): hline(t, 0, TILE-1, i, Y_DARK)
    rect(t, 3, 4, TILE-3, 3, Y_DIM)
    rect(t, 0, 9, TILE-4, 3, Y_CORR)
    tiles.append(t)

    # 11 — scanlines + columns
    t = blank(Y_BASE)
    for y in range(TILE):
        hline(t, 0, TILE-1, y, Y_DARK if y%2==0 else Y_BASE)
    for i in range(0, TILE, 4): vline(t, i, 0, TILE-1, Y_DIM)
    tiles.append(t)

    return tiles

# ── Assemble and save ─────────────────────────────────────────────────────────

TERRAIN_FUNCS = [
    stone_tiles,
    workshop_tiles,
    wood_tiles,
    outdoor_tiles,
    tunnel_tiles,
    dock_tiles,
    carpet_tiles,
    cyber_tiles,
]

def main():
    atlas = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    for row, fn in enumerate(TERRAIN_FUNCS):
        tiles = fn()
        assert len(tiles) == COLS, f"Row {row} ({fn.__name__}) gave {len(tiles)} tiles, need {COLS}"
        for col, tile in enumerate(tiles):
            atlas.paste(tile, (col * TILE, row * TILE))

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out_path = os.path.join(root, "assets", "art", "tiles", "hb_tiles.png")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    atlas.save(out_path)
    print(f"Saved {W}x{H} atlas -> {out_path}")
    print(f"  {ROWS} terrain rows x {COLS} variants = {ROWS*COLS} tiles at {TILE}x{TILE}px")
    print("  Rows: 0=STONE  1=WORKSHOP  2=WOOD  3=OUTDOOR  4=TUNNEL  5=DOCK  6=CARPET  7=CYBER")

if __name__ == "__main__":
    main()
