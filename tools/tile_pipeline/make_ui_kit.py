#!/usr/bin/env python3
"""Ashen Roots UI kit v2 — crafted panels instead of flat dark boxes.

Design language (matches the HD world art):
- panels: dark forged-iron frame with riveted corners and a lit top edge,
  interior of deep smoky glass (semi-transparent so the world reads behind)
- slots: recessed stone sockets — inner shadow at the top, lit lower lip
- selected slot / accent: warm ember glow (255,150,52 family)
- buttons: iron plate with lit bevel; pressed = ember-hot

All textures keep the legacy sizes so they are drop-in for _pixel_sb():
frame* 24x24 (margin 8), slot* 54x54 (margin 5), button* 28x28,
boss_bar 520x28, divider 24x4, hearts 34x30 (2x the old 17x15).
"""
import os, sys, math, random

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image

IRON_DK = (24, 28, 36)
IRON_MID = (44, 52, 64)
IRON_LT = (78, 90, 106)
IRON_HI = (118, 132, 150)
EMBER = (255, 150, 52)
EMBER_DK = (176, 92, 30)
EMBER_HI = (255, 208, 100)
GLASS = (13, 16, 22)          # panel interior
GLASS_A = 235                  # near-opaque smoky glass

def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))

def _rivet(px, x, y):
    px[x, y] = (*IRON_HI, 255)
    px[x + 1, y] = (*IRON_LT, 255)
    px[x, y + 1] = (*IRON_LT, 255)
    px[x + 1, y + 1] = (*IRON_DK, 255)

def frame(size=24, accent=False, inner=False):
    """9-slice panel frame: forged border + smoky interior."""
    im = canvas(size, size)
    px = im.load()
    B = 3 if inner else 4     # border thickness
    for x in range(size):
        for y in range(size):
            edge = min(x, y, size - 1 - x, size - 1 - y)
            if edge == 0:
                px[x, y] = (*IRON_DK, 255)
            elif edge < B:
                # lit top/left, shaded bottom/right
                if y <= x and y < size - 1 - x:
                    c = IRON_LT
                elif x < y and x <= size - 1 - y:
                    c = IRON_MID
                elif y > x and y >= size - 1 - x:
                    c = IRON_DK if edge == 1 else IRON_MID
                else:
                    c = IRON_MID
                px[x, y] = (*c, 255)
            else:
                px[x, y] = (*GLASS, GLASS_A)
    # crisp highlight line along the inner top edge
    for x in range(B, size - B):
        px[x, B] = (*IRON_HI, 255) if not accent else (*EMBER, 255)
    if accent:
        for x in range(B, size - B):
            px[x, B + 1] = (*EMBER_DK, 255)
    # corner rivets
    if not inner:
        for (cx, cy) in ((1, 1), (size - 3, 1), (1, size - 3), (size - 3, size - 3)):
            _rivet(px, cx, cy)
    return im

def slot(size=54, selected=False, hot=False):
    """Recessed socket: dark inner shadow top, lit lower lip."""
    im = canvas(size, size)
    px = im.load()
    B = 3
    rim_lit = EMBER_HI if selected else IRON_LT
    rim_dark = EMBER if selected else IRON_MID
    for x in range(size):
        for y in range(size):
            edge = min(x, y, size - 1 - x, size - 1 - y)
            if edge == 0:
                px[x, y] = (*IRON_DK, 255)
            elif edge < B:
                # recessed: DARK top/left rim, LIT bottom/right lip
                if y <= x and y < size - 1 - x:
                    c = rim_dark if not selected else EMBER_DK
                elif y > x and y >= size - 1 - x:
                    c = rim_lit
                elif x < y:
                    c = rim_dark
                else:
                    c = rim_lit
                px[x, y] = (*c, 255)
            else:
                px[x, y] = (16, 20, 27, 255)
    # inner shadow gradient at the top of the well
    for x in range(B, size - B):
        px[x, B] = (8, 10, 14, 255)
        px[x, B + 1] = (11, 14, 19, 255)
    # soft floor light at the bottom of the well
    for x in range(B + 2, size - B - 2):
        px[x, size - B - 1] = (26, 32, 42, 255)
    if selected:
        # full ember outline + brighter corner ticks
        for x in range(size):
            px[x, 0] = (*EMBER, 255)
            px[x, size - 1] = (*EMBER, 255)
        for y in range(size):
            px[0, y] = (*EMBER, 255)
            px[size - 1, y] = (*EMBER, 255)
        L = 9
        for k in range(L):
            for (x, y) in ((k, 0), (0, k), (size - 1 - k, 0), (size - 1, k),
                           (k, size - 1), (0, size - 1 - k),
                           (size - 1 - k, size - 1), (size - 1, size - 1 - k)):
                px[x, y] = (*EMBER_HI, 255)
        # inner warm glow ring just inside the rim
        for x in range(B, size - B):
            px[x, B + 2] = (52, 34, 22, 255)
    return im

def button(size=28, state="normal"):
    im = canvas(size, size)
    px = im.load()
    if state == "pressed":
        face, lit, dark = EMBER_DK, EMBER, (96, 52, 18)
    elif state == "hover":
        face, lit, dark = (58, 68, 84), IRON_HI, IRON_MID
    else:
        face, lit, dark = IRON_MID, IRON_LT, IRON_DK
    for x in range(size):
        for y in range(size):
            edge = min(x, y, size - 1 - x, size - 1 - y)
            if edge == 0:
                px[x, y] = (*IRON_DK, 255)
            elif edge == 1:
                if y <= x and y < size - 1 - x:
                    px[x, y] = (*lit, 255)
                elif y > x and y >= size - 1 - x:
                    px[x, y] = (*dark, 255)
                else:
                    px[x, y] = (*face, 255)
            else:
                px[x, y] = (*face, 255)
    # face highlight strip
    for x in range(3, size - 3):
        px[x, 2] = (*lit, 255)
    if state == "hover":
        for k in range(5):
            for (x, y) in ((k, 0), (0, k), (size - 1 - k, 0), (size - 1, k)):
                px[x, y] = (*EMBER, 255)
    return im

def boss_bar(w=520, h=28):
    im = canvas(w, h)
    px = im.load()
    for x in range(w):
        for y in range(h):
            edge = min(x, y, w - 1 - x, h - 1 - y)
            if edge == 0:
                px[x, y] = (*IRON_DK, 255)
            elif edge < 3:
                c = IRON_LT if y < h // 2 else IRON_MID
                px[x, y] = (*c, 255)
            else:
                px[x, y] = (14, 17, 23, 245)
    # spiked end caps
    for k in range(4):
        for y in range(6 + k, h - 6 - k):
            px[3 + k, y] = (*IRON_LT, 255)
            px[w - 4 - k, y] = (*IRON_LT, 255)
    return im

def divider(w=24, h=4):
    im = canvas(w, h)
    px = im.load()
    for x in range(w):
        px[x, 1] = (*IRON_MID, 255)
        px[x, 2] = (*IRON_DK, 255)
    return im

def heart(kind):
    """34x30 heart, mirrored lobes, reads at 24x21 on the HUD."""
    W, H = 34, 30
    im = canvas(W, H)
    px = im.load()
    FULL = [(150, 40, 70), (208, 62, 100), (238, 96, 128), (255, 170, 188)]
    EMPTY = [(30, 34, 44), (48, 54, 66), (62, 70, 84)]
    def put(x, y, c):
        px[x, y] = (*c, 255)
        px[W - 1 - x, y] = (*c, 255)
    def shape(x, y):
        dx, dy = x - 8.5, y - 9.0
        in_lobe = dx * dx + dy * dy <= 42
        k = (y - 9.0) / 17.0
        in_tri = 0.0 <= k <= 1.0 and x >= 2 + k * 13.5
        return in_lobe or in_tri
    for x in range(W // 2):
        for y in range(H):
            if not shape(x, y):
                continue
            if kind == "empty":
                pal = EMPTY
                tone = 1 if y < 12 else 0
                put(x, y, pal[tone])
            else:
                tone = 2
                if y < 7:
                    tone = 3
                elif y > 20:
                    tone = 1
                put(x, y, FULL[tone])
    if kind == "half":
        # right half goes empty
        for x in range(W // 2, W):
            for y in range(H):
                if px[x, y][3] > 0:
                    tone = 1 if y < 12 else 0
                    px[x, y] = (*[(30, 34, 44), (48, 54, 66)][tone], 255)
        for y in range(H):  # split line
            if px[W // 2 - 1, y][3] > 0:
                px[W // 2 - 1, y] = (20, 22, 30, 255)
    if kind == "full":
        px[6, 6] = (*FULL[3], 255); px[7, 5] = (*FULL[3], 255)
    # dark outline
    mask = [[px[x, y][3] > 0 for y in range(H)] for x in range(W)]
    for x in range(W):
        for y in range(H):
            if not mask[x][y]:
                for ddx, ddy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + ddx, y + ddy
                    if 0 <= nx < W and 0 <= ny < H and mask[nx][ny]:
                        px[x, y] = (60, 20, 36, 255) if kind != "empty" else (16, 18, 24, 255)
                        break
    return im

OUT = {
    "frame.png": lambda: frame(24, accent=False, inner=False),
    "frame_inner.png": lambda: frame(24, accent=False, inner=True),
    "frame_inner_accent.png": lambda: frame(24, accent=True, inner=True),
    "slot.png": lambda: slot(54, selected=False),
    "slot_selected.png": lambda: slot(54, selected=True),
    "button.png": lambda: button(28, "normal"),
    "button_hover.png": lambda: button(28, "hover"),
    "button_pressed.png": lambda: button(28, "pressed"),
    "boss_bar.png": lambda: boss_bar(),
    "divider.png": lambda: divider(),
    "heart_full.png": lambda: heart("full"),
    "heart_half.png": lambda: heart("half"),
    "heart_empty.png": lambda: heart("empty"),
}

if __name__ == "__main__":
    outdir = "/tmp/ui_kit"
    os.makedirs(outdir, exist_ok=True)
    for name, fn in OUT.items():
        fn().save(f"{outdir}/{name}")
    print("done:", len(OUT))
