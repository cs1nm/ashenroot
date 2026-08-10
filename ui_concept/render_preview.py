#!/usr/bin/env python3
"""Render static preview images of the 'Ashen Archive' UI concept using real game assets."""
import os, json
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = "/home/user/ashenroot"
OUT = os.path.join(ROOT, "ui_concept", "preview")
os.makedirs(OUT, exist_ok=True)

W, H = 1280, 720

# ---------- fonts ----------
PS2P = "/tmp/fonts/ps2p.ttf"
MONO = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
MONO_B = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"

def ps(sz):   return ImageFont.truetype(PS2P, sz)
def mono(sz): return ImageFont.truetype(MONO, sz)
def monob(sz): return ImageFont.truetype(MONO_B, sz)

# ---------- palette ----------
OBS   = (16, 20, 27)
OBS2  = (26, 32, 41)
EMBER = (255, 106, 43)
EMBER2= (255, 159, 67)
GOLD  = (214, 181, 106)
INK   = (233, 227, 211)
DIM   = (151, 160, 154)
DIM2  = (107, 116, 110)
RED   = (224, 82, 82)
TEAL  = (89, 165, 192)
GREEN = (121, 201, 154)

def lerp_c(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

# ---------- helpers ----------
def icon(item, size):
    p = os.path.join(ROOT, "assets", "textures", "items", item + ".png")
    im = Image.open(p).convert("RGBA")
    return im.resize((size, size), Image.NEAREST)

def item_thumb(item, h):
    im = Image.open(os.path.join(ROOT, "assets", "textures", "items", item + ".png")).convert("RGBA")
    w = int(im.width * h / im.height)
    return im.resize((w, h), Image.NEAREST)

def tile_icon(tile, size):
    p = os.path.join(ROOT, "assets", "textures", "tiles", tile + ".png")
    im = Image.open(p).convert("RGBA")
    return im.resize((size, size), Image.NEAREST)

def enemy_frame(enemy_dir, filename, height, frame=0):
    p = os.path.join(ROOT, "assets", "textures", "enemies", "anims", enemy_dir, filename)
    im = Image.open(p).convert("RGBA")
    frames = 1
    json_p = os.path.join(ROOT, "assets", "textures", "enemies", "anims", enemy_dir,
                          enemy_dir + "_anim.json")
    if os.path.exists(json_p):
        try:
            data = json.load(open(json_p))
            anims = data.get("animations", {})
            if "idle" in anims:
                frames = max(1, int(anims["idle"].get("frames", 1)))
        except Exception:
            pass
    fw = im.width // frames
    im = im.crop((frame * fw, 0, frame * fw + fw, im.height))
    w = int(im.width * height / im.height)
    return im.resize((w, height), Image.NEAREST)

def glow(base, target, box, color, radius=12):
    """draw glowing shape from target's alpha onto base"""
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).rectangle(box, fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(radius))
    base.alpha_composite(layer)

def rrect(d, box, r, fill=None, outline=None, width=1):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)

def text_spaced(d, xy, txt, font, fill, spacing=0, anchor=None, shadow=True):
    if shadow:
        d.text((xy[0] + 1, xy[1] + 2), txt, font=font, fill=(0, 0, 0, 200), anchor=anchor)
    if spacing <= 0:
        d.text(xy, txt, font=font, fill=fill, anchor=anchor)
        return
    x, y = xy
    total = sum(int(font.getlength(ch)) for ch in txt) + spacing * (len(txt) - 1)
    if anchor == "mm":
        x -= total / 2
    elif anchor == "ma":
        x -= total
    for ch in txt:
        d.text((x, y), ch, font=font, fill=fill)
        x += int(font.getlength(ch)) + spacing

def cover(img, w, h):
    """cover-crop img to w x h"""
    scale = max(w / img.width, h / img.height)
    nw, nh = int(img.width * scale + 0.5), int(img.height * scale + 0.5)
    img = img.resize((nw, nh), Image.NEAREST)
    x = (nw - w) // 2
    y = (nh - h) // 2
    return img.crop((x, y, x + w, y + h))

def radial_mask(size, cx, cy, r_in, r_out):
    """L-mode radial gradient: 255 inside r_in, 0 outside r_out"""
    small = 256
    sm = Image.new("L", (small, small), 0)
    sd = ImageDraw.Draw(sm)
    cxs, cys = small * cx / size[0], small * cy / size[1]
    rin = r_in / max(size) * small
    rout = r_out / max(size) * small
    for y in range(small):
        for x in range(small):
            dist = ((x - cxs) ** 2 + (y - cys) ** 2) ** 0.5
            if dist <= rin:
                sm.putpixel((x, y), 255)
            elif dist >= rout:
                sm.putpixel((x, y), 0)
            else:
                t = (dist - rin) / (rout - rin)
                sm.putpixel((x, y), int(255 * (1 - t)))
    return sm.resize(size, Image.BILINEAR)

def paste(dst, src, xy):
    dst.alpha_composite(src, xy)

# ---------- shared elements ----------
def hp_ring(base, x, y, r=38, value=87, maxv=100):
    cx, cy = x + r, y + r
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    # glow
    gl = Image.new("RGBA", base.size, (0, 0, 0, 0))
    ImageDraw.Draw(gl).ellipse((cx - r - 6, cy - r - 6, cx + r + 6, cy + r + 6), outline=EMBER, width=4)
    gl = gl.filter(ImageFilter.GaussianBlur(10))
    base.alpha_composite(gl)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=OBS, outline=(58, 66, 78), width=2)
    d.ellipse((cx - r + 6, cy - r + 6, cx + r - 6, cy + r - 6), fill=(10, 13, 18))
    # arc: from -90 deg, clockwise
    frac = value / maxv
    start = 90  # PIL angles: 0 = 3 o'clock, clockwise. We want start at 12 o'clock going clockwise.
    sweep = 360 * frac
    n = 36
    for i in range(n):
        a0 = start + sweep * i / n
        a1 = start + sweep * (i + 1) / n + 0.5
        col = lerp_c(EMBER2, (214, 52, 52), i / max(1, n - 1))
        d.arc((cx - r + 3, cy - r + 3, cx + r - 3, cy + r - 3), a0, a1, fill=col, width=7)
    base.alpha_composite(layer)
    d2 = ImageDraw.Draw(base)
    text_spaced(d2, (cx, cy - 12), str(value), ps(18), (255, 217, 194), anchor="mm")
    text_spaced(d2, (cx, cy + 14), "ЗДОРОВЬЕ", mono(9), DIM, spacing=2, anchor="mm")

def chip(base, xy, text, icon_img=None, size=(None, None), border=EMBER, bg=(16, 20, 27, 220), font=None, fg=INK, pad=(10, 5), r=7):
    d = ImageDraw.Draw(base)
    font = font or mono(11)
    tw = int(font.getlength(text))
    ic = icon_img.width if icon_img else 0
    iw, ih = size if size[0] else (icon_img.width, icon_img.height)
    w = int(pad[0] * 2 + tw + (ic + 6 if icon_img else 0))
    h = int(max(pad[1] * 2 + 14, ih + pad[1] * 2))
    box = (xy[0], xy[1], xy[0] + w, xy[1] + h)
    rrect(d, box, r, fill=bg, outline=border, width=1)
    if icon_img:
        base.alpha_composite(icon_img, (xy[0] + pad[0], xy[1] + (h - ih) // 2))
        tx = xy[0] + pad[0] + ic + 6
    else:
        tx = xy[0] + pad[0]
    d.text((tx, xy[1] + (h - 14) // 2), text, font=font, fill=fg)
    return (box[2], box[3])

def slot_btn(base, xy, item, count, selected, key, size=62, icon_sz=42):
    d = ImageDraw.Draw(base)
    box = (xy[0], xy[1], xy[0] + size, xy[1] + size)
    dy = -3 if selected else 0
    box = (box[0], box[1] + dy, box[2], box[3] + dy)
    if selected:
        gl = Image.new("RGBA", base.size, (0, 0, 0, 0))
        ImageDraw.Draw(gl).rounded_rectangle(box, radius=10, outline=EMBER, width=3)
        gl = gl.filter(ImageFilter.GaussianBlur(7))
        base.alpha_composite(gl)
    rrect(d, box, 10, fill=(28, 34, 44, 245), outline=EMBER if selected else (214, 181, 106, 72), width=2 if selected else 1)
    if item:
        ic = icon(item, icon_sz)
        base.alpha_composite(ic, (xy[0] + (size - icon_sz) // 2, box[1] + (size - icon_sz) // 2))
        if count > 1:
            d.text((box[2] - 5, box[3] - 15), str(count), font=ps(8), fill=(255, 243, 214, 255), anchor="rs")
    if key:
        d.text((box[0] + 6, box[1] + 4), key, font=ps(7), fill=DIM2)
    if selected:
        d.polygon([(xy[0] + size // 2 - 5, box[3] + 8), (xy[0] + size // 2 + 5, box[3] + 8), (xy[0] + size // 2, box[3] + 14)], fill=EMBER)

def hotbar(base, items, selected=0, cy=None):
    n = len(items)
    size, gap, pad = 62, 9, 12
    total = n * size + (n - 1) * gap + pad * 2
    x0 = (W - total) // 2
    y0 = (cy if cy is not None else H - 18 - size - pad * 2)
    d = ImageDraw.Draw(base)
    rrect(d, (x0 - 4, y0 - 4, x0 + total + 4, y0 + size + pad * 2 + 4), 14,
          fill=(13, 16, 22, 210), outline=(214, 181, 106, 56), width=1)
    for i, (item, count) in enumerate(items):
        slot_btn(base, (x0 + pad + i * (size + gap), y0 + pad), item, count, i == selected, str(i + 1))

def context_chip(base, text, y=720 - 18 - 62 - 24 - 40):
    d = ImageDraw.Draw(base)
    font = mono(11)
    tw = int(font.getlength(text))
    w = tw + 28
    x0 = (W - w) // 2
    rrect(d, (x0, y, x0 + w, y + 26), 7, fill=(14, 17, 23, 230), outline=EMBER, width=1)
    d.text((x0 + 14, y + 6), text, font=font, fill=(255, 224, 196))

def top_center(base, night=False):
    d = ImageDraw.Draw(base)
    if night:
        d.ellipse((W // 2 - 62, 22, W // 2 - 48, 36), fill=(223, 233, 242))
        text_spaced(d, (W // 2 + 8, 20), "НОЧЬ 01:15", ps(10), GOLD, spacing=1)
    else:
        d.ellipse((W // 2 - 62, 20, W // 2 - 46, 36), fill=(255, 233, 168))
        text_spaced(d, (W // 2 + 8, 20), "ДЕНЬ 14:22", ps(10), GOLD, spacing=1)
    txt = "ПЕПЕЛЬНЫЕ РУИНЫ"
    font = mono(11)
    tw = int(font.getlength(txt)) + 20
    x0 = (W - tw) // 2
    rrect(d, (x0, 44, x0 + tw, 68), 5, fill=(10, 13, 18, 150), outline=(255, 255, 255, 16), width=1)
    text_spaced(d, (W // 2, 50), txt, font, (207, 214, 207), spacing=4, anchor="ma")
    text_spaced(d, (W // 2 + 2, 50), txt, font, (207, 214, 207), spacing=4)
    msg = "Срублено дерево — дерево ×12"
    f2 = mono(11)
    mw = int(f2.getlength(msg)) + 24
    mx = (W - mw) // 2
    rrect(d, (mx, 76, mx + mw, 100), 6, fill=(12, 15, 20, 200), outline=EMBER, width=1)
    d.text((mx + 12, 82), msg, font=f2, fill=EMBER2)

def lens(base, x, y, r=82, dot=True):
    """circular minimap lens at top-right corner (x,y = top-left of bounding box)"""
    cx, cy = x + r, y + r
    map_img = Image.open(os.path.join(ROOT, "ui_concept", "assets", "world_map.png")).convert("RGBA")
    # crop region around player-ish point (forest)
    mw, mh = map_img.size
    px, py = int(mw * 0.58), int(mh * 0.42)
    half = 240
    crop = map_img.crop((px - half, py - half, px + half, py + half)).resize((r * 2, r * 2), Image.NEAREST)
    mask = Image.new("L", (r * 2, r * 2), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, r * 2, r * 2), fill=255)
    crop.putalpha(mask)
    base.alpha_composite(crop, (x, y))
    d = ImageDraw.Draw(base)
    d.ellipse((x, y, x + r * 2, y + r * 2), outline=GOLD, width=3)
    # inner vignette
    vg = radial_mask((r * 2, r * 2), r, r, r * 1.15, r * 1.5)
    vg = vg.point(lambda v: int(v * 0.55))
    tint = Image.new("RGBA", (r * 2, r * 2), (5, 7, 10, 0))
    tint.putalpha(vg)
    base.alpha_composite(tint, (x, y))
    if dot:
        gl = Image.new("RGBA", base.size, (0, 0, 0, 0))
        ImageDraw.Draw(gl).ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=(255, 226, 122))
        gl = gl.filter(ImageFilter.GaussianBlur(4))
        base.alpha_composite(gl)
        d.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(255, 226, 122), outline=(255, 179, 71), width=1)

def loot_feed(base):
    items = [("wood", 12, "Дерево"), ("copper_ore", 3, "Медная руда"), ("sapling", 1, "Саженец")]
    d = ImageDraw.Draw(base)
    y = H - 24
    for item, count, name in reversed(items):
        txt = "+ %s ×%d" % (name, count)
        font = mono(11)
        ic = icon(item, 16)
        w = int(font.getlength(txt)) + 16 + 6 + 20
        h = 26
        y -= h + 6
        x0 = W - 20 - w
        rrect(d, (x0, y, x0 + w, y + h), 7, fill=(13, 16, 22, 210), outline=(255, 159, 67, 90), width=1)
        base.alpha_composite(ic, (x0 + 10, y + 5))
        d.text((x0 + 32, y + 6), txt, font=font, fill=(255, 233, 201))

def boss_bar(base):
    d = ImageDraw.Draw(base)
    text_spaced(d, (W // 2, 64), "КАМЕННЫЙ ЗВЕРЬ", ps(10), (255, 217, 194), spacing=2, anchor="mm")
    tw, th = 520, 12
    x0 = (W - tw) // 2
    gl = Image.new("RGBA", base.size, (0, 0, 0, 0))
    ImageDraw.Draw(gl).rounded_rectangle((x0 - 2, 84, x0 + tw + 2, 84 + th + 4), radius=8, outline=RED, width=3)
    gl = gl.filter(ImageFilter.GaussianBlur(8))
    base.alpha_composite(gl)
    rrect(d, (x0, 86, x0 + tw, 86 + th), 7, fill=(10, 12, 16, 230), outline=RED, width=1)
    fill_w = int(tw * 0.62)
    for i in range(fill_w):
        col = lerp_c((168, 51, 51), (255, 138, 107), i / fill_w)
        d.line((x0 + i, 86, x0 + i, 86 + th - 1), fill=col)
    rrect(d, (x0, 86, x0 + tw, 86 + th), 7, outline=(0, 0, 0, 0), width=0)

# =========================================================
# 1. GAMEPLAY
# =========================================================
def screen_gameplay(night=False):
    base = Image.new("RGBA", (W, H), (11, 14, 19, 255))
    bg = Image.open(os.path.join(ROOT, "ui_concept", "assets", "gameplay_bg.png")).convert("RGBA")
    base.alpha_composite(cover(bg, W, H))
    d = ImageDraw.Draw(base)
    # vignette
    vg = radial_mask((W, H), W / 2, H * 0.45, 620, 1000)
    tint = Image.new("RGBA", (W, H), (5, 7, 10, 0))
    tint.putalpha(vg.point(lambda v: int(v * 0.5)))
    base.alpha_composite(tint)
    if night:
        nf = Image.new("RGBA", (W, H), (8, 10, 18, 0))
        nf.putalpha(Image.new("L", (W, H), 185))
        base.alpha_composite(nf)

    hp_ring(base, 24, 22)
    d = ImageDraw.Draw(base)
    # armor chip
    ac = icon("copper_armor", 18)
    chip(base, (24, 128), "12", ac, border=TEAL)
    text_spaced(d, (24 + 55, 166), "ВОИН · УРОН 11", mono(10), DIM, spacing=1, anchor="mm")
    # status chips
    sp = icon("mushroom_spore", 12)
    tp = icon("torch", 12)
    c1 = chip(base, (24, 188), "яд 7", sp, border=(121, 201, 154, 90), fg=(207, 233, 212))
    c2 = chip(base, (c1[0] + 8, 188), "огонь 3", tp, border=(255, 106, 43, 120), fg=(255, 201, 168))

    top_center(base, night)
    lens(base, W - 20 - 164, 16)
    loot_feed(base)
    context_chip(base, "ПКМ — ОТКРЫТЬ ДРЕВНИЙ СУНДУК")
    hotbar(base, [("wooden_pickaxe", 1), ("dirt", 54), ("stone", 23), ("wood", 88), ("workbench", 1)], selected=0)
    if night:
        boss_bar(base)
    return base.convert("RGB")

# =========================================================
# 2. INVENTORY
# =========================================================
def overlay_header(base, title, sub, tab_on):
    d = ImageDraw.Draw(base)
    text_spaced(d, (26, 18), title, ps(15), GOLD, spacing=2)
    d.text((26, 46), sub, font=mono(10), fill=DIM)
    tabs = ["РЮКЗАК", "КАРТА", "ЖУРНАЛ"]
    x = W - 26 - 34 - 6
    for i, t in enumerate(reversed(tabs)):
        on = (t == tab_on)
        font = mono(11)
        tw = int(font.getlength(t))
        w = tw + 32
        x -= w
        rrect(d, (x, 20, x + w, 48), 7, fill=(255, 106, 43, 25) if on else (16, 20, 27, 205),
              outline=EMBER if on else (214, 181, 106, 51), width=1 if not on else 1)
        d.text((x + 16, 28), t, font=font, fill=(255, 217, 168) if on else DIM)
        x -= 6
    bx = W - 26 - 34
    rrect(d, (bx, 20, bx + 34, 48), 7, fill=(26, 32, 41, 230), outline=(255, 255, 255, 30), width=1)
    d.text((bx + 13, 26), "×", font=mono(16), fill=DIM)

def stat_row(base, x, y, w, label, value, last=False):
    d = ImageDraw.Draw(base)
    d.text((x, y), label, font=mono(10), fill=(151, 160, 154))
    d.text((x + w, y), value, font=monob(10), fill=GOLD, anchor="ra")
    if not last:
        d.line((x, y + 16, x + w, y + 16), fill=(255, 255, 255, 16), width=1)

def screen_inventory():
    base = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bg = Image.open(os.path.join(ROOT, "ui_concept", "assets", "gameplay_bg.png")).convert("RGBA")
    bg = cover(bg, W, H).filter(ImageFilter.GaussianBlur(3))
    base.alpha_composite(bg)
    dim = Image.new("RGBA", (W, H), (6, 8, 12, 0))
    dim.putalpha(Image.new("L", (W, H), 185))
    base.alpha_composite(dim)
    overlay_header(base, "SURVIVOR'S KIT", "Снаряжение · Припасы · Горн", "РЮКЗАК")

    d = ImageDraw.Draw(base)
    body_y, body_h = 78, H - 78 - 14

    # --- char column ---
    cw = 250
    rrect(d, (26, body_y, 26 + cw, body_y + body_h), 10, fill=(20, 25, 33, 240), outline=(214, 181, 106, 90), width=1)
    # hero sprite
    pl = Image.open(os.path.join(ROOT, "assets", "textures", "player.png")).convert("RGBA")
    frame = pl.crop((0, 0, 48, 64))
    hero_h = 170
    hero = frame.resize((int(48 * hero_h / 64), hero_h), Image.NEAREST)
    base.alpha_composite(hero, (26 + (cw - hero.width) // 2, body_y + 14))
    # equipment slots
    eq = [("copper_sword", "ОРУЖИЕ"), ("copper_armor", "БРОНЯ"), ("root_ring", "АМУЛЕТ")]
    eq_y = body_y + 14 + hero_h + 12
    for i, (item, label) in enumerate(eq):
        x0 = 26 + (cw - 3 * 56 - 2 * 8) // 2 + i * 64
        rrect(d, (x0, eq_y, x0 + 56, eq_y + 56), 9, fill=(28, 34, 44, 245), outline=(255, 159, 67, 150), width=1)
        base.alpha_composite(icon(item, 40), (x0 + 8, eq_y + 8))
        d.text((x0 + 28, eq_y - 13), label, font=mono(8), fill=DIM, anchor="mm")
    # stats
    sy = eq_y + 70
    rrect(d, (26 + 14, sy, 26 + cw - 14, sy + 92), 8, fill=(13, 17, 23, 200), outline=(255, 255, 255, 18), width=1)
    rows = [("Класс", "Воин"), ("Урон", "11"), ("Защита", "5"), ("Холод/Жар", "8% / 6%")]
    for i, (k, v) in enumerate(rows):
        stat_row(base, 26 + 30, sy + 12 + i * 20, cw - 60, k, v, last=(i == 3))

    # --- inventory column ---
    gx0 = 26 + cw + 14
    gw = W - 26 - 14 - 300 - 14 - gx0
    gy0 = body_y
    gh = body_h
    rrect(d, (gx0, gy0, gx0 + gw, gy0 + gh), 10, fill=(20, 25, 33, 240), outline=(214, 181, 106, 90), width=1)
    d.text((gx0 + 14, gy0 + 12), "ПРИПАСЫ · 30 СЛОТОВ", font=ps(9), fill=DIM)
    items = [
        ("copper_ore", 27), ("iron_ore", 9), ("copper_bar", 6), ("torch", 16), ("leaf", 34), ("ash", 41),
        ("root", 18), ("mushroom_spore", 7), ("glowcap", 5), ("sapling", 3), ("copper_sword", 1), ("wooden_bow", 1),
        ("wooden_shield", 1), ("copper_armor", 1), ("root_ring", 1), ("spark_shard", 4), ("memory_shard", 2), ("ancient_chest", 1),
        ("furnace", 1), ("anvil", 1), ("stoneblood_ore", 11), ("ember_root", 6),
    ]
    slot, gap, pad = 76, 8, 14
    cols = 6
    grid_w = cols * slot + (cols - 1) * gap
    gx = gx0 + (gw - grid_w) // 2
    gy = gy0 + 40
    for i in range(30):
        r = i // cols
        c = i % cols
        x0 = gx + c * (slot + gap)
        y0 = gy + r * (slot + gap)
        if i < len(items):
            item, count = items[i]
            sel = (i == 3)
            if sel:
                gl = Image.new("RGBA", base.size, (0, 0, 0, 0))
                ImageDraw.Draw(gl).rounded_rectangle((x0, y0, x0 + slot, y0 + slot), radius=8, outline=EMBER, width=3)
                gl = gl.filter(ImageFilter.GaussianBlur(6))
                base.alpha_composite(gl)
            rrect(d, (x0, y0, x0 + slot, y0 + slot), 8, fill=(24, 30, 39, 235),
                  outline=EMBER if sel else (214, 181, 106, 42), width=2 if sel else 1)
            base.alpha_composite(icon(item, 52), (x0 + (slot - 52) // 2, y0 + (slot - 52) // 2))
            if count > 1:
                d.text((x0 + slot - 5, y0 + slot - 16), str(count), font=ps(8), fill=(255, 243, 214), anchor="rs")
        else:
            rrect(d, (x0, y0, x0 + slot, y0 + slot), 8, fill=(13, 16, 22, 90),
                  outline=(255, 255, 255, 18), width=1)
    # footer
    fy = gy + 3 * (slot + gap) + 14
    d.text((gx0 + 14, fy), "Медная руда — выбран предмет. ПКМ — выбросить половину,", font=mono(10), fill=DIM)
    d.text((gx0 + 14, fy + 15), "перетащите на слот хотбара внизу.", font=mono(10), fill=DIM)

    # --- forge column ---
    fx0 = W - 26 - 300
    rrect(d, (fx0, gy0, fx0 + 300, gy0 + gh), 10, fill=(20, 25, 33, 240), outline=(214, 181, 106, 90), width=1)
    d.text((fx0 + 14, gy0 + 12), "◆ ГОРН РЕЦЕПТОВ", font=ps(9), fill=DIM)
    d.rectangle((fx0 + 14 + 154, gy0 + 13, fx0 + 14 + 156, gy0 + 22), fill=EMBER2)
    sts = ["Руки", "Верстак", "Горн", "Наковальня"]
    sw = (300 - 28 - 3 * 4) / 4
    for i, s in enumerate(sts):
        x0 = fx0 + 14 + i * (sw + 4)
        on = (i == 0)
        rrect(d, (x0, gy0 + 34, x0 + sw, gy0 + 56), 5, fill=(255, 106, 43, 30) if on else (20, 25, 33, 230),
              outline=EMBER if on else (255, 255, 255, 20), width=1)
        d.text((x0 + sw / 2, gy0 + 39), s, font=mono(9), fill=(255, 217, 168) if on else DIM, anchor="ma")
    recs = [
        ("workbench", "Верстак", "×1", [("wood", 8)], True),
        ("torch", "Факел", "×4", [("wood", 1), ("ash", 1)], True),
        ("wooden_pickaxe", "Деревянная кирка", "×1", [("wood", 10), ("stone", 4)], False),
    ]
    have = {"wood": 88, "stone": 23, "ash": 41}
    ry = gy0 + 68
    for icon_id, name, out, cost, ready in recs:
        rrect(d, (fx0 + 14, ry, fx0 + 286, ry + 54), 8, fill=(16, 20, 27, 200), outline=(255, 106, 43, 120) if ready else (255, 255, 255, 16), width=1)
        base.alpha_composite(icon(icon_id, 34), (fx0 + 22, ry + 10))
        d.text((fx0 + 66, ry + 8), name, font=mono(11), fill=INK)
        d.text((fx0 + 66, ry + 24), out, font=mono(9), fill=DIM)
        cx = fx0 + 66
        for it, n in cost:
            cname = {"wood": "Дерево", "stone": "Камень", "ash": "Пепел"}[it]
            col = GREEN if have.get(it, 0) >= n else RED
            t = "%s %d/%d" % (cname, have.get(it, 0), n)
            d.text((cx, ry + 37), t, font=mono(9), fill=col)
            cx += 9 + mono(9).getlength(t)
        rrect(d, (fx0 + 246, ry + 12, fx0 + 282, ry + 42), 5,
              fill=(255, 180, 94) if ready else (42, 49, 60),
              outline=None, width=0)
        d.text((fx0 + 264, ry + 20), "КРАФТ", font=ps(7), fill=(26, 18, 8) if ready else DIM2, anchor="mm")
        ry += 62
    d.text((fx0 + 14, ry + 2), "Верстак рядом: ДА · Горн: ДА · Наковальня: НЕТ", font=mono(9), fill=DIM)
    return base.convert("RGB")

# =========================================================
# 3. MAP
# =========================================================
def screen_map():
    base = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dim = Image.new("RGBA", (W, H), (6, 8, 12, 0))
    dim.putalpha(Image.new("L", (W, H), 185))
    base.alpha_composite(dim)
    overlay_header(base, "WORLD MAP", "Туман войны рассеивается вокруг путника", "КАРТА")
    d = ImageDraw.Draw(base)
    body_y, body_h = 78, H - 78 - 14
    rrect(d, (26, body_y, W - 26, body_y + body_h), 10, fill=(7, 9, 13, 255), outline=(214, 181, 106, 64), width=1)
    map_img = Image.open(os.path.join(ROOT, "ui_concept", "assets", "world_map.png")).convert("RGBA")
    map_img = cover(map_img, W - 52, body_h).convert("RGBA")
    base.alpha_composite(map_img, (26, body_y))
    # fog of war
    fog = radial_mask((W - 52, body_h), (W - 52) * 0.46, body_h * 0.54, (W - 52) * 0.22, (W - 52) * 0.48)
    fog = fog.point(lambda v: int(v * 0.94))
    ft = Image.new("RGBA", (W - 52, body_h), (6, 8, 12, 0))
    ft.putalpha(fog)
    base.alpha_composite(ft, (26, body_y))
    # player marker
    mx = 26 + int((W - 52) * 0.46)
    my = body_y + int(body_h * 0.54)
    gl = Image.new("RGBA", base.size, (0, 0, 0, 0))
    ImageDraw.Draw(gl).ellipse((mx - 8, my - 8, mx + 8, my + 8), fill=(255, 226, 122))
    gl = gl.filter(ImageFilter.GaussianBlur(6))
    base.alpha_composite(gl)
    ImageDraw.Draw(base).ellipse((mx - 6, my - 6, mx + 6, my + 6), fill=(255, 226, 122), outline=(255, 179, 71), width=2)
    # legend
    legend = [("Лес", (74, 123, 80)), ("Топь", (79, 61, 42)), ("Пепельная пустыня", (201, 181, 145)),
              ("Руины", (116, 107, 131)), ("Мёрзлая пустошь", (184, 222, 237)), ("Грибные залы", (23, 22, 40))]
    x = 42
    y = body_y + body_h - 34
    for name, col in legend:
        font = mono(9)
        w = int(font.getlength(name)) + 22
        rrect(d, (x, y, x + w, y + 22), 5, fill=(10, 13, 18, 210), outline=(255, 255, 255, 26), width=1)
        d.rectangle((x + 7, y + 7, x + 14, y + 14), fill=col)
        d.text((x + 19, y + 5), name, font=font, fill=(200, 207, 201))
        x += w + 6
    return base.convert("RGB")

# =========================================================
# 4. JOURNAL
# =========================================================
def screen_journal():
    base = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bg = Image.open(os.path.join(ROOT, "ui_concept", "assets", "gameplay_bg.png")).convert("RGBA")
    base.alpha_composite(cover(bg, W, H).filter(ImageFilter.GaussianBlur(3)))
    dim = Image.new("RGBA", (W, H), (6, 8, 12, 0))
    dim.putalpha(Image.new("L", (W, H), 185))
    base.alpha_composite(dim)
    overlay_header(base, "CHRONICLES", "Память мира, собранная по осколкам", "ЖУРНАЛ")
    d = ImageDraw.Draw(base)
    body_y, body_h = 78, H - 78 - 14

    # left column
    lw = 300
    rrect(d, (26, body_y, 26 + lw, body_y + body_h), 10, fill=(20, 25, 33, 240), outline=(214, 181, 106, 90), width=1)
    tabs = ["Бестиарий", "Материалы", "Рецепты"]
    for i, t in enumerate(tabs):
        x0 = 26 + 14 + i * ((lw - 28 - 8) / 3 + 4)
        w = (lw - 28 - 8) / 3
        on = (i == 0)
        rrect(d, (x0, body_y + 12, x0 + w, body_y + 36), 6, fill=(255, 106, 43, 28) if on else (16, 20, 27, 230),
              outline=EMBER if on else (214, 181, 106, 51), width=1)
        d.text((x0 + w / 2, body_y + 18), t, font=mono(9), fill=(255, 217, 168) if on else DIM, anchor="ma")
    entries = [
        ("wild_slime", "wild_slime_idle.png", "Дикий слизень", "Лес, корневые поляны"),
        ("mossling", "mossling_idle.png", "Моховик", "Поверхность, сырые низины"),
        ("stone_beast", "idle.png", "Каменный зверь", "Пещеры, пробуждается от алтаря"),
    ]
    ey = body_y + 46
    for i, (edir, fname, name, place) in enumerate(entries):
        sel = (i == 2)
        rrect(d, (26 + 12, ey, 26 + lw - 12, ey + 50), 8, fill=(255, 106, 43, 20) if sel else (16, 20, 27, 200),
              outline=EMBER if sel else (255, 255, 255, 16), width=1)
        th = enemy_frame(edir, fname, 36)
        base.alpha_composite(th, (26 + 20, ey + 7))
        d.text((26 + 64, ey + 8), name, font=mono(11), fill=INK)
        d.text((26 + 64, ey + 26), place, font=mono(8), fill=DIM)
        ey += 58

    # right detail
    dx0 = 26 + lw + 14
    dw = W - 26 - dx0
    rrect(d, (dx0, body_y, dx0 + dw, body_y + body_h), 10, fill=(20, 25, 33, 240), outline=(214, 181, 106, 90), width=1)
    text_spaced(d, (dx0 + 18, body_y + 16), "КАМЕННЫЙ ЗВЕРЬ", ps(12), GOLD, spacing=1)
    # sprite preview box
    pbox = (dx0 + 18, body_y + 48, dx0 + dw - 18, body_y + 160)
    rrect(d, pbox, 8, fill=(8, 10, 14, 220), outline=(255, 255, 255, 18), width=1)
    beast = enemy_frame("stone_beast", "idle.png", 100)
    base.alpha_composite(beast, (pbox[0] + (pbox[2] - pbox[0] - beast.width) // 2, pbox[3] - 6 - beast.height))
    d.ellipse((pbox[0] + 40, pbox[3] - 20, pbox[0] + 200, pbox[3] - 16), fill=(0, 0, 0, 120))
    # text
    ty = body_y + 176
    def lbl(text, y):
        d.text((dx0 + 18, y), text, font=mono(9), fill=GOLD)
    def line(text, y, dim=False):
        d.text((dx0 + 18, y), text, font=mono(10), fill=DIM2 if dim else (195, 203, 196))
    lbl("ОБИТАНИЕ", ty); line("Пещеры, пробуждается от алтаря", ty + 15)
    lbl("ИССЛЕДОВАНИЕ", ty + 44); line("Стадия 1 из 4 · Записей об убийствах: 1", ty + 59)
    lbl("ДОБЫЧА", ty + 88); line("Ядро зверя", ty + 103)
    lbl("ЗАМЕТКИ", ty + 132); line("Пробуждается, если выкопать достаточно камня.", ty + 147, dim=True)
    line("Его кровь-камень открывает дорогу в грибные залы.", ty + 162, dim=True)
    return base.convert("RGB")

# =========================================================
# render all
# =========================================================
def save(im, name):
    p = os.path.join(OUT, name)
    im.save(p)
    print("saved", p, im.size)

save(screen_gameplay(), "gameplay.png")
save(screen_gameplay(night=True), "gameplay_night_boss.png")
save(screen_inventory(), "inventory.png")
save(screen_map(), "map.png")
save(screen_journal(), "journal.png")

# overview sheet 2x2
def caption(im, text):
    d = ImageDraw.Draw(im)
    rrect(d, (0, 0, im.width, 26), 0, fill=(10, 13, 18, 255))
    text_spaced(d, (im.width // 2, 7), text, mono(11), (214, 181, 106), spacing=2, anchor="mm")

def cell(im):
    return im.resize((640, 360), Image.LANCZOS)

g = cell(screen_gameplay())
caption(g, "HUD — ГЕЙМПЛЕЙ")
i = cell(screen_inventory())
caption(i, "ИНВЕНТАРЬ — ARCHIVE")
m = cell(screen_map())
caption(m, "КАРТА МИРА")
j = cell(screen_journal())
caption(j, "ЖУРНАЛ — CHRONICLES")

sheet = Image.new("RGB", (1280, 720), (5, 7, 10))
sheet.paste(g, (0, 0))
sheet.paste(i, (640, 0))
sheet.paste(m, (0, 360))
sheet.paste(j, (640, 360))
for x in (639, 640):
    for y in range(720):
        sheet.putpixel((x, y), (30, 34, 42))
for y in (359, 360):
    for x in range(1280):
        sheet.putpixel((x, y), (30, 34, 42))
save(sheet, "overview.png")
print("DONE")
