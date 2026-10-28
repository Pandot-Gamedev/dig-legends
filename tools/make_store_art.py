"""Draws the Roblox store art for Dig Legends into store/:
game icon, thumbnails, game pass icons and developer product icons.

Usage: python3 tools/make_store_art.py
"""

import math
import os
import random

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "store")
FONT_BOLD = "/usr/share/fonts/opentype/inter/InterDisplay-ExtraBold.otf"
FONT_SEMI = "/usr/share/fonts/opentype/inter/Inter-SemiBold.otf"

RARITY = {
    "Common": (200, 200, 200),
    "Uncommon": (90, 200, 90),
    "Rare": (70, 140, 255),
    "Epic": (170, 80, 255),
    "Legendary": (255, 170, 0),
}
GOLD = (255, 200, 40)
NAVY = (20, 32, 52)
DIRT = [(150, 105, 65), (125, 85, 50), (100, 68, 40), (78, 52, 32)]


def font(path, size):
    return ImageFont.truetype(path, size)


def gradient(size, top, bottom):
    w, h = size
    img = Image.new("RGB", size, top)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(1, h - 1)
        color = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        draw.line([(0, y), (w, y)], fill=color)
    return img


def shade(color, amount):
    return tuple(max(0, min(255, c + amount)) for c in color)


def star(d, x, y, r, color):
    pts = []
    for i in range(8):
        rr = r if i % 2 == 0 else r * 0.35
        a = math.pi / 4 * i
        pts.append((x + math.cos(a) * rr, y + math.sin(a) * rr))
    d.polygon(pts, fill=color)


def paste_center(base, layer, cx, cy):
    base.alpha_composite(layer, (int(cx - layer.width / 2), int(cy - layer.height / 2)))


def outlined_text(draw, xy, text, fnt, fill, outline=(40, 22, 10), width=6, anchor="mm"):
    draw.text(xy, text, font=fnt, fill=fill, anchor=anchor, stroke_width=width, stroke_fill=outline)


def layer(size):
    return Image.new("RGBA", (int(size), int(size)), (0, 0, 0, 0))


def gem(size, color, angle=0, shiny=False):
    """A cut gem seen from the front."""
    img = layer(size)
    d = ImageDraw.Draw(img)
    s = size
    top, mid, bottom = s * 0.22, s * 0.42, s * 0.88
    left, right = s * 0.12, s * 0.88
    outline = shade(color, -90)
    d.polygon([(s * 0.3, top), (s * 0.7, top), (right, mid), (s / 2, bottom), (left, mid)], fill=color, outline=outline, width=max(2, int(s * 0.02)))
    d.polygon([(s * 0.3, top), (s * 0.7, top), (s * 0.6, mid), (s * 0.4, mid)], fill=shade(color, 70))
    d.polygon([(left, mid), (s * 0.4, mid), (s / 2, bottom)], fill=shade(color, -35))
    d.polygon([(right, mid), (s * 0.6, mid), (s / 2, bottom)], fill=shade(color, 25))
    d.line([(left, mid), (right, mid)], fill=outline, width=max(2, int(s * 0.015)))
    d.polygon([(s * 0.36, top + s * 0.04), (s * 0.46, top + s * 0.04), (s * 0.4, mid - s * 0.04)], fill=(255, 255, 255, 200))
    if shiny:
        for _ in range(6):
            star(d, random.uniform(s * 0.1, s * 0.9), random.uniform(s * 0.1, s * 0.9), s * 0.06, (255, 250, 210))
    return img.rotate(angle, resample=Image.BICUBIC, expand=True)


def bone(size, angle=0, color=(240, 230, 205)):
    """A cartoon fossil bone."""
    img = layer(size)
    d = ImageDraw.Draw(img)
    s = size
    outline = shade(color, -110)
    r = s * 0.12
    d.rounded_rectangle([s * 0.2, s * 0.44, s * 0.8, s * 0.56], radius=int(s * 0.05), fill=color, outline=outline, width=max(2, int(s * 0.015)))
    for x in (s * 0.2, s * 0.8):
        for y in (s * 0.4, s * 0.6):
            d.ellipse([x - r, y - r, x + r, y + r], fill=color, outline=outline, width=max(2, int(s * 0.015)))
    d.rectangle([s * 0.21, s * 0.45, s * 0.79, s * 0.55], fill=color)
    return img.rotate(angle, resample=Image.BICUBIC, expand=True)


def coin(size, color=GOLD):
    img = layer(size)
    d = ImageDraw.Draw(img)
    s = size
    outline = shade(color, -110)
    d.ellipse([s * 0.1, s * 0.1, s * 0.9, s * 0.9], fill=color, outline=outline, width=max(3, int(s * 0.05)))
    d.ellipse([s * 0.24, s * 0.24, s * 0.76, s * 0.76], outline=shade(color, -50), width=max(2, int(s * 0.03)))
    star(d, s / 2, s / 2, s * 0.17, shade(color, 60))
    return img


def chest(size, open_lid=False, glow=True):
    """A treasure chest, optionally open and spilling light."""
    img = layer(size)
    d = ImageDraw.Draw(img)
    s = size
    wood, dark = (150, 90, 45), (90, 50, 25)
    if glow:
        for i in range(8, 0, -1):
            r = s * 0.06 * i
            alpha = int(18 + 6 * (8 - i))
            d.ellipse([s / 2 - r, s * 0.45 - r * 0.8, s / 2 + r, s * 0.45 + r * 0.8], fill=(255, 220, 90, alpha))
    d.rounded_rectangle([s * 0.18, s * 0.48, s * 0.82, s * 0.82], radius=int(s * 0.03), fill=wood, outline=dark, width=max(3, int(s * 0.02)))
    if open_lid:
        d.polygon([(s * 0.18, s * 0.48), (s * 0.82, s * 0.48), (s * 0.76, s * 0.22), (s * 0.24, s * 0.22)], fill=shade(wood, 20), outline=dark, width=max(3, int(s * 0.02)))
        d.ellipse([s * 0.22, s * 0.42, s * 0.78, s * 0.56], fill=GOLD)
        for i in range(5):
            x = s * (0.3 + i * 0.1)
            d.ellipse([x - s * 0.05, s * 0.4, x + s * 0.05, s * 0.48], fill=shade(GOLD, 30), outline=(170, 120, 0), width=2)
    else:
        d.rounded_rectangle([s * 0.16, s * 0.32, s * 0.84, s * 0.5], radius=int(s * 0.08), fill=shade(wood, 20), outline=dark, width=max(3, int(s * 0.02)))
    for x in (0.3, 0.7):
        d.rectangle([s * (x - 0.03), s * (0.32 if not open_lid else 0.48), s * (x + 0.03), s * 0.82], fill=GOLD, outline=(160, 110, 0), width=2)
    d.rounded_rectangle([s * 0.45, s * 0.5, s * 0.55, s * 0.62], radius=int(s * 0.02), fill=GOLD, outline=(160, 110, 0), width=2)
    return img


def shovel(size, blade=(200, 205, 215), handle=(130, 90, 55), angle=-35, sparkle=False):
    """A shovel, blade down, leaning by angle degrees."""
    img = layer(size)
    d = ImageDraw.Draw(img)
    s = size
    d.rounded_rectangle([s * 0.47, s * 0.08, s * 0.53, s * 0.62], radius=int(s * 0.02), fill=handle, outline=shade(handle, -60), width=max(2, int(s * 0.01)))
    d.rounded_rectangle([s * 0.38, s * 0.05, s * 0.62, s * 0.12], radius=int(s * 0.03), fill=handle, outline=shade(handle, -60), width=max(2, int(s * 0.01)))
    d.polygon([(s * 0.36, s * 0.6), (s * 0.64, s * 0.6), (s * 0.62, s * 0.84), (s / 2, s * 0.95), (s * 0.38, s * 0.84)], fill=blade, outline=shade(blade, -90), width=max(3, int(s * 0.015)))
    d.polygon([(s * 0.4, s * 0.63), (s * 0.46, s * 0.63), (s * 0.44, s * 0.82)], fill=shade(blade, 60))
    if sparkle:
        for _ in range(7):
            star(d, random.uniform(s * 0.2, s * 0.8), random.uniform(s * 0.1, s * 0.9), s * 0.045, (255, 250, 210))
    return img.rotate(angle, resample=Image.BICUBIC, expand=True)


def digger(d, x, ground, h, shirt=(220, 70, 60)):
    """A simple blocky avatar standing on the ground at x."""
    u = h / 6
    skin, pants = (255, 205, 150), (50, 80, 160)
    d.rectangle([x - u * 0.45, ground - u * 2, x - u * 0.05, ground], fill=pants)
    d.rectangle([x + u * 0.05, ground - u * 2, x + u * 0.45, ground], fill=pants)
    d.rectangle([x - u * 0.5, ground - u * 4, x + u * 0.5, ground - u * 2], fill=shirt)
    d.rectangle([x - u * 0.95, ground - u * 4, x - u * 0.55, ground - u * 2.2], fill=skin)
    d.rectangle([x + u * 0.55, ground - u * 4, x + u * 0.95, ground - u * 2.2], fill=skin)
    d.rounded_rectangle([x - u * 0.45, ground - u * 5, x + u * 0.45, ground - u * 4.05], radius=int(u * 0.15), fill=skin)
    d.ellipse([x - u * 0.2, ground - u * 4.65, x - u * 0.08, ground - u * 4.5], fill=(30, 30, 30))
    d.ellipse([x + u * 0.08, ground - u * 4.65, x + u * 0.2, ground - u * 4.5], fill=(30, 30, 30))
    d.rectangle([x - u * 0.6, ground - u * 5.15, x + u * 0.6, ground - u * 4.95], fill=(230, 180, 60))
    d.rounded_rectangle([x - u * 0.4, ground - u * 5.6, x + u * 0.4, ground - u * 5.0], radius=int(u * 0.2), fill=(230, 180, 60))


def scene(size, title=True, tagline=None):
    """A sunny dig site cut open to show treasures buried in the layers."""
    w, h = size
    img = gradient(size, (120, 200, 255), (200, 235, 255)).convert("RGBA")
    d = ImageDraw.Draw(img)
    ground = int(h * 0.48)
    # sun, hills and clouds
    d.ellipse([w * 0.8, h * 0.06, w * 0.8 + h * 0.16, h * 0.22], fill=(255, 240, 150))
    d.ellipse([-w * 0.1, ground - h * 0.12, w * 0.45, ground + h * 0.1], fill=(120, 190, 100))
    d.ellipse([w * 0.5, ground - h * 0.09, w * 1.15, ground + h * 0.1], fill=(110, 180, 95))
    for cx, cy, r in ((0.15, 0.12, 0.05), (0.62, 0.08, 0.04)):
        for dx in (-1, 0, 1):
            d.ellipse([w * cx + dx * h * r - h * r, h * cy - h * r * 0.7, w * cx + dx * h * r + h * r, h * cy + h * r * 0.7], fill=(255, 255, 255))
    # dirt layers
    layer_h = (h - ground) / len(DIRT)
    for i, color in enumerate(DIRT):
        y0 = ground + i * layer_h
        pts = [(0, y0)] + [(x, y0 + math.sin(x / (w * 0.05) + i) * h * 0.008) for x in range(0, w + 20, 20)] + [(w, h), (0, h)]
        d.polygon(pts, fill=color)
        for _ in range(int(w / 25)):
            x, y = random.uniform(0, w), random.uniform(y0 + 8, y0 + layer_h)
            r = random.uniform(h * 0.003, h * 0.008)
            d.ellipse([x - r, y - r, x + r, y + r], fill=shade(color, -25))
    d.rectangle([0, ground - h * 0.012, w, ground + h * 0.012], fill=(100, 175, 75))
    # the hole the digger is working on
    hx = w * 0.3
    d.ellipse([hx - w * 0.09, ground - h * 0.02, hx + w * 0.09, ground + h * 0.05], fill=(60, 40, 25))
    d.ellipse([hx - w * 0.075, ground - h * 0.01, hx + w * 0.075, ground + h * 0.17], fill=(70, 45, 28))
    # buried treasures
    paste_center(img, chest(h * 0.34, open_lid=True), w * 0.62, ground + h * 0.24)
    paste_center(img, gem(h * 0.16, RARITY["Epic"], angle=15, shiny=True), w * 0.85, ground + h * 0.15)
    paste_center(img, bone(h * 0.22, angle=25), w * 0.12, ground + h * 0.3)
    paste_center(img, gem(h * 0.12, RARITY["Rare"], angle=-20), w * 0.4, ground + h * 0.38)
    paste_center(img, coin(h * 0.09), w * 0.3, ground + h * 0.26)
    paste_center(img, coin(h * 0.07), w * 0.92, ground + h * 0.4)
    paste_center(img, bone(h * 0.14, angle=-40, color=(225, 215, 190)), w * 0.78, ground + h * 0.43)
    d = ImageDraw.Draw(img)
    # the digger, a dirt pile and a shovel
    d.ellipse([hx + w * 0.07, ground - h * 0.05, hx + w * 0.2, ground + h * 0.02], fill=(130, 90, 55))
    digger(d, hx - w * 0.12, ground, h * 0.3)
    paste_center(img, shovel(h * 0.3, angle=-25), hx - w * 0.06, ground - h * 0.1)
    d = ImageDraw.Draw(img)
    for _ in range(10):
        star(d, random.uniform(w * 0.5, w * 0.74), random.uniform(ground - h * 0.04, ground + h * 0.12), h * 0.015, (255, 250, 200))
    if title:
        outlined_text(d, (w * 0.5, h * 0.17), "DIG LEGENDS", font(FONT_BOLD, int(h * 0.15)), (255, 215, 90), width=max(4, int(h * 0.012)))
    if tagline:
        d.rounded_rectangle([w * 0.08, h * 0.86, w * 0.92, h * 0.95], radius=int(h * 0.03), fill=(30, 20, 12, 200))
        outlined_text(d, (w * 0.5, h * 0.905), tagline, font(FONT_SEMI, int(h * 0.045)), (255, 255, 255), width=max(2, int(h * 0.004)))
    return img


def icon_art(s):
    """The square game icon: a glowing open chest dug up, with the title."""
    img = gradient((s, s), (110, 195, 255), (190, 230, 255)).convert("RGBA")
    d = ImageDraw.Draw(img)
    ground = int(s * 0.42)
    layer_h = (s - ground) / len(DIRT)
    for i, color in enumerate(DIRT):
        y0 = ground + i * layer_h
        pts = [(0, y0)] + [(x, y0 + math.sin(x / (s * 0.06) + i) * s * 0.01) for x in range(0, s + 20, 20)] + [(s, s), (0, s)]
        d.polygon(pts, fill=color)
        for _ in range(40):
            x, y = random.uniform(0, s), random.uniform(y0 + 8, y0 + layer_h)
            r = random.uniform(s * 0.004, s * 0.01)
            d.ellipse([x - r, y - r, x + r, y + r], fill=shade(color, -25))
    d.rectangle([0, ground - s * 0.015, s, ground + s * 0.015], fill=(100, 175, 75))
    paste_center(img, chest(s * 0.62, open_lid=True), s * 0.5, s * 0.66)
    paste_center(img, gem(s * 0.22, RARITY["Epic"], angle=18, shiny=True), s * 0.16, s * 0.74)
    paste_center(img, gem(s * 0.16, RARITY["Rare"], angle=-15), s * 0.86, s * 0.86)
    paste_center(img, bone(s * 0.26, angle=-30), s * 0.85, s * 0.6)
    paste_center(img, coin(s * 0.1), s * 0.22, s * 0.92)
    paste_center(img, shovel(s * 0.42, angle=-20), s * 0.82, s * 0.36)
    d = ImageDraw.Draw(img)
    for _ in range(12):
        star(d, random.uniform(s * 0.3, s * 0.7), random.uniform(s * 0.4, s * 0.58), s * 0.018, (255, 250, 200))
    outlined_text(d, (s * 0.5, s * 0.14), "DIG", font(FONT_BOLD, int(s * 0.23)), (255, 215, 90), width=14)
    outlined_text(d, (s * 0.5, s * 0.31), "LEGENDS", font(FONT_BOLD, int(s * 0.15)), (255, 255, 255), width=12)
    return img


def save(img, name, size=None):
    os.makedirs(OUT, exist_ok=True)
    if size:
        img = img.resize(size, Image.LANCZOS)
    img.convert("RGB").save(os.path.join(OUT, name), quality=95)
    print("wrote store/" + name)


def badge(bg_top, bg_bottom, draw_fn, label):
    """512x512 square icon with a rounded tile, a picture and a label."""
    s = 1024
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    tile = gradient((s, s), bg_top, bg_bottom).convert("RGBA")
    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, s, s], radius=180, fill=255)
    img.paste(tile, (0, 0), mask)
    d = ImageDraw.Draw(img)
    draw_fn(img, d, s)
    if label:
        d = ImageDraw.Draw(img)
        size = 120 if len(label) <= 9 else 96
        outlined_text(d, (s / 2, s * 0.86), label, font(FONT_BOLD, size), (255, 255, 255), outline=(20, 20, 30), width=10)
    return img


def crown(img, d, s):
    cx, cy, r = s / 2, s * 0.42, s * 0.3
    pts = [(cx - r, cy + r * 0.5), (cx - r, cy - r * 0.4), (cx - r * 0.5, cy), (cx, cy - r * 0.7), (cx + r * 0.5, cy), (cx + r, cy - r * 0.4), (cx + r, cy + r * 0.5)]
    d.polygon(pts, fill=GOLD, outline=(150, 100, 0), width=12)
    d.rectangle([cx - r, cy + r * 0.45, cx + r, cy + r * 0.7], fill=(230, 170, 20))
    for x in (cx - r * 0.5, cx, cx + r * 0.5):
        d.ellipse([x - 28, cy + r * 0.12, x + 28, cy + r * 0.12 + 56], fill=(220, 40, 90))


def coins_arrow(img, d, s):
    for x, y in [(0.38, 0.5), (0.5, 0.4), (0.62, 0.5)]:
        paste_center(img, coin(s * 0.3), s * x, s * y)
    d = ImageDraw.Draw(img)
    d.arc([s * 0.18, s * 0.16, s * 0.82, s * 0.76], 200, 340, fill=(255, 255, 255), width=26)
    d.polygon([(s * 0.8, s * 0.34), (s * 0.86, s * 0.22), (s * 0.7, s * 0.25)], fill=(255, 255, 255))


def big_bag(img, d, s):
    cx = s / 2
    for i, color in enumerate([RARITY["Rare"], RARITY["Epic"], RARITY["Legendary"]]):
        paste_center(img, gem(s * 0.22, color, angle=20 - i * 20), cx - s * 0.13 + i * s * 0.13, s * 0.27)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([cx - s * 0.27, s * 0.3, cx + s * 0.27, s * 0.7], radius=70, fill=(150, 100, 60), outline=(90, 55, 30), width=14)
    d.arc([cx - s * 0.15, s * 0.14, cx + s * 0.15, s * 0.4], 180, 360, fill=(90, 55, 30), width=22)
    outlined_text(d, (cx, s * 0.52), "60", font(FONT_BOLD, 170), (255, 255, 255), outline=(90, 55, 30), width=8)


def portal(img, d, s):
    cx, cy = s / 2, s * 0.43
    for i in range(10, 0, -1):
        r = s * 0.032 * i
        color = (int(80 + 15 * i), int(40 + 10 * i), 255)
        d.ellipse([cx - r, cy - r * 1.15, cx + r, cy + r * 1.15], outline=color, width=18)
    star(d, cx, cy, s * 0.08, (255, 255, 255))


def shovel_icon(color):
    def draw(img, d, s):
        paste_center(img, shovel(s * 0.78, blade=color, handle=shade(color, -70), angle=-35, sparkle=True), s / 2, s * 0.42)
    return draw


def trail_icon(colors):
    def draw(img, d, s):
        for i, color in enumerate(colors):
            y = s * 0.26 + i * (s * 0.36 / max(1, len(colors) - 1))
            pts = [(x, y + math.sin(x / 90) * 40) for x in range(int(s * 0.1), int(s * 0.9), 10)]
            d.line(pts, fill=color, width=46)
        for _ in range(8):
            star(d, random.uniform(s * 0.12, s * 0.88), random.uniform(s * 0.18, s * 0.66), 24, (255, 250, 210))
    return draw


def title_icon(text, color):
    def draw(img, d, s):
        d.rounded_rectangle([s * 0.06, s * 0.3, s * 0.94, s * 0.6], radius=60, fill=NAVY, outline=color, width=16)
        size = 150 if len(text) < 10 else 104
        outlined_text(d, (s / 2, s * 0.45), text, font(FONT_BOLD, size), color, outline=(10, 15, 25), width=6)
    return draw


def main():
    random.seed(11)

    # Game icon: the open chest up close with the title
    save(icon_art(1024), "game_icon_512.png", (512, 512))

    save(scene((1920, 1080), tagline="Dig up 65 treasures  -  5 zones  -  Treasure Rush with friends"), "thumbnail_1_1920x1080.png")

    # Thumbnail 2: feature cards
    t2 = gradient((1920, 1080), (120, 80, 45), (60, 38, 20)).convert("RGBA")
    d = ImageDraw.Draw(t2)
    outlined_text(d, (960, 120), "DIG LEGENDS", font(FONT_BOLD, 130), (255, 215, 90), width=10)
    cards = [
        ("DIG IT OUT", "Tap in the green to dig deeper", RARITY["Rare"]),
        ("COLLECT THEM ALL", "65 finds, 5 rarities, shiny versions", RARITY["Epic"]),
        ("TREASURE RUSH", "Dig together, everyone gets loot", RARITY["Legendary"]),
    ]
    pictures = [
        lambda: shovel(420, angle=-30, sparkle=True),
        lambda: gem(360, RARITY["Epic"], angle=10, shiny=True),
        lambda: chest(440, open_lid=True),
    ]
    for i, (head, sub, color) in enumerate(cards):
        x0 = 90 + i * 600
        d.rounded_rectangle([x0, 260, x0 + 540, 980], radius=40, fill=(35, 24, 14), outline=color, width=10)
        paste_center(t2, pictures[i](), x0 + 270, 520)
        d = ImageDraw.Draw(t2)
        outlined_text(d, (x0 + 270, 800), head, font(FONT_BOLD, 46), (255, 255, 255), width=4)
        d.text((x0 + 270, 880), sub, font=font(FONT_SEMI, 30), fill=(235, 215, 190), anchor="mm")
    save(t2, "thumbnail_2_1920x1080.png")

    passes = [
        ("pass_vip.png", (255, 210, 80), (200, 120, 20), crown, "VIP"),
        ("pass_auto_sell.png", (90, 210, 120), (30, 120, 70), coins_arrow, "AUTO SELL"),
        ("pass_big_bag.png", (110, 170, 240), (40, 80, 160), big_bag, "BIG BACKPACK"),
        ("pass_teleporter.png", (170, 110, 255), (70, 30, 150), portal, "TELEPORT"),
    ]
    for name, top, bottom, fn, label in passes:
        save(badge(top, bottom, fn, label), name, (512, 512))

    products = [
        ("product_skin_golden.png", shovel_icon((255, 200, 40)), "GOLDEN"),
        ("product_skin_neon.png", shovel_icon((255, 60, 200)), "NEON PINK"),
        ("product_skin_galaxy.png", shovel_icon((130, 80, 255)), "GALAXY"),
        ("product_skin_candy.png", shovel_icon((255, 120, 150)), "CANDY"),
        ("product_trail_sparkle.png", trail_icon([(0, 170, 255), (0, 255, 200)]), "SPARKLE"),
        ("product_trail_fire.png", trail_icon([(255, 220, 0), (255, 120, 0), (255, 40, 0)]), "FIRE"),
        ("product_trail_rainbow.png", trail_icon([(255, 0, 0), (255, 200, 0), (0, 220, 0), (0, 120, 255), (200, 0, 255)]), "RAINBOW"),
        ("product_title_lucky.png", title_icon("Lucky Digger", (120, 200, 255)), "TITLE"),
        ("product_title_whisperer.png", title_icon("Rock Whisperer", (160, 255, 160)), "TITLE"),
        ("product_title_diglegend.png", title_icon("Dig Legend", (255, 190, 60)), "TITLE"),
    ]
    for name, fn, label in products:
        save(badge((120, 90, 60), (50, 34, 20), fn, label), name, (512, 512))


if __name__ == "__main__":
    main()
