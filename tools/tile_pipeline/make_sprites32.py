#!/usr/bin/env python3
"""2x-density redraw of furniture/utility sprite tiles.

Keeps each sprite's aspect ratio (engine stretches into the same rects),
doubles the pixel grid, and uses the same wood/stone ramps as the HD tiles
so built structures read as one material family.

Stations (workbench/furnace/anvil/chest) and altars keep their existing art.
"""
import os, sys, math, random

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_tiles32 import ramp, value_noise
from PIL import Image

WOOD = (128, 92, 56)
DARKWOOD = (104, 74, 46)
R = ramp(WOOD)
RD = ramp(DARKWOOD)
IRON = ramp((120, 128, 142), spread=0.5)
GLASS = [(96, 150, 170), (140, 196, 212), (196, 236, 244)]

def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))

def vplank(px, x0, y0, w, h, ramp_=R, tone=2, seed=0):
    """Vertical plank with lit left edge, dark right edge, grain flecks."""
    rng = random.Random(seed)
    for x in range(x0, x0 + w):
        for y in range(y0, y0 + h):
            idx = tone
            if x == x0:
                idx = tone + 1
            elif x == x0 + w - 1:
                idx = tone - 1
            if rng.random() < 0.05:
                idx -= 1
            px[x, y] = ramp_[max(0, min(5, idx))]

def hplank(px, x0, y0, w, h, ramp_=R, tone=2, seed=0):
    rng = random.Random(seed)
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            idx = tone
            if y == y0:
                idx = tone + 1
            elif y == y0 + h - 1:
                idx = tone - 1
            if rng.random() < 0.05:
                idx -= 1
            px[x, y] = ramp_[max(0, min(5, idx))]

def outline(im, color=(43, 30, 18, 255)):
    """1px dark outline around opaque pixels."""
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

# ---------------- pieces ----------------

def door():
    im = canvas(32, 64)
    px = im.load()
    # frame
    vplank(px, 0, 0, 3, 64, RD, 2, 1)
    vplank(px, 29, 0, 3, 64, RD, 2, 2)
    hplank(px, 0, 0, 32, 3, RD, 2, 3)
    hplank(px, 0, 61, 32, 3, RD, 1, 4)
    # panels: 3 vertical planks
    for i, x0 in enumerate((3, 12, 21)):
        vplank(px, x0, 3, 9 if i < 2 else 8, 58, R, 2 + (i % 2), 10 + i)
    # cross braces
    hplank(px, 3, 20, 26, 3, RD, 1, 20)
    hplank(px, 3, 42, 26, 3, RD, 1, 21)
    # handle
    for dx in range(2):
        for dy in range(4):
            px[24 + dx, 30 + dy] = IRON[4] if dy < 2 else IRON[2]
    # hinges
    for y0 in (8, 52):
        for dx in range(3):
            px[1 + dx, y0] = IRON[3]
            px[1 + dx, y0 + 1] = IRON[1]
    return outline(im)

def platform():
    im = canvas(32, 20)
    px = im.load()
    hplank(px, 0, 0, 32, 6, R, 3, 1)
    # gaps between deck boards
    for x in (7, 15, 23):
        for y in range(6):
            px[x, y] = RD[0]
    # support beam + braces
    hplank(px, 2, 6, 28, 3, RD, 1, 2)
    for x0 in (4, 26):
        vplank(px, x0, 9, 3, 11, RD, 1, 3)
    return outline(im)

def ladder():
    im = canvas(32, 32)
    px = im.load()
    vplank(px, 3, 0, 4, 32, R, 2, 1)
    vplank(px, 25, 0, 4, 32, R, 2, 2)
    for y0 in (4, 14, 24):
        hplank(px, 7, y0, 18, 3, R, 3, y0)
    return outline(im)

def fence():
    im = canvas(32, 32)
    px = im.load()
    for x0 in (2, 14, 26):
        vplank(px, x0, 2, 4, 30, R, 2, x0)
        px[x0 + 1, 2] = R[4]  # lit post top
    for y0 in (8, 20):
        hplank(px, 0, y0, 32, 4, R, 3, y0)
    return outline(im)

def window():
    im = canvas(32, 32)
    px = im.load()
    hplank(px, 0, 0, 32, 3, RD, 2, 1)
    hplank(px, 0, 29, 32, 3, RD, 1, 2)
    vplank(px, 0, 0, 3, 32, RD, 2, 3)
    vplank(px, 29, 0, 3, 32, RD, 2, 4)
    # cross bars
    hplank(px, 3, 14, 26, 3, RD, 2, 5)
    vplank(px, 14, 3, 3, 26, RD, 2, 6)
    # glass panes with diagonal shine
    for (gx, gy) in ((3, 3), (17, 3), (3, 17), (17, 17)):
        for x in range(gx, gx + 11 if gx == 3 else gx + 12):
            for y in range(gy, gy + 11 if gy == 3 else gy + 12):
                if x < 32 and y < 32:
                    d = (x - gx) - (y - gy)
                    if -2 <= d <= 0:
                        px[x, y] = GLASS[2]
                    elif d in (3, 4):
                        px[x, y] = GLASS[1]
                    else:
                        px[x, y] = GLASS[0]
    return outline(im)

def trapdoor():
    im = canvas(32, 20)
    px = im.load()
    for i, y0 in enumerate((0, 7, 14)):
        hplank(px, 0, y0, 32, 6 if i < 2 else 6, R, 2 + (i % 2), i)
    # hinges left, pull ring right
    for y0 in (2, 13):
        px[1, y0] = IRON[3]; px[2, y0] = IRON[3]
        px[1, y0 + 1] = IRON[1]; px[2, y0 + 1] = IRON[1]
    for dx, dy in ((0, 0), (1, -1), (2, 0), (1, 1)):
        px[26 + dx, 9 + dy] = IRON[4]
    return outline(im)

def rope():
    im = canvas(32, 32)
    px = im.load()
    RR = ramp((150, 118, 70))
    cx = 14
    for y in range(32):
        off = 1 if (y // 3) % 2 == 0 else 0
        for dx in range(4):
            tone = 3 if dx in (1, 2) else 2
            if (y + dx) % 6 == 0:
                tone = 1  # braid shadow twist
            px[cx + off + dx, y] = RR[tone]
    return outline(im)

def lantern():
    im = canvas(32, 48)
    px = im.load()
    GLOW = [(255, 208, 100), (255, 170, 60), (200, 110, 40)]
    # hanging hook + chain
    for y in range(0, 6):
        px[15, y] = IRON[2]; px[16, y] = IRON[3]
    # top cap
    hplank(px, 8, 6, 16, 4, IRON, 2, 1)
    px[15, 5] = IRON[4]; px[16, 5] = IRON[4]
    # glass body with flame
    for x in range(9, 23):
        for y in range(10, 38):
            d = abs(x - 15.5) + abs(y - 24) * 0.6
            if d < 4:
                px[x, y] = GLOW[0]
            elif d < 7:
                px[x, y] = GLOW[1]
            else:
                px[x, y] = GLOW[2]
    # cage bars
    for x in (9, 15, 21):
        for y in range(10, 38):
            px[x, y] = IRON[1] if y % 6 else IRON[3]
    # bottom cap
    hplank(px, 8, 38, 16, 4, IRON, 1, 2)
    px[15, 43] = IRON[2]; px[16, 43] = IRON[2]
    return outline(im)

def table():
    im = canvas(64, 40)
    px = im.load()
    hplank(px, 0, 0, 64, 7, R, 3, 1)
    for x in (15, 31, 47):  # board gaps
        for y in range(7):
            px[x, y] = RD[0]
    hplank(px, 2, 7, 60, 3, RD, 1, 2)  # apron
    for x0 in (4, 56):
        vplank(px, x0, 10, 4, 30, R, 2, x0)
    return outline(im)

def chair():
    im = canvas(32, 48)
    px = im.load()
    # backrest
    vplank(px, 4, 0, 4, 28, R, 2, 1)
    hplank(px, 8, 4, 16, 3, R, 3, 2)
    hplank(px, 8, 12, 16, 3, R, 3, 3)
    # seat
    hplank(px, 4, 26, 26, 5, R, 3, 4)
    # legs
    vplank(px, 5, 31, 4, 17, RD, 2, 5)
    vplank(px, 24, 31, 4, 17, RD, 2, 6)
    return outline(im)

def sapling():
    im = canvas(32, 32)
    px = im.load()
    G = ramp((70, 130, 62))
    TR = ramp((110, 80, 50))
    # stem
    for y in range(16, 31):
        px[15, y] = TR[2]; px[16, y] = TR[3]
    # small branches
    for i, (bx, by, d) in enumerate(((11, 18, 1), (20, 15, -1))):
        for k in range(4):
            px[bx + k * d * -1 if False else bx + k * (1 if d < 0 else -1), by + k] = TR[2]
    # leaf clumps
    rng = random.Random(7)
    for (cx, cy, r) in ((15, 10, 6), (9, 14, 4), (22, 13, 4), (16, 5, 3)):
        for dx in range(-r, r + 1):
            for dy in range(-r, r + 1):
                if dx * dx + dy * dy <= r * r:
                    x, y = cx + dx, cy + dy
                    if 0 <= x < 32 and 0 <= y < 32:
                        tone = 4 if dy < -r // 2 else (3 if dy < 0 else 2)
                        px[x, y] = G[tone]
    for _ in range(4):
        x, y = rng.randrange(8, 24), rng.randrange(3, 16)
        if px[x, y][3] > 0:
            px[x, y] = G[5]
    return outline(im)

def glow_mushroom():
    im = canvas(32, 32)
    px = im.load()
    LIME = [(96, 150, 64), (134, 196, 88), (168, 232, 110), (214, 250, 170)]
    ST = ramp((190, 180, 150), spread=0.35)
    # stem
    for x in range(13, 19):
        for y in range(18, 30):
            px[x, y] = ST[3] if x < 16 else ST[2]
    # cap: dome
    for x in range(4, 28):
        for y in range(6, 19):
            dx, dy = (x - 15.5) / 12.0, (y - 18.0) / 12.0
            if dx * dx + dy * dy * 1.6 <= 1.0 and y <= 18:
                tone = 2 if y > 12 else (1 if y > 8 else 0)
                px[x, y] = LIME[3 - tone] if False else LIME[2 - tone + 1]
    # glow spots on cap
    rng = random.Random(3)
    for _ in range(6):
        x, y = rng.randrange(7, 25), rng.randrange(8, 16)
        if px[x, y][3] > 0:
            px[x, y] = LIME[3]
    # gill glow line under cap
    for x in range(6, 26):
        if px[x, 18][3] > 0:
            px[x, 18] = LIME[3]
    return outline(im, (30, 60, 34, 255))

def turret():
    im = canvas(32, 32)
    px = im.load()
    # base
    hplank(px, 4, 24, 24, 8, IRON, 1, 1)
    # body
    for x in range(8, 24):
        for y in range(12, 24):
            d = abs(x - 15.5) / 8.0 + abs(y - 18) / 8.0
            px[x, y] = IRON[3] if d < 0.6 else IRON[2]
    px[10, 14] = IRON[5]; px[11, 14] = IRON[5]  # highlight
    # barrel
    for x in range(24, 31):
        px[x, 16] = IRON[4]; px[x, 17] = IRON[2]; px[x, 18] = IRON[1]
    # sensor light
    px[14, 18] = (238, 74, 64, 255); px[15, 18] = (255, 140, 130, 255)
    return outline(im)

def heart():
    im = canvas(32, 32)
    px = im.load()
    P = [(150, 40, 70), (208, 62, 100), (238, 96, 128), (255, 160, 180)]
    for x in range(32):
        for y in range(32):
            # implicit heart curve
            nx, ny = (x - 15.5) / 13.0, -(y - 14.0) / 13.0
            v = (nx * nx + ny * ny - 0.55)
            if v * v * v - nx * nx * ny * ny * ny < 0:
                tone = 2
                if y < 10 and x < 15:
                    tone = 3
                elif y > 20:
                    tone = 1
                px[x, y] = P[tone]
    px[9, 7] = P[3]; px[10, 6] = P[3]  # sparkle
    return outline(im, (80, 20, 40, 255))

def stone_altar():
    im = canvas(32, 32)
    px = im.load()
    S = ramp((104, 108, 116), spread=0.44)
    CY = [(120, 225, 235), (196, 248, 252)]
    # base slab
    hplank(px, 2, 26, 28, 6, S, 2, 1)
    # pillar
    for x in range(10, 22):
        for y in range(12, 26):
            px[x, y] = S[3] if x < 16 else S[2]
    # top slab
    hplank(px, 6, 8, 20, 4, S, 3, 2)
    # floating glowing rune
    for dx, dy in ((0, -2), (0, -1), (0, 0), (-1, -1), (1, -1)):
        px[15 + dx, 4 + dy] = CY[1]
    for dx, dy in ((-1, -2), (1, -2), (-1, 0), (1, 0), (0, 1)):
        px[15 + dx, 4 + dy] = CY[0]
    # rune light on pillar
    for y in range(14, 24, 3):
        px[15, y] = CY[0]; px[16, y] = CY[0]
    return outline(im)

SPRITES = {
    "door": door, "platform": platform, "ladder": ladder, "fence": fence,
    "window": window, "trapdoor": trapdoor, "rope": rope, "lantern": lantern,
    "table": table, "chair": chair, "sapling": sapling,
    "glow_mushroom": glow_mushroom, "turret": turret, "heart": heart,
    "stone_altar": stone_altar,
}

if __name__ == "__main__":
    outdir = "/tmp/sprites32"
    os.makedirs(outdir, exist_ok=True)
    for name, fn in SPRITES.items():
        fn().save(f"{outdir}/{name}.png")
    print("done:", len(SPRITES))
