#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A")
    return alpha.point(lambda value: 255 if value > 18 else 0).getbbox()


def normalize(path: Path, *, output_size: int, fill: float) -> None:
    image = Image.open(path).convert("RGBA")
    bbox = alpha_bbox(image)
    if bbox is None:
        return

    content = image.crop(bbox)
    target = int(output_size * fill)
    scale = min(target / content.width, target / content.height)
    next_size = (
        max(1, round(content.width * scale)),
        max(1, round(content.height * scale)),
    )
    content = content.resize(next_size, Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (output_size, output_size), (0, 0, 0, 0))
    canvas.alpha_composite(
        content,
        ((output_size - content.width) // 2, (output_size - content.height) // 2),
    )
    canvas.save(path)


def main() -> None:
    parser = argparse.ArgumentParser(description="Upscale transparent PNG icon content within a square canvas.")
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument("--output-size", type=int, default=512)
    parser.add_argument("--fill", type=float, default=0.82)
    args = parser.parse_args()

    for path in args.paths:
        normalize(path, output_size=args.output_size, fill=args.fill)


if __name__ == "__main__":
    main()
