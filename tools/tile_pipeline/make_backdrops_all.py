#!/usr/bin/env python3
"""All-biome painterly parallax backdrops.

Layers per biome (512px wide, tile horizontally):
- far   : hazy ridge/skyline sunk toward the sky color
- fog   : soft fog band (biome-tinted)
- mid   : main subject band (trees/ruins/mushrooms/columns...)
- near  : darkest foreground band
- canopy: optional overhang pinned to the top of the screen
          (forest foliage, cave ceilings)

Output: /tmp/backdrops/<biome>/<layer>.png
"""
import math, random, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_backdrops import (LW, lerp, smooth_ridge, fog_band,
                            _shade_crown, forest_far, forest_mid,
                            forest_near, FOREST_SKY)
from PIL import Image

def canvas(h):
    return Image.new("RGBA", (LW, h), (0, 0, 0, 0))

def ridge_fill(px, LH, ridge_fn, top_col, bot_col, wobble=(4, 0.11, 3, 0.043)):
    a1, f1, a2, f2 = wobble
    for x in range(LW):
        t = int(ridge_fn(x) * LH)
        t += int(a1 * math.sin(x * f1) + a2 * math.sin(x * f2 + 1.7))
        for y in range(max(0, t), LH):
            k = (y - t) / max(1, LH - t)
            px[x, y] = (*lerp(top_col, bot_col, k), 255)

def ground_band(px, LH, base, col_top, col_bot, wob_amp=2.0):
    for x in range(LW):
        wob = int(wob_amp * math.sin(x * 0.05))
        for y in range(base + wob, LH):
            k = (y - base) / max(1, LH - base)
            px[x, y] = (*lerp(col_top, col_bot, min(1.0, k * 1.6)), 255)

# ================= frost_wasteland =================

FROST_SKY = (70, 96, 122)

def frost_far():
    LH = 224
    im = canvas(LH); px = im.load()
    ridge_fill(px, LH, smooth_ridge(41, 5, 0.42, 0.16),
               lerp(FROST_SKY, (150, 170, 192), 0.5),
               lerp(FROST_SKY, (120, 142, 166), 0.6))
    return im

def _conifer(px, cx, base, h, w, dark, lit, LH):
    ty = base - h
    for row in range(h):
        y = ty + row
        if not (0 <= y < LH):
            continue
        half = int(1 + (row / h) * w)
        for dx in range(-half, half + 1):
            x = (cx + dx) % LW
            px[x, y] = (*lit, 255) if dx <= -half + 1 or row < 3 else (*dark, 255)

def frost_mid():
    LH = 224
    im = canvas(LH); px = im.load()
    rng = random.Random(42)
    dark = (52, 74, 96); lit = (120, 146, 170)
    base = int(LH * 0.8)
    ground_band(px, LH, base, (110, 132, 158), (74, 96, 120), 3)
    for i in range(9):
        cx = int(i * LW / 9 + rng.randrange(-14, 14)) % LW
        _conifer(px, cx, base + 4, rng.randint(58, 104), rng.randint(9, 13),
                 dark, lit, LH)
    # snow drifts
    for _ in range(60):
        x = rng.randrange(LW); y = base + rng.randrange(2, LH - base - 1)
        px[x, y] = (150, 170, 192, 255)
    return im

def frost_near():
    LH = 288
    im = canvas(LH); px = im.load()
    rng = random.Random(43)
    dark = (26, 40, 58); lit = (66, 88, 112)
    base = int(LH * 0.88)
    ground_band(px, LH, base, (44, 62, 84), (22, 34, 50), 4)
    for i in range(4):
        cx = int(i * LW / 4 + rng.randrange(-24, 24)) % LW
        _conifer(px, cx, base + 8, rng.randint(150, 220), rng.randint(20, 26),
                 dark, lit, LH)
    return im

# ================= marsh =================

MARSH_SKY = (52, 82, 70)

def marsh_far():
    LH = 224
    im = canvas(LH); px = im.load()
    ridge_fill(px, LH, smooth_ridge(51, 6, 0.5, 0.08),
               lerp(MARSH_SKY, (40, 66, 56), 0.5),
               lerp(MARSH_SKY, (32, 56, 47), 0.75))
    return im

def _snag(px, cx, base, h, dark, LH, rng):
    """Dead crooked tree."""
    x = cx
    for row in range(h):
        y = base - row
        if not (0 <= y < LH):
            continue
        x += rng.choice([-1, 0, 0, 1]) if row % 3 == 0 else 0
        w = max(1, 3 - row * 3 // h)
        for dx in range(w):
            px[(x + dx) % LW, y] = (*dark, 255)
        if row > h // 3 and rng.random() < 0.12:  # bare branch
            blen = rng.randint(6, 16); bdir = rng.choice([-1, 1])
            for k in range(blen):
                bx = (x + bdir * k) % LW; by = y - k // 3
                if 0 <= by < LH:
                    px[bx, by] = (*dark, 255)

def marsh_mid():
    LH = 224
    im = canvas(LH); px = im.load()
    rng = random.Random(52)
    dark = (22, 42, 36)
    base = int(LH * 0.8)
    ground_band(px, LH, base, (30, 52, 44), (18, 34, 29), 2)
    for i in range(7):
        cx = int(i * LW / 7 + rng.randrange(-18, 18)) % LW
        _snag(px, cx, base + 2, rng.randint(56, 96), dark, LH, rng)
    # reeds
    for _ in range(70):
        x = rng.randrange(LW); h = rng.randint(6, 18)
        for k in range(h):
            px[(x + k // 6) % LW, base - k] = (*dark, 255)
        px[(x + h // 6) % LW, base - h] = (34, 60, 48, 255)
    return im

def marsh_near():
    LH = 288
    im = canvas(LH); px = im.load()
    rng = random.Random(53)
    dark = (12, 26, 22)
    base = int(LH * 0.88)
    ground_band(px, LH, base, (16, 32, 27), (9, 20, 17), 4)
    for i in range(3):
        cx = int(i * LW / 3 + rng.randrange(-30, 30)) % LW
        _snag(px, cx, base + 6, rng.randint(150, 230), dark, LH, rng)
    for _ in range(50):  # tall cattails
        x = rng.randrange(LW); h = rng.randint(16, 40)
        for k in range(h):
            px[(x + k // 8) % LW, base - k] = (*dark, 255)
        for k in range(4):  # cattail head
            px[(x + h // 8) % LW, base - h - k] = (20, 38, 30, 255)
    return im

# ================= ash_desert =================

DESERT_SKY = (122, 92, 66)

def desert_far():
    LH = 224
    im = canvas(LH); px = im.load()
    ridge_fill(px, LH, smooth_ridge(61, 4, 0.45, 0.14),
               lerp(DESERT_SKY, (166, 128, 88), 0.55),
               lerp(DESERT_SKY, (140, 106, 72), 0.7),
               (6, 0.05, 4, 0.021))
    return im

def desert_mid():
    LH = 224
    im = canvas(LH); px = im.load()
    rng = random.Random(62)
    base = int(LH * 0.74)
    # dune band with lit windward side
    dune = smooth_ridge(63, 5, 0.7, 0.12)
    lit = (150, 112, 74); dark = (108, 80, 54)
    for x in range(LW):
        t = int(dune(x) * LH * 0.5) + base - int(LH * 0.35)
        slope = dune((x + 6) % LW) - dune(x)
        for y in range(max(0, t), LH):
            c = lit if slope < -0.004 else dark
            k = (y - t) / max(1, LH - t)
            px[x, y] = (*lerp(c, (86, 62, 44), min(1.0, k * 1.4)), 255)
    # broken rock spires
    for i in range(3):
        cx = int(i * LW / 3 + rng.randrange(-30, 30)) % LW
        h = rng.randint(40, 70); w = rng.randint(10, 16)
        for row in range(h):
            y = base - row
            half = max(2, w - row * w // h)
            for dx in range(-half, half + 1):
                if 0 <= y < LH:
                    px[(cx + dx) % LW, y] = (96, 70, 50, 255) if dx > -half + 2 else (128, 96, 64, 255)
    return im

def desert_near():
    LH = 288
    im = canvas(LH); px = im.load()
    rng = random.Random(64)
    base = int(LH * 0.84)
    dune = smooth_ridge(65, 4, 0.5, 0.2)
    for x in range(LW):
        t = int(dune(x) * LH * 0.3) + base - int(LH * 0.15)
        for y in range(max(0, t), LH):
            px[x, y] = (66, 48, 36, 255)
    # dead trees
    for i in range(2):
        cx = int(i * LW / 2 + rng.randrange(-40, 40)) % LW
        _snag(px, cx, base, rng.randint(90, 140), (48, 36, 28), LH, rng)
    return im

# ================= ash_ruins / ash_city =================

RUIN_SKY = (86, 70, 82)

def _ruin_wall(px, cx, base, h, w, dark, lit, LH, rng, windows=False,
               ember=None):
    top = base - h
    for x in range(cx, cx + w):
        # broken top edge
        cut = int(6 * math.sin(x * 0.7) + rng.randrange(4))
        for y in range(top + cut, base):
            if not (0 <= y < LH):
                continue
            c = lit if x == cx else dark
            px[x % LW, y] = (*c, 255)
    if windows:
        for wy in range(top + 12, base - 6, 14):
            for wx in range(cx + 3, cx + w - 3, 8):
                if rng.random() < 0.7:
                    for dx in range(3):
                        for dy in range(4):
                            px[(wx + dx) % LW, wy + dy] = (24, 18, 22, 255)
                    if ember and rng.random() < 0.18:
                        px[(wx + 1) % LW, wy + 2] = (*ember, 255)

def ashruins_far():
    LH = 224
    im = canvas(LH); px = im.load()
    ridge_fill(px, LH, smooth_ridge(71, 6, 0.5, 0.1),
               lerp(RUIN_SKY, (120, 100, 112), 0.5),
               lerp(RUIN_SKY, (100, 82, 94), 0.7))
    return im

def ashruins_mid():
    LH = 224
    im = canvas(LH); px = im.load()
    rng = random.Random(72)
    base = int(LH * 0.8)
    ground_band(px, LH, base, (74, 60, 70), (52, 42, 50), 2)
    for i in range(6):
        cx = int(i * LW / 6 + rng.randrange(-10, 10)) % LW
        _ruin_wall(px, cx, base + 2, rng.randint(50, 90), rng.randint(16, 30),
                   (58, 47, 55), (86, 70, 80), LH, rng)
    # broken columns
    for i in range(4):
        cx = int(i * LW / 4 + 40 + rng.randrange(-16, 16)) % LW
        h = rng.randint(24, 46)
        for y in range(base - h, base):
            for dx in range(5):
                px[(cx + dx) % LW, y] = (66, 54, 62, 255) if dx else (92, 76, 86, 255)
    return im

def ashruins_near():
    LH = 288
    im = canvas(LH); px = im.load()
    rng = random.Random(73)
    base = int(LH * 0.88)
    ground_band(px, LH, base, (40, 32, 38), (24, 19, 23), 3)
    for i in range(3):
        cx = int(i * LW / 3 + rng.randrange(-20, 20)) % LW
        _ruin_wall(px, cx, base + 4, rng.randint(140, 220), rng.randint(34, 52),
                   (30, 24, 29), (52, 42, 50), LH, rng)
    # drifting embers
    for _ in range(14):
        x, y = rng.randrange(LW), rng.randrange(LH - 60)
        px[x, y] = (255, 150, 52, 255)
    return im

def ashcity_mid():
    LH = 224
    im = canvas(LH); px = im.load()
    rng = random.Random(82)
    base = int(LH * 0.82)
    ground_band(px, LH, base, (56, 46, 54), (38, 31, 37), 2)
    for i in range(6):
        cx = int(i * LW / 6 + rng.randrange(-8, 8)) % LW
        _ruin_wall(px, cx, base + 2, rng.randint(70, 130), rng.randint(20, 34),
                   (44, 36, 44), (68, 56, 66), LH, rng, windows=True,
                   ember=(240, 140, 60))
    return im

def ashcity_near():
    LH = 288
    im = canvas(LH); px = im.load()
    rng = random.Random(83)
    base = int(LH * 0.9)
    ground_band(px, LH, base, (30, 24, 30), (18, 14, 18), 3)
    for i in range(3):
        cx = int(i * LW / 3 + rng.randrange(-16, 16)) % LW
        _ruin_wall(px, cx, base + 4, rng.randint(170, 250), rng.randint(46, 64),
                   (22, 17, 22), (40, 32, 40), LH, rng, windows=True,
                   ember=(240, 140, 60))
    return im

# ================= mushroom_halls =================

SHROOM_SKY = (64, 56, 96)

def _mushroom(px, cx, base, h, cap_r, stem_c, cap_core, cap_lit, glow, LH, rng):
    ty = base - h
    for y in range(ty, base):
        if not (0 <= y < LH):
            continue
        w = 3 + (2 if (base - y) < h // 4 else 0)
        for dx in range(w):
            px[(cx + dx) % LW, y] = (*stem_c, 255)
    for dx in range(-cap_r, cap_r + 1):
        for dy in range(-cap_r // 2, 3):
            if (dx * dx) / (cap_r * cap_r + 1e-6) + (dy * dy) / (cap_r * cap_r * 0.3 + 1e-6) <= 1.0:
                x, y = (cx + 1 + dx) % LW, ty + dy
                if 0 <= y < LH:
                    px[x, y] = (*(cap_lit if dy < -cap_r // 4 else cap_core), 255)
    for _ in range(cap_r):
        ang = rng.random() * 3.14
        x = (cx + 1 + int(math.cos(ang) * cap_r * 0.8)) % LW
        y = ty + int(-abs(math.sin(ang)) * cap_r * 0.4)
        if 0 <= y < LH:
            px[x, y] = (*glow, 255)

def shroom_far():
    LH = 224
    im = canvas(LH); px = im.load()
    ridge_fill(px, LH, smooth_ridge(91, 6, 0.48, 0.1),
               lerp(SHROOM_SKY, (92, 82, 128), 0.5),
               lerp(SHROOM_SKY, (76, 68, 108), 0.7))
    return im

def shroom_mid():
    LH = 224
    im = canvas(LH); px = im.load()
    rng = random.Random(92)
    base = int(LH * 0.8)
    ground_band(px, LH, base, (56, 50, 88), (40, 36, 64), 2)
    for i in range(6):
        cx = int(i * LW / 6 + rng.randrange(-14, 14)) % LW
        _mushroom(px, cx, base + 2, rng.randint(40, 84), rng.randint(14, 24),
                  (48, 42, 76), (70, 58, 108), (94, 80, 140),
                  (168, 232, 110), LH, rng)
    return im

def shroom_near():
    LH = 288
    im = canvas(LH); px = im.load()
    rng = random.Random(93)
    base = int(LH * 0.88)
    ground_band(px, LH, base, (34, 30, 56), (20, 18, 34), 3)
    for i in range(3):
        cx = int(i * LW / 3 + rng.randrange(-24, 24)) % LW
        _mushroom(px, cx, base + 6, rng.randint(130, 200), rng.randint(34, 48),
                  (26, 23, 44), (42, 36, 68), (58, 50, 92),
                  (120, 180, 80), LH, rng)
    return im

def cave_ceiling(color, glow=None, seed=5, LH=72):
    """Stalactite ceiling band pinned to the screen top."""
    im = canvas(LH); px = im.load()
    rng = random.Random(seed)
    for x in range(LW):
        depth = int(20 + 10 * math.sin(x * 0.045) + 7 * math.sin(x * 0.013 + 2.0))
        for y in range(depth):
            px[x, y] = (*color, 255)
    for _ in range(26):  # stalactites
        x = rng.randrange(LW)
        depth = int(20 + 10 * math.sin(x * 0.045) + 7 * math.sin(x * 0.013 + 2.0))
        ln = rng.randint(6, 22)
        for k in range(ln):
            w = max(1, 3 - k * 3 // ln)
            for dx in range(w):
                if depth + k < LH:
                    px[(x + dx) % LW, depth + k] = (*color, 255)
        if glow and rng.random() < 0.4:
            if depth + ln + 1 < LH:
                px[x, depth + ln] = (*glow, 255)
    return im

# ================= sunken_ruins =================

SUNKEN_SKY = (36, 74, 88)

def sunken_far():
    LH = 224
    im = canvas(LH); px = im.load()
    ridge_fill(px, LH, smooth_ridge(101, 5, 0.55, 0.08),
               lerp(SUNKEN_SKY, (60, 108, 122), 0.5),
               lerp(SUNKEN_SKY, (46, 90, 104), 0.7))
    return im

def _column(px, cx, base, h, w, dark, lit, LH, rng, broken=True):
    top = base - h
    cut = rng.randrange(6) if broken else 0
    for y in range(top + cut, base):
        if not (0 <= y < LH):
            continue
        for dx in range(w):
            c = lit if dx == 0 else dark
            if dx % 3 == 2:  # flutes
                c = tuple(int(v * 0.85) for v in c)
            px[(cx + dx) % LW, y] = (*c, 255)
    # capital
    if not broken or rng.random() < 0.5:
        for dx in range(-2, w + 2):
            for dy in range(3):
                y = top + cut - dy
                if 0 <= y < LH:
                    px[(cx + dx) % LW, y] = (*lit, 255)

def sunken_mid():
    LH = 224
    im = canvas(LH); px = im.load()
    rng = random.Random(102)
    base = int(LH * 0.8)
    ground_band(px, LH, base, (30, 62, 72), (20, 44, 52), 2)
    for i in range(6):
        cx = int(i * LW / 6 + rng.randrange(-10, 10)) % LW
        _column(px, cx, base + 2, rng.randint(50, 92), rng.randint(8, 12),
                (26, 56, 66), (48, 92, 104), LH, rng)
    # seaweed
    for _ in range(40):
        x = rng.randrange(LW); h = rng.randint(8, 24)
        for k in range(h):
            px[(x + int(2 * math.sin(k * 0.5))) % LW, base - k] = (18, 48, 44, 255)
    return im

def sunken_near():
    LH = 288
    im = canvas(LH); px = im.load()
    rng = random.Random(103)
    base = int(LH * 0.88)
    ground_band(px, LH, base, (16, 36, 44), (10, 24, 30), 3)
    for i in range(3):
        cx = int(i * LW / 3 + rng.randrange(-20, 20)) % LW
        _column(px, cx, base + 6, rng.randint(150, 230), rng.randint(18, 26),
                (12, 30, 38), (26, 58, 68), LH, rng)
    for _ in range(30):
        x = rng.randrange(LW); h = rng.randint(20, 50)
        for k in range(h):
            px[(x + int(3 * math.sin(k * 0.3))) % LW, base - k] = (8, 24, 22, 255)
    return im

# ================= lava_roots =================

LAVA_SKY = (96, 46, 34)

def lava_far():
    LH = 224
    im = canvas(LH); px = im.load()
    ridge_fill(px, LH, smooth_ridge(111, 5, 0.5, 0.12),
               lerp(LAVA_SKY, (130, 62, 44), 0.5),
               lerp(LAVA_SKY, (110, 52, 38), 0.7))
    # ember glow spots
    rng = random.Random(111)
    for _ in range(20):
        x, y = rng.randrange(LW), rng.randrange(int(LH * 0.5), LH)
        px[x, y] = (255, 120, 40, 255)
    return im

def _root_strand(px, cx, LH, w, dark, lit, rng):
    phase = rng.random() * 6.28
    amp = 3 + rng.random() * 4
    for y in range(LH):
        sway = math.sin(phase + y * (2 * math.pi / LH) * 2) * amp
        x = int(cx + sway)
        for dx in range(w):
            c = lit if dx == 0 else dark
            px[(x + dx) % LW, y] = (*c, 255)

def lava_mid():
    LH = 224
    im = canvas(LH); px = im.load()
    rng = random.Random(112)
    for i in range(7):
        cx = int(i * LW / 7 + rng.randrange(-10, 10))
        _root_strand(px, cx, LH, rng.randint(6, 10),
                     (66, 34, 26), (96, 50, 36), rng)
    # lava glow pool at the bottom
    for x in range(LW):
        gh = int(12 + 5 * math.sin(x * 0.07))
        for k in range(gh):
            y = LH - 1 - k
            c = (255, 120, 40) if k < gh // 2 else (200, 84, 34)
            px[x, y] = (*c, 255)
    return im

def lava_near():
    LH = 288
    im = canvas(LH); px = im.load()
    rng = random.Random(113)
    for i in range(4):
        cx = int(i * LW / 4 + rng.randrange(-16, 16))
        _root_strand(px, cx, LH, rng.randint(14, 20),
                     (40, 20, 16), (62, 32, 24), rng)
    for x in range(LW):
        gh = int(20 + 8 * math.sin(x * 0.05 + 1.0))
        for k in range(gh):
            y = LH - 1 - k
            c = (255, 150, 52) if k < gh // 3 else ((255, 120, 40) if k < gh * 2 // 3 else (170, 70, 30))
            px[x, y] = (*c, 255)
    return im

# ================= glass_abyss =================

GLASS_SKY = (28, 52, 64)

def _crystal(px, cx, base, h, w, dark, lit, hi, LH):
    top = base - h
    for row in range(h):
        y = base - row
        if not (0 <= y < LH):
            continue
        half = max(1, int(w * (1 - row / h)))
        for dx in range(-half, half + 1):
            c = lit if dx <= -half // 2 else dark
            px[(cx + dx) % LW, y] = (*c, 255)
    if 0 <= top < LH:
        px[cx % LW, top] = (*hi, 255)
        px[cx % LW, min(LH - 1, top + 1)] = (*hi, 255)

def glass_far():
    LH = 224
    im = canvas(LH); px = im.load()
    ridge_fill(px, LH, smooth_ridge(121, 6, 0.52, 0.1),
               lerp(GLASS_SKY, (52, 86, 100), 0.5),
               lerp(GLASS_SKY, (42, 72, 86), 0.7))
    return im

def glass_mid():
    LH = 224
    im = canvas(LH); px = im.load()
    rng = random.Random(122)
    base = int(LH * 0.82)
    ground_band(px, LH, base, (26, 50, 60), (18, 36, 44), 2)
    for i in range(8):
        cx = int(i * LW / 8 + rng.randrange(-10, 10)) % LW
        _crystal(px, cx, base + 2, rng.randint(40, 90), rng.randint(6, 12),
                 (34, 66, 78), (64, 110, 126), (200, 245, 255), LH)
    return im

def glass_near():
    LH = 288
    im = canvas(LH); px = im.load()
    rng = random.Random(123)
    base = int(LH * 0.9)
    ground_band(px, LH, base, (14, 30, 38), (8, 20, 26), 3)
    for i in range(4):
        cx = int(i * LW / 4 + rng.randrange(-18, 18)) % LW
        _crystal(px, cx, base + 6, rng.randint(130, 220), rng.randint(16, 26),
                 (12, 26, 34), (28, 54, 66), (150, 220, 235), LH)
    return im

# ================= registry =================

BIOMES = {
    "forest": {
        "far": forest_far, "mid": forest_mid, "near": forest_near,
        "fog": lambda: fog_band(80, lerp(FOREST_SKY, (255, 255, 255), 0.08), 90),
    },
    "frost_wasteland": {
        "far": frost_far, "mid": frost_mid, "near": frost_near,
        "fog": lambda: fog_band(80, lerp(FROST_SKY, (255, 255, 255), 0.3), 100),
    },
    "marsh": {
        "far": marsh_far, "mid": marsh_mid, "near": marsh_near,
        "fog": lambda: fog_band(90, lerp(MARSH_SKY, (255, 255, 255), 0.12), 120),
    },
    "ash_desert": {
        "far": desert_far, "mid": desert_mid, "near": desert_near,
        "fog": lambda: fog_band(70, lerp(DESERT_SKY, (255, 220, 160), 0.3), 80),
    },
    "ash_ruins": {
        "far": ashruins_far, "mid": ashruins_mid, "near": ashruins_near,
        "fog": lambda: fog_band(80, lerp(RUIN_SKY, (255, 200, 160), 0.12), 90),
    },
    "ash_city": {
        "far": ashruins_far, "mid": ashcity_mid, "near": ashcity_near,
        "fog": lambda: fog_band(80, lerp(RUIN_SKY, (255, 180, 140), 0.1), 100),
    },
    "mushroom_halls": {
        "far": shroom_far, "mid": shroom_mid, "near": shroom_near,
        "fog": lambda: fog_band(80, lerp(SHROOM_SKY, (168, 232, 110), 0.1), 80),
        "canopy": lambda: cave_ceiling((34, 30, 56), (168, 232, 110), 95),
    },
    "sunken_ruins": {
        "far": sunken_far, "mid": sunken_mid, "near": sunken_near,
        "fog": lambda: fog_band(90, lerp(SUNKEN_SKY, (160, 220, 230), 0.15), 110),
        "canopy": lambda: cave_ceiling((14, 34, 42), (110, 230, 215), 105),
    },
    "lava_roots": {
        "far": lava_far, "mid": lava_mid, "near": lava_near,
        "fog": lambda: fog_band(70, lerp(LAVA_SKY, (255, 150, 52), 0.2), 70),
        "canopy": lambda: cave_ceiling((40, 20, 16), (255, 120, 40), 115),
    },
    "glass_abyss": {
        "far": glass_far, "mid": glass_mid, "near": glass_near,
        "fog": lambda: fog_band(80, lerp(GLASS_SKY, (200, 245, 255), 0.15), 80),
        "canopy": lambda: cave_ceiling((10, 22, 30), (200, 245, 255), 125),
    },
}

if __name__ == "__main__":
    outdir = "/tmp/backdrops"
    for biome, layers in BIOMES.items():
        bdir = f"{outdir}/{biome}"
        os.makedirs(bdir, exist_ok=True)
        for name, fn in layers.items():
            fn().save(f"{bdir}/{name}.png")
    print("done:", len(BIOMES), "biomes")
