#!/usr/bin/env python3
"""Procedural animation for blob/critter creatures from a single base sprite.

All frames derive from one hand-picked pixel-art base frame, guaranteeing a
uniform style (same palette, outline and pixel density as the base). The
animator does pixel-safe squash & stretch, hops, recoils, flashes, deflation
and simple ground-root effects, then writes horizontal strips + _anim.json
matching docs/CREATURE_ANIMATION_PIPELINE.md.
"""
import json, math, os, sys
from PIL import Image, ImageEnhance

FRAME = 96          # square frame canvas, matches wild_slime pack
GROUND = 89         # baseline y inside frame; matches the shared pack anchor y=89

def load_base(path):
    im = Image.open(path).convert("RGBA")
    return im.crop(im.getbbox())

def squash(base, sx, sy):
    w = max(1, round(base.width * sx))
    h = max(1, round(base.height * sy))
    return base.resize((w, h), Image.NEAREST)

def place(canvas, sprite, dx=0, dy=0):
    x = FRAME // 2 - sprite.width // 2 + round(dx)
    y = GROUND - sprite.height + round(dy)
    canvas.alpha_composite(sprite, (max(0, min(FRAME - sprite.width, x)),
                                    max(0, min(FRAME - sprite.height, y))))
    return canvas

def frame():
    return Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))

def tint(sprite, factor_rgb, brightness=1.0):
    out = sprite.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            r = min(255, int(r * factor_rgb[0] * brightness))
            g = min(255, int(g * factor_rgb[1] * brightness))
            b = min(255, int(b * factor_rgb[2] * brightness))
            px[x, y] = (r, g, b, a)
    return out

def flash_white(sprite, amount):
    out = sprite.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            px[x, y] = (int(r + (235 - r) * amount), int(g + (235 - g) * amount),
                        int(b + (235 - b) * amount), a)
    return out

def flash_red(sprite, amount):
    """Damage flash: push pixels towards a hot red instead of white.

    The shared damage language for ALL creatures — hurt/death frames blink
    red, matching the runtime ENEMY_HIT_FLASH_COLOR tint in main.gd.
    """
    out = sprite.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            px[x, y] = (int(r + (238 - r) * amount), int(g + (74 - g) * amount),
                        int(b + (64 - b) * amount), a)
    return out

def crumble(sprite, keep_ratio, seed=7):
    """Remove pixels from the top down for the death dissolve."""
    out = sprite.copy()
    px = out.load()
    import random
    rng = random.Random(seed)
    keep_h = int(sprite.height * keep_ratio)
    for y in range(sprite.height):
        for x in range(sprite.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            top_dist = sprite.height - y      # pixels from bottom
            if top_dist > keep_h and rng.random() < 0.85:
                px[x, y] = (0, 0, 0, 0)
    return out

def strip(frames):
    out = Image.new("RGBA", (FRAME * len(frames), FRAME), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.alpha_composite(f, (i * FRAME, 0))
    return out

def build_idle(base, n=10):
    frames = []
    for i in range(n):
        t = i / n * 2 * math.pi
        sy = 1.0 + 0.035 * math.sin(t)
        sx = 1.0 - 0.030 * math.sin(t)
        frames.append(place(frame(), squash(base, sx, sy)))
    return frames

def build_move(base, n=14, hop=4):
    """Hop cycle: crouch -> launch -> airborne -> land -> settle."""
    frames = []
    for i in range(n):
        t = i / (n - 1)
        if t < 0.2:          # crouch
            k = t / 0.2
            spr = squash(base, 1.0 + 0.12 * k, 1.0 - 0.18 * k)
            dy = 0
        elif t < 0.35:       # launch
            k = (t - 0.2) / 0.15
            spr = squash(base, 1.0 - 0.10 * k, 1.0 + 0.14 * k)
            dy = -hop * k
        elif t < 0.7:        # airborne arc
            k = (t - 0.35) / 0.35
            spr = squash(base, 0.95 + 0.05 * k, 1.06 - 0.06 * k)
            dy = -hop * (1.0 - (2 * k - 1) ** 2) - (1 - k) * hop * 0.3
        elif t < 0.85:       # land squash
            k = (t - 0.7) / 0.15
            spr = squash(base, 1.0 + 0.16 * k, 1.0 - 0.20 * k)
            dy = 0
        else:                # settle
            k = (t - 0.85) / 0.15
            spr = squash(base, 1.16 - 0.16 * k, 0.80 + 0.20 * k)
            dy = 0
        frames.append(place(frame(), spr, dy=dy))
    return frames

def build_attack_lunge(base, n=14, hit=(7, 8)):
    """Telegraph (lean back + squash) -> lunge forward -> recover."""
    frames = []
    for i in range(n):
        t = i / (n - 1)
        if t < 0.35:         # telegraph
            k = t / 0.35
            spr = squash(base, 1.0 + 0.10 * k, 1.0 - 0.14 * k)
            spr = tint(spr, (1.05, 1.02, 0.95), 1.0 + 0.08 * k)
            dx = -4 * k
            dy = 0
        elif t < 0.6:        # impact lunge
            k = (t - 0.35) / 0.25
            spr = squash(base, 1.0 - 0.08 * math.sin(k * math.pi), 1.0 + 0.10 * math.sin(k * math.pi))
            spr = flash_white(spr, 0.12 * math.sin(k * math.pi))
            dx = -4 + 14 * k
            dy = -3 * math.sin(k * math.pi)
        else:                # recover
            k = (t - 0.6) / 0.4
            spr = squash(base, 1.0 + 0.05 * (1 - k), 1.0 - 0.05 * (1 - k))
            dx = 10 * (1 - k)
            dy = 0
        frames.append(place(frame(), spr, dx=dx, dy=dy))
    return frames

def build_attack_summon(base, n=18, emit=(10, 11)):
    """Deep crouch + shiver, glow pulse, release at emit frames."""
    frames = []
    for i in range(n):
        t = i / (n - 1)
        if t < 0.45:         # charge: sink + shiver + glow build
            k = t / 0.45
            spr = squash(base, 1.0 + 0.14 * k, 1.0 - 0.22 * k)
            spr = tint(spr, (1.0 + 0.25 * k, 1.0 + 0.2 * k, 0.9), 1.0)
            dx = (1 if i % 2 == 0 else -1) * (1 + int(2 * k))
        elif t < 0.68:       # release burst
            k = (t - 0.45) / 0.23
            spr = squash(base, 1.14 - 0.22 * math.sin(k * math.pi * 0.5), 0.78 + 0.30 * math.sin(k * math.pi * 0.5))
            spr = flash_white(spr, 0.35 * math.sin(k * math.pi))
            dx = 0
        else:                # recover
            k = (t - 0.68) / 0.32
            spr = squash(base, 1.0 + 0.04 * (1 - k), 1.0 + 0.08 * (1 - k) * -1 + 0.08 * (1 - k))
            dx = 0
        frames.append(place(frame(), spr, dx=dx))
    return frames

def build_hurt(base, n=6):
    frames = []
    for i in range(n):
        t = i / (n - 1)
        k = 1.0 - t
        spr = flash_red(squash(base, 1.0 + 0.08 * k, 1.0 - 0.10 * k), 0.62 * k)
        frames.append(place(frame(), spr, dx=-3 * k))
    return frames

def build_death(base, n=16):
    frames = []
    for i in range(n):
        t = i / (n - 1)
        if t < 0.25:         # hit flash + recoil
            k = t / 0.25
            spr = flash_red(base, 0.55 * (1 - k))
            spr = squash(spr, 1.0 + 0.06 * k, 1.0 - 0.10 * k)
        else:                # deflate + desaturate + crumble
            k = (t - 0.25) / 0.75
            spr = squash(base, 1.0 + 0.35 * k, max(0.18, 1.0 - 0.80 * k))
            spr = tint(spr, (1.0 - 0.25 * k, 1.0 - 0.20 * k, 1.0 - 0.25 * k), 1.0 - 0.35 * k)
            if k > 0.55:
                spr = crumble(spr, 1.0 - (k - 0.55) * 1.6, seed=i)
        frames.append(place(frame(), spr))
    return frames

def build_root_impact(palette_src, n=8):
    """Ground root spikes burst: rise fast, hold, sink. Colors sampled from base."""
    px = palette_src.load()
    cols = [px[x, y] for y in range(palette_src.height) for x in range(palette_src.width) if px[x, y][3] > 0]
    cols.sort(key=lambda c: c[0] + c[1] + c[2])
    dark = cols[max(0, len(cols)//10)][:3] + (255,)
    mid = cols[len(cols)//2][:3] + (255,)
    lite = cols[int(len(cols)*0.86)][:3] + (255,)
    spikes = [(-14, 16, 0.0), (-4, 26, 0.12), (7, 20, 0.05), (15, 12, 0.2)]
    frames = []
    for i in range(n):
        t = i / (n - 1)
        h_k = min(1.0, t / 0.35) if t < 0.7 else max(0.0, 1.0 - (t - 0.7) / 0.3)
        f = frame()
        fpx = f.load()
        for sx, sh, delay in spikes:
            k = max(0.0, min(1.0, h_k - delay))
            h = int(sh * k)
            if h <= 0:
                continue
            cx = FRAME // 2 + sx
            w0 = 5
            for yy in range(h):
                w = max(1, round(w0 * (1.0 - yy / max(1, h))))
                y = GROUND - yy
                for xx in range(cx - w // 2, cx - w // 2 + w):
                    if 0 <= xx < FRAME and 0 <= y < FRAME:
                        c = lite if yy == h - 1 else (mid if yy > h * 0.4 else dark)
                        fpx[xx, y] = c
        frames.append(f)
    return frames

def main(base_path, out_dir, name):
    base = load_base(base_path)
    os.makedirs(out_dir, exist_ok=True)
    anims = {
        "idle": (build_idle(base), {"fps": 7, "loop": True}),
        "move": (build_move(base), {"fps": 12, "loop": True}),
        "attack_1": (build_attack_lunge(base), {"fps": 14, "loop": False,
                     "hit_frames": [7, 8], "hit_frames_1based": [8, 9]}),
        "attack_2": (build_attack_summon(base), {"fps": 14, "loop": False,
                     "hit_frames": [10, 11], "hit_frames_1based": [11, 12]}),
        "hurt": (build_hurt(base), {"fps": 14, "loop": False}),
        "death": (build_death(base), {"fps": 12, "loop": False}),
        "root_impact": (build_root_impact(base), {"fps": 13, "loop": False}),
    }
    meta = {
        "frame_size": [FRAME, FRAME],
        "facing": "right",
        "anchor": {"x": FRAME // 2, "y": GROUND},
        "ground_clearance": 1.0,
        "frame_indexing": "0-based",
        "animations": {},
    }
    for state, (frames, extra) in anims.items():
        fname = f"{name}_{state}.png"
        strip(frames).save(os.path.join(out_dir, fname))
        entry = {"file": fname, "frames": len(frames)}
        entry.update(extra)
        meta["animations"][state] = entry
    with open(os.path.join(out_dir, f"{name}_anim.json"), "w") as fh:
        json.dump(meta, fh, indent=1)
    print("written", out_dir, {k: v[1].get("fps") for k, v in anims.items()})

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
