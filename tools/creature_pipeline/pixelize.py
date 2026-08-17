#!/usr/bin/env python3
"""Convert a generated hi-res creature image into a clean game-ready pixel sprite.

Steps: border-connected background removal (flood fill), tight crop,
downscale to target pixel height with nearest sampling, palette clamp
(median cut), and re-outline with the darkest palette tone.
"""
import sys, collections
from collections import deque
from PIL import Image

def key_background(im, tol=30):
    """Remove the flat background, but ONLY the region connected to the
    image border (flood fill). Dark body pixels that merely match the
    background color stay opaque — otherwise creatures with near-background
    colors (e.g. dark bark) end up with transparent holes in the body."""
    px = im.load()
    W, H = im.size
    corners = [px[0,0], px[W-1,0], px[0,H-1], px[W-1,H-1]]
    bg = collections.Counter(corners).most_common(1)[0][0]

    def is_bg(c):
        return all(abs(c[i]-bg[i]) <= tol for i in range(3))

    outside = bytearray(W * H)
    dq = deque()
    for x in range(W):
        for y in (0, H-1):
            if is_bg(px[x,y]) and not outside[y*W+x]:
                outside[y*W+x] = 1; dq.append((x, y))
    for y in range(H):
        for x in (0, W-1):
            if is_bg(px[x,y]) and not outside[y*W+x]:
                outside[y*W+x] = 1; dq.append((x, y))
    while dq:
        x, y = dq.popleft()
        for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
            nx, ny = x+dx, y+dy
            if 0 <= nx < W and 0 <= ny < H and not outside[ny*W+nx] and is_bg(px[nx,ny]):
                outside[ny*W+nx] = 1; dq.append((nx, ny))

    out = Image.new("RGBA", im.size, (0,0,0,0))
    op = out.load()
    for y in range(H):
        for x in range(W):
            if not outside[y*W+x]:
                c = px[x,y]
                op[x,y] = (c[0], c[1], c[2], 255)
    return out

def fill_interior_holes(im):
    """Make any fully enclosed transparent pixels opaque using the average
    of their nearest opaque neighbors (safety net after downscaling)."""
    px = im.load()
    W, H = im.size
    outside = bytearray(W * H)
    dq = deque()
    for x in range(W):
        for y in (0, H-1):
            if px[x,y][3] == 0 and not outside[y*W+x]:
                outside[y*W+x] = 1; dq.append((x, y))
    for y in range(H):
        for x in (0, W-1):
            if px[x,y][3] == 0 and not outside[y*W+x]:
                outside[y*W+x] = 1; dq.append((x, y))
    while dq:
        x, y = dq.popleft()
        for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
            nx, ny = x+dx, y+dy
            if 0 <= nx < W and 0 <= ny < H and not outside[ny*W+nx] and px[nx,ny][3] == 0:
                outside[ny*W+nx] = 1; dq.append((nx, ny))
    holes = [(x, y) for y in range(H) for x in range(W)
             if px[x,y][3] == 0 and not outside[y*W+x]]
    # Grow inward layer by layer so large holes fill with local colors.
    while holes:
        remaining = []
        for x, y in holes:
            neigh = []
            for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
                nx, ny = x+dx, y+dy
                if 0 <= nx < W and 0 <= ny < H and px[nx,ny][3] > 0:
                    neigh.append(px[nx,ny])
            if neigh:
                r = sum(c[0] for c in neigh)//len(neigh)
                g = sum(c[1] for c in neigh)//len(neigh)
                b = sum(c[2] for c in neigh)//len(neigh)
                px[x,y] = (r, g, b, 255)
            else:
                remaining.append((x, y))
        if len(remaining) == len(holes):
            break
        holes = remaining
    return im

def tight_crop(im):
    bbox = im.getbbox()
    return im.crop(bbox) if bbox else im

def pixelize(im, target_h):
    scale = target_h / im.height
    tw = max(1, round(im.width * scale))
    small = im.resize((tw, target_h), Image.BOX)
    # binarize alpha
    px = small.load()
    for y in range(small.height):
        for x in range(small.width):
            r,g,b,a = px[x,y]
            px[x,y] = (r,g,b,255) if a >= 128 else (0,0,0,0)
    return small

def clamp_palette(im, colors=14):
    rgb = im.convert("RGB")
    pal = rgb.quantize(colors=colors, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGB")
    out = Image.new("RGBA", im.size, (0,0,0,0))
    src_a = im.getchannel("A").load()
    pp = pal.load(); op = out.load()
    for y in range(im.height):
        for x in range(im.width):
            if src_a[x,y] >= 128:
                c = pp[x,y]
                op[x,y] = (c[0], c[1], c[2], 255)
    return out

def outline(im, color):
    px = im.load()
    out = im.copy(); op = out.load()
    for y in range(im.height):
        for x in range(im.width):
            if px[x,y][3] == 0:
                continue
            edge = False
            for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                nx,ny = x+dx, y+dy
                if nx<0 or ny<0 or nx>=im.width or ny>=im.height or px[nx,ny][3]==0:
                    edge = True; break
            if edge:
                op[x,y] = color
    return out

def process(src, dst, target_h, colors=14, do_outline=True):
    im = Image.open(src).convert("RGBA")
    im = key_background(im)
    im = tight_crop(im)
    im = pixelize(im, target_h)
    im = fill_interior_holes(im)
    im = clamp_palette(im, colors)
    if do_outline:
        # darkest tone in the sprite as outline color
        cs = [im.getpixel((x,y)) for y in range(im.height) for x in range(im.width) if im.getpixel((x,y))[3]>0]
        darkest = min(cs, key=lambda c: c[0]+c[1]+c[2])
        dark = (max(0,darkest[0]-18), max(0,darkest[1]-18), max(0,darkest[2]-18), 255)
        im = outline(im, dark)
    im.save(dst)
    return im.size

if __name__ == "__main__":
    src, dst, h = sys.argv[1], sys.argv[2], int(sys.argv[3])
    print(process(src, dst, h))
