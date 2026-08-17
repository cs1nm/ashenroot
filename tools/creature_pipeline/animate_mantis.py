#!/usr/bin/env python3
"""Procedural animation for the root-mantis (root_crawler redesign).

Uses three authored key poses (idle / windup / strike) and derives every
strip from them with pixel-safe offsets, squash and the shared RED damage
flash. Pack layout matches the engine contract for root_crawler:
frames 160x96, anchor x=80 y=89, hit frames attack_1=7, attack_2=11,
attack_3=14 @ fps 14, states incl. whip_impact + burrow_dust.
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

def bob(im, phase, amp=1.5):
    """Subtle vertical breathing via whole-sprite squash."""
    sy = 1.0 + (amp / im.height) * math.sin(phase)
    sx = 1.0 - (amp * 0.6 / im.width) * math.sin(phase)
    return squash(im, sx, sy)

def palette_of(base):
    px = base.load()
    cols = [px[x, y] for y in range(base.height) for x in range(base.width) if px[x, y][3] > 0]
    cols.sort(key=lambda c: c[0] + c[1] + c[2])
    return {
        "dark": cols[max(0, len(cols) // 10)][:3] + (255,),
        "mid": cols[len(cols) // 2][:3] + (255,),
        "lite": cols[int(len(cols) * 0.86)][:3] + (255,),
        "glow": (244, 170, 70, 255),
    }

def strip(frames):
    out = Image.new("RGBA", (FRAME_W * len(frames), FRAME_H), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.alpha_composite(f, (i * FRAME_W, 0))
    return out

# Pose alignment offsets: windup coils back, strike lunges forward.
IDLE_DX, WINDUP_DX, STRIKE_DX = 0, -6, 8

def build_idle(idle, n=10):
    frames = []
    for i in range(n):
        t = i / n * 2 * math.pi
        frames.append(place(frame(), bob(idle, t), dx=IDLE_DX))
    return frames

def build_move(idle, n=16):
    """Stalking scuttle: lean forward, quick bob, small advance pulses."""
    frames = []
    for i in range(n):
        t = i / n
        phase = t * 2 * math.pi * 2.0
        spr = bob(idle, phase, amp=2.2)
        dx = IDLE_DX + 3 * math.sin(phase)          # push pulses
        dy = -abs(2.0 * math.sin(phase))            # tiny skitter hop
        frames.append(place(frame(), spr, dx=dx, dy=dy))
    return frames

def build_attack_slash(idle, windup, strike, n=14):
    """attack_1: one fast scythe slash. Hit frames 7-8."""
    frames = []
    for i in range(n):
        if i < 4:                       # coil back
            k = i / 3
            spr = tint(windup, (1.0 + 0.05 * k, 1.0, 0.95))
            frames.append(place(frame(), spr, dx=WINDUP_DX - 2 * k))
        elif i < 7:                     # trembling hold
            spr = tint(windup, (1.08, 1.02, 0.92), 1.03)
            frames.append(place(frame(), spr, dx=WINDUP_DX - 2 + (1 if i % 2 else -1)))
        elif i < 9:                     # STRIKE (hit frames 7-8)
            spr = tint(strike, (1.06, 1.0, 0.95), 1.05)
            frames.append(place(frame(), spr, dx=STRIKE_DX + 3 * (i - 7)))
        elif i < 11:                    # blades planted
            frames.append(place(frame(), strike, dx=STRIKE_DX + 4))
        else:                           # recover
            k = (i - 11) / (n - 12)
            pose = strike if k < 0.5 else idle
            dx = (STRIKE_DX + 4) * (1 - k) + IDLE_DX * k
            frames.append(place(frame(), pose, dx=dx))
    return frames

def build_attack_double(idle, windup, strike, n=20):
    """attack_2: high double slam with a long telegraph. Hit frames 11-12."""
    frames = []
    for i in range(n):
        if i < 6:                       # slow rise into windup
            k = i / 5
            pose = idle if k < 0.4 else windup
            dx = IDLE_DX * (1 - k) + WINDUP_DX * k
            frames.append(place(frame(), pose, dx=dx, dy=-2 * k))
        elif i < 11:                    # hold high, shiver + glow build
            k = (i - 6) / 4
            spr = tint(windup, (1.0 + 0.14 * k, 1.0 + 0.05 * k, 0.9), 1.0 + 0.05 * k)
            frames.append(place(frame(), spr, dx=WINDUP_DX + (1 if i % 2 else -1) * (1 + int(k)), dy=-3))
        elif i < 13:                    # SLAM (hit frames 11-12)
            spr = tint(strike, (1.1, 1.02, 0.9), 1.06)
            frames.append(place(frame(), spr, dx=STRIKE_DX + 4, dy=1))
        elif i < 15:                    # ground shudder
            frames.append(place(frame(), strike, dx=STRIKE_DX + 4 + (1 if i % 2 else -1), dy=1))
        else:                           # recover
            k = (i - 15) / (n - 16)
            pose = strike if k < 0.4 else idle
            dx = (STRIKE_DX + 4) * (1 - k) + IDLE_DX * k
            frames.append(place(frame(), pose, dx=dx))
    return frames

def build_attack_burrow(idle, windup, strike, n=22):
    """attack_3: dig under, travel, erupt blades-first. Hit frames 14-15."""
    frames = []
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        if t < 0.25:                    # crouch + shiver
            k = t / 0.25
            spr = squash(windup, 1.0 + 0.05 * k, 1.0 - 0.12 * k)
            place(f, spr, dx=WINDUP_DX + (1 if i % 2 else -1) * int(1 + k * 2), dy=int(3 * k), clip_ground=True)
        elif t < 0.45:                  # sink underground
            k = (t - 0.25) / 0.2
            place(f, windup, dx=WINDUP_DX, dy=int(windup.height * k * 1.15) + 3, clip_ground=True)
        elif t < 0.6:                   # hidden
            pass
        else:                           # eruption, blades first (hit at 14-15 => t~0.63-0.68)
            k = (t - 0.6) / 0.4
            up = min(1.0, k * 1.7)
            spr = squash(strike, 1.0 - 0.05 * (1 - up), 1.0 + 0.12 * (1 - up))
            place(f, spr, dx=STRIKE_DX, dy=int(strike.height * (1.0 - up) * 1.15), clip_ground=True)
        frames.append(f)
    return frames

def build_hurt(idle, n=6):
    frames = []
    for i in range(n):
        t = i / (n - 1)
        k = 1.0 - t
        spr = flash_red(squash(idle, 1.0 + 0.05 * k, 1.0 - 0.08 * k), 0.62 * k)
        frames.append(place(frame(), spr, dx=IDLE_DX - 4 * k))
    return frames

def build_death(idle, windup, n=18):
    """Red flash, blades sag, body keels over and crumbles."""
    frames = []
    rng = random.Random(13)
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        if t < 0.2:
            k = t / 0.2
            spr = flash_red(idle, 0.55 * (1 - k))
            place(f, spr, dx=IDLE_DX)
        elif t < 0.45:                  # blades sag: use windup squashed lower
            k = (t - 0.2) / 0.25
            spr = squash(windup, 1.0 + 0.05 * k, 1.0 - 0.25 * k)
            spr = tint(spr, (1.0 - 0.1 * k, 1.0 - 0.12 * k, 1.0 - 0.15 * k))
            place(f, spr, dx=WINDUP_DX)
        else:                           # collapse + crumble
            k = (t - 0.45) / 0.55
            spr = squash(windup, 1.0 + 0.2 * k, max(0.18, 0.75 - 0.6 * k))
            spr = tint(spr, (1.0 - 0.3 * k, 1.0 - 0.32 * k, 1.0 - 0.35 * k), 1.0 - 0.35 * k)
            if k > 0.5:
                px = spr.load()
                for yy in range(spr.height):
                    for xx in range(spr.width):
                        if px[xx, yy][3] and rng.random() < (k - 0.5) * 1.9 * (1.0 - yy / spr.height):
                            px[xx, yy] = (0, 0, 0, 0)
            place(f, spr, dx=WINDUP_DX)
        frames.append(f)
    return frames

def build_whip_impact(base, n=8):
    """Amber slash arc + splinters where the blades land."""
    pal = palette_of(base)
    rng = random.Random(5)
    parts = [(rng.uniform(-6, 22), rng.uniform(5, 24), rng.uniform(0.0, 0.25),
              pal["lite"] if rng.random() < 0.5 else pal["mid"]) for _ in range(15)]
    frames = []
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        px = f.load()
        # crescent slash flash on early frames
        if t < 0.45:
            fade = 1.0 - t / 0.45
            for a_step in range(26):
                ang = math.pi * 0.15 + (math.pi * 0.55) * a_step / 25
                rr = 20 + 6 * math.sin(a_step / 25 * math.pi)
                x = ANCHOR_X + 8 + round(math.cos(ang) * rr)
                y = GROUND - 12 - round(math.sin(ang) * rr * 0.8)
                if 0 <= x < FRAME_W and 0 <= y < FRAME_H:
                    g = pal["glow"]
                    px[x, y] = (g[0], g[1], g[2], int(230 * fade))
        for ox, h, delay, col in parts:
            k = max(0.0, min(1.0, (t - delay) / 0.6))
            if k <= 0.0:
                continue
            x = ANCHOR_X + 8 + round(ox * (0.6 + 0.6 * k))
            y = GROUND - round(h * math.sin(k * math.pi))
            a = int(255 * (1.0 - k * 0.55))
            size = 2 if k < 0.6 else 1
            for dx in range(size):
                for dy in range(size):
                    if 0 <= x + dx < FRAME_W and 0 <= y + dy < FRAME_H:
                        px[x + dx, y + dy] = col[:3] + (a,)
        frames.append(f)
    return frames

def build_burrow_dust(base, n=10):
    pal = palette_of(base)
    rng = random.Random(9)
    puffs = [(rng.uniform(-22, 22), rng.uniform(3, 16), rng.uniform(0.0, 0.35),
              pal["lite"] if rng.random() < 0.5 else pal["mid"]) for _ in range(20)]
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

def main(idle_path, windup_path, strike_path, out_dir):
    idle = load(idle_path)
    windup = load(windup_path)
    strike = load(strike_path)
    os.makedirs(out_dir, exist_ok=True)
    anims = {
        "idle": (build_idle(idle), {"fps": 7, "loop": True}),
        "move": (build_move(idle), {"fps": 14, "loop": True}),
        "attack_1": (build_attack_slash(idle, windup, strike), {"fps": 14, "loop": False,
                     "hit_frames": [7, 8], "hit_frames_1based": [8, 9]}),
        "attack_2": (build_attack_double(idle, windup, strike), {"fps": 14, "loop": False,
                     "hit_frames": [11, 12], "hit_frames_1based": [12, 13]}),
        "attack_3": (build_attack_burrow(idle, windup, strike), {"fps": 14, "loop": False,
                     "hit_frames": [14, 15], "hit_frames_1based": [15, 16]}),
        "hurt": (build_hurt(idle), {"fps": 14, "loop": False}),
        "death": (build_death(idle, windup), {"fps": 12, "loop": False}),
        "whip_impact": (build_whip_impact(idle), {"fps": 14, "loop": False}),
        "burrow_dust": (build_burrow_dust(idle), {"fps": 14, "loop": False}),
    }
    meta = {
        "frame_size": [FRAME_W, FRAME_H],
        "facing": "right",
        "anchor": {"x": ANCHOR_X, "y": GROUND},
        "ground_clearance": 1.0,
        "frame_indexing": "0-based",
        "animations": {},
    }
    file_prefix = {"whip_impact": "root_whip_impact.png", "burrow_dust": "root_burrow_dust.png"}
    for state, (frames, extra) in anims.items():
        fname = file_prefix.get(state, f"root_crawler_{state}.png")
        strip(frames).save(os.path.join(out_dir, fname))
        entry = {"file": fname, "frames": len(frames)}
        entry.update(extra)
        meta["animations"][state] = entry
    with open(os.path.join(out_dir, "rootcrawler_anim.json"), "w") as fh:
        json.dump(meta, fh, indent=1)
    print("written", out_dir, {k: len(v[0]) for k, v in anims.items()})

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
