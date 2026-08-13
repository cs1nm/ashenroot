#!/usr/bin/env python3
"""Generate the final pixel-art UI texture set for Shadowgrove (UI_DESIGN.md v2).

Overwrites assets/ui/*.png with the new unified style. Run from repo root:
    python3 tools/gen_ui_assets.py
"""
import os
from PIL import Image, ImageDraw

UI = os.path.join(os.path.dirname(__file__), "..", "assets", "ui")
os.makedirs(UI, exist_ok=True)

# ---- palette v4 (референс: тёмное дерево + крем + янтарь, Terraria-дух) ----
BG_DEEP   = (42, 28, 16)     # очень тёмное дерево (бэкдроп)
BG_PANEL  = (96, 64, 32)     # тёмно-коричневое дерево (панели)
BG_PANEL2 = (128, 88, 48)    # среднее дерево (внутренние блоки)
BG_INNER  = (192, 154, 96)   # светлое дерево/пергамент (слоты)
BORDER    = (58, 36, 16)     # тёмная граница
BORDER_HI = (160, 128, 80)   # светлая граница/блик
ACCENT    = (255, 184, 77)   # янтарь
ACCENT_D  = (217, 138, 43)   # янтарь тёмный (нажатое)
GOLD_TEXT = (255, 217, 138)  # светлое золото (на тёмном дереве)
TEXT_MAIN = (240, 224, 192)  # кремовый текст (на тёмных панелях)
TEXT_DIM  = (192, 168, 128)  # приглушённый крем
TEXT_LIGHT= (255, 240, 214)  # очень светлый
HP        = (214, 69, 69)
HP_BG     = (90, 46, 46)
MANA      = (74, 144, 217)
MANA_BG   = (46, 58, 90)
DEF       = (192, 168, 128)
OK        = (74, 157, 90)
WARN      = (201, 122, 32)
DANGER    = (201, 58, 42)
WOOD_LINE = (128, 88, 48)    # линия досок (темнее панели)

def save(img, name):
    img.save(os.path.join(UI, name))
    print("  wrote", name, img.size)


def shadow(img, d, amount=90):
    """Add a 2px down-right dark shadow of all opaque pixels."""
    px = img.load()
    w, h = img.size
    sh = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    spx = sh.load()
    for y in range(h):
        for x in range(w):
            a = px[x, y][3]
            if a > 0:
                for dx, dy in ((2, 2), (1, 2), (2, 1)):
                    if x + dx < w and y + dy < h:
                        ca = spx[x + dx, y + dy][3]
                        spx[x + dx, y + dy] = (0, 0, 0, min(255, ca + amount))
    out = Image.alpha_composite(sh, img)
    return out


def pixel_round_rect(d, x0, y0, x1, y1, r, fill):
    """A 'pixel-rounded' rectangle: clipped corners (2px steps)."""
    d.rectangle([x0 + r, y0, x1 - r, y1], fill=fill)
    d.rectangle([x0, y0 + r, x1, y1 - r], fill=fill)
    for i in range(r):
        step = r - i
        # top-left
        d.rectangle([x0 + i, y0 + step - 1, x0 + r - 1, y0 + step - 1], fill=fill)
        # top-right
        if x1 - 1 - i >= x1 - r + 1:
            d.rectangle([x1 - r + 1, y0 + step - 1, x1 - 1 - i, y0 + step - 1], fill=fill)
        # bottom-left
        d.rectangle([x0 + i, y1 - step + 1, x0 + r - 1, y1 - step + 1], fill=fill)
        # bottom-right
        if x1 - 1 - i >= x1 - r + 1:
            d.rectangle([x1 - r + 1, y1 - step + 1, x1 - 1 - i, y1 - step + 1], fill=fill)


# ---------------- frame.png (panel, 24x24 slice) ----------------
def make_frame(bg, border_c, hi_c, accent_top=False):
    s = 24
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # body
    d.rectangle([2, 2, s - 3, s - 3], fill=bg)
    # wood planks (2 thin horizontal lines)
    d.rectangle([2, 8, s - 3, 8], fill=WOOD_LINE)
    d.rectangle([2, 16, s - 3, 16], fill=WOOD_LINE)
    # border 2px
    d.rectangle([0, 0, s - 1, 1], fill=border_c)
    d.rectangle([0, s - 2, s - 1, s - 1], fill=border_c)
    d.rectangle([0, 0, 1, s - 1], fill=border_c)
    d.rectangle([s - 2, 0, s - 1, s - 1], fill=border_c)
    # inner bevel
    d.rectangle([2, 2, s - 3, 2], fill=hi_c)
    d.rectangle([2, 2, 2, s - 3], fill=hi_c)
    d.rectangle([2, s - 3, s - 3, s - 3], fill=tuple(c // 2 for c in border_c))
    d.rectangle([s - 3, 2, s - 3, s - 3], fill=tuple(c // 2 for c in border_c))
    if accent_top:
        d.rectangle([2, 0, s - 3, 1], fill=ACCENT)
    # corner studs (metal rivets)
    for cx, cy in ((4, 4), (s - 6, 4), (4, s - 6), (s - 6, s - 6)):
        d.rectangle([cx, cy, cx + 1, cy + 1], fill=GOLD_TEXT)
    return shadow(img, 2)


save(make_frame(BG_PANEL, BORDER, BORDER_HI), "frame.png")
save(make_frame(BG_PANEL2, BORDER, BORDER_HI), "frame_inner.png")
save(make_frame(BG_PANEL2, BORDER, BORDER_HI, accent_top=True), "frame_inner_accent.png")

# ---------------- buttons (28x28 slice) ----------------
def make_button(bg, border_c, tab=True, pressed=False):
    s = 28
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if pressed:
        pixel_round_rect(d, 1, 1, s - 2, s - 2, 3, ACCENT_D)
        d.rectangle([1, s - 3, s - 2, s - 2], fill=tuple(c * 3 // 4 for c in ACCENT_D))
        return shadow(img, 2)
    pixel_round_rect(d, 1, 1, s - 2, s - 2, 3, bg)
    d.rectangle([1, 1, s - 2, 1], fill=tuple(c // 2 for c in border_c))
    d.rectangle([1, 1, 1, s - 2], fill=tuple(c // 2 for c in border_c))
    d.rectangle([1, s - 3, s - 2, s - 3], fill=border_c)
    d.rectangle([s - 3, 1, s - 3, s - 2], fill=border_c)
    d.rectangle([2, 2, s - 4, 2], fill=tuple(min(255, c + 30) for c in bg))
    if tab:
        d.rectangle([3, 3, 4, s - 4], fill=ACCENT)
    return shadow(img, 2)


save(make_button(BG_PANEL2, BORDER), "button.png")
save(make_button((32, 42, 58), BORDER_HI), "button_hover.png")
save(make_button(BG_PANEL2, BORDER, pressed=True), "button_pressed.png")

# ---------------- slots (54x54) ----------------
def make_slot(selected=False):
    s = 54
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([2, 2, s - 3, s - 3], fill=BG_INNER)
    # inset shadow
    d.rectangle([2, 2, s - 3, 2], fill=(0, 0, 0, 90))
    d.rectangle([2, 2, 2, s - 3], fill=(0, 0, 0, 90))
    if selected:
        d.rectangle([1, 1, s - 2, s - 2], outline=ACCENT, width=2)
        for cx, cy in ((3, 3), (s - 5, 3), (3, s - 5), (s - 5, s - 5)):
            d.rectangle([cx, cy, cx + 2, cy + 2], fill=ACCENT)
    else:
        d.rectangle([1, 1, s - 2, s - 2], outline=BORDER, width=1)
        d.rectangle([3, 3, s - 4, s - 4], outline=(0, 0, 0, 40), width=1)
    return shadow(img, 1, amount=60)


save(make_slot(False), "slot.png")
save(make_slot(True), "slot_selected.png")

# ---------------- boss bar background (520x28) ----------------
def make_boss_bar():
    w, h = 520, 28
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w - 1, h - 1], fill=HP_BG)
    d.rectangle([0, 0, w - 1, 1], fill=BORDER)
    d.rectangle([0, h - 2, w - 1, h - 1], fill=BORDER)
    d.rectangle([0, 0, 1, h - 1], fill=BORDER)
    d.rectangle([w - 2, 0, w - 1, h - 1], fill=BORDER)
    # skull icon zone on left (dark inset)
    d.rectangle([4, 4, 22, 22], fill=(0, 0, 0, 80))
    return img


save(make_boss_bar(), "boss_bar.png")

# ---------------- hearts (16x14) ----------------
def make_heart(mode):
    w, h = 16, 14
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # heart shape outline
    pts = [(2, 5), (3, 3), (6, 2), (8, 4), (10, 2), (13, 3), (14, 5), (14, 8), (8, 13), (2, 8)]
    d.polygon(pts, outline=(0, 0, 0, 255))
    fill = None
    if mode == "full":
        fill = HP
    elif mode == "half":
        fill = HP
    if fill:
        d.polygon([(3, 5), (4, 4), (6, 3), (8, 5), (10, 3), (12, 4), (13, 5), (13, 7), (8, 12), (3, 7)], fill=fill)
        # highlight
        d.rectangle([4, 4, 6, 5], fill=tuple(min(255, c + 70) for c in fill))
    if mode == "half":
        # darken the right half
        for y in range(h):
            for x in range(w // 2, w):
                p = img.getpixel((x, y))
                if p[3] > 0:
                    img.putpixel((x, y), (p[0] // 3, p[1] // 3, p[2] // 3, p[3]))
    return img


save(make_heart("full"), "heart_full.png")
save(make_heart("half"), "heart_half.png")
save(make_heart("empty"), "heart_empty.png")

# ---------------- small status icons (14x14) ----------------
def make_icon(draw_fn):
    img = Image.new("RGBA", (14, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    draw_fn(d)
    return shadow(img, 1, amount=60)


def armor_icon(d):
    d.rectangle([3, 3, 10, 10], fill=(90, 100, 120))
    d.rectangle([3, 3, 10, 3], fill=DEF)
    d.rectangle([4, 10, 9, 10], fill=(60, 66, 80))
    d.rectangle([5, 11, 8, 12], fill=(60, 66, 80))


def bubble_icon(d):
    d.rectangle([3, 3, 10, 8], fill=MANA)
    d.rectangle([4, 4, 7, 5], fill=tuple(min(255, c + 60) for c in MANA))
    d.rectangle([3, 9, 6, 10], fill=MANA)
    d.rectangle([7, 10, 10, 10], fill=MANA)


def thermo_icon(d):
    d.rectangle([6, 2, 7, 10], fill=(220, 60, 60))
    d.rectangle([5, 10, 8, 11], fill=(220, 60, 60))
    d.rectangle([6, 3, 7, 4], fill=WARN)


def sun_icon(d):
    d.rectangle([6, 2, 7, 11], fill=ACCENT)
    d.rectangle([2, 6, 11, 7], fill=ACCENT)
    d.rectangle([4, 4, 9, 9], fill=GOLD_TEXT)


save(make_icon(armor_icon), "armor.png")
save(make_icon(bubble_icon), "bubble.png")
save(make_icon(thermo_icon), "thermo.png")
save(make_icon(sun_icon), "sun.png")

# ---------------- lens ring (minimap, 172x172) ----------------
def make_lens_ring():
    s = 172
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = s // 2
    # ring
    for r in range(80, 86):
        d.ellipse([c - r, c - r, c + r, c + r], outline=BORDER_HI if r == 80 else BORDER)
    # compass ticks
    for ang, ln in ((0, 12), (90, 8), (180, 8), (270, 8)):
        import math
        a = math.radians(ang)
        x0 = c + math.sin(a) * 78
        y0 = c - math.cos(a) * 78
        x1 = c + math.sin(a) * (78 + ln)
        y1 = c - math.cos(a) * (78 + ln)
        d.line([x0, y0, x1, y1], fill=ACCENT, width=2)
    return img


save(make_lens_ring(), "lens_ring.png")

# ---------------- divider (332x3 accent line) ----------------
def make_divider(w=332):
    img = Image.new("RGBA", (w, 3), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w - 1, 0], fill=(46, 58, 78))
    d.rectangle([0, 1, min(18, w - 1), 1], fill=ACCENT)
    d.rectangle([0, 2, w - 1, 2], fill=(12, 15, 21))
    return img


save(make_divider(), "divider.png")

# ---------------- skull.png (boss icon, 20x20) ----------------
def make_skull():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([6, 3, 13, 6], fill=(220, 225, 230))
    d.rectangle([4, 6, 15, 13], fill=(220, 225, 230))
    d.rectangle([7, 13, 12, 16], fill=(220, 225, 230))
    # eye sockets
    d.rectangle([6, 7, 9, 10], fill=(20, 22, 28))
    d.rectangle([10, 7, 13, 10], fill=(20, 22, 28))
    # nose
    d.rectangle([9, 11, 10, 12], fill=(20, 22, 28))
    # teeth
    d.rectangle([6, 14, 8, 15], fill=(190, 195, 205))
    d.rectangle([11, 14, 13, 15], fill=(190, 195, 205))
    # outline
    for x, y in [(4, 6), (5, 5), (6, 4), (10, 4), (14, 5), (15, 6), (4, 12), (15, 12)]:
        pass
    d.rectangle([4, 6, 4, 12], outline=(0, 0, 0))
    d.rectangle([15, 6, 15, 12], outline=(0, 0, 0))
    return shadow(img, 1, amount=70)


save(make_skull(), "skull.png")

# ---------------- joystick base / knob (pixel circles) ----------------
def make_circle(size, color, outline=None):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = size // 2
    for y in range(size):
        for x in range(size):
            dx, dy = x - r + 0.5, y - r + 0.5
            dist = (dx * dx + dy * dy) ** 0.5
            if dist <= r - 1:
                img.putpixel((x, y), color)
            elif outline and dist <= r:
                img.putpixel((x, y), outline)
    return img


save(make_circle(192, (26, 34, 48, 120), BORDER), "joy_base.png")
save(make_circle(64, (46, 58, 78, 200), BORDER_HI), "joy_knob.png")

# ---------------- action buttons (attack / jump, 132x132) ----------------
def make_action_btn(kind, pressed=False):
    s = 132
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = s // 2
    r = 62 if not pressed else 58
    for y in range(s):
        for x in range(s):
            dx, dy = x - c + 0.5, y - c + 0.5
            dist = (dx * dx + dy * dy) ** 0.5
            if dist <= r:
                img.putpixel((x, y), (12, 15, 22, 190))
    d.ellipse([c - r, c - r, c + r, c + r], outline=(90, 112, 144), width=2)
    # icon
    ic = ACCENT if not pressed else GOLD_TEXT
    if kind == "jump":
        d.polygon([(c, c - 22), (c - 14, c + 8), (c + 14, c + 8)], fill=ic)
        d.rectangle([c - 5, c + 6, c + 5, c + 18], fill=ic)
    else:  # attack sword
        d.polygon([(c, c - 24), (c - 4, c - 14), (c + 4, c - 14)], fill=ic)
        d.rectangle([c - 2, c - 16, c + 2, c + 12], fill=ic)
        d.rectangle([c - 8, c + 10, c + 8, c + 14], fill=(150, 120, 80))
    return shadow(img, 2)


save(make_action_btn("jump"), "btn_jump.png")
save(make_action_btn("jump", pressed=True), "btn_jump_pressed.png")
save(make_action_btn("atk"), "btn_attack.png")
save(make_action_btn("atk", pressed=True), "btn_attack_pressed.png")

print("UI assets regenerated.")
