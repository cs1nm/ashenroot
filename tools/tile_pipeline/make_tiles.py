#!/usr/bin/env python3
"""Procedural 16x16 tile generator for Ashen Roots.

Design rules (fixes the old noisy/flat tiles):
- clustered organic noise (value clumps), never per-pixel confetti
- volume: lit top edge, shaded bottom/right (soft bevel)
- 4-5 tone ramps derived from one base color per material
- tileable by construction (noise wraps)
- biome accent palette shared with the creature packs
"""
import math, random, sys
from PIL import Image

T = 16

def ramp(base, steps=5, spread=0.42):
    r, g, b = base
    out = []
    for i in range(steps):
        k = 1.0 - spread + (2 * spread) * i / (steps - 1)
        out.append((min(255, int(r * k)), min(255, int(g * k)), min(255, int(b * k))))
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

def base_tile(base, seed, bevel=True, noise_amt=1.0):
    R = ramp(base)
    n1 = value_noise(seed, 3)
    n2 = value_noise(seed + 7, 5)
    im = Image.new("RGB", (T, T))
    px = im.load()
    for y in range(T):
        for x in range(T):
            v = n1(x, y) * 0.65 + n2(x, y) * 0.35
            idx = 1 + int(v * 2.999 * noise_amt)
            if bevel:
                if y == 0: idx = min(4, idx + 1)
                elif y == 1 and v > 0.45: idx = min(4, idx + 1)
                if y == T - 1: idx = max(0, idx - 1)
                elif x == T - 1 and v > 0.5: idx = max(0, idx - 1)
            px[x, y] = R[max(0, min(4, idx))]
    return im

def speckle(im, seed, color, count, size=1):
    rng = random.Random(seed)
    px = im.load()
    for _ in range(count):
        x, y = rng.randrange(T), rng.randrange(T)
        for dx in range(size):
            for dy in range(size):
                px[(x + dx) % T, (y + dy) % T] = color
    return im

def grass(seed, soil, blades, blade_lit):
    im = base_tile(soil, seed)
    px = im.load()
    rng = random.Random(seed + 3)
    n = value_noise(seed + 11, 4)
    for x in range(T):
        depth = 3 + int(n(x, 0) * 3)
        for y in range(depth):
            k = y / max(1, depth - 1)
            if y == 0:
                px[x, y] = blade_lit if rng.random() < 0.55 else blades[0]
            elif k < 0.6:
                px[x, y] = blades[0] if rng.random() > 0.2 else blades[1]
            elif rng.random() > k:  # рваная граница с землёй
                px[x, y] = blades[1]
    return im

def ore(seed, stone_base, vein_dark, vein_lit):
    im = base_tile(stone_base, seed)
    px = im.load()
    rng = random.Random(seed + 5)
    for _ in range(3):  # 3 кластера-жилы
        cx, cy = rng.randrange(2, 14), rng.randrange(2, 14)
        for _ in range(rng.randint(4, 6)):
            dx, dy = rng.randint(-2, 2), rng.randint(-1, 1)
            x, y = (cx + dx) % T, (cy + dy) % T
            px[x, y] = vein_dark
            if rng.random() < 0.5:
                px[(x + 1) % T, y] = vein_lit
    return im

def wood_planks(seed, base):
    R = ramp(base)
    im = Image.new("RGB", (T, T))
    px = im.load()
    rng = random.Random(seed)
    n = value_noise(seed, 4)
    for x in range(T):
        for y in range(T):
            v = n(x, y)
            idx = 1 + int(v * 2.3)
            if x % 5 == 0: idx = 0            # вертикальный шов
            elif x % 5 == 1: idx = min(4, idx + 1)  # блик у шва
            if y == 0: idx = min(4, idx + 1)
            if y == T - 1: idx = max(0, idx - 1)
            px[x, y] = R[max(0, min(4, idx))]
    for _ in range(3):                        # сучки
        x, y = rng.randrange(1, 15), rng.randrange(2, 14)
        px[x, y] = R[0]
    return im

def leaves(seed, base, glow):
    im = base_tile(base, seed, bevel=False)
    px = im.load()
    rng = random.Random(seed + 9)
    n = value_noise(seed + 4, 5)
    for y in range(T):
        for x in range(T):
            v = n(x, y)
            if v > 0.72:
                px[x, y] = glow
            elif v < 0.2 and rng.random() < 0.5:
                px[x, y] = ramp(base)[0]
    return im
