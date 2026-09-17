#!/usr/bin/env python3
"""32px tile textures for Dimension I (Chapter V overgrowth).

Same "B+" philosophy as make_tiles32.py: shared low-contrast base field so
variants knit together, per-variant detail on top, no hard tile borders.
RGBA tiles (flora/crystal/altar/portal) carry real silhouettes with
transparent gaps so the dimension stops reading as bordered cubes.
"""
import random, colorsys
from PIL import Image

T = 32
OUT = "assets/textures/tiles/"


def ramp(base, steps=6, spread=0.5, sat=1.1):
    r, g, b = [c / 255.0 for c in base]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    s = min(1.0, s * sat)
    out = []
    for i in range(steps):
        k = 1.0 - spread + (2 * spread) * i / (steps - 1)
        rr, gg, bb = colorsys.hls_to_rgb(h, max(0.0, min(1.0, l * k)), s)
        out.append((int(rr * 255), int(gg * 255), int(bb * 255)))
    return out


def value_noise(seed, scale=4):
    rng = random.Random(seed)
    grid = [[rng.random() for _ in range(scale)] for _ in range(scale)]
    def sample(x, y):
        fx, fy = (x / T) * scale, (y / T) * scale
        x0, y0 = int(fx) % scale, int(fy) % scale
        x1, y1 = (x0 + 1) % scale, (y0 + 1) % scale
        tx, ty = fx - int(fx), fy - int(fy)
        tx = tx * tx * (3 - 2 * tx)
        ty = ty * ty * (3 - 2 * ty)
        a = grid[y0][x0] * (1 - tx) + grid[y0][x1] * tx
        b = grid[y1][x0] * (1 - tx) + grid[y1][x1] * tx
        return a * (1 - ty) + b * ty
    return sample


def clamp_idx(i, n=6):
    return max(0, min(n - 1, i))


# ---------------- void soil: clustered earth + pebbles + rootlets ----------------

def soil_set():
    # Dimension ground = the overworld forest ground, literally.
    import shutil
    for suffix in ["", "_1", "_2", "_3"]:
        shutil.copyfile(f"assets/textures/tiles/dirt{suffix}.png", f"{OUT}void_soil{suffix}.png")


# ---------------- void stone: mossy fractured rock ----------------

def stone_set():
    import shutil
    for suffix in ["", "_1", "_2", "_3"]:
        shutil.copyfile(f"assets/textures/tiles/stone{suffix}.png", f"{OUT}void_stone{suffix}.png")


# ---------------- bloom stalk: giant stem, cross gradient, bark edges ----------------

def stalk_set():
    import shutil
    for suffix in ["", "_1", "_2", "_3"]:
        shutil.copyfile(f"assets/textures/tiles/wood{suffix}.png", f"{OUT}flora_stalk{suffix}.png")


# ---------------- canopy: leaf clumps with transparent gaps ----------------

def canopy_set():
    import shutil
    for suffix in ["", "_1", "_2", "_3"]:
        shutil.copyfile(f"assets/textures/tiles/leaves{suffix}.png", f"{OUT}flora_canopy{suffix}.png")


# ---------------- vine: transparent bg, stem + leaf pairs ----------------

def vine():
    rng = random.Random(8317)
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    px = im.load()
    stem = (74, 138, 82, 255)
    stem_d = (48, 100, 58, 255)
    leaf_a = (96, 172, 96, 255)
    leaf_b = (58, 118, 66, 255)

    def leaf(cx, cy, w, h, tone):
        for dx in range(w):
            for dy in range(h):
                if dx + dy < w + h - 1:
                    px[(cx + dx) % T, (cy + dy) % T] = tone

    x = 13
    for y in range(T):
        if rng.random() < 0.35:
            x += rng.choice([-1, 1])
        x = max(9, min(20, x))
        # 3px rope: light core, dark edges
        px[x, y] = stem
        px[x + 1, y] = stem
        px[x - 1, y] = stem_d
        px[x + 2, y] = stem_d
        # leaf pairs every 5px, alternating sides, wrapping vertically
        if y % 4 == 1:
            leaf(x - 6, y, 5, 2, leaf_a if (y // 4) % 2 == 0 else leaf_b)
            leaf(x + 3, y + 1, 5, 2, leaf_b if (y // 4) % 2 == 0 else leaf_a)
    im.save(f"{OUT}flora_vine.png")


# ---------------- glow crystal: transparent cluster ----------------

def crystal():
    rng = random.Random(991)
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    px = im.load()
    core = (217, 255, 252, 255)
    body = (127, 227, 224, 235)
    edge = (58, 148, 148, 220)

    def shard(cx, base_y, h, w):
        for i in range(h):
            y = base_y - i
            half = max(0, int(w * (1.0 - i / h) * 0.9) + 1)
            for dx in range(-half, half + 1):
                tone = body
                if i > h - 3:
                    tone = core
                if abs(dx) == half:
                    tone = edge
                if 0 <= y < T and 0 <= cx + dx < T:
                    px[cx + dx, y] = tone

    shard(8, 30, 16, 4)
    shard(17, 31, 24, 5)
    shard(25, 30, 12, 3)
    # tiny sparkles
    for _ in range(6):
        sx, sy = rng.randrange(4, 28), rng.randrange(6, 28)
        if px[sx, sy][3] > 0:
            px[sx, sy] = core
    im.save(f"{OUT}glow_crystal.png")


# ---------------- mana altar: pedestal + floating crystal (RGBA) ----------------

def altar():
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    px = im.load()
    stone_d = (40, 52, 46, 255)
    stone = (86, 104, 92, 255)
    stone_l = (128, 148, 132, 255)
    stone_xl = (168, 186, 170, 255)
    teal = (127, 227, 224, 255)
    teal_l = (225, 255, 253, 255)
    teal_e = (70, 170, 168, 235)
    # floating crystal (larger, 7px)
    for dy in range(7):
        for dx in range(7):
            cx, cy = 12 + dx, 1 + dy
            edge = dx in (0, 6) or dy in (0, 6)
            inner = 2 <= dx <= 4 and 2 <= dy <= 4
            px[cx, cy] = teal_l if inner else (teal_e if edge else teal)
    # pedestal: wide base, column, capital
    for dx in range(1, 31):
        px[dx, 29] = stone_d
        px[dx, 30] = stone_d
        if 3 <= dx <= 9 or 22 <= dx <= 28:
            px[dx, 28] = stone
    for dx in range(3, 29):
        px[dx, 26] = stone
        px[dx, 27] = stone_d
    for dy in range(17, 26):
        for dx in range(7, 25):
            if dx in (7, 8, 23, 24):
                px[dx, dy] = stone_l
            else:
                px[dx, dy] = stone
    for dx in range(9, 23):
        px[dx, 15] = stone_xl
        px[dx, 16] = stone_l
    # carved teal runes on the column
    for rx in (11, 15, 19):
        px[rx, 20] = teal_l
        px[rx, 21] = teal
        px[rx, 22] = teal_e
    im.save(f"{OUT}mana_altar.png")


# ---------------- dimension portal: dark slab, violet rim (RGBA) ----------------

def portal():
    rng = random.Random(3131)
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    px = im.load()
    void_bg = (16, 12, 24, 255)
    rim = (138, 92, 255, 255)
    rim_d = (86, 54, 168, 255)
    spark = (201, 178, 255, 255)
    for y in range(2, 30):
        for x in range(4, 28):
            px[x, y] = void_bg
    # rim
    for x in range(4, 28):
        px[x, 2] = rim
        px[x, 29] = rim_d
    for y in range(2, 30):
        px[4, y] = rim
        px[27, y] = rim_d
    # inner swirl sparks
    for _ in range(26):
        sx, sy = rng.randrange(7, 24), rng.randrange(5, 27)
        px[sx, sy] = spark if rng.random() < 0.4 else rim_d
    im.save(f"{OUT}dim_portal.png")


soil_set()
stone_set()
stalk_set()
canopy_set()
vine()
crystal()
altar()
portal()
print("dimension tiles generated")


# ---------------- dimension backdrops: painterly jungle silhouettes ----------------

def _silhouette_strip(width, height, base_y, amp, seed, tone_top, tone_bot, emergent):
    rng = random.Random(seed)
    import math
    im = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    px = im.load()
    oct1 = [rng.random() for _ in range(16)]
    oct2 = [rng.random() for _ in range(24)]

    def noise1d(t, grid):
        n = len(grid)
        ft = t * n
        i0 = int(ft) % n
        i1 = (i0 + 1) % n
        f = ft - int(ft)
        f = f * f * (3 - 2 * f)
        return grid[i0] * (1 - f) + grid[i1] * f

    def top_at(x):
        y = base_y - amp * (0.35 + 0.65 * noise1d(x / width * 1.0, oct1)) - 14.0 * noise1d(x / width * 2.3, oct2)
        # emergent giant trees: wide rounded humps above the treeline
        for (cx, cw, ch) in emergent:
            dx = min(abs(x - cx), width - abs(x - cx))
            if dx < cw:
                k = 1.0 - (dx / cw) ** 2
                y = min(y, base_y - ch * k)
        return y

    for x in range(width):
        yt = top_at(x)
        for y in range(height):
            if y >= yt:
                k = (y - yt) / max(1.0, height - yt)
                tone = tuple(int(tone_top[i] + (tone_bot[i] - tone_top[i]) * min(1.0, k * 1.6)) for i in range(3))
                px[x, y] = tone + (255,)
    return im


def backdrops():
    W, H = 512, 224
    far = _silhouette_strip(W, H, 150, 40, 771, (34, 74, 52), (22, 50, 36),
                            [(70, 42, 46), (205, 52, 40), (390, 46, 52)])
    far.save(f"{OUT}../backdrops/dimension_1/far.png")
    mid = _silhouette_strip(W, H, 120, 52, 991, (24, 56, 40), (13, 32, 23),
                            [(140, 50, 56), (330, 44, 48), (470, 40, 44)])
    mid.save(f"{OUT}../backdrops/dimension_1/mid.png")
    # fog: soft translucent haze band
    rng = random.Random(555)
    fog = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fpx = fog.load()
    for y in range(60, 190):
        for x in range(W):
            a = int(38 * (1.0 - abs((y - 120) / 70.0)) * (0.7 + 0.3 * rng.random()))
            if a > 0:
                fpx[x, y] = (150, 190, 160, a)
    fog.save(f"{OUT}../backdrops/dimension_1/fog.png")
