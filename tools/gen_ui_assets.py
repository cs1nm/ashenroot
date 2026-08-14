#!/usr/bin/env python3
"""Generate Shadowgrove's minimal charcoal-and-amber pixel UI assets.

The shapes are intentionally restrained: one-pixel borders, clipped corners,
small amber markers and no gradients/wood grain. Run from the repository root:
    python3 tools/gen_ui_assets.py
"""
from __future__ import annotations

import math
import os
from PIL import Image, ImageDraw

UI = os.path.join(os.path.dirname(__file__), "..", "assets", "ui")
os.makedirs(UI, exist_ok=True)

# UI v5 — graphite/charcoal + amber.
BG_DEEP = (8, 11, 15, 246)
BG_PANEL = (15, 19, 25, 244)
BG_PANEL2 = (21, 27, 35, 248)
BG_INNER = (10, 14, 19, 246)
BORDER = (52, 62, 73, 255)
BORDER_HI = (83, 96, 110, 255)
ACCENT = (242, 163, 58, 255)
ACCENT_HI = (255, 201, 103, 255)
ACCENT_D = (173, 101, 31, 255)
TEXT = (232, 237, 242, 255)
TEXT_DIM = (153, 164, 176, 255)
HP = (220, 67, 75, 255)
HP_D = (78, 29, 35, 255)
MANA = (75, 151, 224, 255)
OK = (86, 188, 119, 255)
WARN = (242, 163, 58, 255)


def save(img: Image.Image, name: str) -> None:
    img.save(os.path.join(UI, name))
    print("  wrote", name, img.size)


def clipped_rect(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], fill, cut: int = 2) -> None:
    x0, y0, x1, y1 = box
    draw.polygon(
        [
            (x0 + cut, y0), (x1 - cut, y0), (x1, y0 + cut),
            (x1, y1 - cut), (x1 - cut, y1), (x0 + cut, y1),
            (x0, y1 - cut), (x0, y0 + cut),
        ],
        fill=fill,
    )


def outline_clipped(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], color, cut: int = 2) -> None:
    x0, y0, x1, y1 = box
    points = [
        (x0 + cut, y0), (x1 - cut, y0), (x1, y0 + cut),
        (x1, y1 - cut), (x1 - cut, y1), (x0 + cut, y1),
        (x0, y1 - cut), (x0, y0 + cut), (x0 + cut, y0),
    ]
    draw.line(points, fill=color, width=1)


def make_frame(bg, accent_top: bool = False) -> Image.Image:
    s = 24
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    clipped_rect(d, (0, 0, s - 1, s - 1), bg, 3)
    outline_clipped(d, (0, 0, s - 1, s - 1), BORDER, 3)
    d.line((4, 1, s - 5, 1), fill=BORDER_HI, width=1)
    # Tiny corner marks make the frame distinctive without becoming ornament.
    d.line((2, 5, 2, 9), fill=ACCENT, width=1)
    d.line((s - 3, s - 10, s - 3, s - 6), fill=ACCENT_D, width=1)
    if accent_top:
        d.line((5, 0, s - 6, 0), fill=ACCENT, width=1)
    return img


save(make_frame(BG_PANEL), "frame.png")
save(make_frame(BG_PANEL2), "frame_inner.png")
save(make_frame(BG_PANEL2, True), "frame_inner_accent.png")


def make_button(bg, border, pressed: bool = False) -> Image.Image:
    s = 28
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    clipped_rect(d, (1, 1, s - 2, s - 2), bg, 3)
    outline_clipped(d, (1, 1, s - 2, s - 2), border, 3)
    if pressed:
        d.line((4, s - 3, s - 5, s - 3), fill=ACCENT_HI, width=1)
    else:
        d.line((3, 6, 3, s - 7), fill=ACCENT, width=1)
        d.line((5, 2, s - 6, 2), fill=(255, 255, 255, 20), width=1)
    return img


save(make_button(BG_PANEL2, BORDER), "button.png")
save(make_button((31, 39, 49, 250), ACCENT), "button_hover.png")
save(make_button((92, 57, 25, 252), ACCENT, True), "button_pressed.png")


def make_slot(selected: bool = False) -> Image.Image:
    s = 54
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    clipped_rect(d, (1, 1, s - 2, s - 2), BG_INNER, 3)
    outline_clipped(d, (1, 1, s - 2, s - 2), ACCENT if selected else BORDER, 3)
    d.line((5, 3, s - 6, 3), fill=(255, 255, 255, 18), width=1)
    if selected:
        # Four short amber brackets; no large filled panel or glow.
        for points in [
            ((3, 10), (3, 4), (10, 4)),
            ((s - 11, 4), (s - 4, 4), (s - 4, 10)),
            ((3, s - 11), (3, s - 4), (10, s - 4)),
            ((s - 11, s - 4), (s - 4, s - 4), (s - 4, s - 11)),
        ]:
            d.line(points, fill=ACCENT, width=2)
    return img


save(make_slot(False), "slot.png")
save(make_slot(True), "slot_selected.png")


def make_boss_bar() -> Image.Image:
    w, h = 520, 28
    img = Image.new("RGBA", (w, h), BG_DEEP)
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, w - 1, h - 1), outline=BORDER)
    d.line((26, 1, w - 8, 1), fill=ACCENT, width=1)
    d.rectangle((4, 4, 23, h - 5), fill=(0, 0, 0, 90), outline=BORDER)
    return img


save(make_boss_bar(), "boss_bar.png")


def heart_shape(draw: ImageDraw.ImageDraw, fill) -> None:
    pts = [(1, 4), (3, 2), (6, 2), (8, 4), (10, 2), (13, 2), (15, 4), (15, 8), (8, 14), (1, 8)]
    draw.polygon(pts, fill=fill)


def make_heart(mode: str) -> Image.Image:
    img = Image.new("RGBA", (17, 15), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    heart_shape(d, (5, 7, 10, 255))
    if mode != "empty":
        heart_shape(d, HP_D)
        inner = [(3, 5), (4, 3), (6, 3), (8, 6), (10, 3), (12, 3), (14, 5), (14, 7), (8, 13), (2, 7)]
        d.polygon(inner, fill=HP)
        d.rectangle((4, 4, 6, 5), fill=(255, 151, 154, 255))
    else:
        d.line([(1, 4), (3, 2), (6, 2), (8, 4), (10, 2), (13, 2), (15, 4), (15, 8), (8, 14), (1, 8), (1, 4)], fill=BORDER_HI, width=1)
    if mode == "half":
        for y in range(img.height):
            for x in range(8, img.width):
                r, g, b, a = img.getpixel((x, y))
                if a:
                    img.putpixel((x, y), (r // 3, g // 3, b // 3, a))
    return img


save(make_heart("full"), "heart_full.png")
save(make_heart("half"), "heart_half.png")
save(make_heart("empty"), "heart_empty.png")


def icon(draw_fn) -> Image.Image:
    img = Image.new("RGBA", (14, 14), (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(img))
    return img


def armor(d):
    d.polygon([(2, 3), (7, 1), (12, 3), (11, 9), (7, 13), (3, 9)], fill=(63, 75, 88, 255), outline=TEXT_DIM)
    d.line((7, 3, 7, 10), fill=ACCENT, width=1)


def bubble(d):
    d.ellipse((2, 2, 11, 11), outline=MANA, width=2)
    d.rectangle((4, 3, 6, 4), fill=(171, 218, 255, 255))


def thermo(d):
    d.rectangle((6, 2, 8, 10), outline=TEXT_DIM)
    d.rectangle((7, 4, 7, 10), fill=ACCENT)
    d.ellipse((4, 9, 10, 13), fill=ACCENT_D, outline=ACCENT)


def sun(d):
    d.ellipse((4, 4, 10, 10), fill=ACCENT_HI)
    for a in range(0, 360, 45):
        x0 = 7 + int(round(math.cos(math.radians(a)) * 5))
        y0 = 7 + int(round(math.sin(math.radians(a)) * 5))
        x1 = 7 + int(round(math.cos(math.radians(a)) * 6))
        y1 = 7 + int(round(math.sin(math.radians(a)) * 6))
        d.line((x0, y0, x1, y1), fill=ACCENT)


save(icon(armor), "armor.png")
save(icon(bubble), "bubble.png")
save(icon(thermo), "thermo.png")
save(icon(sun), "sun.png")


def make_lens_ring() -> Image.Image:
    s = 172
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = s // 2
    d.ellipse((4, 4, s - 5, s - 5), outline=(7, 10, 14, 220), width=4)
    d.ellipse((7, 7, s - 8, s - 8), outline=BORDER_HI, width=1)
    d.ellipse((9, 9, s - 10, s - 10), outline=(242, 163, 58, 150), width=1)
    for angle in (0, 90, 180, 270):
        a = math.radians(angle)
        x0 = c + int(math.sin(a) * 74)
        y0 = c - int(math.cos(a) * 74)
        x1 = c + int(math.sin(a) * 82)
        y1 = c - int(math.cos(a) * 82)
        d.line((x0, y0, x1, y1), fill=ACCENT, width=2)
    return img


save(make_lens_ring(), "lens_ring.png")


def make_divider() -> Image.Image:
    img = Image.new("RGBA", (64, 3), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.line((0, 1, 63, 1), fill=BORDER)
    d.line((0, 0, 14, 0), fill=ACCENT)
    return img


save(make_divider(), "divider.png")


def make_skull() -> Image.Image:
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle((3, 2, 12, 10), fill=TEXT_DIM)
    d.rectangle((5, 10, 10, 13), fill=TEXT_DIM)
    d.rectangle((5, 6, 6, 7), fill=BG_DEEP)
    d.rectangle((9, 6, 10, 7), fill=BG_DEEP)
    d.rectangle((7, 9, 8, 10), fill=BG_DEEP)
    d.line((7, 11, 7, 13), fill=BG_DEEP)
    d.line((9, 11, 9, 13), fill=BG_DEEP)
    return img


save(make_skull(), "skull.png")


def ring_asset(size: int, radius: int, ring, center=None) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pad = size // 2 - radius
    d.ellipse((pad, pad, size - pad - 1, size - pad - 1), outline=ring, width=2)
    if center:
        inner_pad = pad + 7
        d.ellipse((inner_pad, inner_pad, size - inner_pad - 1, size - inner_pad - 1), fill=center)
    return img


save(ring_asset(192, 88, (242, 163, 58, 125), (12, 16, 22, 28)), "joy_base.png")
save(ring_asset(64, 27, (242, 163, 58, 185), (18, 23, 30, 90)), "joy_knob.png")


def make_action(kind: str, pressed: bool = False) -> Image.Image:
    s = 132
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ring = ACCENT_HI if pressed else (242, 163, 58, 160)
    d.ellipse((3, 3, s - 4, s - 4), outline=ring, width=3 if pressed else 2)
    if pressed:
        d.ellipse((10, 10, s - 11, s - 11), fill=(242, 163, 58, 35))
    col = ACCENT_HI if pressed else (232, 237, 242, 210)
    c = s // 2
    if kind == "jump":
        d.polygon([(c, 34), (c - 22, 62), (c - 8, 62), (c - 8, 92), (c + 8, 92), (c + 8, 62), (c + 22, 62)], fill=col)
    else:
        d.polygon([(c + 6, 28), (c + 13, 36), (c - 12, 82), (c - 20, 74)], fill=col)
        d.rectangle((c - 24, 78, c + 10, 84), fill=col)
        d.rectangle((c - 12, 84, c - 5, 103), fill=col)
    return img


save(make_action("jump"), "btn_jump.png")
save(make_action("jump", True), "btn_jump_pressed.png")
save(make_action("atk"), "btn_attack.png")
save(make_action("atk", True), "btn_attack_pressed.png")
