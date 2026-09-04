#!/usr/bin/env python3
"""Alternative tile style pilots for Ashen Roots (forest set, 8 materials).

Style A = current pilot (soft bevel + clustered noise)  -> /tmp/new_*.png
Style B = "contrast"  : juicy 6-tone ramps, cracks between clusters (Terraria-vibe)
Style C = "soft"      : painterly, low contrast, large soft clumps
Style D = "graphic"   : voronoi cobbles/clumps with dark seams, chunky ore crystals
"""
import math, random, colorsys
from PIL import Image, ImageDraw

import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_tiles import ramp, value_noise, base_tile

T = 16

# ---------- shared -------------------------------------------------------

def ramp_sat(base, steps=6, spread=0.55, sat=1.18):
    r, g, b = [c / 255.0 for c in base]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    s = min(1.0, s * sat)
    out = []
    for i in range(steps):
        k = 1.0 - spread + (2 * spread) * i / (steps - 1)
        rr, gg, bb = colorsys.hls_to_rgb(h, max(0.0, min(1.0, l * k)), s)
        out.append((int(rr * 255), int(gg * 255), int(bb * 255)))
    return out

def wrap_dist(ax, ay, bx, by):
    dx = min(abs(ax - bx), T - abs(ax - bx))
    dy = min(abs(ay - by), T - abs(ay - by))
    return math.hypot(dx, dy)

def voronoi(seed, cells):
    rng = random.Random(seed)
    pts = [(rng.randrange(T), rng.randrange(T), rng.random()) for _ in range(cells)]
    def sample(x, y):
        best, bi = 1e9, 0
        second = 1e9
        for i, (px_, py_, _) in enumerate(pts):
            d = wrap_dist(x, y, px_, py_)
            if d < best:
                second, best, bi = best, d, i
            elif d < second:
                second = d
        return bi, pts[bi][2], second - best
    return sample

# ---------- STYLE B : contrast -------------------------------------------

def b_base(base, seed, crack=0.16):
    R = ramp_sat(base)
    n1 = value_noise(seed, 3)
    n2 = value_noise(seed + 7, 5)
    def v(x, y):
        return n1(x, y) * 0.6 + n2(x, y) * 0.4
    im = Image.new("RGB", (T, T))
    px = im.load()
    for y in range(T):
        for x in range(T):
            val = v(x, y)
            idx = 1 + int(val * 3.4)
            # cracks between value clusters
            if abs(val - v((x + 1) % T, y)) > crack or abs(val - v(x, (y + 1) % T)) > crack:
                idx = 0
            if y == 0:
                idx = min(5, idx + 1)
            elif y == T - 1:
                idx = max(0, idx - 1)
            px[x, y] = R[max(0, min(5, idx))]
    return im

def b_grass(seed, soil, green):
    im = b_base(soil, seed)
    px = im.load()
    R = ramp_sat(green)
    rng = random.Random(seed + 3)
    n = value_noise(seed + 11, 4)
    for x in range(T):
        depth = 4 + int(n(x, 0) * 3)
        for y in range(depth):
            if y == 0:
                px[x, y] = R[5] if rng.random() < 0.5 else R[4]
            elif y == depth - 1:
                px[x, y] = R[1] if rng.random() < 0.8 else px[x, y]
            else:
                px[x, y] = R[3] if rng.random() < 0.6 else R[2]
        if rng.random() < 0.35:  # свисающий корешок
            px[x, depth] = R[1]
    return im

def b_ore(seed, stone, dark, lit, hi):
    im = b_base(stone, seed)
    px = im.load()
    rng = random.Random(seed + 5)
    for _ in range(3):
        cx, cy = rng.randrange(2, 14), rng.randrange(3, 13)
        for _ in range(rng.randint(5, 7)):
            dx, dy = rng.randint(-2, 2), rng.randint(-1, 1)
            x, y = (cx + dx) % T, (cy + dy) % T
            px[x, y] = lit
            px[x, (y + 1) % T] = dark
        px[cx, cy] = hi
    return im

def b_wood(seed, base):
    R = ramp_sat(base)
    n = value_noise(seed, 4)
    rng = random.Random(seed)
    im = Image.new("RGB", (T, T))
    px = im.load()
    for x in range(T):
        for y in range(T):
            v = n(x, y)
            # горизонтальные волокна
            wave = math.sin((y * 2.1 + v * 4.0)) * 0.5 + 0.5
            idx = 1 + int((v * 0.5 + wave * 0.5) * 2.8)
            if x % 5 == 0:
                idx = 0
            elif x % 5 == 1:
                idx = min(5, idx + 1)
            if y == 0:
                idx = min(5, idx + 1)
            if y == T - 1:
                idx = max(0, idx - 1)
            px[x, y] = R[max(0, min(5, idx))]
    for _ in range(2):  # сучки с колечком
        x, y = rng.randrange(2, 14), rng.randrange(3, 13)
        px[x, y] = R[0]
        px[(x + 1) % T, y] = R[4]
    return im

def b_leaves(seed, base, glow):
    R = ramp_sat(base)
    rng = random.Random(seed)
    im = Image.new("RGB", (T, T), R[0])
    px = im.load()
    # клубки листвы: круглые пучки со светлым верхом
    for _ in range(7):
        cx, cy, r = rng.randrange(T), rng.randrange(T), rng.randint(2, 3)
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if dx * dx + dy * dy <= r * r:
                    x, y = (cx + dx) % T, (cy + dy) % T
                    px[x, y] = R[3] if dy < 0 else R[2]
        px[cx % T, (cy - r) % T] = R[4]
    for _ in range(4):
        px[rng.randrange(T), rng.randrange(T)] = glow
    return im

# ---------- STYLE C : soft painterly --------------------------------------

def c_base(base, seed, tones=5):
    R = ramp(base, steps=tones, spread=0.28)
    n1 = value_noise(seed, 2)
    n2 = value_noise(seed + 7, 4)
    im = Image.new("RGB", (T, T))
    px = im.load()
    for y in range(T):
        for x in range(T):
            v = n1(x, y) * 0.7 + n2(x, y) * 0.3
            v += (1 - y / (T - 1)) * 0.14  # мягкий свет сверху
            idx = int(v * (tones - 0.01))
            px[x, y] = R[max(0, min(tones - 1, idx))]
    return im

def c_grass(seed, soil, green):
    im = c_base(soil, seed)
    px = im.load()
    R = ramp(green, steps=5, spread=0.3)
    n = value_noise(seed + 11, 3)
    rng = random.Random(seed + 2)
    for x in range(T):
        depth = 4 + int(n(x, 0) * 2.5)
        for y in range(depth):
            k = y / max(1, depth - 1)
            px[x, y] = R[4] if y == 0 and rng.random() < 0.4 else R[3 if k < 0.5 else 2]
    return im

def c_ore(seed, stone, dark, lit):
    im = c_base(stone, seed)
    px = im.load()
    rng = random.Random(seed + 5)
    for _ in range(3):
        cx, cy = rng.randrange(2, 14), rng.randrange(3, 13)
        for _ in range(rng.randint(4, 6)):
            x, y = (cx + rng.randint(-2, 2)) % T, (cy + rng.randint(-1, 1)) % T
            px[x, y] = dark if rng.random() < 0.5 else lit
    return im

def c_wood(seed, base):
    R = ramp(base, steps=5, spread=0.3)
    n = value_noise(seed, 3)
    im = Image.new("RGB", (T, T))
    px = im.load()
    for x in range(T):
        for y in range(T):
            idx = 1 + int(n(x, y) * 2.4)
            if x % 8 == 0:
                idx = max(0, idx - 1)
            if y == 0:
                idx = min(4, idx + 1)
            px[x, y] = R[max(0, min(4, idx))]
    return im

def c_leaves(seed, base, glow):
    im = c_base(base, seed, tones=5)
    px = im.load()
    rng = random.Random(seed + 9)
    for _ in range(5):
        px[rng.randrange(T), rng.randrange(T)] = glow
    return im

# ---------- STYLE D : graphic voronoi -------------------------------------

def d_base(base, seed, cells=6, seam_w=0.9):
    R = ramp(base, steps=5, spread=0.4)
    vor = voronoi(seed, cells)
    im = Image.new("RGB", (T, T))
    px = im.load()
    for y in range(T):
        for x in range(T):
            i, tone, edge = vor(x, y)
            idx = 1 + int(tone * 2.9)
            if edge < seam_w:          # тёмный шов между камнями
                idx = 0
            else:
                _, _, eu = vor(x, (y - 1) % T)
                iu, _, _ = vor(x, (y - 1) % T)
                if iu != i:            # светлый верх каждого булыжника
                    idx = min(4, idx + 1)
            px[x, y] = R[max(0, min(4, idx))]
    return im

def d_grass(seed, soil, green):
    im = d_base(soil, seed, cells=5)
    px = im.load()
    R = ramp(green, steps=5, spread=0.42)
    rng = random.Random(seed + 3)
    n = value_noise(seed + 11, 4)
    for x in range(T):
        depth = 4 + int(n(x, 0) * 2.5)
        for y in range(depth):
            if y == 0:
                px[x, y] = R[4]
            elif y == depth - 1:
                px[x, y] = R[0]        # графичная тёмная граница
            else:
                px[x, y] = R[2] if rng.random() < 0.7 else R[3]
    return im

def d_ore(seed, stone, dark, lit, hi):
    im = d_base(stone, seed)
    px = im.load()
    rng = random.Random(seed + 5)
    for _ in range(3):                 # чанки-кристаллы 2x2 с обводкой
        cx, cy = rng.randrange(2, 13), rng.randrange(3, 12)
        for dx in range(2):
            for dy in range(2):
                px[cx + dx, cy + dy] = lit if dy == 0 else dark
        px[cx, cy] = hi
        for dx in range(-1, 3):
            px[(cx + dx) % T, (cy + 2) % T] = tuple(int(c * 0.5) for c in dark)
    return im

def d_wood(seed, base):
    R = ramp(base, steps=5, spread=0.42)
    rng = random.Random(seed)
    im = Image.new("RGB", (T, T))
    px = im.load()
    shades = [1, 2, 2, 3]
    for p in range(4):                 # 4 доски по 4px
        tone = shades[(p + seed) % 4]
        for x in range(p * 4, p * 4 + 4):
            for y in range(T):
                idx = tone
                if x % 4 == 0:
                    idx = 0            # шов
                elif x % 4 == 1:
                    idx = min(4, tone + 1)
                if rng.random() < 0.08:
                    idx = max(0, idx - 1)  # штрихи волокон
                px[x, y] = R[idx]
        # гвоздики
        px[p * 4 + 2, 1] = R[4]
        px[p * 4 + 2, T - 2] = R[0]
    return im

def d_leaves(seed, base, glow):
    R = ramp(base, steps=5, spread=0.42)
    vor = voronoi(seed, 7)
    im = Image.new("RGB", (T, T))
    px = im.load()
    rng = random.Random(seed + 9)
    for y in range(T):
        for x in range(T):
            i, tone, edge = vor(x, y)
            idx = 1 + int(tone * 2.9)
            if edge < 0.9:
                idx = 0
            px[x, y] = R[max(0, min(4, idx))]
    for _ in range(4):
        px[rng.randrange(T), rng.randrange(T)] = glow
    return im

# ---------- palettes -------------------------------------------------------

DIRT = (124, 88, 58)
GRASS_GREEN = (86, 152, 74)
STONE = (104, 108, 116)
WOOD = (128, 92, 56)
LEAVES = (66, 110, 58)
MOSS = (84, 118, 72)
COPPER_D, COPPER_L, COPPER_H = (150, 92, 48), (196, 128, 66), (232, 176, 110)
IRON_D, IRON_L, IRON_H = (126, 134, 148), (186, 194, 206), (228, 234, 242)
LEAF_GLOW = (128, 190, 96)

def build_style(style, seed0=100):
    s = seed0
    if style == "B":
        return {
            "dirt":   b_base(DIRT, s + 1),
            "grass":  b_grass(s + 2, DIRT, GRASS_GREEN),
            "stone":  b_base(STONE, s + 3),
            "copper": b_ore(s + 4, STONE, COPPER_D, COPPER_L, COPPER_H),
            "iron":   b_ore(s + 5, STONE, IRON_D, IRON_L, IRON_H),
            "wood":   b_wood(s + 6, WOOD),
            "leaves": b_leaves(s + 7, LEAVES, LEAF_GLOW),
            "moss":   b_base(MOSS, s + 8),
        }
    if style == "C":
        return {
            "dirt":   c_base(DIRT, s + 1),
            "grass":  c_grass(s + 2, DIRT, GRASS_GREEN),
            "stone":  c_base(STONE, s + 3),
            "copper": c_ore(s + 4, STONE, COPPER_D, COPPER_L),
            "iron":   c_ore(s + 5, STONE, IRON_D, IRON_L),
            "wood":   c_wood(s + 6, WOOD),
            "leaves": c_leaves(s + 7, LEAVES, LEAF_GLOW),
            "moss":   c_base(MOSS, s + 8),
        }
    if style == "D":
        return {
            "dirt":   d_base(DIRT, s + 1, cells=5),
            "grass":  d_grass(s + 2, DIRT, GRASS_GREEN),
            "stone":  d_base(STONE, s + 3),
            "copper": d_ore(s + 4, STONE, COPPER_D, COPPER_L, COPPER_H),
            "iron":   d_ore(s + 5, STONE, IRON_D, IRON_L, IRON_H),
            "wood":   d_wood(s + 6, WOOD),
            "leaves": d_leaves(s + 7, LEAVES, LEAF_GLOW),
            "moss":   d_base(MOSS, s + 8, cells=7),
        }
    raise ValueError(style)

MATS = ["dirt", "grass", "stone", "copper", "iron", "wood", "leaves", "moss"]

if __name__ == "__main__":
    for st in ("B", "C", "D"):
        tiles = build_style(st)
        for name, im in tiles.items():
            im.save(f"/tmp/alt{st}_{name}.png")
    print("done")
