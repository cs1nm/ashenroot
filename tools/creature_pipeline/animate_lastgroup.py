#!/usr/bin/env python3
"""Procedural animation for the last four creature packs.

  drowned_guard  — waterlogged anchor knight, 160x128 anchor 80/121 (grounded)
  ember_rootling — charred lava treefolk, 144x112 anchor 72/105 (grounded)
  night_ember    — violet night flame, 96x96 center 48/48 (flying)
  glass_wraith   — crystal shard specter, 144x160 center 72/80 (flying)

Engine contracts preserved exactly (states, frame counts, fps, hit /
projectile / laser frames and spawns). RED damage flash per convention.
Biome accents: teal (sunken), molten orange (lava), cyan-white (glass).

Usage: animate_lastgroup.py <creature> <pose1> [pose2] <out_dir>
"""
import json, math, os, random, sys
from PIL import Image

def load(path):
    im = Image.open(path).convert("RGBA")
    return im.crop(im.getbbox())

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

class Pack:
    def __init__(self, fw, fh, ax, ay, grounded):
        self.fw, self.fh, self.ax, self.ay = fw, fh, ax, ay
        self.grounded = grounded
        self.anims = {}

    def frame(self):
        return Image.new("RGBA", (self.fw, self.fh), (0, 0, 0, 0))

    def place(self, canvas, sprite, dx=0, dy=0):
        x = self.ax - sprite.width // 2 + round(dx)
        if self.grounded:
            y = self.ay - sprite.height + round(dy)
        else:
            y = self.ay - sprite.height // 2 + round(dy)
        canvas.alpha_composite(sprite, (max(0, min(self.fw - sprite.width, x)), max(0, y)))
        return canvas

    def add(self, state, frames, fname, **extra):
        self.anims[state] = (frames, extra, fname)

    def save(self, out_dir, json_name):
        os.makedirs(out_dir, exist_ok=True)
        meta = {
            "frame_size": [self.fw, self.fh],
            "facing": "right",
            "anchor": {"x": self.ax, "y": self.ay},
            "ground_clearance": 1.0,
            "frame_indexing": "0-based",
            "animations": {},
        }
        for state, (frames, extra, fname) in self.anims.items():
            out = Image.new("RGBA", (self.fw * len(frames), self.fh), (0, 0, 0, 0))
            for i, f in enumerate(frames):
                out.alpha_composite(f, (i * self.fw, 0))
            out.save(os.path.join(out_dir, fname))
            entry = {"file": fname, "frames": len(frames)}
            entry.update(extra)
            meta["animations"][state] = entry
        with open(os.path.join(out_dir, json_name), "w") as fh:
            json.dump(meta, fh, indent=1)
        print("written", out_dir, {k: len(v[0]) for k, v in self.anims.items()})

def bob_frames(pack, base, n, phase_mult=1.0, amp=2.5, dx=0):
    frames = []
    for i in range(n):
        t = i / n * 2 * math.pi * phase_mult
        spr = squash(base, 1.0 - 0.02 * math.sin(t), 1.0 + 0.03 * math.sin(t))
        frames.append(pack.place(pack.frame(), spr, dx=dx, dy=-amp * math.sin(t)))
    return frames

def walk_frames(pack, base, n, amp=2.0):
    frames = []
    for i in range(n):
        phase = i / n * 2 * math.pi * 2.0
        # Grounded gait: weight shifts through compression + lean, feet stay
        # planted (vertical bouncing read as floating in game).
        spr = squash(base, 1.0 + 0.025 * math.sin(phase), 1.0 - 0.05 * abs(math.sin(phase)))
        spr = spr.rotate(2.0 * math.sin(phase), expand=True, resample=Image.NEAREST)
        frames.append(pack.place(pack.frame(), spr, dx=1.5 * math.sin(phase)))
    return frames

def alert_frames(pack, base, n):
    frames = []
    for i in range(n):
        k = i / (n - 1)
        spr = squash(base, 1.0 - 0.03 * k, 1.0 + 0.05 * k)
        if k > 0.4:
            spr = tint(spr, (1.06, 1.03, 1.0), 1.03)
        frames.append(pack.place(pack.frame(), spr, dx=(1 if i % 2 else -1) * (1 if k > 0.3 else 0)))
    return frames

def hurt_frames(pack, base, n):
    frames = []
    for i in range(n):
        t = i / (n - 1)
        k = 1.0 - t
        spr = flash_red(squash(base, 1.0 + 0.05 * k, 1.0 - 0.07 * k), 0.62 * k)
        frames.append(pack.place(pack.frame(), spr, dx=-4 * k))
    return frames

def stunned_frames(pack, base, n):
    frames = []
    for i in range(n):
        t = i / n * 2 * math.pi
        spr = tint(squash(base, 1.03, 0.94), (0.85, 0.85, 0.85))
        frames.append(pack.place(pack.frame(), spr, dx=round(2.0 * math.sin(t)), dy=2))
    return frames

def crumble_death(pack, base, n, seed, mote_col):
    rng = random.Random(seed)
    motes = [(rng.uniform(-14, 14), rng.uniform(0.2, 0.6), rng.uniform(12, 34)) for _ in range(8)]
    frames = []
    for i in range(n):
        t = i / (n - 1)
        f = pack.frame()
        if t < 0.2:
            k = t / 0.2
            pack.place(f, flash_red(base, 0.55 * (1 - k)))
        else:
            k = (t - 0.2) / 0.8
            spr = squash(base, 1.0 + 0.2 * k, max(0.15, 1.0 - 0.85 * k))
            spr = tint(spr, (1.0 - 0.3 * k, 1.0 - 0.33 * k, 1.0 - 0.35 * k), 1.0 - 0.35 * k)
            if k > 0.45:
                px = spr.load()
                for yy in range(spr.height):
                    for xx in range(spr.width):
                        if px[xx, yy][3] and rng.random() < (k - 0.45) * 1.7 * (1.0 - yy / spr.height):
                            px[xx, yy] = (0, 0, 0, 0)
            pack.place(f, spr)
            px = f.load()
            for ox, delay, rise in motes:
                mk = max(0.0, min(1.0, (k - delay) / (1.0 - delay + 1e-5)))
                if mk <= 0.0:
                    continue
                x = pack.ax + round(ox + math.sin(mk * 5.0) * 2)
                y = (pack.ay - 20 if pack.grounded else pack.ay) - round(rise * mk)
                if 0 <= x < pack.fw and 0 <= y < pack.fh:
                    px[x, y] = mote_col[:3] + (int(230 * (1.0 - mk)),)
        frames.append(f)
    return frames

def orb_projectile_frames(pack, n, cy, col, trail_col):
    frames = []
    for i in range(n):
        f = pack.frame()
        px = f.load()
        rr = 3 + (1 if i % 2 else 0)
        for y in range(-rr, rr + 1):
            half = int((rr * rr - y * y) ** 0.5)
            for x in range(-half, half + 1):
                c = col if abs(y) < rr else tuple(int(v * 0.7) for v in col[:3]) + (255,)
                xx, yy = pack.ax + x, cy + y
                if 0 <= xx < pack.fw and 0 <= yy < pack.fh:
                    px[xx, yy] = c[:3] + (255,)
        for t_i in range(3):
            x = pack.ax - 6 - t_i * 5
            y = cy + (1 if (i + t_i) % 2 else -1)
            if 0 <= x < pack.fw:
                px[x, y] = trail_col[:3] + (int(150 - t_i * 45),)
        frames.append(f)
    return frames

def burst_impact_frames(pack, n, cy, col, seed):
    rng = random.Random(seed)
    sparks = [(rng.uniform(0, 2 * math.pi), rng.uniform(4, 15), rng.uniform(0.0, 0.2)) for _ in range(13)]
    frames = []
    for i in range(n):
        t = i / (n - 1)
        f = pack.frame()
        px = f.load()
        for ang, dist, delay in sparks:
            k = max(0.0, min(1.0, (t - delay) / 0.65))
            if k <= 0.0:
                continue
            x = pack.ax + round(math.cos(ang) * dist * k)
            y = cy + round(math.sin(ang) * dist * k * 0.8)
            if 0 <= x < pack.fw and 0 <= y < pack.fh:
                px[x, y] = col[:3] + (int(250 * (1.0 - k * 0.7)),)
        frames.append(f)
    return frames

def ring_vfx_frames(pack, n, cx, cy, col, start=0.5, max_r=30, seed=7):
    rng = random.Random(seed)
    frames = []
    for i in range(n):
        t = i / (n - 1)
        f = pack.frame()
        if t > start:
            k = (t - start) / (1.0 - start)
            rr = 6 + k * max_r
            px = f.load()
            steps = max(12, int(rr * 2.0))
            for s_i in range(steps):
                ang = 2 * math.pi * s_i / steps
                x = cx + round(math.cos(ang) * rr)
                y = cy + round(math.sin(ang) * rr * 0.85)
                if 0 <= x < pack.fw and 0 <= y < pack.fh and rng.random() < 0.85:
                    px[x, y] = col[:3] + (int(240 * (1 - k * 0.8)),)
        frames.append(f)
    return frames

TEAL = (110, 230, 215, 255)
MOLTEN = (255, 120, 40, 255)
GLASS = (200, 245, 255, 255)

# --------------------------------------------------------------------------

def build_guard(idle_p, strike_p, out_dir):
    pack = Pack(160, 128, 80, 121, grounded=True)
    idle = load(idle_p)
    strike = load(strike_p)
    pal = palette_of(idle)
    pack.add("idle", bob_frames(pack, idle, 8, amp=0.0), "idle.png", fps=7, loop=True)
    pack.add("move", walk_frames(pack, idle, 10), "move.png", fps=8, loop=True)
    pack.add("alert", alert_frames(pack, idle, 5), "alert.png", fps=9, loop=False)
    pack.add("hurt", hurt_frames(pack, idle, 4), "hurt.png", fps=12, loop=False)
    pack.add("stunned", stunned_frames(pack, idle, 4), "stunned.png", fps=6, loop=True)

    anchor = []
    for i in range(10):
        if i < 4:                      # heave anchor overhead
            k = i / 3
            spr = squash(idle, 1.0 - 0.04 * k, 1.0 + 0.07 * k)
            anchor.append(pack.place(pack.frame(), spr, dx=-5 * k, dy=-2 * k))
        elif i < 6:                    # apex hold
            spr = tint(idle, (1.04, 1.05, 1.03), 1.03)
            anchor.append(pack.place(pack.frame(), spr, dx=-5 + (1 if i % 2 else -1), dy=-2))
        elif i < 8:                    # STRIKE (hit 6-7)
            k = (i - 6) / 1
            anchor.append(pack.place(pack.frame(), squash(strike, 1.03, 0.99), dx=4 + 5 * k))
        else:
            k = (i - 8) / 1
            anchor.append(pack.place(pack.frame(), strike if k < 0.5 else idle, dx=9 * (1 - k)))
    pack.add("attack_1", anchor, "attack_1_anchor_strike.png", fps=12, loop=False,
             hit_frames=[6, 7], hit_frames_1based=[7, 8])

    harpoon = []
    for i in range(12):
        if i < 5:                      # aim back
            k = i / 4
            spr = squash(idle, 1.0 + 0.04 * k, 1.0 - 0.03 * k)
            harpoon.append(pack.place(pack.frame(), spr, dx=-5 * k))
        elif i < 7:                    # loose at 7
            spr = tint(idle, (1.03, 1.05, 1.05), 1.02)
            harpoon.append(pack.place(pack.frame(), spr, dx=-5 + (1 if i % 2 else 0)))
        elif i < 9:
            harpoon.append(pack.place(pack.frame(), squash(idle, 1.05, 0.97), dx=4))
        else:
            k = (i - 9) / 2
            harpoon.append(pack.place(pack.frame(), idle, dx=4 * (1 - k)))
    pack.add("attack_2", harpoon, "attack_2_harpoon.png", fps=12, loop=False,
             projectile_frames=[7], projectile_frames_1based=[8], projectile_spawn=[118, 52])

    harp_proj = []
    for i in range(4):
        f = pack.frame()
        px = f.load()
        for x in range(-8, 9):
            y = 52 + (1 if (i + x) % 4 == 0 else 0)
            if 0 <= pack.ax + x < 160:
                col = pal["lite"] if abs(x) < 6 else TEAL
                px[pack.ax + x, y] = col[:3] + (255,)
        px[min(159, pack.ax + 9), 52] = TEAL[:3] + (255,)
        harp_proj.append(f)
    pack.add("harpoon_projectile", harp_proj, "harpoon_projectile.png", fps=12, loop=True)
    pack.add("harpoon_impact", burst_impact_frames(pack, 7, 52, TEAL, 51), "harpoon_impact.png", fps=14, loop=False)

    wave = []
    for i in range(12):
        if i < 5:                      # gather water glow
            k = i / 4
            spr = tint(idle, (1.0, 1.0 + 0.06 * k, 1.0 + 0.08 * k), 1.0 + 0.03 * k)
            wave.append(pack.place(pack.frame(), spr, dx=-3 * k))
        elif i < 8:                    # release at 7
            spr = squash(idle, 1.05, 0.96)
            wave.append(pack.place(pack.frame(), spr, dx=2))
        else:
            k = (i - 8) / 3
            wave.append(pack.place(pack.frame(), idle, dx=2 * (1 - k)))
    pack.add("attack_3", wave, "attack_3_water_wave.png", fps=11, loop=False,
             projectile_frames=[7], projectile_frames_1based=[8])

    wave_proj = []
    for i in range(6):
        f = pack.frame()
        px = f.load()
        for x in range(-6, 7):
            h = round(6 * math.sin((x + 6) / 12 * math.pi)) + (1 if i % 2 else 0)
            for y in range(0, h + 1):
                yy = 108 - y
                if 0 <= pack.ax + x < 160 and 0 <= yy < 128:
                    px[pack.ax + x, yy] = TEAL[:3] + (240 if y == h else 150,)
        wave_proj.append(f)
    pack.add("wave_projectile", wave_proj, "wave_projectile.png", fps=12, loop=True)
    pack.add("wave_impact", burst_impact_frames(pack, 8, 108, TEAL, 53), "wave_impact.png", fps=14, loop=False)

    guard_frames = []
    for i in range(8):
        k = min(1.0, i / 3)
        spr = squash(idle, 1.0 + 0.08 * k, 1.0 - 0.06 * k)
        spr = tint(spr, (0.92, 0.94, 0.96), 1.0)
        guard_frames.append(pack.place(pack.frame(), spr, dx=-3 * k))
    pack.add("attack_4", guard_frames, "attack_4_guard.png", fps=8, loop=False)
    pack.add("death", crumble_death(pack, idle, 13, 61, TEAL), "death.png", fps=9, loop=False)
    pack.save(out_dir, "drowned_guard_anim.json")

def build_rootling(idle_p, out_dir):
    pack = Pack(144, 112, 72, 105, grounded=True)
    idle = load(idle_p)
    pack.add("idle", bob_frames(pack, idle, 8, amp=0.0), "idle.png", fps=7, loop=True)
    pack.add("move", walk_frames(pack, idle, 10), "move.png", fps=10, loop=True)
    pack.add("alert", alert_frames(pack, idle, 5), "alert.png", fps=10, loop=False)
    pack.add("hurt", hurt_frames(pack, idle, 4), "hurt.png", fps=14, loop=False)
    pack.add("stunned", stunned_frames(pack, idle, 4), "stunned.png", fps=6, loop=True)

    claw = []
    for i in range(9):
        if i < 4:
            k = i / 3
            spr = squash(idle, 1.0 + 0.05 * k, 1.0 - 0.06 * k)
            claw.append(pack.place(pack.frame(), spr, dx=-5 * k))
        elif i < 7:                    # swipe (hit 5-6)
            k = (i - 4) / 2
            spr = tint(squash(idle, 1.0 - 0.02, 1.0 + 0.02), (1.08, 1.03, 0.97), 1.04)
            claw.append(pack.place(pack.frame(), spr, dx=-5 + 15 * k))
        else:
            k = (i - 7) / 1
            claw.append(pack.place(pack.frame(), idle, dx=10 * (1 - k)))
    pack.add("attack_1", claw, "attack_1_claw.png", fps=13, loop=False,
             hit_frames=[5, 6], hit_frames_1based=[6, 7])

    seed_throw = []
    for i in range(11):
        if i < 4:
            k = i / 3
            spr = tint(idle, (1.0 + 0.1 * k, 1.0 + 0.02 * k, 1.0 - 0.05 * k), 1.0 + 0.04 * k)
            seed_throw.append(pack.place(pack.frame(), spr, dx=-3 * k))
        elif i < 6:                    # shiver hold
            spr = tint(idle, (1.12, 1.04, 0.95), 1.05)
            seed_throw.append(pack.place(pack.frame(), spr, dx=-3 + (1 if i % 2 else -1)))
        elif i < 8:                    # release at 6
            seed_throw.append(pack.place(pack.frame(), squash(idle, 1.05, 0.96), dx=3))
        else:
            k = (i - 8) / 2
            seed_throw.append(pack.place(pack.frame(), idle, dx=3 * (1 - k)))
    pack.add("attack_2", seed_throw, "attack_2_ember_seed.png", fps=12, loop=False,
             projectile_frames=[6], projectile_frames_1based=[7], projectile_spawn=[106, 47])
    pack.add("ember_seed", orb_projectile_frames(pack, 6, 47, MOLTEN, (150, 80, 40, 255)), "ember_seed.png", fps=13, loop=True)
    pack.add("seed_impact", burst_impact_frames(pack, 8, 47, MOLTEN, 67), "seed_impact.png", fps=14, loop=False)

    burst = []
    for i in range(12):
        if i < 6:                      # crouch and glow build
            k = i / 5
            spr = squash(idle, 1.0 + 0.08 * k, 1.0 - 0.12 * k)
            spr = tint(spr, (1.0 + 0.14 * k, 1.0 + 0.04 * k, 0.95), 1.0 + 0.05 * k)
            burst.append(pack.place(pack.frame(), spr, dx=(1 if i % 2 else -1) * (1 if k > 0.4 else 0)))
        elif i < 9:                    # eruption (hit 7)
            spr = squash(idle, 0.94, 1.10)
            burst.append(pack.place(pack.frame(), tint(spr, (1.1, 1.02, 0.95), 1.04)))
        else:
            k = (i - 9) / 2
            burst.append(pack.place(pack.frame(), idle))
    pack.add("attack_3", burst, "attack_3_root_burst.png", fps=11, loop=False,
             hit_frames=[7], hit_frames_1based=[8])

    root_vfx = []
    rng = random.Random(71)
    spikes = [(rng.uniform(-30, 30), rng.uniform(10, 24), rng.uniform(0.0, 0.15)) for _ in range(7)]
    for i in range(12):
        t = i / 11
        f = pack.frame()
        px = f.load()
        if t > 0.45:
            k = (t - 0.45) / 0.55
            h_k = min(1.0, k * 2.2) if k < 0.7 else max(0.0, 1.0 - (k - 0.7) / 0.3)
            for ox, sh, delay in spikes:
                kk = max(0.0, min(1.0, h_k - delay))
                h = int(sh * kk)
                if h <= 0:
                    continue
                cx = 72 + round(ox)
                for yy in range(h):
                    w = max(1, round(4 * (1.0 - yy / max(1, h))))
                    for xx in range(cx - w // 2, cx - w // 2 + w):
                        y = 105 - yy
                        if 0 <= xx < 144 and 0 <= y < 112:
                            px[xx, y] = MOLTEN[:3] + (255,) if yy > h * 0.6 else (60, 40, 30, 255)
        root_vfx.append(f)
    pack.add("root_burst_vfx", root_vfx, "root_burst_vfx.png", fps=11, loop=False,
             hit_frames=[7], hit_frames_1based=[8])
    pack.add("death", crumble_death(pack, idle, 12, 73, MOLTEN), "death.png", fps=10, loop=False)
    pack.save(out_dir, "ember_rootling_anim.json")

def build_nightember(idle_p, out_dir):
    pack = Pack(96, 96, 48, 48, grounded=False)
    idle = load(idle_p)
    pack.add("idle", bob_frames(pack, idle, 8, amp=3.0), "idle.png", fps=9, loop=True)
    pack.add("move", bob_frames(pack, idle, 8, phase_mult=2.0, amp=4.0, dx=2), "move.png", fps=13, loop=True)
    pack.add("alert", alert_frames(pack, idle, 4), "alert.png", fps=11, loop=False)
    pack.add("hurt", hurt_frames(pack, idle, 4), "hurt.png", fps=14, loop=False)

    dash = []
    for i in range(9):
        if i < 4:                      # coil back, brighten
            k = i / 3
            spr = tint(idle, (1.0 + 0.1 * k, 1.0 + 0.05 * k, 1.0), 1.0 + 0.05 * k)
            dash.append(pack.place(pack.frame(), spr, dx=-6 * k))
        elif i < 7:                    # flame dash (hit 5-6)
            k = (i - 4) / 2
            spr = squash(idle, 1.25, 0.85)
            spr = tint(spr, (1.1, 1.04, 0.98), 1.06)
            dash.append(pack.place(pack.frame(), spr, dx=-6 + 24 * k))
        else:
            k = (i - 7) / 1
            dash.append(pack.place(pack.frame(), idle, dx=18 * (1 - k)))
    pack.add("attack_1", dash, "attack_1_flame_dash.png", fps=15, loop=False,
             hit_frames=[5, 6], hit_frames_1based=[6, 7])

    trail = []
    rng = random.Random(79)
    streaks = [(rng.uniform(-30, 2), rng.uniform(-8, 8), rng.uniform(0.0, 0.3)) for _ in range(12)]
    for i in range(9):
        t = i / 8
        f = pack.frame()
        px = f.load()
        if t > 0.4:
            for ox, oy, delay in streaks:
                k = max(0.0, min(1.0, (t - 0.4 - delay) / 0.5))
                if k <= 0.0:
                    continue
                for w in range(3):
                    x = 48 + round(ox - k * 10) - w
                    y = 48 + round(oy)
                    if 0 <= x < 96 and 0 <= y < 96:
                        col = MOLTEN if w == 0 else (120, 60, 140, 255)
                        px[x, y] = col[:3] + (int(200 * (1 - k) * (1 - w * 0.25)),)
        trail.append(f)
    pack.add("flame_trail", trail, "flame_trail.png", fps=15, loop=False,
             hit_frames=[5, 6], hit_frames_1based=[6, 7])

    triple = []
    for i in range(11):
        if i < 4:
            k = i / 3
            spr = tint(idle, (1.0 + 0.12 * k, 1.0 + 0.05 * k, 1.0), 1.0 + 0.06 * k)
            triple.append(pack.place(pack.frame(), spr, dx=-2 * k))
        elif i < 6:
            spr = tint(idle, (1.15, 1.06, 0.98), 1.07)
            triple.append(pack.place(pack.frame(), spr, dx=-2 + (1 if i % 2 else -1)))
        elif i < 8:                    # release at 6
            triple.append(pack.place(pack.frame(), squash(idle, 1.08, 0.94), dx=3))
        else:
            k = (i - 8) / 2
            triple.append(pack.place(pack.frame(), idle, dx=3 * (1 - k)))
    pack.add("attack_2", triple, "attack_2_triple_fire.png", fps=13, loop=False,
             projectile_frames=[6], projectile_frames_1based=[7], projectile_spawn=[73, 48])
    pack.add("fire_projectile", orb_projectile_frames(pack, 6, 48, MOLTEN, (120, 60, 140, 255)), "fire_projectile.png", fps=14, loop=True)
    pack.add("fire_impact", burst_impact_frames(pack, 7, 48, MOLTEN, 83), "fire_impact.png", fps=14, loop=False)

    nburst = []
    for i in range(11):
        if i < 6:
            k = i / 5
            spr = squash(idle, 1.0 + 0.15 * k, 1.0 + 0.15 * k)
            spr = tint(spr, (1.0 + 0.12 * k, 1.0 + 0.04 * k, 1.0 + 0.06 * k), 1.0 + 0.06 * k)
            nburst.append(pack.place(pack.frame(), spr))
        elif i < 9:                    # detonation (hit 7)
            spr = squash(idle, 0.82, 0.82)
            nburst.append(pack.place(pack.frame(), flash_red(spr, 0.12)))
        else:
            nburst.append(pack.place(pack.frame(), idle))
    pack.add("attack_3", nburst, "attack_3_night_burst.png", fps=12, loop=False,
             hit_frames=[7], hit_frames_1based=[8])
    pack.add("burst_vfx", ring_vfx_frames(pack, 11, 48, 48, (170, 110, 230, 255), start=0.55, max_r=30, seed=89),
             "burst_vfx.png", fps=12, loop=False, hit_frames=[7], hit_frames_1based=[8])
    pack.add("death", crumble_death(pack, idle, 10, 97, MOLTEN), "death.png", fps=12, loop=False)
    pack.save(out_dir, "night_ember_anim.json")

def build_wraith(idle_p, out_dir):
    pack = Pack(144, 160, 72, 80, grounded=False)
    idle = load(idle_p)
    pal = palette_of(idle)
    pack.add("idle", bob_frames(pack, idle, 8, amp=2.5), "idle.png", fps=8, loop=True)
    pack.add("move", bob_frames(pack, idle, 8, phase_mult=2.0, amp=3.5, dx=2), "move.png", fps=12, loop=True)
    pack.add("alert", alert_frames(pack, idle, 5), "alert.png", fps=10, loop=False)
    pack.add("hurt", hurt_frames(pack, idle, 4), "hurt.png", fps=14, loop=False)
    pack.add("stunned", stunned_frames(pack, idle, 4), "stunned.png", fps=6, loop=True)

    fan = []
    for i in range(12):
        if i < 5:                      # shards gather and orbit
            k = i / 4
            spr = tint(idle, (1.0 + 0.05 * k, 1.0 + 0.07 * k, 1.0 + 0.1 * k), 1.0 + 0.04 * k)
            fan.append(pack.place(pack.frame(), spr, dx=-3 * k))
        elif i < 7:                    # shiver aim
            spr = tint(idle, (1.06, 1.09, 1.12), 1.05)
            fan.append(pack.place(pack.frame(), spr, dx=-3 + (1 if i % 2 else -1)))
        elif i < 9:                    # release at 7
            fan.append(pack.place(pack.frame(), squash(idle, 1.05, 0.97), dx=3))
        else:
            k = (i - 9) / 2
            fan.append(pack.place(pack.frame(), idle, dx=3 * (1 - k)))
    pack.add("attack_1", fan, "attack_1_shard_fan.png", fps=13, loop=False,
             projectile_frames=[7], projectile_frames_1based=[8], projectile_spawn=[96, 76])

    shard = []
    for i in range(6):
        f = pack.frame()
        px = f.load()
        ang = -0.15
        for l in range(9):
            x = 72 + round(math.cos(ang) * l)
            y = 76 + round(math.sin(ang) * l) + (1 if i % 2 and l > 5 else 0)
            if 0 <= x < 144 and 0 <= y < 160:
                px[x, y] = GLASS[:3] + (255,)
                if l < 4 and y + 1 < 160:
                    px[x, y + 1] = (140, 200, 230, 220)
        shard.append(f)
    pack.add("shard_projectile", shard, "shard_projectile.png", fps=14, loop=True)
    pack.add("shard_impact", burst_impact_frames(pack, 7, 76, GLASS, 101), "shard_impact.png", fps=14, loop=False)

    tslash = []
    for i in range(10):
        if i < 3:                      # shatter out (fade)
            k = i / 2
            spr = tint(idle, (1.0, 1.0, 1.0), 1.0 - 0.5 * k)
            tslash.append(pack.place(pack.frame(), spr, dx=-4 * k))
        elif i < 5:                    # gone
            tslash.append(pack.frame())
        elif i < 8:                    # reappear slashing (hit 6-7)
            k = (i - 5) / 2
            spr = tint(squash(idle, 1.08, 0.95), (1.06, 1.08, 1.1), 0.6 + 0.5 * k)
            tslash.append(pack.place(pack.frame(), spr, dx=16))
        else:
            k = (i - 8) / 1
            tslash.append(pack.place(pack.frame(), idle, dx=16 * (1 - k)))
    pack.add("attack_2", tslash, "attack_2_teleport_slash.png", fps=14, loop=False,
             hit_frames=[6, 7], hit_frames_1based=[7, 8])

    tvfx = []
    rng = random.Random(103)
    frags = [(rng.uniform(0, 2 * math.pi), rng.uniform(4, 20), rng.uniform(0.0, 0.3)) for _ in range(14)]
    for i in range(8):
        t = i / 7
        f = pack.frame()
        px = f.load()
        for ang, dist, delay in frags:
            k = max(0.0, min(1.0, (t - delay) / 0.6))
            if k <= 0.0:
                continue
            x = 72 + round(math.cos(ang) * dist * (1.0 - k))
            y = 80 + round(math.sin(ang) * dist * (1.0 - k))
            if 0 <= x < 144 and 0 <= y < 160:
                px[x, y] = GLASS[:3] + (int(230 * (1 - k * 0.5)),)
        tvfx.append(f)
    pack.add("teleport_vfx", tvfx, "teleport_vfx.png", fps=14, loop=False)

    svfx = []
    for i in range(6):
        f = pack.frame()
        if 1 <= i <= 4:
            px = f.load()
            k = (i - 1) / 3
            for a_step in range(24):
                ang = -0.8 + 1.6 * a_step / 23
                rr = 24 + k * 8
                x = 72 + 14 + round(math.cos(ang) * rr)
                y = 80 + round(math.sin(ang) * rr)
                if 0 <= x < 144 and 0 <= y < 160:
                    col = GLASS if a_step % 2 else pal["lite"]
                    px[x, y] = col[:3] + (int(220 * (1 - k * 0.6)),)
        svfx.append(f)
    pack.add("slash_vfx", svfx, "slash_vfx.png", fps=14, loop=False)

    laser = []
    for i in range(14):
        k = i / 13
        if i < 5:
            spr = tint(idle, (1.0 + 0.06 * k, 1.0 + 0.1 * k, 1.0 + 0.14 * k), 1.0 + 0.05 * k)
            laser.append(pack.place(pack.frame(), spr))
        elif i < 11:
            spr = tint(idle, (1.08, 1.12, 1.16), 1.07)
            laser.append(pack.place(pack.frame(), spr, dx=(1 if i % 2 else -1)))
        else:
            k2 = (i - 11) / 2
            laser.append(pack.place(pack.frame(), idle, dx=(1 - k2)))
    pack.add("attack_3", laser, "attack_3_glass_laser.png", fps=12, loop=False,
             laser_start_frames=[7], laser_start_frames_1based=[8])

    beam = []
    for i in range(14):
        f = pack.frame()
        px = f.load()
        if 7 <= i <= 11:
            wob = 1 if i % 2 else 0
            for x in range(0, 144):
                for w in range(3):
                    y = 32 + w - 1 + wob
                    if 0 <= y < 160:
                        col = GLASS if w == 1 else (150, 210, 235, 255)
                        px[x, y] = col[:3] + (245 if w == 1 else 170,)
        beam.append(f)
    pack.add("laser_beam", beam, "laser_beam.png", fps=12, loop=False,
             laser_start_frames=[7], laser_start_frames_1based=[8],
             anchor={"x": 0, "y": 32})

    cage = []
    for i in range(14):
        if i < 7:                      # raise arms, shards swirl upward
            k = i / 6
            spr = squash(idle, 1.0 - 0.03 * k, 1.0 + 0.06 * k)
            spr = tint(spr, (1.0 + 0.05 * k, 1.0 + 0.08 * k, 1.0 + 0.12 * k), 1.0 + 0.05 * k)
            cage.append(pack.place(pack.frame(), spr, dy=-2 * k))
        elif i < 10:                   # slam shards down (hit 8)
            spr = squash(idle, 1.06, 0.94)
            cage.append(pack.place(pack.frame(), spr, dy=1))
        else:
            k = (i - 10) / 3
            cage.append(pack.place(pack.frame(), idle))
    pack.add("attack_4", cage, "attack_4_crystal_cage.png", fps=11, loop=False,
             hit_frames=[8], hit_frames_1based=[9])

    cage_vfx = []
    rng = random.Random(107)
    bars = [(rng.uniform(-26, 26), rng.uniform(18, 34), rng.uniform(0.0, 0.12)) for _ in range(8)]
    for i in range(14):
        t = i / 13
        f = pack.frame()
        px = f.load()
        if t > 0.5:
            k = (t - 0.5) / 0.5
            h_k = min(1.0, k * 2.0) if k < 0.75 else max(0.0, 1.0 - (k - 0.75) / 0.25)
            for ox, bh, delay in bars:
                kk = max(0.0, min(1.0, h_k - delay))
                h = int(bh * kk)
                cx = 72 + round(ox)
                for yy in range(h):
                    y = 140 - yy
                    if 0 <= cx < 144 and 0 <= y < 160:
                        px[cx, y] = GLASS[:3] + (240,)
                        if cx + 1 < 144:
                            px[cx + 1, y] = (150, 210, 235, 160)
        cage_vfx.append(f)
    pack.add("cage_vfx", cage_vfx, "cage_vfx.png", fps=11, loop=False,
             hit_frames=[8], hit_frames_1based=[9])
    pack.add("death", crumble_death(pack, idle, 14, 109, GLASS), "death.png", fps=10, loop=False)
    pack.save(out_dir, "glass_wraith_anim.json")

if __name__ == "__main__":
    creature = sys.argv[1]
    if creature == "drowned_guard":
        build_guard(sys.argv[2], sys.argv[3], sys.argv[4])
    elif creature == "ember_rootling":
        build_rootling(sys.argv[2], sys.argv[3])
    elif creature == "night_ember":
        build_nightember(sys.argv[2], sys.argv[3])
    elif creature == "glass_wraith":
        build_wraith(sys.argv[2], sys.argv[3])
    else:
        raise SystemExit("unknown creature " + creature)
