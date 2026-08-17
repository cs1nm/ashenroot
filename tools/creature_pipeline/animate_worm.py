#!/usr/bin/env python3
"""Procedural animation for the armored cave worm.

Built from three authored key poses:
  idle  — long armored worm lying on the floor
  bite  — head reared up, lamprey mouth open
  wheel — worm curled into an armored wheel (rolling attack)

The wheel spin uses pixel-safe 90-degree rotations. Pack layout matches the
engine contract for cave_worm: frames 160x96, anchor x=80 y=89, fps 14
attacks, hit frames bite=7, roll=10, burrow=14. Damage feedback is RED per
docs/CREATURE_ANIMATION_PIPELINE.md.
"""
import json, math, os, random, sys
from PIL import Image

FRAME_W = 160
FRAME_H = 96
GROUND = 89
ANCHOR_X = 80

def load(path):
    im = Image.open(path).convert("RGBA")
    return im.crop(im.getbbox())

def frame():
    return Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))

def place(canvas, sprite, dx=0, dy=0, clip_ground=False):
    x = ANCHOR_X - sprite.width // 2 + round(dx)
    y = GROUND - sprite.height + round(dy)
    canvas.alpha_composite(sprite, (max(0, min(FRAME_W - sprite.width, x)), max(0, y)))
    if clip_ground:
        px = canvas.load()
        for yy in range(GROUND + 1, FRAME_H):
            for xx in range(FRAME_W):
                px[xx, yy] = (0, 0, 0, 0)
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

def column_wave(base, phase, amplitude, wavelength, head_lock=0.6):
    out = Image.new("RGBA", (base.width, base.height + 2 * int(amplitude) + 2), (0, 0, 0, 0))
    for x in range(base.width):
        damp = 1.0
        t = x / max(1, base.width - 1)
        if head_lock > 0.0 and t > 0.55:
            damp = 1.0 - head_lock * (t - 0.55) / 0.45
        dy = round(amplitude * damp * math.sin(2 * math.pi * (x / wavelength - phase)))
        col = base.crop((x, 0, x + 1, base.height))
        out.alpha_composite(col, (x, int(amplitude) + 1 + dy))
    return out.crop(out.getbbox()) if out.getbbox() else out

def palette_of(base):
    px = base.load()
    cols = [px[x, y] for y in range(base.height) for x in range(base.width) if px[x, y][3] > 0]
    cols.sort(key=lambda c: c[0] + c[1] + c[2])
    return {
        "dark": cols[max(0, len(cols) // 10)][:3] + (255,),
        "mid": cols[len(cols) // 2][:3] + (255,),
        "lite": cols[int(len(cols) * 0.86)][:3] + (255,),
        "glow": (120, 225, 235, 255),
    }

def strip(frames):
    out = Image.new("RGBA", (FRAME_W * len(frames), FRAME_H), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.alpha_composite(f, (i * FRAME_W, 0))
    return out

def build_idle(idle, n=10):
    frames = []
    for i in range(n):
        t = i / n
        spr = column_wave(idle, t, 1.4, idle.width * 1.5)
        frames.append(place(frame(), spr))
    return frames

def build_move(idle, n=16):
    frames = []
    for i in range(n):
        t = i / n
        spr = column_wave(idle, t * 2.0, 2.8, idle.width * 0.65)
        sx = 1.0 + 0.05 * math.sin(2 * math.pi * t * 2.0)
        spr = squash(spr, sx, 1.0)
        frames.append(place(frame(), spr))
    return frames

def build_attack_bite(idle, bite, n=14):
    """Rear up (telegraph), slam the open mouth down-forward at 7-8."""
    frames = []
    for i in range(n):
        if i < 5:                      # rise into bite pose
            k = i / 4
            pose = idle if k < 0.4 else bite
            spr = squash(pose, 1.0 - 0.04 * k, 1.0 + 0.05 * k)
            frames.append(place(frame(), spr, dx=-4 * k))
        elif i < 7:                    # trembling hold, mouth glowing
            spr = tint(bite, (1.06, 1.03, 1.0), 1.04)
            frames.append(place(frame(), spr, dx=-4 + (1 if i % 2 else -1)))
        elif i < 9:                    # STRIKE forward (hit frames 7-8)
            k = i - 7
            spr = squash(bite, 1.05, 0.95)
            frames.append(place(frame(), spr, dx=8 + 8 * k, dy=2))
        elif i < 11:                   # mouth planted
            frames.append(place(frame(), bite, dx=14, dy=2))
        else:                          # recover to idle
            k = (i - 11) / (n - 12)
            pose = bite if k < 0.5 else idle
            frames.append(place(frame(), pose, dx=14 * (1 - k)))
    return frames

def build_attack_roll(idle, wheel, n=20):
    """Curl into an armored wheel, spin forward, uncurl. Hit frames 10-11."""
    frames = []
    spins = [wheel, wheel.rotate(-90, expand=True), wheel.rotate(-180, expand=True), wheel.rotate(-270, expand=True)]
    for i in range(n):
        if i < 5:                      # curl up: idle compresses into a ball
            k = i / 4
            w = round(idle.width * (1.0 - 0.62 * k))
            h = round(idle.height * (1.0 + (wheel.height / idle.height - 1.0) * k))
            spr = idle.resize((max(wheel.width, w), max(idle.height, h)), Image.NEAREST) if k < 1.0 else wheel
            frames.append(place(frame(), spr))
        elif i < 8:                    # rev up in place (spin without moving)
            spr = spins[(i - 5) % 4]
            frames.append(place(frame(), spr, dy=-1 if i % 2 else 0))
        elif i < 14:                   # rolling strike forward (hit at 10-11)
            k = i - 8
            spr = spins[k % 4]
            frames.append(place(frame(), spr, dx=4 + k * 5))
        elif i < 16:                   # skid stop
            spr = spins[(i - 8) % 4]
            frames.append(place(frame(), spr, dx=34 - (i - 14) * 3))
        else:                          # uncurl back to idle
            k = (i - 16) / (n - 17)
            pose = wheel if k < 0.4 else idle
            frames.append(place(frame(), pose, dx=26 * (1 - k)))
    return frames

def build_attack_burrow(idle, bite, n=22):
    """Dive under the floor, travel, erupt mouth-first. Hit frames 14-15."""
    frames = []
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        if t < 0.25:
            k = t / 0.25
            spr = squash(idle, 1.0 + 0.04 * k, 1.0 - 0.14 * k)
            place(f, spr, dx=(1 if i % 2 else -1) * int(1 + k * 2), dy=int(3 * k), clip_ground=True)
        elif t < 0.45:
            k = (t - 0.25) / 0.2
            place(f, idle, dy=int(idle.height * k * 1.15) + 3, clip_ground=True)
        elif t < 0.6:
            pass                        # hidden underground
        else:                           # eruption, open mouth first
            k = (t - 0.6) / 0.4
            up = min(1.0, k * 1.7)
            spr = squash(bite, 1.0 - 0.05 * (1 - up), 1.0 + 0.12 * (1 - up))
            place(f, spr, dy=int(bite.height * (1.0 - up) * 1.15), clip_ground=True)
        frames.append(f)
    return frames

def build_hurt(idle, n=6):
    frames = []
    for i in range(n):
        t = i / (n - 1)
        k = 1.0 - t
        spr = flash_red(squash(idle, 1.0 + 0.05 * k, 1.0 - 0.08 * k), 0.62 * k)
        frames.append(place(frame(), spr, dx=-4 * k))
    return frames

def build_death(idle, n=18):
    """Red flash, armor plates shear apart, body deflates and crumbles."""
    frames = []
    rng = random.Random(17)
    seg_count = 5
    seg_w = idle.width // seg_count
    seg_data = [(s, rng.uniform(-2.0, 2.0), rng.uniform(0.85, 1.45)) for s in range(seg_count)]
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        if t < 0.2:
            k = t / 0.2
            spr = flash_red(idle, 0.55 * (1 - k))
            place(f, spr)
        else:
            k = (t - 0.2) / 0.8
            fade = tint(idle, (1.0 - 0.28 * k, 1.0 - 0.3 * k, 1.0 - 0.28 * k), 1.0 - 0.4 * k)
            for s, drift, speed in seg_data:
                x0 = s * seg_w
                x1 = idle.width if s == seg_count - 1 else (s + 1) * seg_w
                seg = fade.crop((x0, 0, x1, idle.height))
                drop_k = min(1.0, k * speed)
                sh = max(3, round(seg.height * (1.0 - 0.74 * drop_k)))
                seg = seg.resize((seg.width, sh), Image.NEAREST)
                if k > 0.5:
                    spx = seg.load()
                    for yy in range(seg.height):
                        for xx in range(seg.width):
                            if spx[xx, yy][3] and rng.random() < (k - 0.5) * 1.9 * (1.0 - yy / seg.height):
                                spx[xx, yy] = (0, 0, 0, 0)
                fx = ANCHOR_X - idle.width // 2 + x0 + round(drift * k * 4)
                f.alpha_composite(seg, (fx, GROUND - seg.height))
        frames.append(f)
    return frames

def build_bite_impact(base, n=7):
    """Snapping ring burst: tooth sparks radiating from the bite point."""
    pal = palette_of(base)
    rng = random.Random(3)
    sparks = [(rng.uniform(0, 2 * math.pi), rng.uniform(6, 16), rng.uniform(0.0, 0.2),
               pal["lite"] if rng.random() < 0.6 else pal["glow"]) for _ in range(12)]
    frames = []
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        px = f.load()
        for ang, dist, delay, col in sparks:
            k = max(0.0, min(1.0, (t - delay) / 0.7))
            if k <= 0.0:
                continue
            x = ANCHOR_X + 10 + round(math.cos(ang) * dist * k)
            y = GROUND - 14 + round(math.sin(ang) * dist * k * 0.7)
            a = int(255 * (1.0 - k * 0.7))
            if 0 <= x < FRAME_W and 0 <= y < FRAME_H:
                px[x, y] = col[:3] + (a,)
                if k < 0.5 and x + 1 < FRAME_W:
                    px[x + 1, y] = col[:3] + (a,)
        frames.append(f)
    return frames

def build_dust(base, n, spread, seed):
    pal = palette_of(base)
    rng = random.Random(seed)
    puffs = [(rng.uniform(-spread, spread), rng.uniform(3, 15), rng.uniform(0.0, 0.35),
              pal["lite"] if rng.random() < 0.5 else pal["mid"]) for _ in range(18)]
    frames = []
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        px = f.load()
        for ox, h, delay, col in puffs:
            k = max(0.0, min(1.0, (t - delay) / 0.65))
            if k <= 0.0:
                continue
            x = ANCHOR_X + round(ox * (0.5 + 0.9 * k))
            y = GROUND - round(h * math.sin(k * math.pi))
            a = int(240 * (1.0 - k * 0.7))
            size = 2 if k < 0.5 else 1
            for dx in range(size):
                for dy in range(size):
                    if 0 <= x + dx < FRAME_W and 0 <= y + dy < FRAME_H:
                        px[x + dx, y + dy] = col[:3] + (a,)
        frames.append(f)
    return frames

def main(idle_path, bite_path, wheel_path, out_dir):
    idle = load(idle_path)
    bite = load(bite_path)
    wheel = load(wheel_path)
    os.makedirs(out_dir, exist_ok=True)
    anims = {
        "idle": (build_idle(idle), {"fps": 7, "loop": True}, "cave_worm_idle.png"),
        "move": (build_move(idle), {"fps": 12, "loop": True}, "cave_worm_move.png"),
        "attack_1": (build_attack_bite(idle, bite), {"fps": 14, "loop": False,
                     "hit_frames": [7, 8], "hit_frames_1based": [8, 9]}, "cave_worm_bite.png"),
        "attack_2": (build_attack_roll(idle, wheel), {"fps": 14, "loop": False,
                     "hit_frames": [10, 11], "hit_frames_1based": [11, 12]}, "cave_worm_roll.png"),
        "attack_3": (build_attack_burrow(idle, bite), {"fps": 14, "loop": False,
                     "hit_frames": [14, 15], "hit_frames_1based": [15, 16]}, "cave_worm_burrow.png"),
        "hurt": (build_hurt(idle), {"fps": 14, "loop": False}, "cave_worm_hurt.png"),
        "death": (build_death(idle), {"fps": 12, "loop": False}, "cave_worm_death.png"),
        "bite_impact": (build_bite_impact(idle), {"fps": 14, "loop": False}, "cave_worm_bite_impact.png"),
        "roll_dust": (build_dust(idle, 8, 18, 5), {"fps": 14, "loop": False}, "cave_worm_roll_dust.png"),
        "burrow_dust": (build_dust(idle, 10, 22, 9), {"fps": 14, "loop": False}, "cave_worm_burrow_dust.png"),
    }
    meta = {
        "frame_size": [FRAME_W, FRAME_H],
        "facing": "right",
        "anchor": {"x": ANCHOR_X, "y": GROUND},
        "ground_clearance": 1.0,
        "frame_indexing": "0-based",
        "animations": {},
    }
    for state, (frames, extra, fname) in anims.items():
        strip(frames).save(os.path.join(out_dir, fname))
        entry = {"file": fname, "frames": len(frames)}
        entry.update(extra)
        meta["animations"][state] = entry
    with open(os.path.join(out_dir, "cave_worm_anim.json"), "w") as fh:
        json.dump(meta, fh, indent=1)
    print("written", out_dir, {k: len(v[0]) for k, v in anims.items()})

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
