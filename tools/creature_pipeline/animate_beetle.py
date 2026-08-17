#!/usr/bin/env python3
"""Procedural animation for the mushroom beetle (mushroom halls walker).

Built from three authored key poses:
  idle   — standing beetle with mushroom-cap shell
  charge — cap lowered like a ram shield
  spit   — reared up, mandibles open with poison glow

Pack layout matches the engine contract for mushroom_beetle: frames 128x96,
anchor x=64 y=89, attack_1 bite 8f hit 4-5 @14, attack_2 charge 10f hit 6-7
@12 with dust_vfx, attack_3 poison glob 10f release 5 @12 (spawn 120,70)
with poison_projectile + poison_impact strips. Damage feedback is RED per
docs/CREATURE_ANIMATION_PIPELINE.md; poison glows lime-green.
"""
import json, math, os, random, sys
from PIL import Image

FRAME_W = 128
FRAME_H = 96
GROUND = 89
ANCHOR_X = 64
POISON = (168, 232, 110, 255)

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
    }

def strip(frames):
    out = Image.new("RGBA", (FRAME_W * len(frames), FRAME_H), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.alpha_composite(f, (i * FRAME_W, 0))
    return out

def build_idle(idle, n=8):
    frames = []
    for i in range(n):
        t = i / n * 2 * math.pi
        sy = 1.0 + 0.03 * math.sin(t)
        sx = 1.0 - 0.02 * math.sin(t)
        frames.append(place(frame(), squash(idle, sx, sy)))
    return frames

def build_move(idle, n=10):
    """Scuttling walk with leg-implied body jitter."""
    frames = []
    for i in range(n):
        t = i / n
        phase = t * 2 * math.pi * 2.0
        spr = squash(idle, 1.0 + 0.02 * math.sin(phase), 1.0 - 0.045 * abs(math.sin(phase)))
        # Legs churn via body compression; the shell never leaves the ground.
        frames.append(place(frame(), spr, dx=1.5 * math.sin(phase)))
    return frames

def build_alert(idle, n=5):
    frames = []
    for i in range(n):
        k = i / (n - 1)
        spr = squash(idle, 1.0 - 0.03 * k, 1.0 + 0.05 * k)
        if k > 0.4:
            spr = tint(spr, (1.0, 1.0 + 0.06, 1.0), 1.03)
        frames.append(place(frame(), spr, dx=(1 if i % 2 else -1) * (1 if k > 0.3 else 0)))
    return frames

def build_hurt(idle, n=4):
    frames = []
    for i in range(n):
        t = i / (n - 1)
        k = 1.0 - t
        spr = flash_red(squash(idle, 1.0 + 0.05 * k, 1.0 - 0.07 * k), 0.62 * k)
        frames.append(place(frame(), spr, dx=-4 * k))
    return frames

def build_stunned(idle, n=4):
    frames = []
    for i in range(n):
        t = i / n * 2 * math.pi
        spr = tint(squash(idle, 1.03, 0.94), (0.85, 0.85, 0.85))
        frames.append(place(frame(), spr, dx=round(2.0 * math.sin(t)), dy=1))
    return frames

def build_attack_bite(idle, n=8):
    """Mandible snap: rear back slightly, snap forward at 4-5."""
    frames = []
    for i in range(n):
        if i < 3:
            k = i / 2
            spr = squash(idle, 1.0 + 0.05 * k, 1.0 - 0.06 * k)
            frames.append(place(frame(), spr, dx=-4 * k))
        elif i < 6:                    # snap (hit 4-5)
            k = (i - 3) / 2
            spr = tint(squash(idle, 1.0 - 0.03, 1.0 + 0.03), (1.05, 1.05, 1.0), 1.03)
            frames.append(place(frame(), spr, dx=-4 + 13 * k))
        else:
            k = (i - 6) / 1
            frames.append(place(frame(), idle, dx=9 * (1 - k)))
    return frames

def build_attack_charge(idle, charge, n=10):
    """Cap-first ram: crouch, lower the cap, thunder forward at 6-7."""
    frames = []
    for i in range(n):
        if i < 3:                      # crouch + aim
            k = i / 2
            pose = idle if k < 0.4 else charge
            frames.append(place(frame(), pose, dx=-5 * k))
        elif i < 6:                    # revving shudder
            spr = tint(charge, (1.03, 1.03, 1.0), 1.02)
            frames.append(place(frame(), spr, dx=-5 + (1 if i % 2 else -1)))
        elif i < 8:                    # RAM (hit 6-7)
            k = (i - 6) / 1
            spr = squash(charge, 1.06, 0.96)
            frames.append(place(frame(), spr, dx=2 + 16 * k))
        else:                          # skid recover
            k = (i - 8) / (n - 9)
            pose = charge if k < 0.5 else idle
            frames.append(place(frame(), pose, dx=18 * (1 - k)))
    return frames

def build_dust_vfx(base, n=6):
    """Charge dust kicked behind the beetle."""
    pal = palette_of(base)
    rng = random.Random(7)
    puffs = [(rng.uniform(-30, -6), rng.uniform(2, 12), rng.uniform(0.0, 0.3),
              pal["lite"] if rng.random() < 0.5 else pal["mid"]) for _ in range(14)]
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
            a = int(235 * (1.0 - k * 0.7))
            size = 2 if k < 0.5 else 1
            for dx in range(size):
                for dy in range(size):
                    if 0 <= x + dx < FRAME_W and 0 <= y + dy < FRAME_H:
                        px[x + dx, y + dy] = col[:3] + (a,)
        frames.append(f)
    return frames

def build_attack_spit(idle, spit, n=10):
    """Rear up, gather lime glow, release the glob at frame 5."""
    frames = []
    for i in range(n):
        if i < 3:                      # rear up
            k = i / 2
            pose = idle if k < 0.35 else spit
            frames.append(place(frame(), pose, dx=-2 * k))
        elif i < 5:                    # gather: green glow build + shiver
            k = (i - 3) / 1
            spr = tint(spit, (1.0, 1.0 + 0.08 * (k + 1), 1.0), 1.02)
            frames.append(place(frame(), spr, dx=-2 + (1 if i % 2 else -1)))
        elif i < 7:                    # release (projectile leaves at 5)
            spr = squash(spit, 1.04, 0.96)
            frames.append(place(frame(), spr, dx=2))
        else:                          # settle back down
            k = (i - 7) / (n - 8)
            pose = spit if k < 0.4 else idle
            frames.append(place(frame(), pose, dx=2 * (1 - k)))
    return frames

def build_poison_projectile(n=6):
    """Wobbling lime glob with a drip trail."""
    frames = []
    for i in range(n):
        f = frame()
        px = f.load()
        t = i / n
        wob = math.sin(t * 2 * math.pi)
        cx, cy = ANCHOR_X, 48
        rr = 4 + (1 if i % 2 else 0)
        for y in range(-rr, rr + 1):
            half = int((rr * rr - y * y) ** 0.5)
            for x in range(-half, half + 1):
                col = POISON if abs(y) < rr - 1 else (110, 170, 70, 255)
                xx, yy = cx + x, cy + y + round(wob)
                if 0 <= xx < FRAME_W and 0 <= yy < FRAME_H:
                    px[xx, yy] = col[:3] + (255,)
        for t_i in range(3):           # drip trail
            x = cx - 7 - t_i * 5
            y = cy + round(wob) + t_i
            if 0 <= x < FRAME_W and 0 <= y < FRAME_H:
                px[x, y] = POISON[:3] + (int(160 - t_i * 45),)
        frames.append(f)
    return frames

def build_poison_impact(n=8):
    """Glob splatter: lime droplets burst and settle into a puddle."""
    rng = random.Random(13)
    drops = [(rng.uniform(0, 2 * math.pi), rng.uniform(4, 16), rng.uniform(0.0, 0.2)) for _ in range(14)]
    frames = []
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        px = f.load()
        for ang, dist, delay in drops:
            k = max(0.0, min(1.0, (t - delay) / 0.6))
            if k <= 0.0:
                continue
            x = ANCHOR_X + round(math.cos(ang) * dist * k)
            y = GROUND - 6 - round(abs(math.sin(ang)) * dist * k * 0.8) + round(8 * k * k)
            a = int(240 * (1.0 - k * 0.6))
            if 0 <= x < FRAME_W and 0 <= y < FRAME_H:
                px[x, y] = POISON[:3] + (a,)
        # settling puddle
        if t > 0.4:
            w = round(16 * min(1.0, (t - 0.4) / 0.5))
            for x in range(ANCHOR_X - w, ANCHOR_X + w + 1):
                if 0 <= x < FRAME_W:
                    px[x, GROUND - 1] = POISON[:3] + (int(200 * (1.0 - t * 0.5)),)
        frames.append(f)
    return frames

def build_death(idle, n=11):
    """Red flash, cap cracks off and rolls, body crumples."""
    frames = []
    rng = random.Random(21)
    cap_h = int(idle.height * 0.55)
    cap = idle.crop((0, 0, idle.width, cap_h))
    body = idle.crop((0, cap_h, idle.width, idle.height))
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        if t < 0.2:
            k = t / 0.2
            spr = flash_red(idle, 0.55 * (1 - k))
            place(f, spr)
        else:
            k = (t - 0.2) / 0.8
            # body crumples flat
            bh = max(3, round(body.height * (1.0 - 0.7 * k)))
            bspr = tint(body.resize((body.width, bh), Image.NEAREST),
                        (1.0 - 0.3 * k, 1.0 - 0.3 * k, 1.0 - 0.3 * k), 1.0 - 0.3 * k)
            if k > 0.55:
                px = bspr.load()
                for yy in range(bspr.height):
                    for xx in range(bspr.width):
                        if px[xx, yy][3] and rng.random() < (k - 0.55) * 1.8:
                            px[xx, yy] = (0, 0, 0, 0)
            f.alpha_composite(bspr, (ANCHOR_X - body.width // 2, GROUND - bh))
            # cap tips off and rolls to the side
            cap_spun = cap.rotate(-70 * k, expand=True, resample=Image.NEAREST)
            cap_spun = tint(cap_spun, (1.0 - 0.25 * k, 1.0 - 0.25 * k, 1.0 - 0.25 * k))
            f.alpha_composite(cap_spun, (ANCHOR_X - cap.width // 2 + round(18 * k),
                                         GROUND - bh - cap_spun.height + round(6 * k)))
        frames.append(f)
    return frames

def main(idle_path, charge_path, spit_path, out_dir):
    idle = load(idle_path)
    charge = load(charge_path)
    spit = load(spit_path)
    os.makedirs(out_dir, exist_ok=True)
    anims = {
        "idle": (build_idle(idle), {"fps": 7, "loop": True}, "idle.png"),
        "move": (build_move(idle), {"fps": 10, "loop": True}, "move.png"),
        "alert": (build_alert(idle), {"fps": 10, "loop": False}, "alert.png"),
        "hurt": (build_hurt(idle), {"fps": 14, "loop": False}, "hurt.png"),
        "stunned": (build_stunned(idle), {"fps": 6, "loop": True}, "stunned.png"),
        "attack_1": (build_attack_bite(idle), {"fps": 14, "loop": False,
                     "hit_frames": [4, 5], "hit_frames_1based": [5, 6]}, "attack_1_bite.png"),
        "attack_2": (build_attack_charge(idle, charge), {"fps": 12, "loop": False,
                     "hit_frames": [6, 7], "hit_frames_1based": [7, 8]}, "attack_2_charge.png"),
        "dust_vfx": (build_dust_vfx(idle), {"fps": 12, "loop": False}, "dust_vfx.png"),
        "attack_3": (build_attack_spit(idle, spit), {"fps": 12, "loop": False,
                     "projectile_frames": [5], "projectile_frames_1based": [6],
                     "projectile_spawn": [120, 70]}, "attack_3_poison_glob.png"),
        "poison_projectile": (build_poison_projectile(), {"fps": 14, "loop": True}, "poison_projectile.png"),
        "poison_impact": (build_poison_impact(), {"fps": 14, "loop": False}, "poison_impact.png"),
        "death": (build_death(idle), {"fps": 10, "loop": False}, "death.png"),
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
    with open(os.path.join(out_dir, "mushroom_beetle_anim.json"), "w") as fh:
        json.dump(meta, fh, indent=1)
    print("written", out_dir, {k: len(v[0]) for k, v in anims.items()})

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
