#!/usr/bin/env python3
"""Player sprite sheet generator for Ashen Roots.

Builds the 384x832 (8 cols x 13 rows of 48x64) player.png the engine
expects, from four authored key poses: idle / run / jump / slash.

Row layout consumed by _draw_player_sprite() in scripts/main.gd:
  0 idle (5fps loop)      1 run (10fps loop)     2 airborne (indexed by vy)
  3 reserve (idle)        4 slash               5 spear
  6 bow                   7 cannon              8 staff
  9 reserve (idle)       10 flask              11 turret
 12 reserve (idle)
Feet rest on frame row 61 (same as the previous sheet) so grounding is
unchanged. Attack rows follow the telegraph/strike/recover convention and
read correctly with the engine's progress-based frame indexing.
"""
import math, sys
from PIL import Image

FRAME_W = 48
FRAME_H = 64
COLS = 8
ROWS = 13
FEET_Y = 62          # first empty row below the feet (last opaque row = 61)

def load(path):
    im = Image.open(path).convert("RGBA")
    return im.crop(im.getbbox())

def fit(im, max_w=46, max_h=52):
    k = min(max_w / im.width, max_h / im.height, 1.0)
    if k < 1.0:
        im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.NEAREST)
    return im

def squash(im, sx, sy):
    return im.resize((max(1, round(im.width * sx)), max(1, round(im.height * sy))), Image.NEAREST)

def frame():
    return Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))

def place(canvas, spr, dx=0, dy=0):
    x = FRAME_W // 2 - spr.width // 2 + round(dx)
    y = FEET_Y - spr.height + round(dy)
    canvas.alpha_composite(spr, (max(0, min(FRAME_W - spr.width, x)), max(0, min(FRAME_H - spr.height, y))))
    return canvas

def idle_row(idle):
    frames = []
    for i in range(COLS):
        t = i / COLS * 2 * math.pi
        spr = squash(idle, 1.0 - 0.015 * math.sin(t), 1.0 + 0.02 * math.sin(t))
        frames.append(place(frame(), spr))
    return frames

def run_row(run):
    frames = []
    for i in range(COLS):
        t = i / COLS
        phase = t * 2 * math.pi * 2.0          # two strides per loop
        stretch = 1.0 + 0.06 * math.sin(phase) # stride extension/contact
        spr = squash(run, stretch, 1.0 - 0.04 * abs(math.sin(phase)))
        spr = spr.rotate(3 * math.sin(phase), expand=True, resample=Image.NEAREST)
        frames.append(place(frame(), spr, dy=-abs(2.2 * math.sin(phase))))
    return frames

def air_row(jump):
    """Engine picks frames by vertical velocity: 0 rising fast, 2 rising,
    4 apex/slow fall, 6 falling. Pairs stay consistent."""
    frames = []
    tilts = [-10, -10, -5, -5, 3, 3, 10, 10]
    lifts = [0, 0, -1, -1, 0, 0, 2, 2]
    for i in range(COLS):
        spr = jump.rotate(tilts[i], expand=True, resample=Image.NEAREST)
        frames.append(place(frame(), spr, dy=lifts[i]))
    return frames

def attack_row(idle, slash, forward=8):
    """Telegraph (0-2) -> strike (3-5) -> recover (6-7)."""
    frames = []
    for i in range(COLS):
        if i < 3:
            k = i / 2
            spr = squash(idle, 1.0 + 0.05 * k, 1.0 - 0.05 * k)
            frames.append(place(frame(), spr, dx=-3 * k))
        elif i < 6:
            k = (i - 3) / 2
            spr = squash(slash, 1.0 + 0.02 * math.sin(k * math.pi), 1.0)
            frames.append(place(frame(), spr, dx=-3 + (forward + 3) * min(1.0, k * 1.4)))
        else:
            k = (i - 6) / 1
            spr = slash if k < 0.5 else idle
            frames.append(place(frame(), spr, dx=forward * (1 - k) * 0.5))
    return frames

def main(idle_p, run_p, jump_p, slash_p, out_path):
    idle = fit(load(idle_p))
    run = fit(load(run_p))
    jump = fit(load(jump_p), max_h=48)
    slash = fit(load(slash_p))

    rows = {
        0: idle_row(idle),
        1: run_row(run),
        2: air_row(jump),
        3: idle_row(idle),
        4: attack_row(idle, slash, forward=8),   # slash
        5: attack_row(idle, slash, forward=10),  # spear: longer reach
        6: attack_row(idle, slash, forward=4),   # bow: hold/aim
        7: attack_row(idle, slash, forward=5),   # cannon
        8: attack_row(idle, slash, forward=5),   # staff
        9: idle_row(idle),
        10: attack_row(idle, slash, forward=6),  # flask throw
        11: attack_row(idle, slash, forward=4),  # turret place
        12: idle_row(idle),
    }
    sheet = Image.new("RGBA", (FRAME_W * COLS, FRAME_H * ROWS), (0, 0, 0, 0))
    for r in range(ROWS):
        for c in range(COLS):
            sheet.alpha_composite(rows[r][c], (c * FRAME_W, r * FRAME_H))
    sheet.save(out_path)
    print("written", out_path, sheet.size)

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
