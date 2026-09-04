#!/usr/bin/env python3
"""Ashen Roots UI kit v3 — octagonal carved-stone shapes, no more plain squares.

Shapes:
- slots: octagonal sockets (cut corners like a faceted gem seat), recessed
  interior, ember pins on the diagonals; selected = glowing ember octagon
- panels: cut-corner plate with a double border (iron line + thin ember
  filament along the top) and corner braces
- buttons: angled-end plates (hexagonal pill)

File names and sizes stay legacy so everything stays drop-in:
frame* 24x24 (9-slice margin 8), slot* 54x54 (margin 5), button* 28x28,
boss_bar 520x28, divider 24x4, hearts 34x30.
"""
import os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image

IRON_DK = (24, 28, 36)
IRON_MID = (46, 54, 66)
IRON_LT = (84, 96, 112)
IRON_HI = (128, 142, 160)
EMBER = (255, 150, 52)
EMBER_DK = (176, 92, 30)
EMBER_HI = (255, 208, 100)
GLASS = (13, 16, 22)
GLASS_A = 235
WELL = (15, 19, 26)           # slot interior

def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))

def _oct_edge(x, y, w, h, cut):
    """Distance-ish classification for an octagon with corner cut `cut`.
    Returns None if outside, else the border depth (0 = outline)."""
    # distance to each flat side
    d = min(x, y, w - 1 - x, h - 1 - y)
    # distance to each diagonal (45deg cuts)
    dd = min(x + y - cut, (w - 1 - x) + y - cut,
             x + (h - 1 - y) - cut, (w - 1 - x) + (h - 1 - y) - cut)
    if dd < 0:
        return None
    return min(d, dd)

def frame(size=24, accent=False, inner=False):
    """Cut-corner panel plate. Diagonals live inside the 8px corner patches
    so the 9-slice never distorts them."""
    im = canvas(size, size)
    px = im.load()
    cut = 6 if not inner else 5
    for x in range(size):
        for y in range(size):
            e = _oct_edge(x, y, size, size, cut)
            if e is None:
                continue
            if e == 0:
                px[x, y] = (*IRON_DK, 255)
            elif e == 1:
                # lit top edge, shaded bottom
                c = IRON_LT if y < size // 2 else IRON_MID
                px[x, y] = (*c, 255)
            elif e == 2:
                px[x, y] = (*IRON_MID, 255) if y < size // 2 else (*IRON_DK, 255)
            else:
                px[x, y] = (*GLASS, GLASS_A)
    # thin filament along the inner top edge
    fil = EMBER if accent else IRON_HI
    for x in range(cut, size - cut):
        px[x, 3] = (*fil, 255)
    if accent:
        for x in range(cut, size - cut):
            px[x, 4] = (*EMBER_DK, 255)
    # ember pins on the corner diagonals
    if not inner:
        for (cx, cy) in ((cut - 2, cut - 2), (size - cut + 1, cut - 2),
                         (cut - 2, size - cut + 1), (size - cut + 1, size - cut + 1)):
            if 0 <= cx < size and 0 <= cy < size:
                px[cx, cy] = (*EMBER_DK, 255)
    return im

def slot(size=54, selected=False):
    """Octagonal recessed socket."""
    im = canvas(size, size)
    px = im.load()
    cut = 13
    rim_out = EMBER if selected else IRON_DK
    rim_lit = EMBER_HI if selected else IRON_LT
    rim_dark = EMBER_DK if selected else IRON_MID
    for x in range(size):
        for y in range(size):
            e = _oct_edge(x, y, size, size, cut)
            if e is None:
                continue
            if e == 0:
                px[x, y] = (*rim_out, 255)
            elif e <= 2:
                # recessed: dark upper rim, lit lower lip
                c = rim_dark if y < size // 2 else rim_lit
                px[x, y] = (*c, 255)
            elif e == 3:
                # inner shadow ring
                px[x, y] = (9, 12, 16, 255) if y < size // 2 else (20, 25, 33, 255)
            else:
                px[x, y] = (*WELL, 255)
    # soft floor light pooling at the bottom of the well
    for x in range(cut, size - cut):
        px[x, size - 6] = (24, 30, 40, 255)
        px[x, size - 7] = (20, 25, 34, 255)
    # diagonal facet pins (tiny studs on the cut corners)
    pin = EMBER_HI if selected else IRON_HI
    half_cut = cut // 2
    for (sx, sy) in ((half_cut, half_cut), (size - 1 - half_cut, half_cut),
                     (half_cut, size - 1 - half_cut), (size - 1 - half_cut, size - 1 - half_cut)):
        px[sx, sy] = (*pin, 255)
    if selected:
        # inner ember glow ring
        for x in range(size):
            for y in range(size):
                e = _oct_edge(x, y, size, size, cut)
                if e == 4:
                    px[x, y] = (64, 40, 24, 255)
    return im

def button(size=28, state="normal"):
    """Angled-end plate."""
    im = canvas(size, size)
    px = im.load()
    cut = 5
    if state == "pressed":
        face, lit, dark, oline = EMBER_DK, EMBER_HI, (110, 58, 20), (60, 30, 12)
    elif state == "hover":
        face, lit, dark, oline = (60, 70, 86), IRON_HI, IRON_MID, IRON_DK
    else:
        face, lit, dark, oline = IRON_MID, IRON_LT, IRON_DK, IRON_DK
    for x in range(size):
        for y in range(size):
            e = _oct_edge(x, y, size, size, cut)
            if e is None:
                continue
            if e == 0:
                px[x, y] = (*oline, 255)
            elif e == 1:
                c = lit if y < size // 2 else dark
                px[x, y] = (*c, 255)
            else:
                px[x, y] = (*face, 255)
    # face highlight strip under the top bevel
    for x in range(cut, size - cut):
        px[x, 2] = (*lit, 255)
    if state == "hover":
        # ember pins on the four diagonals
        h = cut // 2
        for (sx, sy) in ((h, h), (size - 1 - h, h), (h, size - 1 - h), (size - 1 - h, size - 1 - h)):
            px[sx, sy] = (*EMBER, 255)
    return im

def boss_bar(w=520, h=28):
    im = canvas(w, h)
    px = im.load()
    cut = 9
    for x in range(w):
        for y in range(h):
            dd = min(x + y - cut, (w - 1 - x) + y - cut,
                     x + (h - 1 - y) - cut, (w - 1 - x) + (h - 1 - y) - cut)
            if dd < 0:
                continue
            e = min(x, y, w - 1 - x, h - 1 - y, dd)
            if e == 0:
                px[x, y] = (*IRON_DK, 255)
            elif e < 3:
                c = IRON_LT if y < h // 2 else IRON_MID
                px[x, y] = (*c, 255)
            else:
                px[x, y] = (14, 17, 23, 245)
    # ember pins at the angled ends
    px[4, h // 2] = (*EMBER, 255)
    px[w - 5, h // 2] = (*EMBER, 255)
    return im

def divider(w=24, h=4):
    im = canvas(w, h)
    px = im.load()
    for x in range(w):
        px[x, 1] = (*IRON_MID, 255)
        px[x, 2] = (*IRON_DK, 255)
    return im

def heart(kind):
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
                tone = 1 if y < 12 else 0
                put(x, y, EMPTY[tone])
            else:
                tone = 2
                if y < 7:
                    tone = 3
                elif y > 20:
                    tone = 1
                put(x, y, FULL[tone])
    if kind == "half":
        for x in range(W // 2, W):
            for y in range(H):
                if px[x, y][3] > 0:
                    tone = 1 if y < 12 else 0
                    px[x, y] = (*[(30, 34, 44), (48, 54, 66)][tone], 255)
        for y in range(H):
            if px[W // 2 - 1, y][3] > 0:
                px[W // 2 - 1, y] = (20, 22, 30, 255)
    if kind == "full":
        px[6, 6] = (*FULL[3], 255); px[7, 5] = (*FULL[3], 255)
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
