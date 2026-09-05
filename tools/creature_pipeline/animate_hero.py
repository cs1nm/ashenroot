#!/usr/bin/env python3
"""Player sprite sheet generator for Ashen Roots — hero v4.

Player feedback on v3: "no face, flat". v4 changes the character design:

  * Terraria-style proportions: big head (~37% of body height, incl. hair),
    14px-wide face with a clearly readable face — 3x2 dark eyes with a white
    glint pixel, nose, smile, fringe shadow on the forehead.
  * Bright, clean palette (22 colors, joint across ALL poses) instead of the
    muddy dark v3 ramp. Hair keeps a small plait; belt with amber buckle;
    boots with lighter cuffs and dark soles.
  * Palette is quantized JOINTLY over all authored poses (median cut, no
    dither, NO despeckle — despeckle ate the eyes on v3). Face colors
    (eye white/eye dark) and the buckle are protected from quantization and
    from recolor so no recolored hero can lose the face.
  * Four authored poses (idle / run / jump / slash) drive the same
    384x832, 13-row x 8-col sheet layout the engine expects:
      0 idle (5fps)   1 run (10fps)   2 airborne (by vy)   3 reserve (idle)
      4 slash         5 spear         6 bow                7 cannon
      8 staff         9 reserve      10 flask             11 turret
     12 reserve (idle)
    Feet rest on frame row 61 (FEET_Y=62) so grounding and the 12x28
    PLAYER_SIZE physics body are unchanged. Attack rows follow
    telegraph -> strike -> recover; the engine indexes frames start-to-end
    (attack_anim_time counts down), which matches this order.

Run from the repository root:
    python3 tools/creature_pipeline/animate_hero.py            # writes the sheet
    python3 tools/creature_pipeline/animate_hero.py /tmp/out.png  # custom path
"""
import math
import sys
from PIL import Image, ImageDraw

FRAME_W = 48
FRAME_H = 64
COLS = 8
ROWS = 13
FEET_Y = 62          # frame rows [FEET_Y ..] must stay empty; feet bottom = 61

# --------------------------------------------------------------------------
# 22-color joint palette. Zone membership drives CHAR_RECOLOR_ZONES in
# scripts/main.gd: skin/hair/tunic/boots recolor, face & buckle are fixed so
# the face can never be destroyed by customization.
# --------------------------------------------------------------------------
OUT = (26, 20, 34)          # silhouette outline (fixed)

SKIN_HI = (250, 216, 178)
SKIN = (235, 190, 148)
SKIN_SH = (208, 152, 116)
SKIN_DK = (172, 118, 92)
MOUTH = (150, 92, 84)

HAIR_HI = (146, 74, 50)
HAIR = (110, 50, 36)
HAIR_SH = (78, 32, 28)
HAIR_DK = (54, 22, 22)

TUNIC_HI = (168, 176, 186)
TUNIC = (136, 146, 158)
TUNIC_MID = (106, 118, 134)
TUNIC_SH = (80, 92, 110)
TUNIC_DK = (58, 66, 82)

BOOTS_HI = (128, 94, 64)
BOOTS = (96, 68, 50)
BOOTS_SH = (68, 46, 38)
BOOTS_DK = (54, 36, 32)

EYE_WHITE = (240, 244, 246)  # fixed (face)
EYE_DARK = (28, 22, 32)      # fixed (face)
BUCKLE = (214, 158, 66)      # fixed (amber)

PALETTE = [OUT, SKIN_HI, SKIN, SKIN_SH, SKIN_DK, MOUTH, HAIR_HI, HAIR,
           HAIR_SH, HAIR_DK, TUNIC_HI, TUNIC, TUNIC_MID, TUNIC_SH,
           TUNIC_DK, BOOTS_HI, BOOTS, BOOTS_SH, BOOTS_DK, EYE_WHITE,
           EYE_DARK, BUCKLE]

# Recolor zones -> exact base-sheet colors (order = matching priority).
RECOLOR_ZONES = {
    "skin": [SKIN_HI, SKIN, SKIN_SH, SKIN_DK, MOUTH],
    "hair": [HAIR_HI, HAIR, HAIR_SH, HAIR_DK],
    "tunic": [TUNIC_HI, TUNIC, TUNIC_MID, TUNIC_SH, TUNIC_DK],
    "boots": [BOOTS_HI, BOOTS, BOOTS_SH, BOOTS_DK],
}
PROTECTED = [EYE_WHITE, EYE_DARK, BUCKLE, OUT]

# --------------------------------------------------------------------------
# Low-level painting (flat fills at 1x; no anti-aliasing anywhere).
# --------------------------------------------------------------------------
def canvas():
    return Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))

def rect(d, x0, y0, x1, y1, c):
    d.rectangle([x0, y0, x1, y1], fill=c)

def px(d, x, y, c):
    d.point([(x, y)], fill=c)

def outline_pass(im):
    """Silhouette outline: every opaque pixel touching transparency becomes
    OUT. Done last, so it hugs the exact shape and keeps 1px gaps (e.g.
    between arm and torso, between legs) readable."""
    d = ImageDraw.Draw(im)
    for y in range(FRAME_H):
        for x in range(FRAME_W):
            a = im.getpixel((x, y))[3]
            if a == 0:
                continue
            edge = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if nx < 0 or ny < 0 or nx >= FRAME_W or ny >= FRAME_H or im.getpixel((nx, ny))[3] == 0:
                    edge = True
                    break
            if edge:
                d.point([(x, y)], fill=OUT)
    return im

# --------------------------------------------------------------------------
# Body parts. All numbers are hand-authored pixel coordinates on the 48x64
# frame; the sheet is drawn facing RIGHT (engine flips by facing direction).
# Proportions: head (incl. hair) rows 16..32 (~37% of the 46px figure),
# torso 35..48, legs 48..61. Face rows 21..32.
# --------------------------------------------------------------------------
def draw_head(d, dx=0, dy=0):
    """Big hero head: hair cap + fringe + side locks + plait, 14px face with
    readable 3x2 glint eyes, nose, smile. The plait sits at the back (+x)."""
    # Hair cap with highlight band (kept one row inside the silhouette so the
    # outline pass can't eat it).
    rect(d, 16 + dx, 16 + dy, 31 + dx, 19 + dy, HAIR)
    rect(d, 17 + dx, 17 + dy, 30 + dx, 17 + dy, HAIR_HI)
    # Fringe + underside shadow line; forehead shading below it.
    rect(d, 17 + dx, 20 + dy, 30 + dx, 20 + dy, HAIR_SH)
    rect(d, 18 + dx, 21 + dy, 29 + dx, 21 + dy, SKIN_SH)
    # Face.
    rect(d, 17 + dx, 22 + dy, 30 + dx, 32 + dy, SKIN)
    rect(d, 18 + dx, 22 + dy, 29 + dx, 22 + dy, SKIN_HI)  # forehead glow
    # Eyes: 3x2 dark with white glint at the top-left corner.
    rect(d, 18 + dx, 24 + dy, 20 + dx, 25 + dy, EYE_DARK)
    px(d, 18 + dx, 24 + dy, EYE_WHITE)
    rect(d, 27 + dx, 24 + dy, 29 + dx, 25 + dy, EYE_DARK)
    px(d, 27 + dx, 24 + dy, EYE_WHITE)
    # Nose (lit side + shadow side) + smile with darker corners.
    rect(d, 23 + dx, 27 + dy, 23 + dx, 27 + dy, SKIN_SH)
    rect(d, 24 + dx, 27 + dy, 24 + dx, 27 + dy, SKIN_DK)
    rect(d, 21 + dx, 30 + dy, 27 + dx, 30 + dy, MOUTH)
    px(d, 20 + dx, 30 + dy, SKIN_DK)
    px(d, 28 + dx, 30 + dy, SKIN_DK)
    # Chin shading.
    rect(d, 18 + dx, 31 + dy, 29 + dx, 32 + dy, SKIN_SH)
    # Side locks + plait behind the head.
    rect(d, 15 + dx, 19 + dy, 16 + dx, 24 + dy, HAIR_SH)
    rect(d, 31 + dx, 19 + dy, 32 + dx, 24 + dy, HAIR_SH)
    rect(d, 32 + dx, 18 + dy, 33 + dx, 25 + dy, HAIR_SH)
    rect(d, 33 + dx, 24 + dy, 34 + dx, 27 + dy, HAIR_DK)

def draw_torso(d, dx=0):
    """Tunic torso: collar, center sheen, side shading, belt with buckle,
    short skirt. 14px wide (x 17..30 at dx=0)."""
    # Neck (hair shadow on the sides).
    rect(d, 21 + dx, 33, 26 + dx, 34, SKIN)
    rect(d, 21 + dx, 34, 21 + dx, 34, SKIN_DK)
    rect(d, 26 + dx, 34, 26 + dx, 34, SKIN_DK)
    rect(d, 22 + dx, 34, 25 + dx, 34, SKIN_SH)
    # Collar.
    rect(d, 19 + dx, 35, 28 + dx, 36, TUNIC_SH)
    # Torso.
    rect(d, 18 + dx, 36, 29 + dx, 46, TUNIC)
    rect(d, 21 + dx, 37, 26 + dx, 43, TUNIC_HI)
    rect(d, 18 + dx, 38, 18 + dx, 44, TUNIC_MID)
    rect(d, 29 + dx, 38, 29 + dx, 44, TUNIC_MID)
    rect(d, 19 + dx, 44, 28 + dx, 44, TUNIC_MID)
    # Belt + buckle.
    rect(d, 18 + dx, 45, 29 + dx, 46, TUNIC_DK)
    rect(d, 22 + dx, 45, 25 + dx, 46, BUCKLE)
    # Skirt with hem shadow.
    rect(d, 18 + dx, 47, 29 + dx, 48, TUNIC)
    rect(d, 18 + dx, 48, 29 + dx, 48, TUNIC_SH)

# Arm patterns, authored for the RIGHT (+x) side; mirrored for the left.
# Arm patterns: (rel x0, y0, x1, y1, color) relative to the shoulder anchor.
# Author for the RIGHT side; +x = forward (facing direction). Thickness is
# 3px everywhere on purpose: the outline pass eats border pixels, so a 2px
# limb would turn into a solid black blob (that was the run-frame problem).
ARM = {
    # "mirror" patterns are body-symmetric shapes (hang/raise/stretch out)
    # and get flipped for the left side; "abs" patterns describe the
    # swing DIRECTION (fwd = +x, back = -x) and are used verbatim for both
    # sides — a forward-swung left arm must also point forward.
    "down": ("mirror", [
        (0, 0, 2, 2, TUNIC),                                 # sleeve
        (1, 0, 1, 0, TUNIC_SH),                              # sleeve highlight
        (0, 3, 2, 7, SKIN),                                  # forearm
        (0, 8, 2, 10, SKIN_SH), (1, 9, 1, 9, SKIN),          # fist
    ]),
    "swing_fwd": ("abs", [
        (0, 0, 2, 2, TUNIC), (1, 1, 1, 1, TUNIC_SH),
        (3, 1, 5, 3, SKIN),
        (6, 2, 8, 4, SKIN_SH), (7, 3, 7, 3, SKIN),
    ]),
    "swing_back": ("abs", [   # sweeping past the hip, not across the chest
        (-1, 0, 1, 2, TUNIC),
        (-4, 4, -2, 6, SKIN),
        (-7, 5, -5, 7, SKIN_SH), (-6, 6, -6, 6, SKIN),
    ]),
    "raised": ("mirror", [
        (0, -1, 2, 0, TUNIC),
        (3, -5, 5, -2, SKIN),
        (3, -8, 5, -6, SKIN_SH), (4, -7, 4, -7, SKIN),
    ]),
    "out": ("mirror", [
        (0, 0, 2, 2, TUNIC),
        (3, 0, 5, 2, SKIN),
        (6, 0, 8, 2, SKIN_SH), (7, 2, 7, 2, SKIN_DK),
    ]),
    "across": ("abs", [   # slash wind-up: hand pulled back across the chest
        (-1, 0, 1, 2, TUNIC),
        (-4, 1, -2, 3, SKIN),
        (-7, 0, -5, 2, SKIN_SH), (-6, 1, -6, 1, SKIN),
    ]),
    "extended": ("abs", [  # full forward strike at shoulder height
        (0, 0, 3, 2, TUNIC),
        (4, 1, 9, 3, SKIN),
        (10, 1, 12, 3, SKIN_SH), (11, 2, 11, 2, SKIN),
    ]),
}

def draw_arm(d, side, variant, ax, ay):
    """side=+1 right, -1 left; (ax, ay) = shoulder anchor."""
    mode, pat = ARM[variant]
    for (rx, y0, rx1, y1, c) in pat:
        if mode == "mirror" and side < 0:
            x0, x1 = ax - rx1, ax - rx
        else:
            x0, x1 = ax + rx, ax + rx1
        rect(d, x0, ay + y0, x1, ay + y1, c)

# Leg patterns (absolute, relative to hip row 48). Facing RIGHT.
LEG = {
    "stand": {
        "L": [(19, 48, 22, 51, TUNIC_DK), (18, 52, 23, 59, BOOTS),
              (18, 52, 19, 53, BOOTS_HI), (18, 60, 23, 61, BOOTS_DK),
              (23, 56, 23, 57, BOOTS_SH)],
        "R": [(26, 48, 29, 51, TUNIC_DK), (25, 52, 30, 59, BOOTS),
              (29, 52, 30, 53, BOOTS_HI), (25, 60, 30, 61, BOOTS_DK),
              (25, 56, 25, 57, BOOTS_SH)],
    },
    "stride_front": {  # LEADING leg: reaches forward, foot planted on 61
        "L": [(21, 48, 24, 50, TUNIC_DK),          # thigh angled forward
              (24, 51, 30, 55, BOOTS),             # shin forward
              (25, 51, 26, 52, BOOTS_HI),          # cuff highlight
              (24, 56, 31, 60, BOOTS),             # foot ahead of the body
              (24, 61, 29, 61, BOOTS_DK),          # sole on the ground row
              (30, 58, 31, 60, BOOTS_DK),          # toe cap
              (28, 53, 28, 54, BOOTS_SH)],
        "R": [(26, 48, 29, 50, TUNIC_DK),
              (29, 51, 35, 55, BOOTS),
              (30, 51, 31, 52, BOOTS_HI),
              (29, 56, 36, 60, BOOTS),
              (29, 61, 34, 61, BOOTS_DK),
              (35, 58, 36, 60, BOOTS_DK),
              (33, 53, 33, 54, BOOTS_SH)],
    },
    "stride_back": {   # TRAILING leg: extended behind, heel lifted
        "L": [(16, 48, 19, 50, TUNIC_DK),          # thigh angled back
              (14, 51, 18, 55, BOOTS),
              (14, 51, 15, 52, BOOTS_HI),
              (14, 56, 18, 57, BOOTS),             # heel up
              (14, 58, 19, 58, BOOTS_DK),          # toe as the sole
              (16, 53, 16, 54, BOOTS_SH)],
        "R": [(21, 48, 24, 50, TUNIC_DK),
              (19, 51, 23, 55, BOOTS),
              (19, 51, 20, 52, BOOTS_HI),
              (19, 56, 23, 57, BOOTS),
              (19, 58, 24, 58, BOOTS_DK),
              (21, 53, 21, 54, BOOTS_SH)],
    },
    "tuck": {          # jump rise: knees up, feet under the skirt
        "L": [(19, 48, 22, 49, TUNIC_DK), (18, 50, 23, 54, BOOTS),
              (22, 50, 23, 51, BOOTS_HI), (18, 55, 23, 55, BOOTS_DK)],
        "R": [(26, 48, 29, 49, TUNIC_DK), (25, 50, 30, 54, BOOTS),
              (28, 50, 29, 51, BOOTS_HI), (25, 55, 30, 55, BOOTS_DK)],
    },
    "mid": {           # jump apex: legs half-extended
        "L": [(19, 48, 22, 50, TUNIC_DK), (18, 51, 23, 57, BOOTS),
              (22, 51, 23, 52, BOOTS_HI), (18, 58, 23, 58, BOOTS_DK)],
        "R": [(26, 48, 29, 50, TUNIC_DK), (25, 51, 30, 57, BOOTS),
              (28, 51, 29, 52, BOOTS_HI), (25, 58, 30, 58, BOOTS_DK)],
    },
    "reach": {         # jump fall: legs extended down
        "L": [(19, 48, 22, 51, TUNIC_DK), (18, 52, 23, 59, BOOTS),
              (22, 52, 23, 53, BOOTS_HI), (18, 60, 23, 60, BOOTS_DK)],
        "R": [(26, 48, 29, 51, TUNIC_DK), (25, 52, 30, 59, BOOTS),
              (28, 52, 29, 53, BOOTS_HI), (25, 60, 30, 60, BOOTS_DK)],
    },
    "lunge": {         # slash: front leg bent forward, rear leg extended back,
                       # BOTH feet planted on row 61 (no floating hero)
        "L": [(16, 48, 19, 51, TUNIC_DK), (14, 52, 19, 58, BOOTS),
              (16, 52, 17, 53, BOOTS_HI), (17, 53, 17, 56, BOOTS_SH),
              (14, 59, 19, 61, BOOTS_DK)],
        "R": [(25, 48, 28, 51, TUNIC_DK), (26, 52, 31, 58, BOOTS),
              (29, 52, 30, 53, BOOTS_HI), (27, 59, 32, 61, BOOTS_DK)],
    },
}

def draw_leg(d, side, variant):
    for (x0, y0, x1, y1, c) in LEG[variant]["L" if side < 0 else "R"]:
        rect(d, x0, y0, x1, y1, c)

# --------------------------------------------------------------------------
# Authored poses.
# --------------------------------------------------------------------------
def pose_idle():
    im = canvas(); d = ImageDraw.Draw(im)
    draw_head(d)
    draw_torso(d)
    draw_leg(d, -1, "stand"); draw_leg(d, +1, "stand")
    draw_arm(d, -1, "down", 17, 37)
    draw_arm(d, +1, "down", 30, 37)
    return outline_pass(im)

def pose_run(front_side):
    """Stride pose: front_side=+1 -> right leg forward, left arm forward."""
    im = canvas(); d = ImageDraw.Draw(im)
    draw_head(d, dx=2)                       # slight forward lean of the head
    draw_torso(d, dx=1)                      # body leans into the run
    draw_leg(d, front_side, "stride_front")
    draw_leg(d, -front_side, "stride_back")
    # Opposite arm swing: if the right leg leads, the left arm is forward.
    fwd = -front_side
    draw_arm(d, fwd, "swing_fwd", 30 if fwd > 0 else 17, 37)
    draw_arm(d, -fwd, "swing_back", 30 if -fwd > 0 else 17, 37)
    return outline_pass(im)

def pose_jump(variant):
    im = canvas(); d = ImageDraw.Draw(im)
    draw_head(d)
    draw_torso(d)
    draw_leg(d, -1, variant); draw_leg(d, +1, variant)
    ax_l, ax_r = 17, 30
    if variant == "rise":
        draw_arm(d, -1, "raised", ax_l, 37); draw_arm(d, +1, "raised", ax_r, 37)
    elif variant == "mid":
        draw_arm(d, -1, "out", ax_l, 37); draw_arm(d, +1, "out", ax_r, 37)
    else:
        draw_arm(d, -1, "raised", ax_l, 36); draw_arm(d, +1, "raised", ax_r, 36)
    return outline_pass(im)

def pose_slash(phase):
    """phase: windup / strike / recover. Facing RIGHT (engine flips)."""
    im = canvas(); d = ImageDraw.Draw(im)
    if phase == "windup":
        draw_head(d, dx=-1)
        draw_torso(d, dx=-1)
        draw_leg(d, -1, "stand"); draw_leg(d, +1, "stand")
        draw_arm(d, +1, "across", 30, 36)
        draw_arm(d, -1, "swing_back", 17, 37)
    elif phase == "strike":
        draw_head(d, dx=3)
        draw_torso(d, dx=2)
        draw_leg(d, +1, "lunge"); draw_leg(d, -1, "lunge")
        draw_arm(d, +1, "extended", 31, 36)
        draw_arm(d, -1, "swing_back", 18, 37)
    else:  # recover: weight still forward, arm dropping
        draw_head(d, dx=1)
        draw_torso(d, dx=1)
        draw_leg(d, +1, "stand"); draw_leg(d, -1, "stand")
        draw_arm(d, +1, "swing_fwd", 31, 37)
        draw_arm(d, -1, "down", 17, 37)
    return outline_pass(im)

# --------------------------------------------------------------------------
# Joint quantization + palette validation.
# --------------------------------------------------------------------------
def joint_quantize(images, colors=22, protected=PROTECTED, tol=14):
    """Median-cut the union of ALL poses to `colors` with no dithering, then
    restore protected colors (eyes, buckle, outline) so the face survives.
    Only OPAQUE pixels participate (transparent background must never steal
    a palette bin). No despeckle: single-pixel face features must never
    merge into their neighbors. Returns (images, used_colors)."""
    hist = {}
    for im in images:
        for p in im.getdata():
            if p[3] == 0:
                continue
            c = (p[0], p[1], p[2])
            hist[c] = hist.get(c, 0) + 1
    if len(hist) <= colors:
        pal = sorted(hist)  # already within budget: identity mapping
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
                c = _nearest(src, pal)
                # Protected colors: keep exact. Exact match first — OUT and
                # EYE_DARK sit within `tol` of each other, so a fuzzy check
                # alone would swap the outline for the eye color.
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
    """Median cut over a color histogram (counts as weights)."""
    boxes = [[(c, n) for c, n in hist.items()]]
    while len(boxes) < colors:
        # Split the box covering the widest channel with the most colors.
        boxes.sort(key=lambda b: (-len(b), -max(max(c[k] for c, _ in b) - min(c[k] for c, _ in b) for k in range(3))))
        box = boxes.pop(0)
        if len(box) < 2:
            # Unsplittable: keep it and stop if nothing else can split.
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

def _nearest(c, pal):
    best = None; bd = 1 << 30
    for p in pal:
        d = sum((c[k] - p[k]) ** 2 for k in range(3))
        if d < bd:
            bd = d; best = p
    return best

def validate_palette():
    assert len(PALETTE) == 22, "palette must stay 22 colors"
    assert len(set(PALETTE)) == 22, "palette contains duplicates"
    # Recolor safety: any two DISTINCT zone colors must differ by >=12/255 in
    # at least one channel, otherwise _recolor_player_sheet (threshold 0.045
    # per channel) can leak a color into the wrong zone.
    zone_colors = [c for lst in RECOLOR_ZONES.values() for c in lst]
    for i, a in enumerate(zone_colors):
        for b in zone_colors[i + 1:]:
            sep = max(abs(a[k] - b[k]) for k in range(3))
            assert sep >= 12, "zone colors too close: %s vs %s (sep %d)" % (a, b, sep)
    # Recolor must never touch protected colors.
    for pc in PROTECTED:
        for c in zone_colors:
            sep = max(abs(pc[k] - c[k]) for k in range(3))
            assert sep >= 12, "protected %s collides with zone color %s" % (pc, c)
    # Outline must stay the darkest fixed color.
    for c in zone_colors:
        assert sum(c) > sum(OUT) + 12, "outline must be darkest: %s" % (c,)
    print("palette ok: 22 colors, zones separated, face protected")

# --------------------------------------------------------------------------
# Row builders (same conventions as v3, tuned for the new silhouette).
# --------------------------------------------------------------------------
def fit_sprite(im, max_w=46, max_h=50):
    k = min(max_w / im.width, max_h / im.height, 1.0)
    if k < 1.0:
        im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.NEAREST)
    return im

def place(canvas_im, spr, dx=0, dy=0):
    x = FRAME_W // 2 - spr.width // 2 + round(dx)
    y = FEET_Y - spr.height + round(dy)
    x = max(0, min(FRAME_W - spr.width, x))
    y = max(0, min(FRAME_H - spr.height, y))
    canvas_im.alpha_composite(spr, (x, y))
    return canvas_im

def squash(im, sx, sy):
    im = im.crop(im.getbbox())   # transform only the sprite, not the canvas
    return im.resize((max(1, round(im.width * sx)), max(1, round(im.height * sy))), Image.NEAREST)

def frame():
    return Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))

def idle_row(idle):
    frames = []
    for i in range(COLS):
        t = i / COLS * 2 * math.pi
        # Breathing squash only — feet never leave row 61 (grounding contract).
        spr = squash(idle, 1.0 - 0.012 * math.sin(t), 1.0 + 0.018 * math.sin(t))
        frames.append(place(frame(), spr))
    return frames

def run_row(run_a, run_b):
    frames = []
    for i in range(COLS):
        t = i / COLS
        pose = run_a if i % 2 == 0 else run_b
        phase = t * 2 * math.pi
        stretch = 1.0 + 0.03 * math.sin(phase)
        spr = squash(pose, stretch, 1.0 - 0.05 * abs(math.sin(phase)))
        spr = spr.rotate(2.0 * math.sin(phase), expand=True, resample=Image.NEAREST)
        spr = spr.crop(spr.getbbox())
        # Bob UP (place()'s dy is a downward offset).
        bob = -abs(2.0 * math.sin(phase))
        frames.append(place(frame(), spr, dy=bob))
    return frames

def air_row(poses):
    """Engine indexes frames 0 rising-fast, 2 rising, 4 apex, 6 falling;
    frames come in consistent pairs. Tiny tilts only (stay inside the frame)."""
    sequence = [poses["rise"], poses["rise"], poses["mid"], poses["mid"],
                poses["mid"], poses["apex"], poses["fall"], poses["fall"]]
    tilts = [4, 4, 2, 2, -1, -1, -4, -4]
    frames = []
    for i in range(COLS):
        base = sequence[i].crop(sequence[i].getbbox())
        spr = base.rotate(tilts[i], expand=True, resample=Image.NEAREST)
        frames.append(place(frame(), spr))
    return frames

def attack_row(windup, strike, recover, idle, forward):
    """Telegraph (0-1) -> strike (2-4) -> recover (5-7)."""
    frames = []
    for i in range(COLS):
        if i < 2:
            spr = windup if i == 0 else squash(windup, 1.02, 0.98)
            frames.append(place(frame(), spr.crop(spr.getbbox()), dx=-2 - 2 * i))
        elif i < 5:
            k = (i - 2) / 2.0
            spr = squash(strike, 1.0 + 0.02 * math.sin(k * math.pi), 1.0)
            frames.append(place(frame(), spr.crop(spr.getbbox()), dx=forward * min(1.0, 0.4 + 0.3 * k)))
        else:
            spr = recover if i == 5 else idle
            frames.append(place(frame(), spr.crop(spr.getbbox()), dx=forward * (1 - (i - 5) / 2.0) * 0.5))
    return frames

# --------------------------------------------------------------------------
# Sheet assembly.
# --------------------------------------------------------------------------
def build_sheet(poses):
    rows = {
        0: idle_row(poses["idle"]),
        1: run_row(poses["run_a"], poses["run_b"]),
        2: air_row(poses["air"]),
        3: idle_row(poses["idle"]),
        4: attack_row(poses["windup"], poses["strike"], poses["recover"],
                      poses["idle"], forward=7),
        5: attack_row(poses["windup"], poses["strike"], poses["recover"],
                      poses["idle"], forward=9),
        6: attack_row(poses["windup"], poses["strike"], poses["recover"],
                      poses["idle"], forward=4),
        7: attack_row(poses["windup"], poses["strike"], poses["recover"],
                      poses["idle"], forward=4),
        8: attack_row(poses["windup"], poses["strike"], poses["recover"],
                      poses["idle"], forward=5),
        9: idle_row(poses["idle"]),
        10: attack_row(poses["windup"], poses["strike"], poses["recover"],
                       poses["idle"], forward=6),
        11: attack_row(poses["windup"], poses["strike"], poses["recover"],
                       poses["idle"], forward=4),
        12: idle_row(poses["idle"]),
    }
    sheet = Image.new("RGBA", (FRAME_W * COLS, FRAME_H * ROWS), (0, 0, 0, 0))
    for r in range(ROWS):
        for c in range(COLS):
            sheet.alpha_composite(rows[r][c], (c * FRAME_W, r * FRAME_H))
    return sheet

def verify_sheet(sheet, poses):
    # Palette: every opaque pixel must be one of the 22 colors.
    used = {}
    for p in sheet.getdata():
        if p[3] == 0:
            continue
        key = (p[0], p[1], p[2])
        used[key] = used.get(key, 0) + 1
    assert set(used) <= set(PALETTE), "off-palette colors: %s" % (set(used) - set(PALETTE))
    assert len(used) == 22, "expected 22 colors on the sheet, found %d" % len(used)
    # Feet contract: grounded rows (all but run/air) must land exactly on
    # row FEET_Y-1; run cycles bob a little; air frames may tuck up to row 55.
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
            assert lo <= feet <= hi, "frame %d,%d feet at %d (want %d..%d)" % (
                r, c, feet, lo, hi)
    print("sheet ok: 22 colors, all %d frames grounded per contract" % (ROWS * COLS))

# --------------------------------------------------------------------------
def main(out_path="assets/textures/player.png"):
    validate_palette()
    idle = pose_idle()
    run_a = pose_run(front_side=+1)
    run_b = pose_run(front_side=-1)
    jump = {
        "rise": pose_jump("tuck"),
        "mid": pose_jump("mid"),
        "apex": pose_jump("mid"),
        "fall": pose_jump("reach"),
    }
    windup = pose_slash("windup")
    strike = pose_slash("strike")
    recover = pose_slash("recover")
    originals = [idle, run_a, run_b, jump["rise"], jump["mid"], jump["fall"],
                 windup, strike, recover]
    # Joint quantization ACROSS all authored poses (shared 22-color palette,
    # no dither, no despeckle; face colors protected).
    quant, used = joint_quantize(originals)
    assert len(used) <= 22, "quantizer left %d colors" % len(used)
    (idle, run_a, run_b, j_rise, j_mid, j_fall, windup, strike, recover) = quant
    pose_map = {
        "idle": idle,
        "run_a": run_a,
        "run_b": run_b,
        "windup": windup,
        "strike": strike,
        "recover": recover,
        "air": {"rise": j_rise, "mid": j_mid, "apex": j_mid, "fall": j_fall},
    }
    sheet = build_sheet(pose_map)
    verify_sheet(sheet, pose_map)
    sheet.save(out_path)
    print("written", out_path, sheet.size)

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "assets/textures/player.png")
