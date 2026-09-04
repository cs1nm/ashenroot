#!/usr/bin/env python3
"""Painterly parallax backdrops for Ashen Roots biomes.

Realism recipe (vs the old flat silhouettes):
- atmospheric perspective: each further layer is tinted toward the sky
  color (hazy, desaturated); the near layer is dark and saturated
- volume: crowns are shaded spheres (sky-lit top, dark core), trunks have
  a lit edge and bark cracks
- fog bands between layers sell the depth
- all layers tile horizontally at 512px

Output layers per biome: far / fog / mid / near (RGBA 512x224/288).
"""
import math, random, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageFilter

LW = 512

def lerp(a, b, k):
    return tuple(int(a[i] + (b[i] - a[i]) * k) for i in range(3))

def smooth_ridge(seed, segments=8, base=0.5, amp=0.3):
    rng = random.Random(seed)
    pts = [base + (rng.random() - 0.5) * 2 * amp for _ in range(segments)]
    def f(x):
        t = (x / LW) * segments
        i0 = int(t) % segments
        i1 = (i0 + 1) % segments
        k = t - int(t)
        k = k * k * (3 - 2 * k)
        return pts[i0] * (1 - k) + pts[i1] * k
    return f

def fog_band(height, color, peak_alpha=110):
    """Soft horizontal fog: fades in from the top, solid toward the bottom."""
    im = Image.new("RGBA", (LW, height), (0, 0, 0, 0))
    px = im.load()
    for y in range(height):
        k = y / (height - 1)
        a = int(peak_alpha * min(1.0, k * 1.8))
        for x in range(LW):
            px[x, y] = (*color, a)
    return im

# ---------------- forest ----------------

FOREST_SKY = (46, 74, 68)        # hazy teal the far layer sinks into

def _shade_crown(px, cx, cy, r, core, lit, rim, LH, rng, blobs=5):
    """Crown = irregular cluster of shaded lobes: wide and flat-bottomed
    like a real broadleaf, rim-lit top, dark shadowed underside."""
    centers = [(cx, cy, r)]
    for _ in range(blobs - 1):
        ang = rng.random() * 6.28
        rr = int(r * (0.45 + rng.random() * 0.4))
        # spread lobes mostly sideways (crowns grow wide, not tall)
        centers.append((cx + int(math.cos(ang) * r * 1.05),
                        cy + int(math.sin(ang) * r * 0.35) - int(r * 0.1),
                        rr))
    # lumpy underside: each column has its own bottom limit so the crown
    # reads as foliage lobes, not a flat plate
    bottom_base = cy + int(r * 0.7)
    bot = {}
    for (bx, by, br) in centers:
        for dx in range(-br, br + 1):
            x = (bx + dx) % LW
            lump = int(3 * math.sin(x * 0.55 + bx) + 2 * math.sin(x * 0.23 + by))
            cur = bottom_base + lump
            bot[x] = max(bot.get(x, 0), cur)
    for (bx, by, br) in centers:
        for dx in range(-br, br + 1):
            for dy in range(-br, br + 1):
                d2 = dx * dx + dy * dy
                if d2 > br * br:
                    continue
                x = (bx + dx) % LW
                y = by + dy
                if y > bot.get(x, bottom_base):
                    continue
                # ragged silhouette edge
                if d2 > (br - 1) * (br - 1) and rng.random() < 0.35:
                    continue
                if not (0 <= y < LH):
                    continue
                # light from above
                lk = -dy / max(1.0, br)
                if lk > 0.6:
                    px[x, y] = (*rim, 255)
                elif lk > 0.0:
                    px[x, y] = (*lit, 255)
                else:
                    px[x, y] = (*core, 255)
    # shadowed underside: darken the last two rows of each column
    for x, yb in bot.items():
        for yy in (yb, yb - 1):
            if 0 <= yy < LH and px[x, yy][3] > 0:
                px[x, yy] = (*core, 255)
    # leaf speckles on the lit top
    for _ in range(r * 2):
        ang = rng.random() * 3.14 - 2.2
        rr = r * (0.7 + rng.random() * 0.5)
        x = (cx + int(math.cos(ang) * rr * 1.1)) % LW
        y = cy + int(math.sin(ang) * rr * 0.6)
        if 0 <= y < min(bot.get(x, bottom_base), LH):
            px[x, y] = (*rim, 255)

def forest_far():
    """Hazy ridge of canopy, almost dissolved into the sky."""
    LH = 224
    im = Image.new("RGBA", (LW, LH), (0, 0, 0, 0))
    px = im.load()
    ridge = smooth_ridge(11, 6, 0.40, 0.12)
    ridge2 = smooth_ridge(17, 9, 0.52, 0.10)
    far_top = lerp(FOREST_SKY, (30, 56, 52), 0.55)
    far_bot = lerp(FOREST_SKY, (26, 50, 47), 0.8)
    for x in range(LW):
        t1 = int(ridge(x) * LH)
        # lumpy canopy edge
        t1 += int(4 * math.sin(x * 0.11) + 3 * math.sin(x * 0.043 + 1.7))
        for y in range(max(0, t1), LH):
            k = (y - t1) / max(1, LH - t1)
            px[x, y] = (*lerp(far_top, far_bot, k), 255)
        # second, slightly darker ridge line inside
        t2 = int(ridge2(x) * LH)
        t2 += int(3 * math.sin(x * 0.09 + 3.1))
        for y in range(max(0, t2), LH):
            px[x, y] = (*far_bot, 255)
    return im

def forest_mid():
    """Mid trees with shaded crowns and lit trunks, plus canopy overhang."""
    LH = 224
    im = Image.new("RGBA", (LW, LH), (0, 0, 0, 0))
    px = im.load()
    rng = random.Random(23)
    core = (20, 44, 38)
    lit = (34, 66, 52)
    rim = (52, 92, 66)
    trunk = (26, 34, 30)
    trunk_lit = (44, 56, 46)
    base = int(LH * 0.78)
    # ground band with soft top
    for x in range(LW):
        wob = int(2 * math.sin(x * 0.05))
        for y in range(base + wob, LH):
            k = (y - base) / max(1, LH - base)
            px[x, y] = (*lerp(lit, core, min(1.0, k * 1.6)), 255)
    # trees
    for i in range(7):
        cx = int(i * LW / 7 + rng.randrange(-16, 16)) % LW
        h = rng.randint(84, 128)
        ty = base - h
        w = rng.randint(6, 9)
        # trunk with lit left edge
        for y in range(ty + int(h * 0.25), base + 4):
            sway = int(2 * math.sin(y * 0.03 + i * 2.0))
            for dx in range(w):
                x = (cx + dx + sway) % LW
                px[x, y] = (*trunk_lit, 255) if dx == 0 else (*trunk, 255)
        # crown cluster
        _shade_crown(px, cx + w // 2, ty + int(h * 0.22),
                     rng.randint(20, 27), core, lit, rim, LH, rng, 6)
    # canopy overhang across the top (we are IN the forest)
    for x in range(LW):
        depth = int(26 + 12 * math.sin(x * 0.035) + 8 * math.sin(x * 0.013 + 2.0))
        for y in range(depth):
            k = y / max(1, depth)
            px[x, y] = (*lerp(core, lit, k * 0.4), 255)
    rngc = random.Random(5)
    for _ in range(90):  # dangling leaf clumps on the overhang edge
        x = rngc.randrange(LW)
        depth = int(26 + 12 * math.sin(x * 0.035) + 8 * math.sin(x * 0.013 + 2.0))
        for k in range(rngc.randint(2, 6)):
            px[x, min(223, depth + k)] = (*core, 255)
    return im

def forest_near():
    """Foreground: two massive trunks with bark texture and rim light,
    dark undergrowth line with ferns."""
    LH = 288
    im = Image.new("RGBA", (LW, LH), (0, 0, 0, 0))
    px = im.load()
    rng = random.Random(37)
    bark = (16, 22, 20)
    bark_mid = (24, 32, 28)
    bark_lit = (40, 54, 44)
    green_dark = (12, 26, 22)
    green_mid = (20, 40, 32)
    base = int(LH * 0.9)
    # undergrowth band
    for x in range(LW):
        wob = int(4 * math.sin(x * 0.03) + 2 * math.sin(x * 0.09 + 1.0))
        for y in range(base + wob, LH):
            px[x, y] = (*green_dark, 255)
    # ferns / tall grass silhouettes
    for i in range(38):
        fx = rng.randrange(LW)
        fh = rng.randint(8, 22)
        lean = rng.choice([-1, 1]) * rng.random() * 0.6
        for k in range(fh):
            x = (fx + int(k * lean)) % LW
            y = base - k + int(4 * math.sin(fx * 0.03))
            if 0 <= y < LH:
                c = green_mid if k > fh * 0.6 else green_dark
                px[x, y] = (*c, 255)
    # two big trunks
    for i, cx in enumerate((int(LW * 0.16), int(LW * 0.62))):
        w = 26 + i * 6
        for y in range(LH):
            sway = int(3 * math.sin(y * 0.02 + i * 2.2))
            for dx in range(w):
                x = (cx + dx + sway) % LW
                # rim light on the left edge, core dark
                if dx <= 1:
                    c = bark_lit
                elif dx <= 3:
                    c = bark_mid
                else:
                    c = bark
                px[x, y] = (*c, 255)
        # bark cracks: vertical dark strokes
        for _ in range(26):
            bx = cx + rng.randrange(4, w - 2)
            by = rng.randrange(LH - 30)
            ln = rng.randint(8, 26)
            for k in range(ln):
                x = (bx + int(1.5 * math.sin(k * 0.4))) % LW
                y = by + k
                if y < LH:
                    px[x, y] = (10, 14, 13, 255)
        # branch stub with leaf clump
        by = rng.randint(60, 130)
        bdir = -1 if i == 0 else 1
        for k in range(30):
            x = (cx + (w if bdir > 0 else 0) + bdir * k) % LW
            y = by - k // 2
            if 0 <= y < LH:
                px[x, y] = (*bark_mid, 255)
                px[x, min(LH - 1, y + 1)] = (*bark, 255)
        _shade_crown(px, (cx + (w if bdir > 0 else 0) + bdir * 32) % LW,
                     by - 22, 16, green_dark, green_mid, (30, 56, 42), LH, rng, 4)
    return im

def forest_fog():
    return fog_band(80, lerp(FOREST_SKY, (255, 255, 255), 0.08), 90)

# ---------------- registry ----------------

BIOMES = {
    "forest": [("far", forest_far), ("fog", forest_fog),
               ("mid", forest_mid), ("near", forest_near)],
}

if __name__ == "__main__":
    outdir = "/tmp/backdrops"
    for biome, layers in BIOMES.items():
        bdir = f"{outdir}/{biome}"
        os.makedirs(bdir, exist_ok=True)
        for name, fn in layers:
            fn().save(f"{bdir}/{name}.png")
    print("done")
