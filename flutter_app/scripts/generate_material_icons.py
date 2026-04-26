from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/images/output/materials"
SCALE = 4
SIZE = 256
W = SIZE * SCALE


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    hex_color = hex_color.lstrip("#")
    return (
        int(hex_color[0:2], 16),
        int(hex_color[2:4], 16),
        int(hex_color[4:6], 16),
        alpha,
    )


def sc(v: float) -> int:
    return int(round(v * SCALE))


def new_canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def soft_shadow(base: Image.Image, bbox: tuple[int, int, int, int], alpha: int = 60) -> None:
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    offset = sc(8)
    sd.ellipse(
        (bbox[0] + offset, bbox[1] + offset, bbox[2] + offset, bbox[3] + offset),
        fill=(84, 54, 42, alpha),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(sc(10)))
    base.alpha_composite(shadow)


def glow(base: Image.Image, color: str, radius: int = 70, alpha: int = 80) -> None:
    g = Image.new("RGBA", base.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(g)
    gd.ellipse(
        (sc(128 - radius), sc(128 - radius), sc(128 + radius), sc(128 + radius)),
        fill=rgba(color, alpha),
    )
    g = g.filter(ImageFilter.GaussianBlur(sc(22)))
    base.alpha_composite(g)


def downsave(img: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    img = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    img.save(OUT / name)


def draw_sparkles(d: ImageDraw.ImageDraw, color: str = "#FFF3A8") -> None:
    pts = [(54, 64, 7), (196, 74, 5), (62, 190, 5), (206, 188, 6), (156, 46, 4)]
    for x, y, r in pts:
        x, y, r = sc(x), sc(y), sc(r)
        d.line((x - r, y, x + r, y), fill=rgba(color, 190), width=sc(2))
        d.line((x, y - r, x, y + r), fill=rgba(color, 190), width=sc(2))


def polygon(cx: float, cy: float, points: list[tuple[float, float]]) -> list[tuple[int, int]]:
    return [(sc(cx + x), sc(cy + y)) for x, y in points]


def gem(img: Image.Image, d: ImageDraw.ImageDraw, fill: str, outline: str, rare: bool = False) -> None:
    glow(img, fill, 75, 90 if rare else 55)
    pts = polygon(128, 126, [(0, -78), (62, -26), (42, 58), (0, 90), (-42, 58), (-62, -26)])
    soft_shadow(img, (sc(66), sc(48), sc(190), sc(216)), 45)
    d.polygon(pts, fill=rgba(fill, 245), outline=rgba(outline, 235))
    d.polygon(polygon(128, 123, [(0, -62), (44, -20), (0, 5), (-44, -20)]), fill=rgba("#FFFFFF", 72))
    d.line((sc(128), sc(48), sc(128), sc(214)), fill=rgba("#FFFFFF", 75), width=sc(3))
    d.line((sc(66), sc(100), sc(190), sc(100)), fill=rgba("#FFFFFF", 65), width=sc(3))
    if rare:
        draw_sparkles(d)


def scroll(img: Image.Image, d: ImageDraw.ImageDraw) -> None:
    glow(img, "#FFD76A", 76, 64)
    soft_shadow(img, (sc(56), sc(48), sc(200), sc(208)), 48)
    d.rounded_rectangle((sc(58), sc(54), sc(198), sc(204)), radius=sc(22), fill=rgba("#F8E5B8"), outline=rgba("#B98238"), width=sc(5))
    d.ellipse((sc(46), sc(48), sc(84), sc(88)), fill=rgba("#E2B15F"), outline=rgba("#9A6628"), width=sc(4))
    d.ellipse((sc(172), sc(170), sc(210), sc(210)), fill=rgba("#E2B15F"), outline=rgba("#9A6628"), width=sc(4))
    for y in (94, 120, 146):
        d.rounded_rectangle((sc(88), sc(y), sc(170), sc(y + 8)), radius=sc(4), fill=rgba("#B98238", 155))


def gear_core(img: Image.Image, d: ImageDraw.ImageDraw) -> None:
    glow(img, "#89A6B8", 70, 70)
    soft_shadow(img, (sc(62), sc(62), sc(194), sc(194)), 42)
    cx = cy = sc(128)
    outer = sc(62)
    teeth = []
    for i in range(16):
        angle = math.tau * i / 16
        r = outer + (sc(14) if i % 2 == 0 else 0)
        teeth.append((cx + int(math.cos(angle) * r), cy + int(math.sin(angle) * r)))
    d.polygon(teeth, fill=rgba("#8EA2AD"), outline=rgba("#516976"), width=sc(4))
    d.ellipse((sc(84), sc(84), sc(172), sc(172)), fill=rgba("#F4C45F"), outline=rgba("#6B7680"), width=sc(5))
    d.ellipse((sc(108), sc(108), sc(148), sc(148)), fill=rgba("#FFF3C0"), outline=rgba("#9C7B2F"), width=sc(4))


def passive_gem(img: Image.Image, d: ImageDraw.ImageDraw) -> None:
    glow(img, "#79D6C9", 74, 80)
    soft_shadow(img, (sc(60), sc(54), sc(196), sc(210)), 42)
    pts = polygon(128, 128, [(0, -74), (58, -36), (58, 36), (0, 74), (-58, 36), (-58, -36)])
    d.polygon(pts, fill=rgba("#73D7C8"), outline=rgba("#2B8F88"), width=sc(5))
    d.polygon(polygon(128, 118, [(0, -42), (36, -18), (0, 4), (-36, -18)]), fill=rgba("#FFFFFF", 86))
    d.ellipse((sc(104), sc(104), sc(152), sc(152)), fill=rgba("#E9FFF9", 200))


def essence(img: Image.Image, d: ImageDraw.ImageDraw, fill: str, outline: str, kind: str) -> None:
    glow(img, fill, 80, 92)
    soft_shadow(img, (sc(72), sc(44), sc(184), sc(210)), 38)
    drop = polygon(128, 130, [(0, -82), (42, -26), (34, 36), (0, 78), (-34, 36), (-42, -26)])
    d.polygon(drop, fill=rgba(fill, 235), outline=rgba(outline), width=sc(5))
    d.ellipse((sc(100), sc(82), sc(126), sc(112)), fill=rgba("#FFFFFF", 92))
    if kind == "fire":
        d.polygon(polygon(128, 126, [(0, -44), (18, -6), (8, 36), (-14, 14)]), fill=rgba("#FFE68A", 220))
    elif kind == "leaf":
        d.arc((sc(96), sc(78), sc(168), sc(166)), 220, 45, fill=rgba("#F3FFE8", 210), width=sc(5))
        d.line((sc(122), sc(128), sc(154), sc(100)), fill=rgba("#F3FFE8", 210), width=sc(4))
    elif kind == "water":
        d.arc((sc(88), sc(130), sc(168), sc(186)), 0, 180, fill=rgba("#E8FFFF", 220), width=sc(5))
    elif kind == "bolt":
        d.polygon(polygon(128, 127, [(10, -46), (-14, 8), (6, 8), (-10, 48), (34, -12), (10, -12)]), fill=rgba("#FFF8AA", 230))
    elif kind == "moon":
        d.ellipse((sc(108), sc(88), sc(154), sc(140)), fill=rgba("#F9EAFB", 220))
        d.ellipse((sc(126), sc(80), sc(166), sc(132)), fill=rgba(fill, 235))


def potion(img: Image.Image, d: ImageDraw.ImageDraw) -> None:
    glow(img, "#58C7BB", 74, 70)
    soft_shadow(img, (sc(78), sc(48), sc(178), sc(210)), 42)
    d.rounded_rectangle((sc(106), sc(48), sc(150), sc(86)), radius=sc(8), fill=rgba("#D7F4F1"), outline=rgba("#4E8582"), width=sc(4))
    d.rounded_rectangle((sc(82), sc(78), sc(174), sc(204)), radius=sc(34), fill=rgba("#BFF4EE"), outline=rgba("#397E78"), width=sc(5))
    d.rectangle((sc(88), sc(134), sc(168), sc(196)), fill=rgba("#54C7B9", 215))
    d.ellipse((sc(104), sc(102), sc(126), sc(126)), fill=rgba("#FFFFFF", 92))


def ticket(img: Image.Image, d: ImageDraw.ImageDraw) -> None:
    glow(img, "#FFB860", 72, 70)
    soft_shadow(img, (sc(48), sc(76), sc(208), sc(180)), 44)
    d.rounded_rectangle((sc(48), sc(78), sc(208), sc(178)), radius=sc(18), fill=rgba("#FFD38A"), outline=rgba("#B46B31"), width=sc(5))
    d.ellipse((sc(36), sc(112), sc(68), sc(144)), fill=(0, 0, 0, 0), outline=rgba("#B46B31"), width=sc(4))
    d.ellipse((sc(188), sc(112), sc(220), sc(144)), fill=(0, 0, 0, 0), outline=rgba("#B46B31"), width=sc(4))
    d.line((sc(128), sc(90), sc(128), sc(166)), fill=rgba("#B46B31", 125), width=sc(3))
    d.polygon(polygon(92, 128, [(0, -20), (7, -6), (22, -3), (11, 8), (14, 22), (0, 14), (-14, 22), (-11, 8), (-22, -3), (-7, -6)]), fill=rgba("#FFF4C6", 230), outline=rgba("#D59A42"), width=sc(3))


def dust(img: Image.Image, d: ImageDraw.ImageDraw) -> None:
    glow(img, "#EDEBFF", 84, 95)
    for r, a in [(62, 50), (42, 90), (22, 160)]:
        d.ellipse((sc(128 - r), sc(128 - r), sc(128 + r), sc(128 + r)), fill=rgba("#D9D7FF", a))
    draw_sparkles(d, "#FFFFFF")
    d.polygon(polygon(128, 128, [(0, -54), (12, -12), (54, 0), (12, 12), (0, 54), (-12, 12), (-54, 0), (-12, -12)]), fill=rgba("#FFFFFF", 210), outline=rgba("#B9B2FF", 230), width=sc(4))


def category(img: Image.Image, d: ImageDraw.ImageDraw, fill: str, glyph: str) -> None:
    glow(img, fill, 76, 68)
    soft_shadow(img, (sc(50), sc(50), sc(206), sc(206)), 38)
    d.rounded_rectangle((sc(50), sc(50), sc(206), sc(206)), radius=sc(46), fill=rgba(fill, 225), outline=rgba("#7E6B58", 120), width=sc(5))
    if glyph == "all":
        for x, y in [(91, 91), (136, 91), (91, 136), (136, 136)]:
            d.rounded_rectangle((sc(x), sc(y), sc(x + 30), sc(y + 30)), radius=sc(7), fill=rgba("#FFF7DC", 230))
    elif glyph == "shard":
        gem(img, d, "#8BCBFF", "#3F86C8", False)
    elif glyph == "tool":
        d.line((sc(92), sc(164), sc(164), sc(92)), fill=rgba("#FFF4D2"), width=sc(16))
        d.ellipse((sc(142), sc(70), sc(184), sc(112)), fill=rgba("#E8EEF2"), outline=rgba("#6C7B84"), width=sc(4))
    elif glyph == "essence":
        essence(img, d, "#8FCEFF", "#287FB5", "water")
    elif glyph == "box":
        d.polygon(polygon(128, 106, [(0, -34), (58, 0), (0, 34), (-58, 0)]), fill=rgba("#FFE7A8"))
        d.polygon(polygon(99, 143, [(0, -34), (29, -17), (29, 48), (0, 66), (-29, 48), (-29, -17)]), fill=rgba("#D9A45B"))
        d.polygon(polygon(157, 143, [(0, -34), (29, -17), (29, 48), (0, 66), (-29, 48), (-29, -17)]), fill=rgba("#C88F47"))


def make(name: str, fn) -> None:
    img, d = new_canvas()
    fn(img, d)
    downsave(img, name)


def main() -> None:
    make("material_common_shard.png", lambda i, d: gem(i, d, "#8CCBFF", "#3F86C8"))
    make("material_advanced_shard.png", lambda i, d: gem(i, d, "#4FAAFF", "#236DAE", True))
    make("material_rare_shard.png", lambda i, d: gem(i, d, "#C077FF", "#8242B6", True))
    make("material_talent_scroll.png", scroll)
    make("material_skill_core.png", gear_core)
    make("material_passive_gem.png", passive_gem)
    make("material_essence_a.png", lambda i, d: essence(i, d, "#FF705F", "#B64238", "fire"))
    make("material_essence_b.png", lambda i, d: essence(i, d, "#6ECF73", "#2E8540", "leaf"))
    make("material_essence_c.png", lambda i, d: essence(i, d, "#58B8FF", "#2778B8", "water"))
    make("material_essence_d.png", lambda i, d: essence(i, d, "#FFD95A", "#B78725", "bolt"))
    make("material_essence_e.png", lambda i, d: essence(i, d, "#A76BDB", "#663AA2", "moon"))
    make("material_exp_potion.png", potion)
    make("material_sweep_ticket.png", ticket)
    make("material_crystal_dust.png", dust)
    make("category_all.png", lambda i, d: category(i, d, "#F4B46E", "all"))
    make("category_shard.png", lambda i, d: category(i, d, "#86C8F6", "shard"))
    make("category_functional.png", lambda i, d: category(i, d, "#F2C46E", "tool"))
    make("category_essence.png", lambda i, d: category(i, d, "#87D5C9", "essence"))
    make("category_universal.png", lambda i, d: category(i, d, "#C8A0F4", "box"))


if __name__ == "__main__":
    main()
