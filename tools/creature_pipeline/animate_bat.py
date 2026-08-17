#!/usr/bin/env python3
"""Procedural animation for flying creatures (cave bat).

Built from three authored key poses:
  up    — wings raised at the top of the flap
  down  — wings swept below the body
  hang  — wings folded, hanging from the ceiling

Frames are 160x112 with a CENTER anchor (80,56) because the engine treats
bats as flying (drawn from sprite center, not a ground line). States and hit
frames follow the existing bat pack contract:
  attack_1 bite   8f  hit 4-5 @14
  attack_2 sonic 10f  projectile release 5 @12
  attack_3 dive   4f  hit 3 @12, plus dive_loop 3f and dive_recover 6f
  death_fall 10f + death_impact 6f
Damage feedback is RED per docs/CREATURE_ANIMATION_PIPELINE.md.
"""
import json, math, os, random, sys
from PIL import Image

FRAME_W = 160
FRAME_H = 112
CX = 80
CY = 56

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

def place_top(canvas, sprite, dx=0, dy=0):
    """For the hanging pose: feet glued to the frame top."""
    x = CX - sprite.width // 2 + round(dx)
    canvas.alpha_composite(sprite, (max(0, min(FRAME_W - sprite.width, x)), max(0, round(dy))))
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
    """k=0 -> wings up pose, k=1 -> wings down pose. Chooses the nearer
    authored pose and squashes it toward the midpoint so the flap reads
    as continuous motion without hand-drawn inbetweens."""
    if k < 0.5:
        t = k / 0.5                     # 0..1 away from 'up'
        return squash(up, 1.0 - 0.06 * t, 1.0 - 0.18 * t)
    t = (k - 0.5) / 0.5                 # 0..1 toward full 'down'
    return squash(down, 0.94 + 0.06 * t, 0.82 + 0.18 * t)

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

def flap_cycle(up, down, n, bob_amp=3.0, speed=1.0):
    frames = []
    for i in range(n):
        t = i / n
        k = 0.5 - 0.5 * math.cos(2 * math.pi * t * speed)   # 0..1..0
        spr = wing_blend(up, down, k)
        dy = -bob_amp * math.sin(2 * math.pi * t * speed)
        frames.append(place_center(frame(), spr, dy=dy))
    return frames

def build_idle(up, down, n=8):
    return flap_cycle(up, down, n, bob_amp=2.5)

def build_move(up, down, n=8):
    frames = []
    for i in range(n):
        t = i / n
        k = 0.5 - 0.5 * math.cos(2 * math.pi * t)
        spr = wing_blend(up, down, k)
        spr = squash(spr, 1.02, 0.98)          # slight forward lean
        dy = -4.0 * math.sin(2 * math.pi * t)
        frames.append(place_center(frame(), spr, dx=2, dy=dy))
    return frames

def build_hang_idle(hang, n=6):
    frames = []
    for i in range(n):
        t = i / n * 2 * math.pi
        spr = squash(hang, 1.0 + 0.03 * math.sin(t), 1.0 + 0.02 * math.cos(t))
        frames.append(place_top(frame(), spr, dx=round(math.sin(t) * 1.5)))
    return frames

def build_wake_up(hang, up, n=4):
    frames = []
    for i in range(n):
        k = i / (n - 1)
        if k < 0.5:
            spr = squash(hang, 1.0 + 0.3 * k, 1.0 - 0.15 * k)
            frames.append(place_top(frame(), spr))
        else:
            spr = squash(up, 0.7 + 0.3 * (k - 0.5) * 2, 0.7 + 0.3 * (k - 0.5) * 2)
            frames.append(place_center(frame(), spr, dy=-6 * (1 - k)))
    return frames

def build_attack_bite(up, down, n=8):
    """Quick dart forward with a snap. Hit frames 4-5 @14fps."""
    frames = []
    for i in range(n):
        if i < 3:                      # rear back, wings up
            k = i / 2
            spr = wing_blend(up, down, 0.15)
            frames.append(place_center(frame(), spr, dx=-5 * k, dy=-2 * k))
        elif i < 6:                    # dart forward (hit at 4-5)
            k = (i - 3) / 2
            spr = wing_blend(up, down, 0.85)
            spr = tint(spr, (1.06, 1.02, 1.0), 1.04)
            frames.append(place_center(frame(), spr, dx=-5 + 16 * k, dy=2 * k))
        else:                          # recover
            k = (i - 6) / 1
            spr = wing_blend(up, down, 0.4)
            frames.append(place_center(frame(), spr, dx=11 * (1 - k)))
    return frames

def build_sonic(up, down, base, n=10):
    """Hover, mouth opens, cyan ring pulse released at frame 5 @12fps."""
    pal = palette_of(base)
    frames = []
    for i in range(n):
        f = frame()
        k_f = 0.5 - 0.5 * math.cos(2 * math.pi * (i / n) * 2)
        spr = wing_blend(up, down, k_f * 0.5)   # shallow hover flap
        if 2 <= i <= 4:                          # inhale glow build
            spr = tint(spr, (1.0 + 0.04 * (i - 1), 1.0 + 0.05 * (i - 1), 1.0 + 0.07 * (i - 1)))
        place_center(f, spr)
        if 4 <= i <= 7:                          # expanding sonic rings
            px = f.load()
            ring_k = (i - 4) / 3
            for ring in range(2):
                rr = 8 + ring_k * 26 + ring * 7
                fade = 1.0 - ring_k * 0.7 - ring * 0.2
                if fade <= 0:
                    continue
                steps = max(10, int(rr * 1.6))
                for s_i in range(steps):
                    ang = -0.9 + 1.8 * s_i / steps   # forward-facing arc
                    x = CX + 18 + round(math.cos(ang) * rr)
                    y = CY + round(math.sin(ang) * rr * 0.8)
                    if 0 <= x < FRAME_W and 0 <= y < FRAME_H:
                        g = pal["glow"]
                        px[x, y] = (g[0], g[1], g[2], int(235 * fade))
        frames.append(f)
    return frames

def build_dive_start(up, down, n=4):
    """Tuck and tip into the dive. Hit frame 3 @12fps."""
    frames = []
    for i in range(n):
        k = i / (n - 1)
        spr = wing_blend(up, down, 0.1 + 0.2 * k)
        spr = squash(spr, 1.0 - 0.25 * k, 1.0 + 0.1 * k)
        spr = spr.rotate(-22 * k, expand=True, resample=Image.NEAREST)
        frames.append(place_center(frame(), spr, dx=3 * k, dy=4 * k))
    return frames

def build_dive_loop(up, down, n=3):
    frames = []
    for i in range(n):
        spr = wing_blend(up, down, 0.25)
        spr = squash(spr, 0.75, 1.1)
        spr = spr.rotate(-32, expand=True, resample=Image.NEAREST)
        frames.append(place_center(frame(), spr, dx=2, dy=6 + (1 if i % 2 else 0)))
    return frames

def build_dive_recover(up, down, n=6):
    frames = []
    for i in range(n):
        k = i / (n - 1)
        spr = wing_blend(up, down, 0.8 - 0.6 * k)
        spr = spr.rotate(-30 * (1 - k), expand=True, resample=Image.NEAREST)
        frames.append(place_center(frame(), spr, dy=6 - 10 * k))
    return frames

def build_hurt(up, down, n=4):
    frames = []
    for i in range(n):
        t = i / (n - 1)
        k = 1.0 - t
        spr = flash_red(wing_blend(up, down, 0.3), 0.62 * k)
        frames.append(place_center(frame(), spr, dx=-4 * k, dy=2 * k))
    return frames

def build_death_fall(up, down, n=10):
    """Red flash, wings crumple, tumbling fall."""
    frames = []
    for i in range(n):
        t = i / (n - 1)
        spr = wing_blend(up, down, 0.6)
        if t < 0.3:
            spr = flash_red(spr, 0.55 * (1 - t / 0.3))
        spr = squash(spr, 1.0 - 0.3 * t, 1.0 - 0.2 * t)
        spr = spr.rotate(-140 * t, expand=True, resample=Image.NEAREST)
        dy = -4 + 34 * t * t
        frames.append(place_center(frame(), spr, dy=dy))
    return frames

def build_death_impact(base, n=6):
    """Dust ring where the bat hits the floor."""
    pal = palette_of(base)
    rng = random.Random(7)
    puffs = [(rng.uniform(-16, 16), rng.uniform(2, 12), rng.uniform(0.0, 0.3),
              pal["lite"] if rng.random() < 0.5 else pal["mid"]) for _ in range(15)]
    frames = []
    floor_y = CY + 34
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
            size = 2 if k < 0.5 else 1
            for dx in range(size):
                for dy2 in range(size):
                    if 0 <= x + dx < FRAME_W and 0 <= y + dy2 < FRAME_H:
                        px[x + dx, y + dy2] = col[:3] + (a,)
        frames.append(f)
    return frames

def main(up_path, down_path, hang_path, out_dir):
    up = load(up_path)
    down = load(down_path)
    hang = load(hang_path)
    os.makedirs(out_dir, exist_ok=True)
    death_fall = build_death_fall(up, down)
    anims = {
        "idle": (build_idle(up, down), {"fps": 8, "loop": True}, "bat_idle_hover.png"),
        "move": (build_move(up, down), {"fps": 12, "loop": True}, "bat_fly_move.png"),
        "hang_idle": (build_hang_idle(hang), {"fps": 6, "loop": True}, "bat_hang_idle.png"),
        "wake_up": (build_wake_up(hang, up), {"fps": 10, "loop": False}, "bat_wake_up.png"),
        "hurt": (build_hurt(up, down), {"fps": 14, "loop": False}, "bat_hurt.png"),
        "attack_1": (build_attack_bite(up, down), {"fps": 14, "loop": False,
                     "hit_frames": [4, 5], "hit_frames_1based": [5, 6]}, "bat_bite_attack.png"),
        "attack_2": (build_sonic(up, down, up), {"fps": 12, "loop": False,
                     "projectile_frames": [5], "projectile_frames_1based": [6]}, "bat_sonic_cast.png"),
        "attack_3": (build_dive_start(up, down), {"fps": 12, "loop": False,
                     "hit_frames": [3], "hit_frames_1based": [4]}, "bat_dive_start.png"),
        "dive_loop": (build_dive_loop(up, down), {"fps": 14, "loop": True}, "bat_dive_loop.png"),
        "dive_recover": (build_dive_recover(up, down), {"fps": 12, "loop": False}, "bat_dive_recover.png"),
        "death": (death_fall, {"fps": 12, "loop": False}, "bat_death_fall.png"),
        "death_fall": (death_fall, {"fps": 12, "loop": False}, "bat_death_fall.png"),
        "death_impact": (build_death_impact(up), {"fps": 12, "loop": False}, "bat_death_impact.png"),
    }
    meta = {
        "frame_size": [FRAME_W, FRAME_H],
        "facing": "right",
        "anchor": {"x": CX, "y": CY},
        "ground_clearance": 1.0,
        "frame_indexing": "0-based",
        "animations": {},
    }
    written = set()
    for state, (frames, extra, fname) in anims.items():
        if fname not in written:
            strip(frames).save(os.path.join(out_dir, fname))
            written.add(fname)
        entry = {"file": fname, "frames": len(frames)}
        entry.update(extra)
        meta["animations"][state] = entry
    with open(os.path.join(out_dir, "bat_anim.json"), "w") as fh:
        json.dump(meta, fh, indent=1)
    print("written", out_dir, {k: len(v[0]) for k, v in anims.items()})

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
