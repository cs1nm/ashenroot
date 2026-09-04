#!/usr/bin/env python3
"""Full 32x32 tile rollout for Ashen Roots.

Builds every full-block material in the approved HD style (quiet shared base
per material + variant-only interior details) plus biome override sets.

Skipped on purpose:
- water / lava: engine crops liquid surface by texture height; needs an
  engine fix before upgrading (separate package).
- furniture / stations / plants (alpha sprites): hand-drawn package later.

Output: /tmp/tiles32/<name>[_1..3].png and /tmp/tiles32/biomes/<biome>/<name>.png
"""
import os, math, random, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_tiles32 import (T, ramp, value_noise, clamp_idx,
                          dirt, grass, stone, ore, wood, leaves, moss)
from PIL import Image

BASE = 40

# ---------------- extra generators ----------------

def sand(seed, base, accent, detail_seed=None):
    """Wind-layered sand: soft horizontal strata + drifting speckles."""
    if detail_seed is None:
        detail_seed = seed
    R = ramp(base, spread=0.34)
    n = value_noise(seed, 3)
    im = Image.new("RGB", (T, T))
    px = im.load()
    for y in range(T):
        for x in range(T):
            wave = math.sin(y * 0.55 + n(x, y) * 3.2) * 0.5 + 0.5
            idx = 2 if wave < 0.62 else 3
            px[x, y] = R[clamp_idx(idx)]
    rng = random.Random(detail_seed + 3)
    M = 3
    for _ in range(10):  # drifting grains
        x, y = rng.randrange(M, T - M), rng.randrange(M, T - M)
        px[x, y] = R[4] if rng.random() < 0.7 else R[1]
    for _ in range(2):  # warm accent glints
        x, y = rng.randrange(M, T - M), rng.randrange(M, T - M)
        px[x, y] = accent
    return im

def snow(seed, base, detail_seed=None):
    """Soft snow: two bright tones, blue shadow pockets, sparkles."""
    if detail_seed is None:
        detail_seed = seed
    R = ramp(base, spread=0.22)
    n = value_noise(seed, 2)
    im = Image.new("RGB", (T, T))
    px = im.load()
    for y in range(T):
        for x in range(T):
            v = n(x, y)
            idx = 3 if v < 0.6 else 4
            px[x, y] = R[clamp_idx(idx)]
    rng = random.Random(detail_seed + 3)
    M = 3
    for _ in range(4):  # shadow pockets
        cx, cy = rng.randrange(M, T - M - 3), rng.randrange(M, T - M - 2)
        w, h = rng.randint(3, 5), rng.randint(2, 3)
        for dx in range(w):
            for dy in range(h):
                if rng.random() < 0.75:
                    px[cx + dx, cy + dy] = R[2]
    for _ in range(5):  # sparkles
        x, y = rng.randrange(M, T - M), rng.randrange(M, T - M)
        px[x, y] = R[5]
    return im

def brick(seed, base, mortar_scale=0.5, glow=None, detail_seed=None):
    """Brick courses 16x8 with running bond and dark mortar."""
    if detail_seed is None:
        detail_seed = seed
    R = ramp(base)
    mortar = tuple(int(c * mortar_scale) for c in R[1])
    rng_tone = random.Random(seed + 1)   # brick tones SHARED across variants
    rng = random.Random(detail_seed + 3)
    n = value_noise(seed, 5)
    BW, BH = 16, 8
    rows = T // BH
    tones = [[rng_tone.choice([2, 2, 3, 3, 4]) for _ in range(3)] for _ in range(rows)]
    im = Image.new("RGB", (T, T))
    px = im.load()
    for y in range(T):
        row = y // BH
        offset = (row % 2) * (BW // 2)
        for x in range(T):
            bx = (x + offset) % T
            tone = tones[row][bx // BW]
            idx = tone + (1 if n(x, y) > 0.72 else (-1 if n(x, y) < 0.2 else 0))
            if y % BH == 0 or bx % BW == 0:
                px[x, y] = mortar
                continue
            if y % BH == 1:
                idx = min(5, idx + 1)   # lit top of each brick
            elif y % BH == BH - 1:
                idx = max(1, idx - 1)
            px[x, y] = R[clamp_idx(idx)]
    for _ in range(4):  # chips / pitting per variant
        x, y = rng.randrange(2, T - 2), rng.randrange(2, T - 2)
        if px[x, y] != mortar:
            px[x, y] = R[1]
    if glow is not None:  # embers stuck in mortar
        for _ in range(3):
            x, y = rng.randrange(2, T - 2), rng.randrange(1, rows) * BH
            px[x, y] = glow
    return im

def root_block(seed, base, glow=None, detail_seed=None):
    """Woody root mass: thick vertical roots that sway with a bounded sine
    wobble (no cumulative drift -> no diagonal lattice artifact)."""
    if detail_seed is None:
        detail_seed = seed
    R = ramp(base)
    soil = tuple(int(c * 0.55) for c in R[1])
    im = Image.new("RGB", (T, T), soil)
    px = im.load()
    rng_path = random.Random(seed + 2)   # root paths SHARED across variants
    n = value_noise(seed, 3)
    for i in range(4):  # vertical winding roots
        cx = i * (T // 4) + rng_path.randrange(2)
        phase = rng_path.random() * 6.28
        amp = 0.8 + rng_path.random() * 0.6   # small sway: roots never cross
        for y in range(T):
            # bounded sine sway, wraps vertically (freq multiple of 2pi/T)
            sway = math.sin(phase + y * (2 * math.pi / T)) * amp
            x = int(cx + sway) % T
            w = 3 + (1 if n(x, y) > 0.62 else 0)
            for dx in range(w):
                xx = (x + dx) % T
                tone = 3 if dx == 0 else 2
                px[xx, y] = R[tone]
            px[(x + w) % T, y] = R[1]  # shaded side
    rng = random.Random(detail_seed + 3)
    for _ in range(4):  # bark nicks per variant
        x, y = rng.randrange(2, T - 2), rng.randrange(2, T - 2)
        px[x, y] = R[4]
    if glow is not None:
        for _ in range(2):
            x, y = rng.randrange(2, T - 2), rng.randrange(2, T - 2)
            px[x, y] = glow
    return im

def crystal_stone(seed, stone_base, dark, lit, hi, shards=5, detail_seed=None):
    """Stone studded with angular crystal shards (bigger than ore blobs)."""
    if detail_seed is None:
        detail_seed = seed
    im = stone(seed, stone_base, detail_seed)
    px = im.load()
    rng = random.Random(detail_seed + 9)
    shadow = tuple(int(c * 0.4) for c in dark)
    for _ in range(shards):
        cx, cy = rng.randrange(4, T - 5), rng.randrange(4, T - 5)
        h = rng.randint(3, 5)
        for i in range(h):  # upward shard: narrow at tip
            w = max(1, 2 - i // 2)
            for dx in range(-w + 1, w):
                x, y = cx + dx, cy - i
                if 0 <= x < T and 0 <= y < T:
                    px[x, y] = lit if dx <= 0 else dark
        if cy - h >= 0:
            px[cx, cy - h + 1] = hi
        for dx in range(-1, 2):  # socket shadow
            if 0 <= cx + dx < T and cy + 1 < T:
                px[cx + dx, cy + 1] = shadow
    return im

def glassy_stone(seed, base, streak, detail_seed=None):
    """Smooth vitrified stone with diagonal glassy streaks."""
    if detail_seed is None:
        detail_seed = seed
    R = ramp(base, spread=0.36)
    n = value_noise(seed, 3)
    im = Image.new("RGB", (T, T))
    px = im.load()
    for y in range(T):
        for x in range(T):
            idx = 2 if n(x, y) < 0.58 else 3
            px[x, y] = R[clamp_idx(idx)]
    rng = random.Random(detail_seed + 3)
    for _ in range(3):  # diagonal streaks
        x, y = rng.randrange(2, T - 2), rng.randrange(4, T - 4)
        ln = rng.randint(4, 7)
        for i in range(ln):
            xx, yy = (x + i) % T, (y - i) % T
            px[xx, yy] = streak if i % 3 else R[5]
    for _ in range(3):
        x, y = rng.randrange(2, T - 2), rng.randrange(2, T - 2)
        px[x, y] = R[4]
    return im

def mud(seed, base, detail_seed=None):
    """Wet mud: quiet clumps, dark wet pits with glossy highlights."""
    if detail_seed is None:
        detail_seed = seed
    im = dirt(seed, base, detail_seed)
    px = im.load()
    R = ramp(base)
    rng = random.Random(detail_seed + 13)
    M = 3
    for _ in range(4):  # wet pits with a gloss pixel
        cx, cy = rng.randrange(M, T - M - 2), rng.randrange(M, T - M - 2)
        for dx in range(rng.randint(2, 3)):
            for dy in range(2):
                px[cx + dx, cy + dy] = R[0]
        px[cx, cy] = R[5]
    return im

# ---------------- palettes ----------------

STONE_C = (100, 104, 112)

FOREST = {
    "dirt": (124, 88, 58), "green": (88, 154, 74), "wood": (128, 92, 56),
    "leaves": (62, 106, 56), "moss": (88, 126, 74),
}

MATS = {}

def reg(name, fn, has_variants=True):
    MATS[name] = (fn, has_variants)

# forest core
reg("dirt",   lambda s, d: dirt(s + 1, FOREST["dirt"], d + 1))
reg("grass",  lambda s, d: grass(s + 2, FOREST["dirt"], FOREST["green"], d + 2))
reg("stone",  lambda s, d: stone(s + 3, STONE_C, d + 3))
reg("copper", lambda s, d: ore(s + 4, STONE_C, (148, 88, 44), (200, 130, 66), (240, 182, 116), d + 4))
reg("iron",   lambda s, d: ore(s + 5, STONE_C, (120, 128, 142), (190, 198, 210), (234, 240, 248), d + 5))
reg("wood",   lambda s, d: wood(s + 6, FOREST["wood"], d + 6))
reg("leaves", lambda s, d: leaves(s + 7, FOREST["leaves"], (132, 196, 98), detail_seed=d + 7))
reg("moss",   lambda s, d: moss(s + 8, FOREST["moss"], STONE_C, d + 8))

# soils & surfaces
reg("ash",          lambda s, d: dirt(s + 9, (86, 80, 92), d + 9))
reg("ash_sand",     lambda s, d: sand(s + 10, (198, 168, 118), (246, 164, 58), d + 10))
reg("frozen_dirt",  lambda s, d: dirt(s + 11, (108, 112, 128), d + 11))
reg("snow_block",   lambda s, d: snow(s + 12, (200, 218, 234), d + 12))
reg("mud",          lambda s, d: mud(s + 13, (92, 72, 48), d + 13))
reg("mushroom_soil", lambda s, d: dirt(s + 14, (104, 70, 108), d + 14))

# rock family
reg("ruin",         lambda s, d: brick(s + 15, (96, 90, 110), 0.55, None, d + 15))
reg("ash_brick",    lambda s, d: brick(s + 16, (104, 76, 82), 0.45, (255, 150, 52), d + 16))
reg("rubble",       lambda s, d: stone(s + 17, (112, 102, 92), d + 17))
reg("sunken_stone", lambda s, d: stone(s + 18, (66, 104, 108), d + 18))
reg("depth_stone",  lambda s, d: stone(s + 19, (66, 58, 86), d + 19))
reg("glass_stone",  lambda s, d: glassy_stone(s + 20, (74, 112, 118), (200, 245, 255), d + 20))
reg("stoneblood",   lambda s, d: ore(s + 21, (92, 96, 104), (122, 34, 34), (190, 62, 52), (238, 74, 64), d + 21))
reg("abyss_crystal", lambda s, d: crystal_stone(s + 22, (56, 62, 80), (90, 150, 165), (150, 214, 224), (220, 250, 255), 5, d + 22))

# organics
reg("root",      lambda s, d: root_block(s + 23, (118, 78, 48), None, d + 23))
reg("lava_root", lambda s, d: root_block(s + 24, (96, 56, 44), (255, 120, 40), d + 24))

# ---------------- biome overrides ----------------

BIOMES = {
    "ash_desert": {
        "dirt": (150, 106, 62), "green": (176, 148, 66), "stone": (120, 108, 94),
        "wood": (138, 100, 58), "leaves": (150, 122, 54), "moss": (146, 132, 66),
        "glow": (246, 164, 58),
    },
    "ash_ruins": {
        "dirt": (98, 84, 86), "green": (118, 112, 92), "stone": (94, 88, 104),
        "wood": (104, 86, 80), "leaves": (104, 96, 112), "moss": (118, 110, 86),
        "glow": (255, 150, 52),
    },
    "marsh": {
        "dirt": (94, 78, 50), "green": (84, 128, 60), "stone": (90, 98, 88),
        "wood": (98, 80, 52), "leaves": (58, 98, 52), "moss": (100, 132, 60),
        "glow": (140, 190, 90),
    },
    "frost_wasteland": {
        "dirt": (108, 104, 112), "green": (150, 180, 186), "stone": (106, 116, 132),
        "wood": (106, 88, 66), "leaves": (112, 144, 152), "moss": (118, 148, 128),
        "glow": (215, 240, 250),
    },
}

def build_biome(biome, p, s):
    out = {
        "dirt":   dirt(s + 1, p["dirt"], s + 51),
        "grass":  grass(s + 2, p["dirt"], p["green"], s + 52),
        "stone":  stone(s + 3, p["stone"], s + 53),
        "wood":   wood(s + 6, p["wood"], s + 56),
        "leaves": leaves(s + 7, p["leaves"], p["glow"], detail_seed=s + 57),
        "moss":   moss(s + 8, p["moss"], p["stone"], s + 58),
    }
    if biome == "frost_wasteland":
        out["snow_block"] = snow(s + 12, (206, 222, 238), s + 62)
    return out

# ---------------- main ----------------

if __name__ == "__main__":
    outdir = "/tmp/tiles32"
    os.makedirs(outdir, exist_ok=True)
    for name, (fn, has_variants) in MATS.items():
        count = 4 if has_variants else 1
        for vi in range(count):
            suffix = "" if vi == 0 else f"_{vi}"
            fn(BASE, BASE + vi * 100).save(f"{outdir}/{name}{suffix}.png")
    for bi, (biome, p) in enumerate(BIOMES.items()):
        bdir = f"{outdir}/biomes/{biome}"
        os.makedirs(bdir, exist_ok=True)
        for name, im in build_biome(biome, p, BASE + 1000 + bi * 500).items():
            im.save(f"{bdir}/{name}.png")
    print("done:", len(MATS), "materials +", len(BIOMES), "biome sets")
