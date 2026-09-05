#!/usr/bin/env python3
"""Item icon pilot — one shared style for all inventory icons.

Style contract (matches creature packs + UI kit):
- 32x32, single connected silhouette (no floating satellite pieces)
- thick 1px dark outline around everything
- light from top-left: lit plane / mid plane / shaded plane per part
- material accents: ember for fire/copper, cyan for magic, lime for nature
- generous margins (2px) so icons breathe inside octagonal slots
"""
import os, sys, math, random

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image

# shared palettes
WOOD_D, WOOD_M, WOOD_L = (86, 58, 34), (122, 84, 50), (158, 114, 70)
IRON_D, IRON_M, IRON_L, IRON_H = (74, 84, 98), (118, 130, 146), (168, 180, 196), (222, 230, 240)
COPPER_D, COPPER_M, COPPER_L, COPPER_H = (128, 70, 34), (178, 104, 50), (216, 140, 72), (246, 186, 120)
STONE_D, STONE_M, STONE_L = (78, 82, 92), (108, 114, 126), (144, 152, 166)
OUT = (26, 18, 14, 255)

def canvas():
    return Image.new("RGBA", (32, 32), (0, 0, 0, 0))

def outline(im, color=OUT):
    px = im.load()
    w, h = im.size
    mask = [[px[x, y][3] > 0 for y in range(h)] for x in range(w)]
    for x in range(w):
        for y in range(h):
            if not mask[x][y]:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and mask[nx][ny]:
                        px[x, y] = color
                        break
    return im

def _thick_diag(px, x0, y0, length, dir_x, dir_y, w, colors):
    """Thick diagonal bar; colors=(lit, mid, dark) across the width."""
    lit, mid, dark = colors
    for k in range(length):
        cx = x0 + int(k * dir_x)
        cy = y0 + int(k * dir_y)
        for t in range(w):
            x, y = cx + t, cy + t
            if 0 <= x < 32 and 0 <= y < 32:
                c = lit if t == 0 else (mid if t < w - 1 else dark)
                px[x, y] = (*c, 255)

def wooden_pickaxe():
    im = canvas(); px = im.load()
    # handle: bottom-left to top-right
    _thick_diag(px, 6, 25, 18, 1, -1, 3, (WOOD_L, WOOD_M, WOOD_D))
    # head: arc of stone across the top-right
    cxx, cyy = 22, 9
    for ang_i in range(-52, 53, 4):
        a = math.radians(ang_i + 45)
        for rr in (7, 8, 9):
            x = int(cxx + math.cos(a) * rr) - 3
            y = int(cyy - math.sin(a) * rr) + 3
            if 0 <= x < 32 and 0 <= y < 32:
                c = STONE_L if rr == 7 else (STONE_M if rr == 8 else STONE_D)
                px[x, y] = (*c, 255)
    # binding wrap
    for t in range(3):
        px[18 + t, 13] = (*WOOD_D, 255)
        px[18 + t, 14] = (*COPPER_M, 255)
    return outline(im)

def copper_sword():
    im = canvas(); px = im.load()
    # blade
    _thick_diag(px, 10, 21, 15, 1, -1, 3, (COPPER_H, COPPER_L, COPPER_M))
    px[25, 5] = (*COPPER_H, 255)  # tip
    px[26, 5] = (*COPPER_H, 255)
    # fuller line down the middle
    for k in range(3, 13):
        x, y = 11 + k, 21 - k
        px[x, y] = (*COPPER_M, 255)
    # guard
    for t in range(-3, 4):
        x, y = 10 + t, 22 + t
        if 0 <= x < 32 and 0 <= y < 32:
            px[x, y] = (*IRON_M, 255)
            px[x + 1, y] = (*IRON_L, 255)
    # grip
    for k in range(5):
        x, y = 8 - k // 2, 24 + k // 2
        px[x, y] = (*WOOD_D, 255)
        px[x + 1, y] = (*WOOD_M, 255)
    # pommel
    px[5, 27] = (*IRON_L, 255); px[6, 27] = (*IRON_M, 255)
    px[5, 28] = (*IRON_M, 255); px[6, 28] = (*IRON_D, 255)
    return outline(im)

def iron_bar():
    im = canvas(); px = im.load()
    # isometric ingot: top face, front face, side face
    for y in range(11, 16):        # top face (parallelogram)
        for x in range(6 + (15 - y), 22 + (15 - y)):
            px[x, y] = (*IRON_L, 255)
    for x in range(7, 23):         # lit top edge
        px[x + 4, 11] = (*IRON_H, 255)
    for y in range(16, 23):        # front face
        for x in range(6, 22):
            px[x, y] = (*IRON_M, 255)
    for y in range(16, 23):        # side face (shaded)
        for k in range(4):
            x = 22 + k - (y - 16) * 0 
            sx = 22 + (22 - y) * 0 + k
            if sx < 32:
                px[sx - k + k, y] = px[sx - k + k, y]
        for k in range(1, 5):
            x = 21 + k
            yy = y - 0
            if x < 27:
                px[x + (15 - 11), yy] = (*IRON_D, 255) if yy > 15 else px[x, yy]
    # clean side face: quad between top-right edge and front-right edge
    for y in range(12, 23):
        for k in range(4):
            x = 22 + (15 - max(y, 15)) + k + (0 if y >= 16 else (15 - y))
            xx = 22 + k + max(0, 15 - y)
            if xx < 30 and 11 < y:
                px[xx, y] = (*IRON_D, 255)
    # stamp on the front
    for x in range(12, 16):
        px[x, 18] = (*IRON_D, 255)
        px[x, 19] = (*IRON_L, 255)
    return outline(im)

def copper_ore():
    im = canvas(); px = im.load()
    rng = random.Random(7)
    # rock lump: irregular blob of stone
    for x in range(32):
        for y in range(32):
            dx, dy = (x - 15.5) / 11.0, (y - 18.0) / 9.0
            r = dx * dx + dy * dy
            wob = 0.16 * math.sin(x * 0.9) + 0.13 * math.sin(y * 1.3)
            if r + wob <= 1.0:
                if dy < -0.4:
                    px[x, y] = (*STONE_L, 255)
                elif dx > 0.45 or dy > 0.5:
                    px[x, y] = (*STONE_D, 255)
                else:
                    px[x, y] = (*STONE_M, 255)
    # copper crystal studs (2x2, lit top-left)
    for (cx, cy) in ((10, 14), (18, 12), (14, 20), (21, 19), (8, 21)):
        px[cx, cy] = (*COPPER_L, 255)
        px[cx + 1, cy] = (*COPPER_M, 255)
        px[cx, cy + 1] = (*COPPER_M, 255)
        px[cx + 1, cy + 1] = (*COPPER_D, 255)
        px[cx, cy - 1] = (*COPPER_H, 255)
    return outline(im)

def acid_flask():
    im = canvas(); px = im.load()
    GLASS_EDGE = (150, 200, 190)
    LIQ_D, LIQ_M, LIQ_L = (52, 130, 60), (86, 182, 84), (140, 230, 120)
    # bottle body: round-bottom flask
    for x in range(32):
        for y in range(32):
            dx, dy = (x - 15.5) / 8.5, (y - 20.0) / 8.0
            if dx * dx + dy * dy <= 1.0:
                px[x, y] = (*LIQ_M, 230)
    # liquid fill: darker toward the bottom, wave line on top
    for x in range(32):
        for y in range(32):
            if px[x, y][3] > 0:
                if y > 24:
                    px[x, y] = (*LIQ_D, 235)
                elif y < 17 + int(math.sin(x * 0.8)):
                    px[x, y] = (*LIQ_L, 200)
    # neck
    for y in range(7, 13):
        for x in range(13, 19):
            px[x, y] = (*GLASS_EDGE, 190) if x in (13, 18) else (*LIQ_L, 130)
    # cork
    for y in range(4, 8):
        for x in range(12, 20):
            c = WOOD_M if y > 4 else WOOD_L
            px[x, y] = (*c, 255)
    # glass shine
    for k in range(5):
        px[10 + k // 2, 15 + k] = (225, 250, 240, 220)
    # bubbles
    px[18, 22] = (*LIQ_L, 255); px[13, 25] = (*LIQ_L, 255)
    return outline(im, (16, 42, 30, 255))

def moss_fiber():
    im = canvas(); px = im.load()
    G_D, G_M, G_L = (44, 82, 44), (74, 122, 62), (116, 168, 88)
    # coiled skein: three loops
    for i, (cx, cy, r) in enumerate(((15, 13, 6), (12, 19, 6), (19, 19, 6))):
        for ang_i in range(0, 360, 3):
            a = math.radians(ang_i)
            for rr in (r - 1, r):
                x = int(cx + math.cos(a) * rr)
                y = int(cy + math.sin(a) * rr * 0.8)
                if 0 <= x < 32 and 0 <= y < 32:
                    c = G_L if (ang_i + i * 40) % 360 < 120 else (G_M if (ang_i + i * 40) % 360 < 260 else G_D)
                    px[x, y] = (*c, 255)
    # fill loop centers with mid tone strands
    rng = random.Random(3)
    for _ in range(60):
        x, y = rng.randrange(8, 25), rng.randrange(9, 26)
        if px[x, y][3] == 0:
            dx1 = (x - 15.5) ** 2 + (y - 16.5) ** 2
            if dx1 < 81:
                px[x, y] = (*G_M, 255) if rng.random() < 0.7 else (*G_D, 255)
    # loose fiber ends
    for k in range(5):
        px[22 + k // 2, 24 + k] = (*G_M, 255)
        px[9 - k // 3, 23 + k] = (*G_D, 255)
    return outline(im, (20, 34, 20, 255))

PILOT = {
    "wooden_pickaxe": wooden_pickaxe,
    "copper_sword": copper_sword,
    "iron_bar": iron_bar,
    "copper_ore": copper_ore,
    "acid_flasks": acid_flask,
    "moss_fiber": moss_fiber,
}

if __name__ == "__main__":
    outdir = "/tmp/items32"
    os.makedirs(outdir, exist_ok=True)
    for name, fn in PILOT.items():
        fn().save(f"{outdir}/{name}.png")
    print("done:", len(PILOT))
