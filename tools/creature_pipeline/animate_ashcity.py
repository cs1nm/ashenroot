#!/usr/bin/env python3
"""Procedural animation for the four Ash City creatures.

  ash_phantom  — floating hooded ash ghost (idle + slash poses), 128x128 c64/64
  ash_wisp     — smoldering ember ball (idle pose), 96x96 c48/48
  ash_sentinel — basalt golem knight (idle + slam poses), 160x128 anchor 80/121
  ruin_drone   — rusty hovering machine (idle pose), 128x128 c64/64

All packs keep their engine contracts (states, frame counts, fps, hit /
projectile frames and spawn points). Damage feedback is RED per
docs/CREATURE_ANIMATION_PIPELINE.md; ember-orange is the biome accent.

Usage: animate_ashcity.py <creature> <pose1> [pose2] <out_dir>
"""
import json, math, os, random, sys
from PIL import Image

EMBER = (255, 150, 52, 255)

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

def bob_frames(pack, base, n, fps_phase=1.0, amp=2.5, dx=0):
    frames = []
    for i in range(n):
        t = i / n * 2 * math.pi * fps_phase
        spr = squash(base, 1.0 - 0.02 * math.sin(t), 1.0 + 0.03 * math.sin(t))
        frames.append(pack.place(pack.frame(), spr, dx=dx, dy=-amp * math.sin(t)))
    return frames

def hurt_frames(pack, base, n):
    frames = []
    for i in range(n):
        t = i / (n - 1)
        k = 1.0 - t
        spr = flash_red(squash(base, 1.0 + 0.05 * k, 1.0 - 0.07 * k), 0.62 * k)
        frames.append(pack.place(pack.frame(), spr, dx=-4 * k))
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

def stunned_frames(pack, base, n):
    frames = []
    for i in range(n):
        t = i / n * 2 * math.pi
        spr = tint(squash(base, 1.03, 0.94), (0.85, 0.85, 0.85))
        frames.append(pack.place(pack.frame(), spr, dx=round(2.0 * math.sin(t)), dy=2))
    return frames

def crumble_death(pack, base, n, seed=17, ember_motes=True):
    """Red flash, collapse into ash, ember motes rise."""
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
            if ember_motes:
                px = f.load()
                for ox, delay, rise in motes:
                    mk = max(0.0, min(1.0, (k - delay) / (1.0 - delay + 1e-5)))
                    if mk <= 0.0:
                        continue
                    x = pack.ax + round(ox + math.sin(mk * 5.0) * 2)
                    y = (pack.ay - 20 if pack.grounded else pack.ay) - round(rise * mk)
                    if 0 <= x < pack.fw and 0 <= y < pack.fh:
                        px[x, y] = EMBER[:3] + (int(230 * (1.0 - mk)),)
        frames.append(f)
    return frames

def ember_projectile_frames(pack, n=6, cy=None):
    """Pulsing ember bolt with a smoke trail."""
    cy = cy if cy is not None else (pack.ay if not pack.grounded else pack.ay - 40)
    frames = []
    for i in range(n):
        f = pack.frame()
        px = f.load()
        rr = 3 + (1 if i % 2 else 0)
        for y in range(-rr, rr + 1):
            half = int((rr * rr - y * y) ** 0.5)
            for x in range(-half, half + 1):
                col = EMBER if abs(y) < rr else (200, 90, 30, 255)
                xx, yy = pack.ax + x, cy + y
                if 0 <= xx < pack.fw and 0 <= yy < pack.fh:
                    px[xx, yy] = col[:3] + (255,)
        for t_i in range(3):
            x = pack.ax - 6 - t_i * 5
            y = cy + (1 if (i + t_i) % 2 else -1)
            if 0 <= x < pack.fw:
                px[x, y] = (120, 110, 105, int(150 - t_i * 45))
        frames.append(f)
    return frames

def ember_impact_frames(pack, n, cy=None, seed=5):
    cy = cy if cy is not None else (pack.ay if not pack.grounded else pack.ay - 20)
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
            a = int(250 * (1.0 - k * 0.7))
            if 0 <= x < pack.fw and 0 <= y < pack.fh:
                px[x, y] = EMBER[:3] + (a,)
        frames.append(f)
    return frames

# --------------------------------------------------------------------------

def build_phantom(idle_p, slash_p, out_dir):
    pack = Pack(128, 128, 64, 64, grounded=False)
    idle = load(idle_p)
    slash = load(slash_p)
    pal = palette_of(idle)
    pack.add("idle", bob_frames(pack, idle, 8), "idle.png", fps=7, loop=True)
    pack.add("move", bob_frames(pack, idle, 10, fps_phase=2.0, amp=3.5, dx=2), "move.png", fps=10, loop=True)
    pack.add("alert", alert_frames(pack, idle, 5), "alert.png", fps=10, loop=False)
    pack.add("hurt", hurt_frames(pack, idle, 4), "hurt.png", fps=14, loop=False)
    pack.add("stunned", stunned_frames(pack, idle, 4), "stunned.png", fps=6, loop=True)

    claw = []
    for i in range(8):
        if i < 3:
            k = i / 2
            claw.append(pack.place(pack.frame(), idle, dx=-5 * k, dy=-2 * k))
        elif i < 6:                    # slash (hit 4-5)
            k = (i - 3) / 2
            spr = tint(slash, (1.05, 1.02, 1.0), 1.03)
            claw.append(pack.place(pack.frame(), spr, dx=-5 + 16 * k))
        else:
            k = (i - 6) / 1
            claw.append(pack.place(pack.frame(), slash if k < 0.5 else idle, dx=11 * (1 - k)))
    pack.add("attack_1", claw, "attack_1_claw.png", fps=14, loop=False,
             hit_frames=[4, 5], hit_frames_1based=[5, 6])

    slash_vfx = []
    for i in range(6):
        f = pack.frame()
        if 1 <= i <= 4:
            px = f.load()
            k = (i - 1) / 3
            for a_step in range(24):
                ang = -0.8 + 1.6 * a_step / 23
                rr = 22 + k * 8
                x = pack.ax + 16 + round(math.cos(ang) * rr)
                y = pack.ay + round(math.sin(ang) * rr)
                if 0 <= x < 128 and 0 <= y < 128:
                    col = pal["lite"] if a_step % 2 else EMBER
                    px[x, y] = col[:3] + (int(220 * (1 - k * 0.6)),)
        slash_vfx.append(f)
    pack.add("slash_vfx", slash_vfx, "slash_vfx.png", fps=16, loop=False)

    dash = []
    for i in range(10):
        if i < 4:                      # fade + wind up
            k = i / 3
            spr = tint(idle, (1.0, 1.0, 1.0), 1.0 - 0.3 * k)
            dash.append(pack.place(pack.frame(), spr, dx=-6 * k))
        elif i < 8:                    # phase dash (hit 6-7)
            k = (i - 4) / 3
            spr = squash(slash, 1.1, 0.92)
            spr = tint(spr, (1.05, 1.0, 0.95), 0.75 + 0.35 * k)
            dash.append(pack.place(pack.frame(), spr, dx=-6 + 26 * k))
        else:
            k = (i - 8) / 1
            dash.append(pack.place(pack.frame(), idle, dx=20 * (1 - k)))
    pack.add("attack_2", dash, "attack_2_phase_dash.png", fps=12, loop=False,
             hit_frames=[6, 7], hit_frames_1based=[7, 8])

    dash_vfx = []
    rng = random.Random(9)
    streaks = [(rng.uniform(-30, 6), rng.uniform(-14, 14), rng.uniform(0.0, 0.3)) for _ in range(12)]
    for i in range(6):
        t = i / 5
        f = pack.frame()
        px = f.load()
        for ox, oy, delay in streaks:
            k = max(0.0, min(1.0, (t - delay) / 0.6))
            if k <= 0.0:
                continue
            for w in range(4):
                x = pack.ax + round(ox - k * 14) - w
                y = pack.ay + round(oy)
                if 0 <= x < 128 and 0 <= y < 128:
                    col = pal["mid"] if w > 1 else pal["lite"]
                    px[x, y] = col[:3] + (int(190 * (1 - k) * (1 - w * 0.2)),)
        dash_vfx.append(f)
    pack.add("dash_vfx", dash_vfx, "dash_vfx.png", fps=14, loop=False)

    bolt = []
    for i in range(10):
        if i < 4:                      # gather ember
            k = i / 3
            spr = tint(idle, (1.0 + 0.1 * k, 1.0 + 0.02 * k, 1.0 - 0.05 * k), 1.0 + 0.04 * k)
            bolt.append(pack.place(pack.frame(), spr, dx=-2 * k))
        elif i < 6:                    # release at 5
            spr = squash(idle, 1.04, 0.97)
            bolt.append(pack.place(pack.frame(), spr, dx=2))
        else:
            k = (i - 6) / 3
            bolt.append(pack.place(pack.frame(), idle, dx=2 * (1 - k)))
    pack.add("attack_3", bolt, "attack_3_ember_bolt.png", fps=12, loop=False,
             projectile_frames=[5], projectile_frames_1based=[6], projectile_spawn=[108, 42])
    pack.add("ember_projectile", ember_projectile_frames(pack, 6, cy=42), "ember_projectile.png", fps=14, loop=True)
    pack.add("ember_impact", ember_impact_frames(pack, 8, cy=42), "ember_impact.png", fps=14, loop=False)
    pack.add("death", crumble_death(pack, idle, 11), "death.png", fps=10, loop=False)
    pack.save(out_dir, "ash_phantom_anim.json")

def build_wisp(idle_p, out_dir):
    pack = Pack(96, 96, 48, 48, grounded=False)
    idle = load(idle_p)
    pack.add("idle", bob_frames(pack, idle, 8, amp=3.0), "idle.png", fps=8, loop=True)
    pack.add("move", bob_frames(pack, idle, 8, fps_phase=2.0, amp=4.0, dx=2), "move.png", fps=12, loop=True)
    pack.add("alert", alert_frames(pack, idle, 4), "alert.png", fps=10, loop=False)
    pack.add("hurt", hurt_frames(pack, idle, 4), "hurt.png", fps=14, loop=False)

    bolt = []
    for i in range(9):
        if i < 4:
            k = i / 3
            spr = tint(idle, (1.0 + 0.12 * k, 1.0 + 0.04 * k, 1.0 - 0.05 * k), 1.0 + 0.06 * k)
            bolt.append(pack.place(pack.frame(), spr, dx=-2 * k))
        elif i < 6:                    # release at 5
            spr = squash(idle, 1.08, 0.94)
            bolt.append(pack.place(pack.frame(), spr, dx=3))
        else:
            k = (i - 6) / 2
            bolt.append(pack.place(pack.frame(), idle, dx=3 * (1 - k)))
    pack.add("attack_1", bolt, "attack_1_ember_bolt.png", fps=13, loop=False,
             projectile_frames=[5], projectile_frames_1based=[6], projectile_spawn=[72, 48])
    pack.add("ember_projectile", ember_projectile_frames(pack, 6, cy=48), "ember_projectile.png", fps=14, loop=True)
    pack.add("ember_impact", ember_impact_frames(pack, 7, cy=48), "ember_impact.png", fps=14, loop=False)

    burst = []
    for i in range(10):
        if i < 6:                      # swell and brighten
            k = i / 5
            spr = squash(idle, 1.0 + 0.14 * k, 1.0 + 0.14 * k)
            spr = tint(spr, (1.0 + 0.15 * k, 1.0 + 0.05 * k, 1.0 - 0.1 * k), 1.0 + 0.08 * k)
            burst.append(pack.place(pack.frame(), spr, dx=(1 if i % 2 else -1) * (1 if k > 0.5 else 0)))
        elif i < 8:                    # detonate (hit 6)
            spr = squash(idle, 0.85, 0.85)
            burst.append(pack.place(pack.frame(), flash_red(spr, 0.15)))
        else:
            k = (i - 8) / 1
            burst.append(pack.place(pack.frame(), idle))
    pack.add("attack_2", burst, "attack_2_fire_burst.png", fps=12, loop=False,
             hit_frames=[6], hit_frames_1based=[7])

    burst_vfx = []
    rng = random.Random(15)
    for i in range(10):
        t = i / 9
        f = pack.frame()
        px = f.load()
        if t > 0.5:
            ring_k = (t - 0.5) / 0.5
            rr = 6 + ring_k * 26
            steps = max(12, int(rr * 2.0))
            for s_i in range(steps):
                ang = 2 * math.pi * s_i / steps
                x = 48 + round(math.cos(ang) * rr)
                y = 48 + round(math.sin(ang) * rr * 0.85)
                if 0 <= x < 96 and 0 <= y < 96 and rng.random() < 0.85:
                    px[x, y] = EMBER[:3] + (int(240 * (1 - ring_k * 0.8)),)
        burst_vfx.append(f)
    pack.add("burst_vfx", burst_vfx, "burst_vfx.png", fps=12, loop=False)
    pack.add("death", crumble_death(pack, idle, 9, seed=23), "death.png", fps=12, loop=False)
    pack.save(out_dir, "ash_wisp_anim.json")

def build_sentinel(idle_p, slam_p, out_dir):
    pack = Pack(160, 128, 80, 121, grounded=True)
    idle = load(idle_p)
    slam = load(slam_p)
    pal = palette_of(idle)
    pack.add("idle", bob_frames(pack, idle, 8, amp=0.0), "idle.png", fps=7, loop=True)
    move = []
    for i in range(10):
        t = i / 10
        phase = t * 2 * math.pi * 2.0
        spr = squash(idle, 1.0 + 0.02 * math.sin(phase), 1.0 - 0.03 * abs(math.sin(phase)))
        move.append(pack.place(pack.frame(), spr, dx=1.5 * math.sin(phase), dy=-abs(2.0 * math.sin(phase))))
    pack.add("move", move, "move.png", fps=9, loop=True)
    pack.add("alert", alert_frames(pack, idle, 5), "alert.png", fps=9, loop=False)
    pack.add("hurt", hurt_frames(pack, idle, 4), "hurt.png", fps=12, loop=False)
    pack.add("stunned", stunned_frames(pack, idle, 5), "stunned.png", fps=6, loop=True)

    hammer = []
    for i in range(10):
        if i < 4:                      # heave the hammer arm back/up
            k = i / 3
            spr = squash(idle, 1.0 - 0.04 * k, 1.0 + 0.06 * k)
            hammer.append(pack.place(pack.frame(), spr, dx=-5 * k, dy=-2 * k))
        elif i < 6:                    # hold, ember flare
            spr = tint(idle, (1.06, 1.02, 0.97), 1.03)
            hammer.append(pack.place(pack.frame(), spr, dx=-5 + (1 if i % 2 else -1), dy=-2))
        elif i < 8:                    # SWING (hit 6-7)
            k = (i - 6) / 1
            spr = squash(slam, 1.04, 0.98)
            hammer.append(pack.place(pack.frame(), spr, dx=4 + 6 * k))
        else:
            k = (i - 8) / 1
            hammer.append(pack.place(pack.frame(), slam if k < 0.5 else idle, dx=10 * (1 - k)))
    pack.add("attack_1", hammer, "attack_1_hammer_swing.png", fps=12, loop=False,
             hit_frames=[6, 7], hit_frames_1based=[7, 8])

    gslam = []
    for i in range(12):
        if i < 5:                      # slow rise tall
            k = i / 4
            spr = squash(idle, 1.0 - 0.05 * k, 1.0 + 0.10 * k)
            gslam.append(pack.place(pack.frame(), spr, dy=-3 * k))
        elif i < 7:                    # shudder at apex
            spr = tint(squash(idle, 0.95, 1.10), (1.07, 1.02, 0.96), 1.04)
            gslam.append(pack.place(pack.frame(), spr, dx=(1 if i % 2 else -1), dy=-3))
        elif i < 9:                    # SLAM (hit 7)
            gslam.append(pack.place(pack.frame(), squash(slam, 1.05, 1.0), dy=1))
        else:
            k = (i - 9) / 2
            gslam.append(pack.place(pack.frame(), slam if k < 0.6 else idle))
    pack.add("attack_2", gslam, "attack_2_ground_slam.png", fps=11, loop=False,
             hit_frames=[7], hit_frames_1based=[8])

    slam_vfx = []
    rng = random.Random(27)
    puffs = [(rng.uniform(-30, 30), rng.uniform(3, 15), rng.uniform(0.0, 0.2)) for _ in range(16)]
    for i in range(8):
        t = i / 7
        f = pack.frame()
        px = f.load()
        for ox, h, delay in puffs:
            k = max(0.0, min(1.0, (t - delay) / 0.7))
            if k <= 0.0:
                continue
            x = 80 + round(ox * (0.5 + 0.8 * k))
            y = 121 - round(h * math.sin(k * math.pi))
            if 0 <= x < 160 and 0 <= y < 128:
                col = pal["lite"] if rng.random() < 0.5 else pal["mid"]
                px[x, y] = col[:3] + (int(235 * (1 - k * 0.7)),)
        slam_vfx.append(f)
    pack.add("slam_vfx", slam_vfx, "slam_vfx.png", fps=12, loop=False)

    cracks = []
    for i in range(8):
        t = i / 7
        f = pack.frame()
        px = f.load()
        reach = round(8 + 52 * min(1.0, t * 1.6))
        rng2 = random.Random(31)
        for direction in (-1, 1):
            x, y = 80, 121
            while abs(x - 80) < reach:
                x += direction * rng2.randint(1, 3)
                y += rng2.randint(-1, 1)
                y = max(115, min(126, y))
                if 0 <= x < 160:
                    px[x, y] = EMBER[:3] + (int(230 * (1 - t * 0.5)),)
        cracks.append(f)
    pack.add("ground_cracks", cracks, "ground_cracks.png", fps=12, loop=False)

    throw = []
    for i in range(11):
        if i < 4:
            k = i / 3
            spr = squash(idle, 1.0 + 0.04 * k, 1.0 - 0.04 * k)
            throw.append(pack.place(pack.frame(), spr, dx=-4 * k))
        elif i < 6:
            spr = tint(idle, (1.06, 1.02, 0.97), 1.02)
            throw.append(pack.place(pack.frame(), spr, dx=-4 + (1 if i % 2 else -1)))
        elif i < 8:                    # release at 6
            spr = squash(idle, 1.05, 0.96)
            throw.append(pack.place(pack.frame(), spr, dx=3))
        else:
            k = (i - 8) / 2
            throw.append(pack.place(pack.frame(), idle, dx=3 * (1 - k)))
    pack.add("attack_3", throw, "attack_3_ash_projectile.png", fps=12, loop=False,
             projectile_frames=[6], projectile_frames_1based=[7], projectile_spawn=[115, 49])
    pack.add("sentinel_projectile", ember_projectile_frames(pack, 6, cy=49), "sentinel_projectile.png", fps=14, loop=True)
    pack.add("projectile_impact", ember_impact_frames(pack, 8, cy=49, seed=33), "projectile_impact.png", fps=14, loop=False)

    guard = []
    for i in range(8):
        k = min(1.0, i / 3)
        spr = squash(idle, 1.0 + 0.08 * k, 1.0 - 0.06 * k)
        spr = tint(spr, (0.92 + 0.02 * k, 0.92, 0.95), 1.0)
        guard.append(pack.place(pack.frame(), spr, dx=-3 * k))
    pack.add("attack_4", guard, "attack_4_guard.png", fps=8, loop=False)
    pack.add("death", crumble_death(pack, idle, 13, seed=37), "death.png", fps=9, loop=False)
    pack.save(out_dir, "ash_sentinel_anim.json")

def build_drone(idle_p, out_dir):
    pack = Pack(128, 128, 64, 64, grounded=False)
    idle = load(idle_p)
    pal = palette_of(idle)
    pack.add("idle", bob_frames(pack, idle, 8, amp=2.0), "idle.png", fps=8, loop=True)
    pack.add("move", bob_frames(pack, idle, 8, fps_phase=2.0, amp=3.0, dx=2), "move.png", fps=12, loop=True)
    pack.add("alert", alert_frames(pack, idle, 5), "alert.png", fps=10, loop=False)
    pack.add("hurt", hurt_frames(pack, idle, 4), "hurt.png", fps=14, loop=False)
    pack.add("stunned", stunned_frames(pack, idle, 4), "stunned.png", fps=7, loop=True)

    bolt = []
    for i in range(10):
        if i < 4:                      # lens charge glow
            k = i / 3
            spr = tint(idle, (1.0 + 0.1 * k, 1.0 + 0.03 * k, 1.0 - 0.04 * k), 1.0 + 0.05 * k)
            bolt.append(pack.place(pack.frame(), spr, dx=-2 * k))
        elif i < 7:                    # recoil on release at 6
            k = (i - 4) / 2
            spr = squash(idle, 1.0 - 0.04 * k, 1.0)
            bolt.append(pack.place(pack.frame(), spr, dx=-2 - 4 * k))
        else:
            k = (i - 7) / 2
            bolt.append(pack.place(pack.frame(), idle, dx=-6 * (1 - k)))
    pack.add("attack_1", bolt, "attack_1_energy_bolt.png", fps=13, loop=False,
             projectile_frames=[6], projectile_frames_1based=[7], projectile_spawn=[98, 64])
    pack.add("drone_bolt", ember_projectile_frames(pack, 6, cy=64), "drone_bolt.png", fps=14, loop=True)
    pack.add("bolt_impact", ember_impact_frames(pack, 7, cy=64, seed=41), "bolt_impact.png", fps=14, loop=False)

    laser = []
    for i in range(14):
        k = i / 13
        if i < 5:
            spr = tint(idle, (1.0 + 0.12 * k, 1.0 + 0.04 * k, 1.0), 1.0 + 0.05 * k)
            laser.append(pack.place(pack.frame(), spr, dy=-1 * math.sin(k * 6)))
        elif i < 11:                   # firing: steady with vibration
            spr = tint(idle, (1.12, 1.05, 0.98), 1.06)
            laser.append(pack.place(pack.frame(), spr, dx=(1 if i % 2 else -1)))
        else:
            k2 = (i - 11) / 2
            laser.append(pack.place(pack.frame(), idle, dx=(1 - k2)))
    pack.add("attack_2", laser, "attack_2_laser.png", fps=12, loop=False,
             laser_start_frames=[8], laser_start_frames_1based=[9])

    beam = []
    for i in range(14):
        f = pack.frame()
        px = f.load()
        if 8 <= i <= 12:
            wob = 1 if i % 2 else 0
            for x in range(0, 128):
                for w in range(3):
                    y = 32 + w - 1 + wob
                    if 0 <= y < 128:
                        col = EMBER if w == 1 else (200, 90, 30, 255)
                        px[x, y] = col[:3] + (240 if w == 1 else 170,)
        beam.append(f)
    pack.add("laser_beam", beam, "laser_beam.png", fps=12, loop=False,
             laser_start_frames=[8], laser_start_frames_1based=[9],
             anchor={"x": 0, "y": 32})

    pulse = []
    for i in range(11):
        if i < 6:
            k = i / 5
            spr = squash(idle, 1.0 + 0.1 * k, 1.0 + 0.1 * k)
            spr = tint(spr, (1.0 + 0.1 * k, 1.0 + 0.04 * k, 1.0), 1.0 + 0.05 * k)
            pulse.append(pack.place(pack.frame(), spr))
        elif i < 9:                    # pulse out (hit 7)
            spr = squash(idle, 0.9, 0.9)
            pulse.append(pack.place(pack.frame(), spr))
        else:
            pulse.append(pack.place(pack.frame(), idle))
    pack.add("attack_3", pulse, "attack_3_pulse.png", fps=12, loop=False,
             hit_frames=[7], hit_frames_1based=[8])

    pulse_vfx = []
    rng = random.Random(43)
    for i in range(11):
        t = i / 10
        f = pack.frame()
        px = f.load()
        if t > 0.5:
            ring_k = (t - 0.5) / 0.5
            rr = 8 + ring_k * 34
            steps = max(14, int(rr * 2.0))
            for s_i in range(steps):
                ang = 2 * math.pi * s_i / steps
                x = 64 + round(math.cos(ang) * rr)
                y = 64 + round(math.sin(ang) * rr * 0.9)
                if 0 <= x < 128 and 0 <= y < 128 and rng.random() < 0.85:
                    px[x, y] = EMBER[:3] + (int(235 * (1 - ring_k * 0.8)),)
        pulse_vfx.append(f)
    pack.add("pulse_vfx", pulse_vfx, "pulse_vfx.png", fps=12, loop=False,
             hit_frames=[7], hit_frames_1based=[8])

    death = []
    rng = random.Random(47)
    for i in range(12):
        t = i / 11
        spr = idle
        if t < 0.25:
            spr = flash_red(idle, 0.55 * (1 - t / 0.25))
        spr = squash(spr, 1.0 - 0.15 * t, 1.0 - 0.15 * t)
        spr = spr.rotate(-100 * t, expand=True, resample=Image.NEAREST)
        f = pack.place(pack.frame(), spr, dy=30 * t * t)
        if t > 0.3:
            px = f.load()
            for s in range(3):
                x = 64 + rng.randint(-12, 12)
                y = 64 + round(30 * t * t) + rng.randint(-10, 4)
                if 0 <= x < 128 and 0 <= y < 128:
                    px[x, y] = EMBER[:3] + (int(220 * (1 - t)),)
        death.append(f)
    pack.add("death", death, "death.png", fps=11, loop=False)

    death_vfx = []
    rng = random.Random(53)
    parts = [(rng.uniform(0, 2 * math.pi), rng.uniform(6, 22), rng.uniform(0.0, 0.25)) for _ in range(14)]
    for i in range(9):
        t = i / 8
        f = pack.frame()
        px = f.load()
        for ang, dist, delay in parts:
            k = max(0.0, min(1.0, (t - delay) / 0.7))
            if k <= 0.0:
                continue
            x = 64 + round(math.cos(ang) * dist * k)
            y = 88 + round(math.sin(ang) * dist * k * 0.6)
            if 0 <= x < 128 and 0 <= y < 128:
                col = EMBER if rng.random() < 0.4 else pal["mid"]
                px[x, y] = col[:3] + (int(240 * (1 - k * 0.7)),)
        death_vfx.append(f)
    pack.add("death_vfx", death_vfx, "death_vfx.png", fps=14, loop=False)
    pack.save(out_dir, "ruin_drone_anim.json")

if __name__ == "__main__":
    creature = sys.argv[1]
    if creature == "ash_phantom":
        build_phantom(sys.argv[2], sys.argv[3], sys.argv[4])
    elif creature == "ash_wisp":
        build_wisp(sys.argv[2], sys.argv[3])
    elif creature == "ash_sentinel":
        build_sentinel(sys.argv[2], sys.argv[3], sys.argv[4])
    elif creature == "ruin_drone":
        build_drone(sys.argv[2], sys.argv[3])
    else:
        raise SystemExit("unknown creature " + creature)
