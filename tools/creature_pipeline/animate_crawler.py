#!/usr/bin/env python3
"""Procedural animation for long, low crawling creatures (root_crawler style).

Works from a single elongated base sprite. Movement is a traveling vertical
wave over pixel columns (inchworm crawl), attacks are head lunge, tail whip
and a burrow dive; hurt/death use the shared RED damage flash convention.

Frame layout matches the existing root_crawler pack: 160x96 frames,
anchor x=80 y=89, hit frames attack_1=7, attack_2=11, attack_3=14 @ fps 14.
"""
import json, math, os, random, sys
from PIL import Image

FRAME_W = 160
FRAME_H = 96
GROUND = 89
ANCHOR_X = 80

def load_base(path):
    im = Image.open(path).convert("RGBA")
    return im.crop(im.getbbox())

def frame():
    return Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))

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

def tint(sprite, factor_rgb, brightness=1.0):
    out = sprite.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            px[x, y] = (min(255, int(r * factor_rgb[0] * brightness)),
                        min(255, int(g * factor_rgb[1] * brightness)),
                        min(255, int(b * factor_rgb[2] * brightness)), a)
    return out

def column_wave(base, phase, amplitude, wavelength, head_lock=0.0):
    """Shift each pixel column vertically by a traveling sine wave.

    head_lock > 0 dampens the wave towards the head (right side) so the head
    stays readable while the body undulates.
    """
    out = Image.new("RGBA", (base.width, base.height + 2 * int(amplitude) + 2), (0, 0, 0, 0))
    for x in range(base.width):
        damp = 1.0
        if head_lock > 0.0:
            t = x / max(1, base.width - 1)
            damp = 1.0 - head_lock * max(0.0, t - 0.55) / 0.45 if t > 0.55 else 1.0
        dy = round(amplitude * damp * math.sin(2 * math.pi * (x / wavelength - phase)))
        col = base.crop((x, 0, x + 1, base.height))
        out.alpha_composite(col, (x, int(amplitude) + 1 + dy))
    return out.crop(out.getbbox()) if out.getbbox() else out

def squash(base, sx, sy):
    w = max(1, round(base.width * sx))
    h = max(1, round(base.height * sy))
    return base.resize((w, h), Image.NEAREST)

def place(canvas, sprite, dx=0, dy=0, clip_ground=False):
    x = ANCHOR_X - sprite.width // 2 + round(dx)
    y = GROUND - sprite.height + round(dy)
    canvas.alpha_composite(sprite, (max(0, min(FRAME_W - sprite.width, x)), y if y >= 0 else 0))
    if clip_ground:
        px = canvas.load()
        for yy in range(GROUND + 1, FRAME_H):
            for xx in range(FRAME_W):
                px[xx, yy] = (0, 0, 0, 0)
    return canvas

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

def build_idle(base, n=10):
    frames = []
    for i in range(n):
        t = i / n
        spr = column_wave(base, t, 1.6, base.width * 1.4, head_lock=0.7)
        frames.append(place(frame(), spr))
    return frames

def build_move(base, n=16):
    frames = []
    for i in range(n):
        t = i / n
        spr = column_wave(base, t * 2.0, 3.0, base.width * 0.6, head_lock=0.55)
        # slight inchworm push: body compresses and extends
        sx = 1.0 + 0.04 * math.sin(2 * math.pi * t * 2.0)
        spr = squash(spr, sx, 1.0)
        frames.append(place(frame(), spr))
    return frames

def build_attack_bite(base, n=14):
    """Head lunge bite. Telegraph 0-35%, hit frames 7-8, recover."""
    frames = []
    for i in range(n):
        t = i / (n - 1)
        if t < 0.35:
            k = t / 0.35
            spr = squash(base, 1.0 - 0.08 * k, 1.0 + 0.06 * k)
            spr = tint(spr, (1.03, 1.0, 0.95), 1.0 + 0.05 * k)
            dx = -6 * k
        elif t < 0.62:
            k = (t - 0.35) / 0.27
            spr = squash(base, 1.0 + 0.10 * math.sin(k * math.pi), 1.0 - 0.06 * math.sin(k * math.pi))
            dx = -6 + 22 * k
        else:
            k = (t - 0.62) / 0.38
            spr = base
            dx = 16 * (1 - k)
        frames.append(place(frame(), spr, dx=dx))
    return frames

def build_attack_whip(base, n=20):
    """Tail (left side) curls up then slams down; hit frames 11-12."""
    frames = []
    tail_w = int(base.width * 0.42)
    body = base.crop((tail_w, 0, base.width, base.height))
    tail = base.crop((0, 0, tail_w, base.height))
    for i in range(n):
        t = i / (n - 1)
        if t < 0.5:
            lift_k = math.sin(min(1.0, t / 0.45) * math.pi * 0.5)     # raise
        elif t < 0.62:
            lift_k = 1.0 - (t - 0.5) / 0.12                            # slam down fast
        else:
            lift_k = 0.0
        f = frame()
        # body stays planted, slightly braced
        bx = ANCHOR_X - base.width // 2 + tail_w
        f.alpha_composite(body, (bx, GROUND - body.height))
        # tail columns rotate up around the joint
        joint_x = bx
        for x in range(tail_w - 1, -1, -1):
            col = tail.crop((x, 0, x + 1, tail.height))
            dist = (tail_w - x) / tail_w
            dy = -round(34 * lift_k * dist * dist)
            dx_c = round(8 * lift_k * dist)
            f.alpha_composite(col, (joint_x - (tail_w - x) + dx_c, GROUND - tail.height + dy))
        if 0.5 <= t < 0.62:
            f = place(f, Image.new("RGBA", (1, 1), (0, 0, 0, 0)))  # no-op keep signature simple
        frames.append(f)
    return frames

def build_attack_burrow(base, n=22):
    """Dive underground, travel, resurface. Hit at frame 14 (emergence)."""
    frames = []
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        if t < 0.28:                     # shiver + nose down
            k = t / 0.28
            spr = column_wave(base, k * 0.5, 1.5, base.width, head_lock=0.0)
            place(f, spr, dx=(1 if i % 2 == 0 else -1) * int(1 + k * 2), dy=int(4 * k), clip_ground=True)
        elif t < 0.5:                    # sinking
            k = (t - 0.28) / 0.22
            place(f, base, dy=int(base.height * k * 1.1) + 4, clip_ground=True)
        elif t < 0.64:                   # hidden
            pass
        else:                            # emerge (hit lands here, frame 14 of 22 => t=0.667)
            k = (t - 0.64) / 0.36
            up = min(1.0, k * 1.6)
            spr = squash(base, 1.0 - 0.06 * (1 - up), 1.0 + 0.10 * (1 - up))
            place(f, spr, dy=int(base.height * (1.0 - up) * 1.1), clip_ground=True)
        frames.append(f)
    return frames

def build_hurt(base, n=6):
    frames = []
    for i in range(n):
        t = i / (n - 1)
        k = 1.0 - t
        spr = flash_red(squash(base, 1.0 + 0.05 * k, 1.0 - 0.08 * k), 0.62 * k)
        frames.append(place(frame(), spr, dx=-4 * k))
    return frames

def build_death(base, n=18):
    """Red flash, then the root body breaks into segments that collapse."""
    frames = []
    seg_count = 4
    seg_w = base.width // seg_count
    rng = random.Random(11)
    seg_data = [(s, rng.uniform(-1.5, 1.5), rng.uniform(0.8, 1.4)) for s in range(seg_count)]
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        if t < 0.22:
            k = t / 0.22
            spr = flash_red(base, 0.55 * (1 - k))
            place(f, spr)
        else:
            k = (t - 0.22) / 0.78
            fade = tint(base, (1.0 - 0.3 * k, 1.0 - 0.3 * k, 1.0 - 0.32 * k), 1.0 - 0.4 * k)
            for s, drift, speed in seg_data:
                x0 = s * seg_w
                x1 = base.width if s == seg_count - 1 else (s + 1) * seg_w
                seg = fade.crop((x0, 0, x1, base.height))
                drop_k = min(1.0, k * speed)
                sh = max(3, round(seg.height * (1.0 - 0.72 * drop_k)))
                seg = seg.resize((seg.width, sh), Image.NEAREST)
                if k > 0.55:              # crumble away
                    spx = seg.load()
                    for yy in range(seg.height):
                        for xx in range(seg.width):
                            if spx[xx, yy][3] and rng.random() < (k - 0.55) * 1.8 * (1.0 - yy / seg.height):
                                spx[xx, yy] = (0, 0, 0, 0)
                fx = ANCHOR_X - base.width // 2 + x0 + round(drift * k * 4)
                f.alpha_composite(seg, (fx, GROUND - seg.height))
        frames.append(f)
    return frames

def build_whip_impact(base, n=8):
    """Dust + splinters where the tail slams."""
    pal = palette_of(base)
    rng = random.Random(5)
    parts = [(rng.uniform(-16, 16), rng.uniform(4, 22), rng.uniform(0.0, 0.25),
              pal["lite" if rng.random() < 0.7 else "mid"]) for _ in range(16)]
    frames = []
    for i in range(n):
        t = i / (n - 1)
        f = frame()
        px = f.load()
        for ox, h, delay, col in parts:
            k = max(0.0, min(1.0, (t - delay) / 0.6))
            if k <= 0.0:
                continue
            rise = h * math.sin(k * math.pi)
            x = ANCHOR_X + round(ox * (0.6 + 0.6 * k))
            y = GROUND - round(rise)
            size = 2 if k < 0.6 else 1
            a = int(255 * (1.0 - k * 0.55))
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
              pal["lite" if rng.random() < 0.5 else "mid"]) for _ in range(20)]
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

def main(base_path, out_dir, name):
    base = load_base(base_path)
    os.makedirs(out_dir, exist_ok=True)
    anims = {
        "idle": (build_idle(base), {"fps": 7, "loop": True}),
        "move": (build_move(base), {"fps": 14, "loop": True}),
        "attack_1": (build_attack_bite(base), {"fps": 14, "loop": False,
                     "hit_frames": [7, 8], "hit_frames_1based": [8, 9]}),
        "attack_2": (build_attack_whip(base), {"fps": 14, "loop": False,
                     "hit_frames": [11, 12], "hit_frames_1based": [12, 13]}),
        "attack_3": (build_attack_burrow(base), {"fps": 14, "loop": False,
                     "hit_frames": [14, 15], "hit_frames_1based": [15, 16]}),
        "hurt": (build_hurt(base), {"fps": 14, "loop": False}),
        "death": (build_death(base), {"fps": 12, "loop": False}),
        "whip_impact": (build_whip_impact(base), {"fps": 14, "loop": False}),
        "burrow_dust": (build_burrow_dust(base), {"fps": 14, "loop": False}),
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
        fname = file_prefix.get(state, f"{name}_{state}.png")
        strip(frames).save(os.path.join(out_dir, fname))
        entry = {"file": fname, "frames": len(frames)}
        entry.update(extra)
        meta["animations"][state] = entry
    with open(os.path.join(out_dir, f"rootcrawler_anim.json" if name == "root_crawler" else f"{name}_anim.json"), "w") as fh:
        json.dump(meta, fh, indent=1)
    print("written", out_dir, {k: len(v[0]) for k, v in anims.items()})

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
