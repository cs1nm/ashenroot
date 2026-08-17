#!/usr/bin/env python3
"""Procedural animation for the spore bat (mushroom halls flyer).

Built from two authored key poses (wings up / wings down). Pack layout
matches the engine contract for spore_bat: frames 160x96, CENTER anchor
(80,48), attack_1 bite 8f hit 4 @14, attack_2 spore burst 10f hit 5 @12,
plus spore_cloud / spore_trail VFX strips. Damage feedback is RED per
docs/CREATURE_ANIMATION_PIPELINE.md; spores glow lime-green.
"""
import json, math, os, random, sys
from PIL import Image

FRAME_W = 160
FRAME_H = 96
CX = 80
CY = 48
SPORE = (168, 232, 110, 255)

def load(path):
    im = Image.open(path).convert("RGBA")
    return im.crop(im.getbbox())

def frame():
    return Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))

def place_center(canvas, sprite, dx=0, dy=0):
    x = CX - sprite.width // 2 + round(dx)
    y = CY - sprite.height // 2 + round(dy)
    canvas.alpha_composite(sprite, (max(0, min(FRAME_W - sprite.width, x)),
                                    max(0, min(FRAME_H - sprite.height, y))))
    return canvas

def squash(im, sx, sy):
    return im.resize((max(1, round(im.width * sx)), max(1, round(im.height * sy))), Image.NEAREST)

def flash_red(sprite, amount):
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

def tint(sprite, f, brightness=1.0):
    out = sprite.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            px[x, y] = (min(255, int(r * f[0] * brightness)), min(255, int(g * f[1] * brightness)),
                        min(255, int(b * f[2] * brightness)), a)
    return out

def wing_blend(up, down, k):
    if k < 0.5:
        t = k / 0.5
        return squash(up, 1.0 - 0.06 * t, 1.0 - 0.18 * t)
    t = (k - 0.5) / 0.5
    return squash(down, 0.94 + 0.06 * t, 0.82 + 0.18 * t)

def palette_of(base):
    px = base.load()
    cols = [px[x, y] for y in range(base.height) for x in range(base.width) if px[x, y][3] > 0]
    cols.sort(key=lambda c: c[0] + c[1] + c[2])
    return {
        "dark": cols[max(0, len(cols) // 10)][:3] + (255,),
        "mid": cols[len(cols) // 2][:3] + (255,),
        "lite": cols[int(len(cols) * 0.86)][:3] + (255,),
    }

def strip(frames):
    out = Image.new("RGBA", (FRAME_W * len(frames), FRAME_H), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.alpha_composite(f, (i * FRAME_W, 0))
    return out

def sprinkle_spores(f, cx, cy, count, spread, t, rng, rise=6.0):
    """Falling lime spore motes around a point."""
    px = f.load()
    for m in range(count):
        ang = rng.uniform(0, 2 * math.pi)
        dist = rng.uniform(2, spread)
        x = cx + round(math.cos(ang) * dist)
        y = cy + round(math.sin(ang) * dist * 0.6 + t * rise)
        a = int(220 * max(0.15, 1.0 - t))
        if 0 <= x < FRAME_W and 0 <= y < FRAME_H:
            px[x, y] = SPORE[:3] + (a,)

def build_idle(up, down, n=8):
    frames = []
    rng = random.Random(3)
    for i in range(n):
        t = i / n
        k = 0.5 - 0.5 * math.cos(2 * math.pi * t)
        f = place_center(frame(), wing_blend(up, down, k), dy=-2.5 * math.sin(2 * math.pi * t))
        # a couple of ambient spores drifting off the wings
        sprinkle_spores(f, CX, CY + 6, 2, 16, (i % 4) / 4.0, rng)
        frames.append(f)
    return frames

def build_move(up, down, n=8):
    frames = []
    for i in range(n):
        t = i / n
        k = 0.5 - 0.5 * math.cos(2 * math.pi * t)
        spr = squash(wing_blend(up, down, k), 1.02, 0.98)
        frames.append(place_center(frame(), spr, dx=2, dy=-4.0 * math.sin(2 * math.pi * t)))
    return frames

def build_alert(up, down, n=5):
    frames = []
    for i in range(n):
        k = i / (n - 1)
        spr = wing_blend(up, down, 0.2)
        spr = tint(spr, (1.0 + 0.05 * k, 1.0 + 0.07 * k, 1.0), 1.0 + 0.04 * k)
        frames.append(place_center(frame(), spr, dy=-2 * k, dx=(1 if i % 2 else -1)))
    return frames

def build_hurt(up, down, n=4):
    frames = []
    for i in range(n):
        t = i / (n - 1)
        k = 1.0 - t
        spr = flash_red(wing_blend(up, down, 0.3), 0.62 * k)
        frames.append(place_center(frame(), spr, dx=-4 * k, dy=2 * k))
    return frames

def build_stunned(up, down, n=4):
    frames = []
    for i in range(n):
        t = i / n * 2 * math.pi
        spr = tint(wing_blend(up, down, 0.75), (0.85, 0.85, 0.85))
        frames.append(place_center(frame(), spr, dx=round(2.0 * math.sin(t)), dy=3))
    return frames

def build_attack_bite(up, down, n=8):
    """Dart bite, hit frame 4 @14fps."""
    frames = []
    for i in range(n):
        if i < 3:
            k = i / 2
            spr = wing_blend(up, down, 0.15)
            frames.append(place_center(frame(), spr, dx=-5 * k, dy=-2 * k))
        elif i < 6:                    # dart (hit at 4)
            k = (i - 3) / 2
            spr = tint(wing_blend(up, down, 0.85), (1.06, 1.04, 1.0), 1.04)
            frames.append(place_center(frame(), spr, dx=-5 + 16 * k, dy=2 * k))
        else:
            k = (i - 6) / 1
            frames.append(place_center(frame(), wing_blend(up, down, 0.4), dx=11 * (1 - k)))
    return frames

def build_spore_burst(up, down, n=10):
    """Shudder, then burst a lime spore ring at frame 5 @12fps."""
    rng = random.Random(11)
    frames = []
    for i in range(n):
        f = frame()
        k_f = 0.5 - 0.5 * math.cos(2 * math.pi * (i / n) * 2)
        spr = wing_blend(up, down, k_f * 0.5)
        if 2 <= i <= 4:                # inhale: greenish glow build
            spr = tint(spr, (1.0, 1.0 + 0.06 * (i - 1), 1.0), 1.0 + 0.02 * (i - 1))
        if 5 <= i <= 6:                # burst pump
            spr = squash(spr, 1.1, 0.9)
        place_center(f, spr, dx=(1 if i % 2 else -1) if 2 <= i <= 4 else 0)
        if i >= 5:                     # expanding spore ring
            px = f.load()
            ring_k = (i - 5) / 4
            rr = 6 + ring_k * 30
            steps = max(12, int(rr * 2.2))
            for s_i in range(steps):
                ang = 2 * math.pi * s_i / steps
                x = CX + round(math.cos(ang) * rr)
                y = CY + round(math.sin(ang) * rr * 0.8 + ring_k * 6)
                fade = 1.0 - ring_k * 0.75
                if 0 <= x < FRAME_W and 0 <= y < FRAME_H and rng.random() < 0.8:
                    px[x, y] = SPORE[:3] + (int(235 * fade),)
        frames.append(f)
    return frames

def build_spore_cloud(base, n=12):
    """Lingering spore cloud: swirling lime motes that settle and fade."""
    rng = random.Random(19)
    motes = [(rng.uniform(0, 2 * math.pi), rng.uniform(4, 24), rng.uniform(0.5, 1.6),
              rng.uniform(0.0, 0.3)) for _ in range(26)]
    frames = []
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        px = f.load()
        for ang0, dist, speed, delay in motes:
            k = max(0.0, min(1.0, (t - delay) / (1.0 - delay + 1e-5)))
            ang = ang0 + k * speed
            x = CX + round(math.cos(ang) * dist * (1.0 - 0.25 * k))
            y = CY + round(math.sin(ang) * dist * 0.7 + k * 10)
            a = int(230 * (1.0 - k * 0.8) * (0.4 + 0.6 * min(1.0, t * 4)))
            if 0 <= x < FRAME_W and 0 <= y < FRAME_H:
                px[x, y] = SPORE[:3] + (a,)
                if k < 0.4 and x + 1 < FRAME_W:
                    px[x + 1, y] = SPORE[:3] + (a // 2,)
        frames.append(f)
    return frames

def build_spore_trail(base, n=8):
    """Short drifting trail of spores behind the bat."""
    rng = random.Random(29)
    motes = [(rng.uniform(-26, -4), rng.uniform(-8, 8), rng.uniform(0.0, 0.4)) for _ in range(12)]
    frames = []
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        px = f.load()
        for ox, oy, delay in motes:
            k = max(0.0, min(1.0, (t - delay) / 0.7))
            if k <= 0.0:
                continue
            x = CX + round(ox - k * 8)
            y = CY + round(oy + k * 6)
            a = int(210 * (1.0 - k))
            if 0 <= x < FRAME_W and 0 <= y < FRAME_H:
                px[x, y] = SPORE[:3] + (a,)
        frames.append(f)
    return frames

def build_death(up, down, n=10):
    """Red flash, tumbling fall, puffing spores on the way down."""
    rng = random.Random(37)
    frames = []
    for i in range(n):
        t = i / (n - 1)
        spr = wing_blend(up, down, 0.6)
        if t < 0.3:
            spr = flash_red(spr, 0.55 * (1 - t / 0.3))
        spr = squash(spr, 1.0 - 0.3 * t, 1.0 - 0.2 * t)
        spr = spr.rotate(-130 * t, expand=True, resample=Image.NEAREST)
        f = place_center(frame(), spr, dy=-3 + 30 * t * t)
        if t > 0.3:
            sprinkle_spores(f, CX, CY + int(24 * t), 3, 12, t, rng)
        frames.append(f)
    return frames

def build_death_impact(base, n=6):
    """Floor hit: dust + a final lime spore puff."""
    pal = palette_of(base)
    rng = random.Random(43)
    puffs = [(rng.uniform(-14, 14), rng.uniform(2, 12), rng.uniform(0.0, 0.3),
              pal["lite"] if rng.random() < 0.4 else SPORE) for _ in range(16)]
    frames = []
    floor_y = CY + 30
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        px = f.load()
        for ox, h, delay, col in puffs:
            k = max(0.0, min(1.0, (t - delay) / 0.65))
            if k <= 0.0:
                continue
            x = CX + round(ox * (0.5 + 0.9 * k))
            y = floor_y - round(h * math.sin(k * math.pi))
            a = int(240 * (1.0 - k * 0.7))
            if 0 <= x < FRAME_W and 0 <= y < FRAME_H:
                px[x, y] = col[:3] + (a,)
        frames.append(f)
    return frames

def main(up_path, down_path, out_dir):
    up = load(up_path)
    down = load(down_path)
    os.makedirs(out_dir, exist_ok=True)
    anims = {
        "idle": (build_idle(up, down), {"fps": 8, "loop": True}, "spore_bat_idle.png"),
        "move": (build_move(up, down), {"fps": 12, "loop": True}, "spore_bat_move.png"),
        "alert": (build_alert(up, down), {"fps": 10, "loop": False}, "spore_bat_alert.png"),
        "hurt": (build_hurt(up, down), {"fps": 14, "loop": False}, "spore_bat_hurt.png"),
        "stunned": (build_stunned(up, down), {"fps": 6, "loop": True}, "spore_bat_stunned.png"),
        "attack_1": (build_attack_bite(up, down), {"fps": 14, "loop": False,
                     "hit_frames": [4], "hit_frames_1based": [5]}, "spore_bat_bite.png"),
        "attack_2": (build_spore_burst(up, down), {"fps": 12, "loop": False,
                     "hit_frames": [5], "hit_frames_1based": [6]}, "spore_bat_spore_burst.png"),
        "spore_cloud": (build_spore_cloud(up), {"fps": 11.2, "loop": False}, "spore_bat_spore_cloud.png"),
        "spore_trail": (build_spore_trail(up), {"fps": 9.1, "loop": True}, "spore_bat_spore_trail.png"),
        "death": (build_death(up, down), {"fps": 12, "loop": False}, "spore_bat_death.png"),
        "death_impact": (build_death_impact(up), {"fps": 10, "loop": False}, "spore_bat_death_impact.png"),
    }
    meta = {
        "frame_size": [FRAME_W, FRAME_H],
        "facing": "right",
        "anchor": {"x": CX, "y": CY},
        "ground_clearance": 1.0,
        "frame_indexing": "0-based",
        "animations": {},
    }
    for state, (frames, extra, fname) in anims.items():
        strip(frames).save(os.path.join(out_dir, fname))
        entry = {"file": fname, "frames": len(frames)}
        entry.update(extra)
        meta["animations"][state] = entry
    with open(os.path.join(out_dir, "spore_bat_anim.json"), "w") as fh:
        json.dump(meta, fh, indent=1)
    print("written", out_dir, {k: len(v[0]) for k, v in anims.items()})

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
