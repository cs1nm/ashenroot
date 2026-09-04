#!/usr/bin/env python3
"""32x32 water/lava tiles.

Engine contract (scripts/main.gd liquid drawing):
- partial tiles are cropped from the BOTTOM of the texture, so the lit
  surface band must live in the TOP rows only;
- alpha must stay uniform per tile (water 220, lava 230) like the old set;
- variants share the same body field, only sparkle/bubble details differ.
"""
import math, random, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_tiles32 import T, value_noise
from PIL import Image

def liquid(seed, deep, mid, lit, surface, alpha, detail_seed=None, bubbles=0):
    if detail_seed is None:
        detail_seed = seed
    n = value_noise(seed, 3)
    im = Image.new("RGBA", (T, T))
    px = im.load()
    for y in range(T):
        for x in range(T):
            # gentle horizontal wave bands
            wave = math.sin(y * 0.5 + n(x, y) * 2.6) * 0.5 + 0.5
            c = mid if wave > 0.45 else deep
            px[x, y] = (*c, alpha)
    # lit surface band: top 3 rows (world-space crop keeps these on top)
    for x in range(T):
        px[x, 0] = (*surface, alpha)
        px[x, 1] = (*surface, alpha)
        if n(x, 2) > 0.5:
            px[x, 2] = (*lit, alpha)
    rng = random.Random(detail_seed + 3)
    for _ in range(6):  # glints in the body
        x, y = rng.randrange(2, T - 2), rng.randrange(5, T - 3)
        px[x, y] = (*lit, alpha)
    for _ in range(bubbles):  # lava only: bright ember bubbles
        x, y = rng.randrange(3, T - 3), rng.randrange(6, T - 4)
        px[x, y] = (*surface, alpha)
        px[x + 1, y] = (*lit, alpha)
    return im

WATER = dict(deep=(31, 101, 121), mid=(45, 135, 153), lit=(64, 159, 176),
             surface=(130, 209, 213), alpha=220)
LAVA = dict(deep=(109, 37, 26), mid=(150, 55, 33), lit=(233, 106, 48),
            surface=(255, 208, 100), alpha=230, bubbles=3)

if __name__ == "__main__":
    outdir = "/tmp/tiles32"
    os.makedirs(outdir, exist_ok=True)
    for vi in range(4):
        suffix = "" if vi == 0 else f"_{vi}"
        liquid(60, detail_seed=60 + vi * 100, **WATER).save(f"{outdir}/water{suffix}.png")
        liquid(61, detail_seed=61 + vi * 100, **LAVA).save(f"{outdir}/lava{suffix}.png")
    print("done")
