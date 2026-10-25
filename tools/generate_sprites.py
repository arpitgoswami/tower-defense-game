#!/usr/bin/env python3
"""Procedural pixel-art generator. Run from the project root:  python3 tools/generate_sprites.py
Creates PNG sprites in assets/sprites and SpriteFrames .tres files in assets/frames."""
import os, random
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "sprites")
FRAMES = os.path.join(HERE, "..", "assets", "frames")
os.makedirs(OUT, exist_ok=True); os.makedirs(FRAMES, exist_ok=True)
OL = (24, 16, 32, 255)  # shared outline colour


def C(r, g, b, a=255): return (r, g, b, a)


def new(w, h): return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def outline(img, col=OL):
    w, h = img.size
    src = img.load()
    res = img.copy(); dst = res.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 200:
                        dst[x, y] = col; break
    return res


def rect(d, x0, y0, x1, y1, col):  # [x0,x1) x [y0,y1)
    if x1 > x0 and y1 > y0:
        d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=col)


def save(img, name):
    img.save(os.path.join(OUT, name))


def sheet(frames, name):
    w, h = frames[0].size
    s = new(w * len(frames), h)
    for i, f in enumerate(frames): s.paste(f, (i * w, 0))
    save(s, name)


# ------------------------------------------------------------------ WIZARD (24x24, 4 frames)
def wizard(kind, i):
    img = new(24, 24); d = ImageDraw.Draw(img)
    robe, robe_l, robe_d = C(70, 64, 170), C(104, 96, 214), C(46, 40, 120)
    skin, beard, hat, hat_l = C(244, 204, 164), C(236, 236, 244), C(58, 52, 150), C(92, 84, 200)
    wood = C(122, 80, 44)
    bob = 1 if (kind == "idle" and i == 1) else 0
    rect(d, 18, 7 + bob, 20, 23, wood)  # staff
    d.polygon([(7, 23), (16, 23), (15, 12 + bob), (8, 12 + bob)], fill=robe)
    rect(d, 8, 15 + bob, 10, 23, robe_l)
    rect(d, 14, 17, 16, 23, robe_d)
    rect(d, 7, 21, 17, 23, robe_d)
    rect(d, 9, 17 + bob, 15, 18 + bob, C(240, 200, 70))  # belt
    if kind == "cast":
        rect(d, 15, 12 if i == 0 else 10, 19, 14 if i == 0 else 12, robe_l)
        rect(d, 18, 10 if i == 0 else 8, 20, 12 if i == 0 else 10, skin)
    else:
        rect(d, 15, 14 + bob, 18, 16 + bob, robe_l); rect(d, 17, 14 + bob, 19, 16 + bob, skin)
    rect(d, 9, 8 + bob, 15, 13 + bob, skin)
    rect(d, 9, 11 + bob, 15, 16 + bob, beard)
    rect(d, 10, 9 + bob, 11, 10 + bob, OL); rect(d, 13, 9 + bob, 14, 10 + bob, OL)
    d.polygon([(12, 0 + bob), (16, 8 + bob), (8, 8 + bob)], fill=hat)
    rect(d, 11, 2 + bob, 12, 7 + bob, hat_l)
    rect(d, 6, 7 + bob, 18, 9 + bob, hat)
    rect(d, 6, 7 + bob, 18, 8 + bob, hat_l)
    rect(d, 9, 6 + bob, 15, 7 + bob, C(240, 200, 70))
    img = outline(img)
    d = ImageDraw.Draw(img)
    oy = 5 + bob
    if kind == "cast":
        r = 3 if i == 0 else 4
        cy = 6 if i == 0 else 4
        d.ellipse([19 - r, cy - r, 19 + r, cy + r], fill=C(255, 170, 40), outline=C(255, 240, 150))
        d.point([(19, cy), (18, cy - 1)], fill=C(255, 255, 255))
    else:
        d.ellipse([17, oy - 2, 22, oy + 3], fill=C(80, 210, 255), outline=C(200, 250, 255))
        d.point([(19, oy - 1)], fill=C(255, 255, 255))
    return img


wiz = [wizard("idle", 0), wizard("idle", 1), wizard("cast", 0), wizard("cast", 1)]
sheet(wiz, "wizard.png")


# ------------------------------------------------------------------ TOWER (48x56)
def tower():
    img = new(48, 56); d = ImageDraw.Draw(img)
    st, st_l, st_d = C(150, 150, 164), C(188, 188, 202), C(104, 104, 122)
    rect(d, 6, 14, 42, 50, st)
    rect(d, 6, 14, 12, 50, st_l); rect(d, 36, 14, 42, 50, st_d)
    rect(d, 2, 48, 46, 56, st_d); rect(d, 2, 48, 46, 50, st)
    for k in range(0, 40, 8):  # crenellations
        rect(d, 4 + k, 6, 9 + k, 14, st_l)
    rect(d, 4, 12, 44, 16, st_l)
    rect(d, 4, 15, 44, 17, st_d)
    for row, y in enumerate(range(20, 48, 6)):  # bricks
        rect(d, 6, y, 42, y + 1, st_d)
        off = 6 if row % 2 else 0
        for x in range(10 + off, 42, 12):
            rect(d, x, y, x + 1, y + 6, st_d)
    rect(d, 19, 36, 29, 50, C(60, 40, 30))  # door
    d.pieslice([19, 30, 29, 42], 180, 360, fill=C(60, 40, 30))
    rect(d, 20, 40, 21, 50, C(90, 62, 40))
    rect(d, 22, 22, 26, 29, C(30, 24, 48))  # window
    rect(d, 22, 22, 23, 29, C(80, 60, 140))
    return outline(img)


save(tower(), "tower.png")


# ------------------------------------------------------------------ TREES (32x40)
def tree(variant):
    img = new(32, 40); d = ImageDraw.Draw(img)
    rnd = random.Random(variant * 7 + 3)
    trunk, trunk_d = C(112, 72, 40), C(82, 50, 30)
    rect(d, 14, 28, 19, 39, trunk); rect(d, 17, 28, 19, 39, trunk_d)
    if variant == 0:  # pine
        g = [C(34, 110, 62), C(46, 140, 76), C(68, 170, 90)]
        for y, hw in [(2, 5), (10, 8), (18, 11), (24, 13)]:
            d.polygon([(16, y), (16 + hw + 2, y + 12), (16 - hw - 2, y + 12)], fill=g[0])
            d.polygon([(16, y), (16 - hw - 2, y + 12), (16, y + 12)], fill=g[1])
        for _ in range(14):
            d.point((rnd.randint(8, 24), rnd.randint(8, 34)), fill=g[2])
    elif variant == 1:  # round oak
        g = [C(52, 136, 56), C(78, 170, 70), C(116, 200, 90)]
        d.ellipse([3, 4, 29, 32], fill=g[0])
        d.ellipse([5, 5, 22, 24], fill=g[1])
        d.ellipse([8, 7, 16, 14], fill=g[2])
    else:  # autumn tree
        g = [C(176, 90, 36), C(220, 130, 40), C(244, 184, 64)]
        d.ellipse([4, 6, 28, 30], fill=g[0])
        d.ellipse([2, 12, 16, 28], fill=g[1]); d.ellipse([14, 6, 28, 22], fill=g[1])
        d.ellipse([8, 8, 16, 14], fill=g[2])
    return outline(img)


for v in range(3): save(tree(v), f"tree_{v}.png")


# ------------------------------------------------------------------ GRASS
def grass_tile(seed, flowers=False):
    rnd = random.Random(seed)
    img = new(16, 16); px = img.load()
    base = [C(88, 160, 72), C(82, 152, 68), C(96, 170, 78)]
    for y in range(16):
        for x in range(16):
            px[x, y] = rnd.choices(base, [6, 3, 2])[0]
    for _ in range(3):
        x, y = rnd.randint(1, 12), rnd.randint(2, 14)
        px[x, y] = C(60, 124, 56); px[x + 1, y - 1] = C(60, 124, 56); px[x + 2, y] = C(60, 124, 56)
    if flowers:
        x, y = rnd.randint(2, 12), rnd.randint(2, 12)
        px[x, y] = C(250, 240, 120); px[x + 1, y] = C(250, 250, 250); px[x, y + 1] = C(250, 250, 250)
    return img


tiles = [grass_tile(1), grass_tile(2), grass_tile(3, True)]
for i, t in enumerate(tiles): save(t, f"grass_{i}.png")
bg = new(128, 128); rnd = random.Random(11)
for ty in range(8):
    for tx in range(8):
        bg.paste(tiles[rnd.choices([0, 1, 2], [5, 4, 1])[0]], (tx * 16, ty * 16))
save(bg, "grass_bg.png")


# ------------------------------------------------------------------ BOLT / IMPACT / COIN / MISC
def bolt(i):
    img = new(16, 12); d = ImageDraw.Draw(img)
    for k in range(3):  # flame tail pointing left
        d.polygon([(2 + k * 2, 6), (8, 3 + (i + k) % 2), (8, 9 - (i + k) % 2)],
                  fill=[C(200, 60, 30), C(255, 120, 30), C(255, 190, 60)][k])
    d.ellipse([6, 2, 13, 9], fill=C(255, 150, 40), outline=C(255, 220, 110))
    d.ellipse([8, 4, 11, 7], fill=C(255, 250, 200))
    return img


sheet([bolt(0), bolt(1)], "bolt.png")


def impact(i):
    img = new(24, 24); d = ImageDraw.Draw(img)
    r = [4, 8, 11, 11][i]; a = [255, 255, 200, 110][i]
    d.ellipse([12 - r, 12 - r, 11 + r, 11 + r], fill=C(255, 170, 50, a))
    if i < 3:
        d.ellipse([12 - r + 3, 12 - r + 3, 11 + r - 3, 11 + r - 3], fill=C(255, 240, 160, a))
    if i >= 1:
        for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)]:
            L = min(r + 1 + i, 11)
            x, y = 12 + dx * L, 12 + dy * L
            d.rectangle([x - 1, y - 1, x, y], fill=C(255, 220, 90, a))
    return img


sheet([impact(i) for i in range(4)], "impact.png")


def coin(i):
    img = new(12, 12); d = ImageDraw.Draw(img)
    hw = [5, 3, 1, 3][i]
    d.ellipse([6 - hw - 1, 1, 6 + hw, 10], fill=C(250, 200, 40))
    if hw > 1:
        d.ellipse([6 - hw + 1, 3, 6 + hw - 2, 8], outline=C(200, 140, 20))
        d.point([(6 - hw + 1, 3)], fill=C(255, 250, 190))
    return outline(img)


sheet([coin(i) for i in range(4)], "coin.png")

img = new(4, 4); ImageDraw.Draw(img).rectangle([0, 0, 3, 3], fill=(255, 255, 255, 255)); save(img, "pixel.png")
img = new(16, 6); ImageDraw.Draw(img).ellipse([0, 0, 15, 5], fill=(0, 0, 0, 90)); save(img, "shadow.png")
img = new(8, 8); d = ImageDraw.Draw(img)
d.ellipse([0, 0, 7, 7], fill=(255, 255, 120, 70)); d.ellipse([2, 2, 5, 5], fill=(255, 255, 160, 255)); save(img, "firefly.png")
img = new(64, 28); d = ImageDraw.Draw(img)
for box in ([4, 12, 30, 26], [18, 4, 46, 24], [34, 10, 62, 26], [2, 18, 60, 27]):
    d.ellipse(box, fill=(255, 255, 255, 150))
save(img, "cloud.png")
ic = new(64, 64); ic.paste(wiz[0].resize((48, 48), Image.NEAREST), (8, 8))
bgc = Image.new("RGBA", (64, 64), (60, 120, 70, 255)); bgc.alpha_composite(ic); save(bgc, "icon.png")


# ------------------------------------------------------------------ ZOMBIES
def zombie_frame(S, P, row, f):
    """Front-facing zombie. row 0 = walk, row 1 = attack. Origin (feet) at the bottom."""
    img = new(S, S); d = ImageDraw.Draw(img)
    cx = S // 2
    feet = S - 2
    hw, hh, bw, bh, ll, al = P["hw"], P["hh"], P["bw"], P["bh"], P["ll"], P["al"]
    skin, skin_d, cloth, cloth_d, eye = P["skin"], P["skin_d"], P["cloth"], P["cloth_d"], P["eye"]
    lw, aw = P["lw"], P["aw"]
    if row == 0:
        bob = [0, 1, 0, 1][f]; lift = [(0, 2), (1, 1), (2, 0), (1, 1)][f]
        swing = [0.7, 0.2, -0.3, 0.2][f]; lunge = 0
    else:
        bob = [0, -1, 2, 1][f]; lift = (0, 0); lunge = [0, -1, 2, 1][f]
        swing = [-0.7, -1.0, 1.0, 0.4][f]
    hip = feet - ll
    for side, lf in ((-1, lift[0]), (1, lift[1])):
        x0 = cx + (-bw // 2 + 1 if side < 0 else bw // 2 - 1 - lw)
        rect(d, x0, hip + bob, x0 + lw, feet - lf + 1, cloth_d)
        rect(d, x0, feet - lf - 1, x0 + lw, feet - lf + 1, skin_d)
    body_top = hip - bh + bob
    rect(d, cx - bw // 2, body_top, cx - bw // 2 + bw, hip + bob + 1, cloth)
    rect(d, cx - bw // 2, body_top, cx - bw // 2 + 2, hip + bob + 1, P["cloth_l"])
    rect(d, cx - bw // 2 + bw - 2, body_top, cx - bw // 2 + bw, hip + bob + 1, cloth_d)
    for k in range(P.get("tears", 2)):  # tattered hem
        rect(d, cx - bw // 2 + 1 + k * 4, hip + bob - 1, cx - bw // 2 + 3 + k * 4, hip + bob + 2, skin_d)
    if P.get("vest"):
        rect(d, cx - bw // 2 + 2, body_top + 1, cx - bw // 2 + bw - 2, hip + bob - 2, P["vest"])
        rect(d, cx - 1, body_top + 1, cx + 1, hip + bob - 2, cloth_d)
    head_top = body_top - hh + 1 + (lunge if row else 0)
    rect(d, cx - hw // 2, head_top, cx - hw // 2 + hw, head_top + hh, skin)
    rect(d, cx - hw // 2, head_top, cx - hw // 2 + 2, head_top + hh, P["skin_l"])
    ey = head_top + max(2, hh // 3)
    rect(d, cx - hw // 2 + 2, ey, cx - hw // 2 + 4, ey + 2, eye)
    rect(d, cx + hw // 2 - 4, ey, cx + hw // 2 - 2, ey + 2, eye)
    my = head_top + hh - 3
    mouth_h = 2 if row == 0 else (3 if f in (1, 2) else 2)
    rect(d, cx - hw // 2 + 2, my, cx + hw // 2 - 2, my + mouth_h, C(70, 20, 30))
    if row == 1 and f in (1, 2):
        rect(d, cx - hw // 2 + 3, my, cx - hw // 2 + 5, my + 1, C(240, 240, 220))
    if P.get("horns"):
        bone = C(236, 224, 190)
        rect(d, cx - hw // 2 - 1, head_top - 3, cx - hw // 2 + 2, head_top + 1, bone)
        rect(d, cx + hw // 2 - 2, head_top - 3, cx + hw // 2 + 1, head_top + 1, bone)
        rect(d, cx - hw // 2 - 2, head_top - 5, cx - hw // 2, head_top - 2, bone)
        rect(d, cx + hw // 2, head_top - 5, cx + hw // 2 + 2, head_top - 2, bone)
        rect(d, cx - hw // 2, head_top - 1, cx + hw // 2, head_top + 1, C(250, 200, 40))  # crown band
    if P.get("hair"):
        rect(d, cx - hw // 2, head_top - 1, cx + hw // 2, head_top + 2, P["hair"])
    shoulder = body_top + 2
    for side in (-1, 1):
        sw = swing * side if row == 0 else swing
        reach = int(al * sw)
        ax = cx - bw // 2 - aw if side < 0 else cx + bw // 2
        y_a, y_b = sorted((shoulder, shoulder + reach))
        rect(d, ax, y_a, ax + aw, y_b + aw + 1, skin)
        rect(d, ax, y_b, ax + aw, y_b + aw + 1, skin_d)
        rect(d, ax, shoulder, ax + aw, shoulder + 3, cloth)
    if P.get("pads"):
        for side in (-1, 1):
            px_ = cx - bw // 2 - aw - 1 if side < 0 else cx + bw // 2 - 1
            rect(d, px_, shoulder - 2, px_ + aw + 2, shoulder + 2, P["pads"])
    return outline(img)


ZP = {
    "normal": dict(S=24, hw=9, hh=8, bw=10, bh=8, ll=5, al=6, lw=3, aw=2, tears=2,
                   skin=C(112, 176, 96), skin_l=C(146, 206, 120), skin_d=C(74, 128, 72),
                   cloth=C(90, 96, 168), cloth_l=C(120, 126, 200), cloth_d=C(60, 64, 120), eye=C(250, 240, 90)),
    "fast": dict(S=24, hw=8, hh=8, bw=8, bh=8, ll=7, al=7, lw=2, aw=2, tears=1, hair=C(60, 40, 40),
                 skin=C(168, 190, 100), skin_l=C(200, 220, 130), skin_d=C(120, 140, 70),
                 cloth=C(176, 70, 60), cloth_l=C(214, 100, 80), cloth_d=C(120, 44, 44), eye=C(255, 60, 60)),
    "tank": dict(S=32, hw=12, hh=9, bw=18, bh=11, ll=6, al=8, lw=5, aw=4, tears=3, vest=C(120, 80, 48),
                 pads=C(110, 110, 124),
                 skin=C(78, 136, 84), skin_l=C(106, 164, 108), skin_d=C(52, 96, 62),
                 cloth=C(88, 62, 52), cloth_l=C(116, 86, 70), cloth_d=C(56, 38, 34), eye=C(255, 150, 40)),
    "boss": dict(S=48, hw=18, hh=14, bw=26, bh=16, ll=9, al=12, lw=7, aw=6, tears=4, horns=True,
                 pads=C(200, 170, 50), vest=C(100, 30, 60),
                 skin=C(140, 90, 150), skin_l=C(170, 120, 180), skin_d=C(96, 56, 110),
                 cloth=C(130, 40, 70), cloth_l=C(170, 64, 96), cloth_d=C(80, 24, 50), eye=C(255, 70, 50)),
}
for name, P in ZP.items():
    S = P["S"]
    sh = new(S * 4, S * 2)
    for row in range(2):
        for f in range(4):
            sh.paste(zombie_frame(S, P, row, f), (f * S, row * S))
    save(sh, f"zombie_{name}.png")


# ------------------------------------------------------------------ SpriteFrames .tres writer
def write_frames(name, png, fw, fh, anims):
    """anims: list of (anim_name, [(col,row)...], fps, loop)"""
    subs = []
    for an, cells, fps, loop in anims:
        for c in cells:
            if c not in subs: subs.append(c)
    lines = [f'[gd_resource type="SpriteFrames" load_steps={len(subs) + 2} format=3]', "",
             f'[ext_resource type="Texture2D" path="res://assets/sprites/{png}" id="1_tex"]', ""]
    for i, (cx, cy) in enumerate(subs):
        lines += [f'[sub_resource type="AtlasTexture" id="AtlasTexture_{i}"]', 'atlas = ExtResource("1_tex")',
                  f"region = Rect2({cx * fw}, {cy * fh}, {fw}, {fh})", ""]
    parts = []
    for an, cells, fps, loop in anims:
        fr = ", ".join('{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_%d")\n}' % subs.index(c) for c in cells)
        parts.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}' % (fr, "true" if loop else "false", an, fps))
    lines += ["[resource]", "animations = [" + ", ".join(parts) + "]", ""]
    with open(os.path.join(FRAMES, name + ".tres"), "w") as f:
        f.write("\n".join(lines))


write_frames("wizard_frames", "wizard.png", 24, 24, [
    ("idle", [(0, 0), (1, 0)], 2.5, True), ("cast", [(2, 0), (3, 0), (3, 0)], 14.0, False)])
write_frames("bolt_frames", "bolt.png", 16, 12, [("fly", [(0, 0), (1, 0)], 14.0, True)])
write_frames("impact_frames", "impact.png", 24, 24, [("hit", [(i, 0) for i in range(4)], 18.0, False)])
write_frames("coin_frames", "coin.png", 12, 12, [("spin", [(i, 0) for i in range(4)], 10.0, True)])
for name, P in ZP.items():
    write_frames(f"zombie_{name}_frames", f"zombie_{name}.png", P["S"], P["S"], [
        ("walk", [(i, 0) for i in range(4)], 8.0, True), ("attack", [(i, 1) for i in range(4)], 7.0, True)])
print("sprites + frames done")
