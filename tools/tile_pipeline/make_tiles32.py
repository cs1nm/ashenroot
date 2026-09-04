#!/usr/bin/env python3
"""32x32 tile generator for Ashen Roots (double pixel density pilot).

Why 32px: creatures are authored at 2x density (mossling 160px @ scale 0.5),
so 16px tiles are visibly coarser than mobs. 32px tiles match that density.
Engine draws tiles via draw_texture_rect stretched to TILE_SIZE, so higher
resolution files are drop-in.

Style: "B+" — contrast clustered ramps (Terraria-like read) with detail that
16px could not hold: pebbles & roots in dirt, individual grass blades, shaded
ore crystals, plank grain with nails, leaf clumps with sky holes.
"""
import math, random, colorsys
from PIL import Image

T = 32

def ramp(base, steps=6, spread=0.5, sat=1.12):
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

# ---------------- dirt: clustered soil + pebbles + thin roots ----------------

def dirt(seed, base, detail_seed=None):
    """seed drives the base clump field (SHARED across variants so tiles knit
    together); detail_seed drives pebbles/rootlets (varies per variant)."""
    if detail_seed is None:
        detail_seed = seed
    R = ramp(base)
    # base field is deliberately LOW-contrast and shapeless: a repeating
    # memorable silhouette across tiles reads as wallpaper. Variation comes
    # from per-variant details instead.
    n1 = value_noise(seed, 3)
    n2 = value_noise(seed + 7, 6)
    im = Image.new("RGB", (T, T))
    px = im.load()
    def v(x, y):
        return n1(x, y) * 0.5 + n2(x, y) * 0.5
    for y in range(T):
        for x in range(T):
            val = v(x, y)
            idx = 2 if val < 0.62 else 3   # two quiet midtones only
            px[x, y] = R[clamp_idx(idx)]
    rng = random.Random(detail_seed + 3)
    M = 3  # keep variant details away from tile borders
    for _ in range(6):  # pebbles 2x2 with lit top
        cx, cy = rng.randrange(M, T - M - 1), rng.randrange(M, T - M - 1)
        tone = rng.choice([2, 3])
        for dx in range(2):
            px[cx + dx, cy] = R[tone + 1]
            px[cx + dx, cy + 1] = R[tone - 1]
    for _ in range(5):  # small dark clods (variant-driven, do the shaping)
        cx, cy = rng.randrange(M, T - M - 2), rng.randrange(M, T - M - 2)
        w, h = rng.randint(2, 4), rng.randint(1, 3)
        for dx in range(w):
            for dy in range(h):
                if rng.random() < 0.75:
                    px[cx + dx, cy + dy] = R[1]
    for _ in range(3):  # soft winding rootlets (one tone down, not black)
        x, y = rng.randrange(M, T - M), rng.randrange(M, T - M - 7)
        for _ in range(rng.randint(4, 7)):
            if M <= x < T - M and y < T - M:
                cur = px[x, y]
                px[x, y] = tuple(int(c * 0.8) for c in cur)
            x += rng.choice([-1, 0, 1])
            y += 1
    return im

# ---------------- grass: soil base + layered blades ----------------

def grass(seed, soil, green, detail_seed=None):
    if detail_seed is None:
        detail_seed = seed
    im = dirt(seed, soil, detail_seed)
    px = im.load()
    G = ramp(green)
    rng = random.Random(detail_seed + 5)
    n = value_noise(seed + 11, 5)  # turf depth SHARED so edges line up
    depth = [6 + int(n(x, 0) * 5) for x in range(T)]
    # body of turf
    for x in range(T):
        for y in range(depth[x]):
            k = y / max(1, depth[x] - 1)
            if k > 0.75 and rng.random() < k:  # ragged soil boundary
                continue
            tone = 3 if k < 0.35 else (2 if k < 0.7 else 1)
            px[x, y] = G[tone]
    # lit tips along top
    for x in range(T):
        if rng.random() < 0.5:
            px[x, 0] = G[5]
        elif rng.random() < 0.5:
            px[x, 0] = G[4]
    # hanging rootlets under turf
    for _ in range(5):
        x = rng.randrange(T)
        for i in range(rng.randint(1, 3)):
            px[x, min(T - 1, depth[x] + i)] = G[1]
    return im

# ---------------- stone: big clusters + cracks + chips ----------------

def stone(seed, base, detail_seed=None):
    if detail_seed is None:
        detail_seed = seed
    R = ramp(base, spread=0.44)
    n1 = value_noise(seed, 3)
    n2 = value_noise(seed + 7, 5)
    im = Image.new("RGB", (T, T))
    px = im.load()
    def v(x, y):
        return n1(x, y) * 0.6 + n2(x, y) * 0.4
    for y in range(T):
        for x in range(T):
            val = v(x, y)
            idx = 2 if val < 0.58 else 3   # quiet two-tone rock mass
            px[x, y] = R[clamp_idx(idx)]
    rng = random.Random(detail_seed + 3)
    M = 3
    for _ in range(3):  # variant cracks: short jagged lines, lit edge above
        x = rng.randrange(M, T - M)
        y = rng.randrange(M, T - M - 6)
        for _ in range(rng.randint(4, 7)):
            if M <= x < T - M and y < T - M:
                px[x, y] = R[0]
                if y > 0:
                    px[x, y - 1] = R[4]
            x += rng.choice([-1, 0, 0, 1])
            y += 1
    for _ in range(4):  # shaded facets (dark patch with lit top edge)
        cx, cy = rng.randrange(M, T - M - 3), rng.randrange(M, T - M - 2)
        w, h = rng.randint(3, 5), rng.randint(2, 3)
        for dx in range(w):
            for dy in range(h):
                if rng.random() < 0.8:
                    px[cx + dx, cy + dy] = R[1]
            px[cx + dx, cy - 1] = R[4]
    for _ in range(3):  # sparse chips
        x, y = rng.randrange(M, T - M), rng.randrange(M, T - M - 1)
        px[x, y] = R[5]
        px[x, y + 1] = R[1]
    return im

# ---------------- ore: shaded crystal clusters in stone ----------------

def ore(seed, stone_base, dark, lit, hi, detail_seed=None):
    if detail_seed is None:
        detail_seed = seed
    im = stone(seed, stone_base, detail_seed)
    px = im.load()
    rng = random.Random(detail_seed + 9)
    shadow = tuple(int(c * 0.45) for c in dark)
    for ci in range(4):
        cx, cy = rng.randrange(3, T - 4), rng.randrange(3, T - 4)
        blobs = rng.randint(3, 5)
        for _ in range(blobs):
            bx, by = cx + rng.randint(-2, 2), cy + rng.randint(-2, 2)
            # 2x2 crystal: lit top-left, dark bottom-right, highlight pixel
            px[bx % T, by % T] = lit
            px[(bx + 1) % T, by % T] = lit
            px[bx % T, (by + 1) % T] = dark
            px[(bx + 1) % T, (by + 1) % T] = dark
        # dark socket outline under the cluster
        for dx in range(-1, 3):
            px[(cx + dx) % T, (cy + 2) % T] = shadow
        px[cx % T, cy % T] = hi
    return im

# ---------------- wood planks: grain waves, seams, nails ----------------

def wood(seed, base, detail_seed=None):
    if detail_seed is None:
        detail_seed = seed
    R = ramp(base)
    rng = random.Random(detail_seed)
    n = value_noise(seed, 5)  # grain field shared across variants
    im = Image.new("RGB", (T, T))
    px = im.load()
    PW = 8  # plank width -> 4 planks
    plank_tone = [rng.choice([1, 2, 2, 3]) for _ in range(T // PW)]
    for x in range(T):
        p = x // PW
        for y in range(T):
            v = n(x, y)
            wave = math.sin(y * 0.9 + v * 5.0 + p * 2.0) * 0.5 + 0.5
            idx = plank_tone[p] + (1 if wave > 0.62 else (-1 if wave < 0.18 else 0))
            if x % PW == 0:
                idx = 0                       # seam
            elif x % PW == 1:
                idx = min(5, idx + 1)         # lit edge next to seam
            if y == 0:
                idx = min(5, idx + 1)
            elif y == T - 1:
                idx = max(0, idx - 1)
            px[x, y] = R[clamp_idx(idx)]
    for p in range(T // PW):  # knots + nails per plank
        kx, ky = p * PW + rng.randrange(3, 7), rng.randrange(6, T - 6)
        px[kx, ky] = R[0]
        px[kx - 1, ky] = R[0]
        px[kx, ky - 1] = R[4]
        nx = p * PW + PW // 2
        px[nx, 2] = R[5]
        px[nx, 3] = R[0]
        px[nx, T - 3] = R[5]
        px[nx, T - 2] = R[0]
    return im

# ---------------- leaves: clumps, sky holes, lit crowns ----------------

def leaves(seed, base, glow, hole=(31, 38, 52), detail_seed=None):
    if detail_seed is None:
        detail_seed = seed
    R = ramp(base)
    rng = random.Random(detail_seed)
    im = Image.new("RGB", (T, T), R[1])
    px = im.load()
    n = value_noise(seed + 4, 4)
    for y in range(T):
        for x in range(T):
            if n(x, y) < 0.3:
                px[x, y] = R[0]
    # leaf clumps: rounded blobs, lit on top, dark under
    for _ in range(14):
        cx, cy, r = rng.randrange(T), rng.randrange(T), rng.randint(2, 4)
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if dx * dx + dy * dy <= r * r:
                    x, yy = (cx + dx) % T, (cy + dy) % T
                    if dy < -r // 2:
                        px[x, yy] = R[4]
                    elif dy < 0:
                        px[x, yy] = R[3]
                    else:
                        px[x, yy] = R[2]
        px[cx % T, (cy - r) % T] = R[5]
    # tiny sky holes
    for _ in range(4):
        x, y = rng.randrange(T), rng.randrange(T)
        px[x, y] = hole
        px[(x + 1) % T, y] = hole
    # glow accents (biome accent color)
    for _ in range(5):
        px[rng.randrange(T), rng.randrange(T)] = glow
    return im

# ---------------- moss: mossy stone hybrid ----------------

def moss(seed, base, stone_base, detail_seed=None):
    """Moss drapes over stone from the top and drips down — directional,
    like turf on dirt, not random blotches."""
    if detail_seed is None:
        detail_seed = seed
    im = stone(seed + 20, stone_base, detail_seed)
    px = im.load()
    G = ramp(base)
    rng = random.Random(detail_seed + 8)
    n = value_noise(seed + 6, 5)  # drip depth SHARED so columns line up
    # top blanket with dripping tongues
    depth = [7 + int(n(x, 0) * 8) for x in range(T)]
    for x in range(T):
        for y in range(depth[x]):
            k = y / max(1, depth[x] - 1)
            if k > 0.7 and rng.random() < k - 0.25:  # ragged tongue tip
                continue
            tone = 3 if k < 0.3 else (2 if k < 0.65 else 1)
            px[x, y] = G[tone]
        if rng.random() < 0.6:  # lit crest along the very top
            px[x, 0] = G[4]
    # a few hanging strands below the tongues
    for _ in range(4):
        x = rng.randrange(T)
        for i in range(rng.randint(1, 3)):
            yy = depth[x] + i
            if yy < T - 2:
                px[x, yy] = G[1]
    # sparse cushions clinging lower on the rock (kept off side borders)
    for _ in range(3):
        cx, cy = rng.randrange(3, T - 4), rng.randrange(T // 2, T - 5)
        for dx in range(-1, 3):
            px[cx + dx, cy] = G[2]
            if 0 <= dx <= 1:
                px[cx + dx, cy - 1] = G[3]
    return im

# ---------------- palettes ----------------

DIRT = (124, 88, 58)
GRASS_GREEN = (88, 154, 74)
STONE = (100, 104, 112)
WOOD = (128, 92, 56)
LEAVES = (62, 106, 56)
MOSS = (88, 126, 74)
COPPER_D, COPPER_L, COPPER_H = (148, 88, 44), (200, 130, 66), (240, 182, 116)
IRON_D, IRON_L, IRON_H = (120, 128, 142), (190, 198, 210), (234, 240, 248)
LEAF_GLOW = (132, 196, 98)

BASE_SEED = 40  # ONE shared base field per material -> variants knit together

def build(variant=0):
    """variant only reshuffles small interior details (pebbles, chips,
    crystals, knots); the underlying clump/crack field is identical, so any
    mix of variants tiles seamlessly."""
    s = BASE_SEED
    d = BASE_SEED + variant * 100
    return {
        "dirt":   dirt(s + 1, DIRT, d + 1),
        "grass":  grass(s + 2, DIRT, GRASS_GREEN, d + 2),
        "stone":  stone(s + 3, STONE, d + 3),
        "copper": ore(s + 4, STONE, COPPER_D, COPPER_L, COPPER_H, d + 4),
        "iron":   ore(s + 5, STONE, IRON_D, IRON_L, IRON_H, d + 5),
        "wood":   wood(s + 6, WOOD, d + 6),
        "leaves": leaves(s + 7, LEAVES, LEAF_GLOW, detail_seed=d + 7),
        "moss":   moss(s + 8, MOSS, STONE, d + 8),
    }

if __name__ == "__main__":
    # base + 3 variants, mirroring the game's dirt.png / dirt_1..3.png layout
    for vi in range(4):
        suffix = "" if vi == 0 else f"_{vi}"
        for name, im in build(vi).items():
            im.save(f"/tmp/hd_{name}{suffix}.png")
    print("done")
