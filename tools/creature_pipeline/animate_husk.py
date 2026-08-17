#!/usr/bin/env python3
"""Procedural animation for the cave husk (hunched stone humanoid).

Built from four authored key poses:
  idle  — hunched stand
  reach — claw arm fully extended forward
  throw — arm raised overhead with a boulder
  slam  — crouched, both claws smashed into the ground

Pack layout matches the engine contract for cave_husk:
frames 160x96, anchor x=80 y=89, states incl. alert/stunned/VFX layers,
attack_1 reach 8f hit 4-5 @9.4, attack_2 rock throw 10f release 5 @9.7
(projectile_spawn 112,46), attack_3 slam 8f hit 5 @8.2. Damage feedback is
RED per docs/CREATURE_ANIMATION_PIPELINE.md.
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

def place(canvas, sprite, dx=0, dy=0):
    x = ANCHOR_X - sprite.width // 2 + round(dx)
    y = GROUND - sprite.height + round(dy)
    canvas.alpha_composite(sprite, (max(0, min(FRAME_W - sprite.width, x)), max(0, y)))
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

def breathe(base, phase, amp=1.5):
    sy = 1.0 + (amp / base.height) * math.sin(phase)
    sx = 1.0 - (amp * 0.5 / base.width) * math.sin(phase)
    return squash(base, sx, sy)

def build_idle(idle, n=6):
    frames = []
    for i in range(n):
        t = i / n * 2 * math.pi
        frames.append(place(frame(), breathe(idle, t)))
    return frames

def build_move(idle, n=8):
    """Heavy shamble: lurching steps with body dip."""
    frames = []
    for i in range(n):
        t = i / n
        phase = t * 2 * math.pi * 2.0
        spr = breathe(idle, phase, amp=2.0)
        lean = squash(spr, 1.0 + 0.03 * math.sin(phase), 1.0 - 0.05 * abs(math.sin(phase)))
        # Weight stays planted: the walk reads through body compression,
        # not through leaving the ground (which looked like floating).
        frames.append(place(frame(), lean, dx=1.5 * math.sin(phase)))
    return frames

def build_alert(idle, n=5):
    """Snap upright, shards rattle, face crack flares."""
    frames = []
    for i in range(n):
        k = i / (n - 1)
        spr = squash(idle, 1.0 - 0.04 * k, 1.0 + 0.06 * k)
        if k > 0.4:
            spr = tint(spr, (1.0 + 0.04, 1.0 + 0.06, 1.0 + 0.10), 1.03)
        frames.append(place(frame(), spr, dx=(1 if i % 2 else -1) * (1 if k > 0.3 else 0)))
    return frames

def build_hurt(idle, n=3):
    frames = []
    for i in range(n):
        t = i / (n - 1)
        k = 1.0 - t
        spr = flash_red(squash(idle, 1.0 + 0.05 * k, 1.0 - 0.07 * k), 0.62 * k)
        frames.append(place(frame(), spr, dx=-4 * k))
    return frames

def build_stunned(idle, n=4):
    """Sagging wobble with dimmed glow."""
    frames = []
    for i in range(n):
        t = i / n * 2 * math.pi
        spr = squash(idle, 1.0 + 0.05, 1.0 - 0.10)
        spr = tint(spr, (0.85, 0.85, 0.88))
        frames.append(place(frame(), spr, dx=round(2.0 * math.sin(t)), dy=2))
    return frames

def build_attack_reach(idle, reach, n=8):
    """Claw reach: coil back, lunge with the extended arm at 4-5."""
    frames = []
    for i in range(n):
        if i < 3:                      # coil
            k = i / 2
            spr = squash(idle, 1.0 + 0.06 * k, 1.0 - 0.08 * k)
            frames.append(place(frame(), spr, dx=-5 * k))
        elif i < 6:                    # lunge (hit 4-5)
            k = (i - 3) / 2
            spr = tint(reach, (1.04, 1.04, 1.06), 1.03)
            frames.append(place(frame(), spr, dx=-5 + 16 * k))
        else:                          # recover
            k = (i - 6) / 1
            pose = reach if k < 0.5 else idle
            frames.append(place(frame(), pose, dx=11 * (1 - k)))
    return frames

def build_reach_vfx(base, n=8):
    """Claw swipe streaks aligned with the lunge frames."""
    pal = palette_of(base)
    frames = []
    for i in range(n):
        f = frame()
        if 4 <= i <= 6:
            px = f.load()
            k = (i - 4) / 2
            fade = 1.0 - k * 0.7
            for s_i in range(3):
                for a_step in range(16):
                    ang = -0.5 + 1.0 * a_step / 15
                    rr = 16 + s_i * 5 + k * 8
                    x = ANCHOR_X + 26 + round(math.cos(ang) * rr)
                    y = GROUND - 30 + round(math.sin(ang) * rr)
                    if 0 <= x < FRAME_W and 0 <= y < FRAME_H:
                        col = pal["lite"] if s_i % 2 == 0 else pal["glow"]
                        px[x, y] = col[:3] + (int(200 * fade),)
        frames.append(f)
    return frames

def build_attack_throw(idle, throw, n=10):
    """Boulder throw: heave up, hold, release at frame 5, follow through."""
    frames = []
    for i in range(n):
        if i < 3:                      # heave the rock up
            k = i / 2
            pose = idle if k < 0.35 else throw
            spr = squash(pose, 1.0, 1.0 - 0.04 * (1 - k))
            frames.append(place(frame(), spr, dx=-3 * k))
        elif i < 5:                    # aim hold, shiver
            spr = tint(throw, (1.03, 1.04, 1.07), 1.02)
            frames.append(place(frame(), spr, dx=-3 + (1 if i % 2 else -1)))
        elif i < 7:                    # release (projectile leaves at 5)
            k = (i - 5) / 1
            spr = squash(throw, 1.0 + 0.05 * k, 1.0 - 0.05 * k)
            frames.append(place(frame(), spr, dx=4 * k))
        else:                          # follow-through back to idle
            k = (i - 7) / (n - 8)
            pose = throw if k < 0.4 else idle
            frames.append(place(frame(), pose, dx=4 * (1 - k)))
    return frames

def build_rock_projectile(base, n=6):
    """Spinning boulder with a faint trail."""
    pal = palette_of(base)
    rock = Image.new("RGBA", (14, 12), (0, 0, 0, 0))
    rp = rock.load()
    for y in range(12):
        for x in range(14):
            ddx = (x - 7) / 7.0
            ddy = (y - 6) / 6.0
            if ddx * ddx + ddy * ddy <= 1.0:
                if ddy < -0.35:
                    rp[x, y] = pal["lite"]
                elif ddy > 0.45:
                    rp[x, y] = pal["dark"]
                else:
                    rp[x, y] = pal["mid"]
    frames = []
    for i in range(n):
        f = frame()
        spun = rock.rotate(-60 * i, expand=True, resample=Image.NEAREST)
        f.alpha_composite(spun, (ANCHOR_X - spun.width // 2, 44 - spun.height // 2))
        px = f.load()
        for t_i in range(3):
            x = ANCHOR_X - 10 - t_i * 6
            y = 44 + (1 if (i + t_i) % 2 else -1)
            if 0 <= x < FRAME_W:
                col = pal["mid"]
                px[x, y] = col[:3] + (int(150 - t_i * 45),)
        frames.append(f)
    return frames

def build_rock_impact(base, n=7):
    """Boulder shatters: shards + dust."""
    pal = palette_of(base)
    rng = random.Random(23)
    shards = [(rng.uniform(0, 2 * math.pi), rng.uniform(5, 18), rng.uniform(0.0, 0.2),
               pal["lite"] if rng.random() < 0.5 else pal["mid"]) for _ in range(14)]
    frames = []
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        px = f.load()
        for ang, dist, delay, col in shards:
            k = max(0.0, min(1.0, (t - delay) / 0.7))
            if k <= 0.0:
                continue
            x = ANCHOR_X + round(math.cos(ang) * dist * k)
            y = GROUND - 8 + round(math.sin(ang) * dist * k * 0.6) + round(6 * k * k)
            a = int(255 * (1.0 - k * 0.65))
            size = 2 if k < 0.5 else 1
            for dx in range(size):
                for dy in range(size):
                    if 0 <= x + dx < FRAME_W and 0 <= y + dy < FRAME_H:
                        px[x + dx, y + dy] = col[:3] + (a,)
        frames.append(f)
    return frames

def build_attack_slam(idle, slam, n=8):
    """Rise tall, then crash both claws down at frame 5."""
    frames = []
    for i in range(n):
        if i < 3:                      # rise up tall
            k = i / 2
            spr = squash(idle, 1.0 - 0.05 * k, 1.0 + 0.10 * k)
            frames.append(place(frame(), spr, dy=-2 * k))
        elif i < 5:                    # hold high, shiver
            spr = squash(idle, 0.95, 1.10)
            spr = tint(spr, (1.03, 1.04, 1.08), 1.02)
            frames.append(place(frame(), spr, dx=(1 if i % 2 else -1), dy=-2))
        elif i < 7:                    # SLAM down (hit 5)
            spr = squash(slam, 1.0 + 0.04, 1.0)
            frames.append(place(frame(), spr, dy=1))
        else:                          # settle
            frames.append(place(frame(), slam))
    return frames

def build_slam_vfx(base, n=8):
    """Ground shockwave ripple + dust burst on the slam frames."""
    pal = palette_of(base)
    rng = random.Random(31)
    puffs = [(rng.uniform(-26, 26), rng.uniform(3, 14), rng.uniform(0.0, 0.15),
              pal["lite"] if rng.random() < 0.5 else pal["mid"]) for _ in range(16)]
    frames = []
    for i in range(n):
        f = frame()
        if i >= 5:
            t = (i - 5) / max(1, n - 6)
            px = f.load()
            for direction in (-1, 1):
                x = ANCHOR_X + direction * round(8 + 30 * t)
                for w in range(3):
                    xx = x + direction * w
                    yy = GROUND - (2 - w if w < 2 else 0)
                    if 0 <= xx < FRAME_W and 0 <= yy < FRAME_H:
                        px[xx, yy] = pal["glow"][:3] + (int(220 * (1.0 - t)),)
            for ox, h, delay, col in puffs:
                k = max(0.0, min(1.0, (t - delay) / 0.7))
                if k <= 0.0:
                    continue
                x = ANCHOR_X + round(ox * (0.5 + 0.8 * k))
                y = GROUND - round(h * math.sin(k * math.pi))
                a = int(235 * (1.0 - k * 0.7))
                if 0 <= x < FRAME_W and 0 <= y < FRAME_H:
                    px[x, y] = col[:3] + (a,)
        frames.append(f)
    return frames

def build_death(idle, n=10):
    """Red flash, glow dies, the husk crumbles into rubble."""
    frames = []
    rng = random.Random(41)
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        if t < 0.2:
            k = t / 0.2
            spr = flash_red(idle, 0.55 * (1 - k))
            place(f, spr)
        else:
            k = (t - 0.2) / 0.8
            spr = squash(idle, 1.0 + 0.25 * k, max(0.15, 1.0 - 0.85 * k))
            spr = tint(spr, (1.0 - 0.3 * k, 1.0 - 0.32 * k, 1.0 - 0.3 * k), 1.0 - 0.35 * k)
            if k > 0.45:
                px = spr.load()
                for yy in range(spr.height):
                    for xx in range(spr.width):
                        if px[xx, yy][3] and rng.random() < (k - 0.45) * 1.7 * (1.0 - yy / spr.height):
                            px[xx, yy] = (0, 0, 0, 0)
            place(f, spr)
        frames.append(f)
    return frames

def build_death_vfx(base, n=10):
    """Escaping cyan motes as the animating spark leaves the husk."""
    pal = palette_of(base)
    rng = random.Random(47)
    motes = [(rng.uniform(-12, 12), rng.uniform(0.1, 0.5), rng.uniform(14, 40),
              rng.uniform(0.6, 1.3)) for _ in range(10)]
    frames = []
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        px = f.load()
        for ox, delay, rise, wobble in motes:
            k = max(0.0, min(1.0, (t - delay) / (1.0 - delay + 1e-5)))
            if k <= 0.0:
                continue
            x = ANCHOR_X + round(ox + math.sin(k * 6.0) * 3 * wobble)
            y = GROUND - 30 - round(rise * k)
            a = int(230 * (1.0 - k))
            if 0 <= x < FRAME_W and 0 <= y < FRAME_H:
                g = pal["glow"]
                px[x, y] = (g[0], g[1], g[2], a)
        frames.append(f)
    return frames

def main(idle_path, reach_path, throw_path, slam_path, out_dir):
    idle = load(idle_path)
    reach = load(reach_path)
    throw = load(throw_path)
    slam = load(slam_path)
    os.makedirs(out_dir, exist_ok=True)
    anims = {
        "idle": (build_idle(idle), {"fps": 7, "loop": True}, "cave_husk_idle_sheet.png"),
        "move": (build_move(idle), {"fps": 10, "loop": True}, "cave_husk_move_sheet.png"),
        "alert": (build_alert(idle), {"fps": 8.6, "loop": False}, "cave_husk_alert_sheet.png"),
        "hurt": (build_hurt(idle), {"fps": 12.3, "loop": False}, "cave_husk_hurt_sheet.png"),
        "stunned": (build_stunned(idle), {"fps": 6, "loop": True}, "cave_husk_stunned_sheet.png"),
        "attack_1": (build_attack_reach(idle, reach), {"fps": 9.4, "loop": False,
                     "hit_frames": [4, 5], "hit_frames_1based": [5, 6]}, "cave_husk_attack_reach_sheet.png"),
        "reach_vfx": (build_reach_vfx(idle), {"fps": 9.4, "loop": False}, "cave_husk_attack_reach_vfx_sheet.png"),
        "attack_2": (build_attack_throw(idle, throw), {"fps": 9.7, "loop": False,
                     "projectile_frames": [5], "projectile_frames_1based": [6],
                     "projectile_spawn": [112, 46]}, "cave_husk_throw_rock_sheet.png"),
        "rock_projectile": (build_rock_projectile(idle), {"fps": 12, "loop": True}, "cave_husk_rock_projectile_sheet.png"),
        "rock_impact": (build_rock_impact(idle), {"fps": 14.1, "loop": False}, "cave_husk_rock_impact_sheet.png"),
        "attack_3": (build_attack_slam(idle, slam), {"fps": 8.2, "loop": False,
                     "hit_frames": [5], "hit_frames_1based": [6]}, "cave_husk_attack_slam_sheet.png"),
        "slam_vfx": (build_slam_vfx(idle), {"fps": 8.2, "loop": False}, "cave_husk_attack_slam_vfx_sheet.png"),
        "death": (build_death(idle), {"fps": 5.9, "loop": False}, "cave_husk_death_sheet.png"),
        "death_vfx": (build_death_vfx(idle), {"fps": 5.9, "loop": False}, "cave_husk_death_vfx_sheet.png"),
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
    with open(os.path.join(out_dir, "cave_husk_anim.json"), "w") as fh:
        json.dump(meta, fh, indent=1)
    print("written", out_dir, {k: len(v[0]) for k, v in anims.items()})

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
