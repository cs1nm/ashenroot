#!/usr/bin/env python3
"""Player sprite sheet generator for Ashen Roots — hero v5.

History:
  v3 (original) — player: "soap". 42 real palette colors, ~8 near-black
  outline shades (soft downscale + median cut), face 8x5 px hidden behind
  the fringe => dirt, not a character.
  v4 (chibi)    — player: "awful". 37% head, cartoon baby, off style.
  v5 (this)     — keep the v3 SILHOUETTE (proportions, wanderer look,
  layers) but paint it cleanly and give it a readable face.

Method (source of truth for the silhouette = the v3 sheet itself):
  1. extract the four authored v3 base frames (idle / run / air / slash)
     from tools/creature_pipeline/hero_v3_bases.png;
  2. remap every opaque pixel to a 22-color flat palette (v3 hues);
  3. 3x3 mode filter (kills single-pixel noise, keeps zone edges);
  4. re-outline with ONE outline color (no near-black shades);
  5. re-author the face on EVERY pose from a detected face anchor
     (topmost skin row): opened forehead, two 2x2 glint eyes, nose,
     mouth line — readable at game scale;
  6. build the same 384x832 13-row x 8-col sheet the engine expects
     (feet stay on frame row 61 so the 12x28 PLAYER_SIZE physics body
     is untouched), quantize jointly across all poses (median cut, no
     dither, NO despeckle — it ate the eyes on v3).

Run from the repository root:
    python3 tools/creature_pipeline/animate_hero.py [out.png]
"""
import math
import sys
from collections import Counter
from PIL import Image, ImageDraw

FRAME_W = 48
FRAME_H = 64
COLS = 8
ROWS = 13
FEET_Y = 62
BASES_PATH = "tools/creature_pipeline/hero_v3_bases.png"

# --------------------------------------------------------------------------
# Clean 22-color palette (v3-style hues, flat steps). These exact values
# must be mirrored into CHAR_RECOLOR_ZONES / PROTECTED in scripts/main.gd.
# --------------------------------------------------------------------------
BLACK = (10, 8, 16)             # unified outline + pupil

SKIN_L = (241, 186, 128)
SKIN = (216, 158, 114)
SKIN_M = (184, 128, 96)
SKIN_D = (134, 88, 74)

HAIR_L = (117, 56, 47)
HAIR = (89, 38, 38)
HAIR_M = (67, 25, 30)
HAIR_D = (42, 10, 18)

TUNIC_L = (125, 134, 143)
TUNIC = (112, 119, 130)
TUNIC_M = (72, 83, 104)
TUNIC_D = (55, 60, 75)
TUNIC_DK = (48, 44, 54)
TUNIC_X = (36, 33, 40)

BOOT_L = (107, 93, 91)
BOOT = (101, 66, 61)
BOOT_M = (81, 60, 62)
BOOT_D = (73, 48, 52)
BOOT_DK = (48, 30, 36)

EYE_WHITE = (236, 238, 240)
BUCKLE = (203, 150, 68)

PALETTE = [BLACK, SKIN_L, SKIN, SKIN_M, SKIN_D, HAIR_L, HAIR, HAIR_M,
           HAIR_D, TUNIC_L, TUNIC, TUNIC_M, TUNIC_D, TUNIC_DK, TUNIC_X,
           BOOT_L, BOOT, BOOT_M, BOOT_D, BOOT_DK, EYE_WHITE, BUCKLE]

RECOLOR_ZONES = {
    "skin": [SKIN_L, SKIN, SKIN_M, SKIN_D],
    "hair": [HAIR_L, HAIR, HAIR_M, HAIR_D],
    "tunic": [TUNIC_L, TUNIC, TUNIC_M, TUNIC_D, TUNIC_DK, TUNIC_X],
    "boots": [BOOT_L, BOOT, BOOT_M, BOOT_D, BOOT_DK],
}
PROTECTED = [EYE_WHITE, BUCKLE, BLACK]

SKIN_COLORS = {SKIN_L, SKIN, SKIN_M, SKIN_D}
HAIR_COLORS = {HAIR_L, HAIR, HAIR_M, HAIR_D}

# --------------------------------------------------------------------------
def nearest(c, pal):
    best, bd = None, 1 << 30
    for p in pal:
        d = sum((c[i] - p[i]) ** 2 for i in range(3))
        if d < bd:
            bd, best = d, p
    return best

def remap(im):
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    px, op = im.load(), out.load()
    for y in range(im.height):
        for x in range(im.width):
            c = px[x, y]
            if c[3] == 0:
                continue
            n = nearest(c[:3], PALETTE)
            op[x, y] = (n[0], n[1], n[2], 255)
    return out

def mode_filter(im):
    px = im.load()
    W, H = im.size
    changes = []
    for y in range(1, H - 1):
        for x in range(1, W - 1):
            if px[x, y][3] == 0:
                continue
            win = Counter()
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    if dx == 0 and dy == 0:
                        continue
                    c = px[x + dx, y + dy]
                    if c[3]:
                        win[(c[0], c[1], c[2])] += 1
            if not win:
                continue
            top, cnt = win.most_common(1)[0]
            own = (px[x, y][0], px[x, y][1], px[x, y][2])
            if own != top and cnt >= 5:
                changes.append((x, y, top))
    for (x, y, c) in changes:
        px[x, y] = (c[0], c[1], c[2], 255)
    return im

def outline(im):
    px = im.load()
    W, H = im.size
    out = []
    for y in range(H):
        for x in range(W):
            if px[x, y][3] == 0:
                continue
            edge = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if nx < 0 or ny < 0 or nx >= W or ny >= H or px[nx, ny][3] == 0:
                    edge = True
                    break
            if edge:
                out.append((x, y))
    for (x, y) in out:
        px[x, y] = (BLACK[0], BLACK[1], BLACK[2], 255)
    return im

def interior(px, x, y, W, H):
    """Pixel is not on the silhouette edge (all 4 neighbors opaque)."""
    if x <= 0 or y <= 0 or x >= W - 1 or y >= H - 1:
        return False
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        if px[x + dx, y + dy][3] == 0:
            return False
    return True

# --------------------------------------------------------------------------
# Face. The v3 face is small and hidden; we open the forehead and place
# eyes/nose/mouth relative to the DETECTED face anchor (topmost skin row),
# so the same recipe lands correctly on every pose (run/air heads shift
# by a pixel or two).
# --------------------------------------------------------------------------
def find_face_anchor(im):
    px = im.load()
    for y in range(14, 30):
        xs = [x for x in range(16, 34)
              if px[x, y][3] and px[x, y][:3] in SKIN_COLORS]
        if len(xs) >= 2:
            return (min(xs), y)
    return (23, 20)  # fallback: idle expectation

def reauthor_face(im):
    d = ImageDraw.Draw(im)
    px = im.load()
    W, H = im.size

    def rect(x0, y0, x1, y1, c):
        d.rectangle([x0, y0, x1, y1], fill=c)

    ax, ay = find_face_anchor(im)
    # 1. Open the forehead: one row of hair above the eyes -> skin, so the
    #    fringe rides higher and the face gets room. Only interior pixels
    #    (never the silhouette outline).
    for x in range(ax - 1, ax + 10):
        if not interior(px, x, ay - 1, W, H):
            continue
        c = px[x, ay - 1][:3]
        if c in HAIR_COLORS or c == BLACK:
            rect(x, ay - 1, x, ay - 1, SKIN_L)
    # Hairline shadow band right under the fringe (1px, softer than skin).
    for x in range(ax + 2, ax + 10):
        if interior(px, x, ay - 1, W, H):
            c = px[x, ay - 1][:3]
            if c == SKIN_L:
                rect(x, ay - 1, x, ay - 1, SKIN_M if x >= ax + 4 else SKIN)
    # 2. Eyes: 2x2 BLACK with a top-left white glint, two rows below the
    #    anchor, INSIDE the face (they sit on skin or on the old fringe
    #    shadow, never on the outline).
    for ex in (ax + 1, ax + 7):
        for yy in (ay + 2, ay + 3):
            for xx in (ex, ex + 1):
                if interior(px, xx, yy, W, H):
                    rect(xx, yy, xx, yy, BLACK)
        if interior(px, ex, ay + 2, W, H):
            rect(ex, ay + 2, ex, ay + 2, EYE_WHITE)
    # 3. Under-eye shading.
    for ex in (ax + 1, ax + 7):
        if interior(px, ex, ay + 4, W, H):
            rect(ex, ay + 4, ex + 1, ay + 4, SKIN_M)
    # 4. Nose shadow (two pixels between the eyes, one row down).
    for xx in (ax + 4, ax + 5):
        if interior(px, xx, ay + 4, W, H):
            if px[xx, ay + 4][:3] in SKIN_COLORS:
                rect(xx, ay + 4, xx, ay + 4, SKIN_D)
    # 5. Mouth: short dark-red line two rows below the nose.
    if interior(px, ax + 3, ay + 6, W, H):
        rect(ax + 3, ay + 6, ax + 7, ay + 6, HAIR_M)
    return im

def paint_buckle(im):
    """v3 has no belt buckle (it appeared in v4). Find the dark belt band
    on the torso (TUNIC_D/TUNIC_DK run) and put a small amber buckle in its
    middle so the 22nd palette color (and the protected detail) actually
    exists on the sheet. Interior-checked: never overwrites the outline."""
    d = ImageDraw.Draw(im)
    px = im.load()
    W, H = im.size
    for y in range(42, 49):
        run = 0
        for x in range(16, 32):
            if px[x, y][3] and px[x, y][:3] in (TUNIC_D, TUNIC_DK):
                run += 1
                if run >= 5:
                    cx = x - run // 2 - 1
                    for yy in (y, y + 1):
                        for xx in (cx, cx + 1, cx + 2):
                            if interior(px, xx, yy, W, H):
                                d.rectangle([xx, yy, xx, yy], fill=BUCKLE)
                    return im
            else:
                run = 0
    return im

# --------------------------------------------------------------------------
# Base frames: 4 authored v3 poses as a 192x64 strip (idle, run, air, slash).
# --------------------------------------------------------------------------
def get_base_frames(path=BASES_PATH):
    strip = Image.open(path).convert("RGBA")
    names = ["idle", "run", "air", "slash"]
    return {n: strip.crop((i * FRAME_W, 0, (i + 1) * FRAME_W, FRAME_H))
            for i, n in enumerate(names)}

def clean_frame(fr):
    fr = remap(fr)
    fr = mode_filter(fr)
    fr = outline(fr)
    return fr

def crop_sprite(im):
    return im.crop(im.getbbox())

def squash(im, sx, sy):
    im = crop_sprite(im)
    return im.resize((max(1, round(im.width * sx)), max(1, round(im.height * sy))), Image.NEAREST)

def place(canvas, spr, dx=0, dy=0):
    x = FRAME_W // 2 - spr.width // 2 + round(dx)
    y = FEET_Y - spr.height + round(dy)
    x = max(0, min(FRAME_W - spr.width, x))
    y = max(0, min(FRAME_H - spr.height, y))
    canvas.alpha_composite(spr, (x, y))
    return canvas

def frame():
    return Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))

def idle_row(idle):
    frames = []
    for i in range(COLS):
        t = i / COLS * 2 * math.pi
        spr = squash(idle, 1.0 - 0.010 * math.sin(t), 1.0 + 0.015 * math.sin(t))
        frames.append(place(frame(), spr))
    return frames

def run_row(run):
    frames = []
    for i in range(COLS):
        t = i / COLS
        phase = t * 2 * math.pi
        stretch = 1.0 + 0.03 * math.sin(phase)
        spr = squash(run, stretch, 1.0 - 0.04 * abs(math.sin(phase)))
        spr = spr.rotate(2.0 * math.sin(phase), expand=True, resample=Image.NEAREST)
        spr = spr.crop(spr.getbbox())
        bob = -abs(2.0 * math.sin(phase))
        frames.append(place(frame(), spr, dy=bob))
    return frames

def air_row(air):
    tilts = [4, 4, 2, 2, -1, -1, -4, -4]
    frames = []
    for i in range(COLS):
        base = crop_sprite(air)
        spr = base.rotate(tilts[i], expand=True, resample=Image.NEAREST)
        frames.append(place(frame(), spr))
    return frames

def attack_row(idle, slash, forward):
    frames = []
    for i in range(COLS):
        if i < 2:
            spr = squash(slash, 1.0 - 0.02 * i, 1.0 + 0.01 * i)
            frames.append(place(frame(), crop_sprite(spr), dx=-2 - 2 * i))
        elif i < 5:
            k = (i - 2) / 2.0
            spr = squash(slash, 1.0 + 0.02 * math.sin(k * math.pi), 1.0)
            frames.append(place(frame(), crop_sprite(spr), dx=forward * min(1.0, 0.4 + 0.3 * k)))
        else:
            spr = idle
            frames.append(place(frame(), crop_sprite(spr), dx=forward * (1 - (i - 5) / 2.0) * 0.5))
    return frames

def build_sheet(poses):
    rows = {
        0: idle_row(poses["idle"]),
        1: run_row(poses["run"]),
        2: air_row(poses["air"]),
        3: idle_row(poses["idle"]),
        4: attack_row(poses["idle"], poses["slash"], forward=7),
        5: attack_row(poses["idle"], poses["slash"], forward=9),
        6: attack_row(poses["idle"], poses["slash"], forward=4),
        7: attack_row(poses["idle"], poses["slash"], forward=4),
        8: attack_row(poses["idle"], poses["slash"], forward=5),
        9: idle_row(poses["idle"]),
        10: attack_row(poses["idle"], poses["slash"], forward=6),
        11: attack_row(poses["idle"], poses["slash"], forward=4),
        12: idle_row(poses["idle"]),
    }
    sheet = Image.new("RGBA", (FRAME_W * COLS, FRAME_H * ROWS), (0, 0, 0, 0))
    for r in range(ROWS):
        for c in range(COLS):
            sheet.alpha_composite(rows[r][c], (c * FRAME_W, r * FRAME_H))
    return sheet

def joint_quantize(images, colors=22, protected=PROTECTED, tol=14):
    hist = {}
    for im in images:
        for p in im.getdata():
            if p[3] == 0:
                continue
            c = (p[0], p[1], p[2])
            hist[c] = hist.get(c, 0) + 1
    if len(hist) <= colors:
        pal = sorted(hist)
    else:
        pal = _median_cut(hist, colors)
    out = []
    for im in images:
        o = im.copy(); op = o.load()
        for yy in range(im.height):
            for xx in range(im.width):
                if op[xx, yy][3] == 0:
                    continue
                src = op[xx, yy]
                c = nearest(src[:3], pal)
                for pc in protected:
                    if src[:3] == pc:
                        c = pc
                        break
                else:
                    for pc in protected:
                        if all(abs(src[i] - pc[i]) <= tol for i in range(3)):
                            c = pc
                            break
                op[xx, yy] = (c[0], c[1], c[2], 255)
        out.append(o)
    used = sorted({(p[0], p[1], p[2]) for im in out for p in im.getdata() if p[3] > 0})
    return out, used

def _median_cut(hist, colors):
    boxes = [[(c, n) for c, n in hist.items()]]
    while len(boxes) < colors:
        boxes.sort(key=lambda b: (-len(b), -max(max(c[k] for c, _ in b) - min(c[k] for c, _ in b) for k in range(3))))
        box = boxes.pop(0)
        if len(box) < 2:
            if all(len(b) < 2 for b in boxes):
                boxes.append(box)
                break
            boxes.insert(0, box)
            continue
        spread = [max(c[k] for c, _ in box) - min(c[k] for c, _ in box) for k in range(3)]
        ch = spread.index(max(spread))
        box.sort(key=lambda item: item[0][ch])
        mid = len(box) // 2
        boxes.append(box[:mid])
        boxes.append(box[mid:])
    pal = []
    for box in boxes:
        w = sum(n for _, n in box)
        pal.append(tuple(round(sum(c[k] * n for c, n in box) / w) for k in range(3)))
    return pal

def validate_palette():
    assert len(PALETTE) == 22, "palette must stay 22 colors"
    assert len(set(PALETTE)) == 22, "palette contains duplicates"
    # The engine's _recolor_player_sheet matches a pixel to a zone color
    # when ALL THREE channels sit within 0.045 (~11.5/255). Two colors from
    # DIFFERENT zones must therefore differ by >= 12 in at least one channel
    # (otherwise recolor leaks across zones). Within a zone the ramp is
    # scanned light-to-dark, so close neighbors are fine.
    TH = 11.5
    zone_colors = [c for lst in RECOLOR_ZONES.values() for c in lst]
    zone_of = {}
    for z, lst in RECOLOR_ZONES.items():
        for c in lst:
            zone_of[c] = z
    for i, a in enumerate(zone_colors):
        for b in zone_colors[i + 1:]:
            if zone_of[a] == zone_of[b]:
                continue
            sep = max(abs(a[k] - b[k]) for k in range(3))
            assert sep >= 12, "cross-zone colors too close: %s (%s) vs %s (%s)" % (a, zone_of[a], b, zone_of[b])
    for pc in PROTECTED:
        for c in zone_colors:
            sep = max(abs(pc[i] - c[i]) for i in range(3))
            assert sep >= 12, "protected %s collides with zone color %s" % (pc, c)
    for c in zone_colors:
        assert sum(c) > sum(BLACK) + 12, "outline must be darkest: %s" % (c,)
    print("palette ok: 22 colors, cross-zone separated, face protected")

def verify_sheet(sheet):
    used = {}
    for p in sheet.getdata():
        if p[3] == 0:
            continue
        key = (p[0], p[1], p[2])
        used[key] = used.get(key, 0) + 1
    assert set(used) <= set(PALETTE), "off-palette: %s" % (set(used) - set(PALETTE))
    assert len(used) == 22, "expected 22 colors, found %d" % len(used)
    feet_ok = {0: (61, 61), 1: (55, 61), 2: (0, 61), 3: (61, 61),
               4: (61, 61), 5: (61, 61), 6: (61, 61), 7: (61, 61),
               8: (61, 61), 9: (61, 61), 10: (61, 61), 11: (61, 61),
               12: (61, 61)}
    for r in range(ROWS):
        for c in range(COLS):
            f = sheet.crop((c * FRAME_W, r * FRAME_H, (c + 1) * FRAME_W, (r + 1) * FRAME_H))
            bbox = f.getbbox()
            assert bbox is not None, "empty frame %d,%d" % (r, c)
            feet = bbox[3] - 1
            lo, hi = feet_ok[r]
            assert lo <= feet <= hi, "frame %d,%d feet at %d (want %d..%d)" % (r, c, feet, lo, hi)
    print("sheet ok: 22 colors, all %d frames grounded per contract" % (ROWS * COLS))

# --------------------------------------------------------------------------
def main(out_path="assets/textures/player.png"):
    validate_palette()
    bases = get_base_frames()
    cleaned = {n: clean_frame(fr) for n, fr in bases.items()}
    poses = {}
    for name in ("idle", "run", "air", "slash"):
        poses[name] = paint_buckle(reauthor_face(cleaned[name]))
    quant, used = joint_quantize([poses[n] for n in ("idle", "run", "air", "slash")])
    poses = {n: quant[i] for i, n in enumerate(("idle", "run", "air", "slash"))}
    sheet = build_sheet(poses)
    verify_sheet(sheet)
    sheet.save(out_path)
    print("written", out_path, sheet.size)

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    main(out_path=args[0] if len(args) > 0 else "assets/textures/player.png")
