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
    base = (112, 80, 52)
    R = ramp(base)
    for variant in range(4):
        rng = random.Random(9100 + variant * 37)
        n1 = value_noise(2101 + variant * 17, 3)
        n2 = value_noise(2108 + variant * 23, 6)
        im = Image.new("RGB", (T, T))
        px = im.load()
        for y in range(T):
            for x in range(T):
                v = n1(x, y) * 0.65 + n2(x, y) * 0.35
                px[x, y] = R[clamp_idx(int(v * 5.99))]
        for _ in range(10 + variant * 2):
            sx, sy = rng.randrange(T), rng.randrange(T)
            c = R[0] if rng.random() < 0.5 else R[5]
            for dx in range(2):
                for dy in range(1 + (sx + dx) % 2):
                    px[(sx + dx) % T, (sy + dy) % T] = c
        for _ in range(3 + variant):
            rx, ry = rng.randrange(T), rng.randrange(T)
            for step in range(4 + rng.randrange(4)):
                px[(rx + step) % T, (ry + step // 2) % T] = R[1]
        # jungle humus: moss patches and tiny sprouts in the earth
        humus = [(74, 118, 62), (58, 100, 52)]
        for _ in range(4 + variant):
            mx2, my2 = rng.randrange(T), rng.randrange(T)
            for dx in range(rng.randrange(2, 5)):
                for dy in range(rng.randrange(1, 3)):
                    if rng.random() < 0.8:
                        px[(mx2 + dx) % T, (my2 + dy) % T] = humus[rng.randrange(2)]
        im.save(f"{OUT}void_soil.png" if variant == 0 else f"{OUT}void_soil_{variant}.png")


# ---------------- void stone: mossy fractured rock ----------------

def stone_set():
    base = (78, 94, 74)
    R = ramp(base, spread=0.55)
    moss = ramp((95, 142, 77), steps=4, spread=0.4)
    n1 = value_noise(3301, 4)
    for variant in range(4):
        rng = random.Random(7700 + variant * 41)
        im = Image.new("RGB", (T, T))
        px = im.load()
        for y in range(T):
            for x in range(T):
                v = n1(x, y)
                px[x, y] = R[clamp_idx(int(v * 5.99))]
        # angular stone patches
        for _ in range(5):
            sx, sy = rng.randrange(T), rng.randrange(T)
            w, h2 = rng.randrange(4, 9), rng.randrange(3, 7)
            tone = R[clamp_idx(rng.randrange(1, 5))]
            for dx in range(w):
                for dy in range(h2):
                    if rng.random() < 0.82:
                        px[(sx + dx) % T, (sy + dy) % T] = tone
        # moss clusters hugging edges
        for _ in range(4 + variant):
            sx, sy = rng.randrange(T), rng.randrange(T)
            for dx in range(rng.randrange(2, 5)):
                for dy in range(rng.randrange(1, 3)):
                    if rng.random() < 0.8:
                        px[(sx + dx) % T, (sy + dy) % T] = moss[clamp_idx(rng.randrange(0, 4), 4)]
        # cracks
        for _ in range(2 + variant % 2):
            cx, cy = rng.randrange(T), rng.randrange(T)
            for step in range(5 + rng.randrange(5)):
                px[(cx + step) % T, (cy + (step * rng.choice([1, 2]))) % T] = R[0]
        im.save(f"{OUT}void_stone.png" if variant == 0 else f"{OUT}void_stone_{variant}.png")


# ---------------- bloom stalk: giant stem, cross gradient, bark edges ----------------

def stalk_set():
    bark = (28, 58, 40)
    ramp_cols = [(52, 100, 62), (66, 124, 76), (82, 148, 90), (98, 168, 105), (110, 182, 116)]
    node = (44, 86, 54)
    for variant in range(2):
        rng = random.Random(4500 + variant * 13)
        jitter = [rng.random() for _ in range(T)]
        im = Image.new("RGB", (T, T))
        px = im.load()
        for x in range(T):
            if x <= 1 or x >= T - 2:
                for y in range(T):
                    px[x, y] = bark
                continue
            d = abs(x - 15.5) / 15.5
            base = int((1.0 - d) * (len(ramp_cols) - 1) + 0.5)
            for y in range(T):
                tone = ramp_cols[max(0, min(len(ramp_cols) - 1, base))]
                # sparse darker striations along the fiber direction
                if (x * 7 + y * 5 + int(jitter[x] * 11)) % 13 == 0:
                    tone = ramp_cols[max(0, base - 1)]
                px[x, y] = tone
        im.save(f"{OUT}flora_stalk.png" if variant == 0 else f"{OUT}flora_stalk_{variant}.png")


# ---------------- canopy: leaf clumps with transparent gaps ----------------

def canopy_set():
    dark = (40, 96, 58)
    mid = (64, 134, 76)
    lite = (110, 190, 98)
    deep = (28, 72, 44)
    for variant in range(3):
        rng = random.Random(6200 + variant * 29)
        im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
        px = im.load()

        def blob(cx, cy, r, tone):
            for dy in range(-r, r + 1):
                for dx in range(-r, r + 1):
                    if dx * dx + dy * dy <= r * r * (0.72 + rng.random() * 0.35):
                        px[(cx + dx) % T, (cy + dy) % T] = tone + (255,)

        # solid foliage mass first: crowns of adjacent tiles must merge
        for y in range(T):
            for x in range(T):
                px[x, y] = mid + (255,)
        for _ in range(5):
            blob(rng.randrange(T), rng.randrange(T), rng.randrange(3, 6), dark)
        for _ in range(4):
            blob(rng.randrange(T), rng.randrange(T), rng.randrange(2, 4), deep)
        for _ in range(5):
            blob(rng.randrange(T), rng.randrange(T), rng.randrange(2, 4), lite)
        # small notches only near tile borders keep silhouettes organic
        # while the interior stays continuous with neighbouring tiles
        for _ in range(14):
            ex, ey = rng.choice([0, 1, T - 2, T - 1]), rng.randrange(T)
            if rng.random() < 0.5:
                ex, ey = rng.randrange(T), rng.choice([0, 1, T - 2, T - 1])
            for dx in range(rng.randrange(1, 4)):
                for dy in range(rng.randrange(1, 3)):
                    px[(ex + dx) % T, (ey + dy) % T] = (0, 0, 0, 0)
        im.save(f"{OUT}flora_canopy.png" if variant == 0 else f"{OUT}flora_canopy_{variant}.png")


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
