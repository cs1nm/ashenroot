#!/usr/bin/env python3
"""Batch: cut 3x2 AI sheets into cells and pixelize each into a 32x32 icon.

CRISP settings approved by the player:
- contrast x1.22 + saturation x1.15 BEFORE quantization
- hard 10-color palette, no dither
- despeckle pass (single-pixel islands merge into dominant neighbor)
- hard alpha (>110), outline at 0.6x of darkest tone
Usage: pixelize_items.py <sheet.png> <out_dir> name1 name2 ... name6
"""
import sys, os

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "creature_pipeline"))
from pixelize import key_background, fill_interior_holes, tight_crop, outline
from PIL import Image, ImageEnhance

def clamp_palette_hard(im, colors):
    rgb = Image.new("RGB", im.size, (255, 0, 255))
    rgb.paste(im, mask=im.getchannel("A"))
    q = rgb.quantize(colors=colors + 1, method=Image.MEDIANCUT, dither=Image.Dither.NONE)
    back = q.convert("RGB")
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    po, pb, pa = out.load(), back.load(), im.load()
    for y in range(im.height):
        for x in range(im.width):
            if pa[x, y][3] > 0:
                po[x, y] = (*pb[x, y], 255)
    return out

def despeckle(im):
    px = im.load()
    W, H = im.size
    for _ in range(2):
        for y in range(H):
            for x in range(W):
                c = px[x, y]
                if c[3] == 0:
                    continue
                neigh = {}
                same = 0
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and px[nx, ny][3] > 0:
                        nc = px[nx, ny]
                        if nc == c:
                            same += 1
                        neigh[nc] = neigh.get(nc, 0) + 1
                if same == 0 and neigh:
                    px[x, y] = max(neigh, key=neigh.get)
    return im

def keep_largest_component(im):
    """Drop satellite fragments (neighbor-cell spillover on AI sheets):
    keep only the largest 8-connected opaque region."""
    px = im.load()
    W, H = im.size
    seen = bytearray(W * H)
    best_region = []
    from collections import deque
    for sy in range(H):
        for sx in range(W):
            if px[sx, sy][3] == 0 or seen[sy * W + sx]:
                continue
            region = []
            dq = deque([(sx, sy)])
            seen[sy * W + sx] = 1
            while dq:
                x, y = dq.popleft()
                region.append((x, y))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < W and 0 <= ny < H and not seen[ny * W + nx] and px[nx, ny][3] > 0:
                            seen[ny * W + nx] = 1
                            dq.append((nx, ny))
            if len(region) > len(best_region):
                best_region = region
    keep = set(best_region)
    for y in range(H):
        for x in range(W):
            if px[x, y][3] > 0 and (x, y) not in keep:
                px[x, y] = (0, 0, 0, 0)
    return im

def process_cell(cell, out_path, target=28, colors=10):
    cut = key_background(cell, tol=26)
    cut = keep_largest_component(cut)
    cut = tight_crop(cut)
    if cut.size[0] == 0 or cut.size[1] == 0:
        print("EMPTY CELL ->", out_path)
        return False
    w, h = cut.size
    scale = float(target) / max(w, h)
    tw, th = max(1, round(w * scale)), max(1, round(h * scale))
    small = cut.resize((tw, th), Image.LANCZOS)
    rgb = small.convert("RGB")
    rgb = ImageEnhance.Contrast(rgb).enhance(1.22)
    rgb = ImageEnhance.Color(rgb).enhance(1.15)
    a = small.getchannel("A").point(lambda v: 255 if v > 110 else 0)
    small = Image.merge("RGBA", (*rgb.split(), a))
    small = clamp_palette_hard(small, colors)
    small = despeckle(small)
    small = fill_interior_holes(small)
    px = small.load()
    darkest = (40, 30, 24); best = 10 ** 9
    for y in range(small.height):
        for x in range(small.width):
            cpx = px[x, y]
            if cpx[3] > 0:
                v = cpx[0] + cpx[1] + cpx[2]
                if v < best:
                    best = v; darkest = cpx[:3]
    dk = tuple(int(ch * 0.6) for ch in darkest)
    small = outline(small, tuple(list(dk) + [255]))
    canvas = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    canvas.paste(small, ((32 - small.width) // 2, (32 - small.height) // 2))
    canvas.save(out_path)
    return True

def main():
    sheet_path, out_dir = sys.argv[1], sys.argv[2]
    names = sys.argv[3:9]
    os.makedirs(out_dir, exist_ok=True)
    src = Image.open(sheet_path).convert("RGB")
    W, H = src.size
    cw, ch = W // 3, H // 2
    i = 0
    for r in range(2):
        for c in range(3):
            if i >= len(names):
                break
            if names[i] != "-":
                cell = src.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch))
                ok = process_cell(cell, os.path.join(out_dir, names[i] + ".png"))
                print(("OK " if ok else "FAIL ") + names[i])
            i += 1

if __name__ == "__main__":
    main()
