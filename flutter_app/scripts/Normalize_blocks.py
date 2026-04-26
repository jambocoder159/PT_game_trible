"""
貓咪特工 — 方塊素材標準化腳本
================================
解決 AI 生圖時方塊大小不一致的問題。

原理：
  1. 偵測每張圖的非透明內容邊界
  2. 裁切出實際方塊區域
  3. 統一縮放到相同尺寸（佔畫布 90%）
  4. 置中貼回目標尺寸畫布

用法：
  # 標準化所有方塊（1024→128）
  python normalize_blocks.py -i ./raw_blocks -o ./output/blocks

  # 自訂輸出尺寸
  python normalize_blocks.py -i ./raw_blocks -o ./output/blocks --size 128

  # 同時生成正常版 + 暗化版
  python normalize_blocks.py -i ./raw_blocks -o ./output/blocks --dark

  # 預覽單張（輸出 debug 圖）
  python normalize_blocks.py --preview ./raw_blocks/block_coral.png -o ./test
"""

import argparse
from pathlib import Path
from PIL import Image, ImageEnhance, ImageDraw
import numpy as np


def find_content_bbox(img: Image.Image, threshold: int = 10) -> tuple[int, int, int, int]:
    """找到非透明像素的邊界框 (left, top, right, bottom)"""
    alpha = np.array(img.split()[-1])
    rows = np.any(alpha > threshold, axis=1)
    cols = np.any(alpha > threshold, axis=0)

    if not rows.any() or not cols.any():
        return (0, 0, img.width, img.height)

    top, bottom = np.where(rows)[0][[0, -1]]
    left, right = np.where(cols)[0][[0, -1]]
    return (int(left), int(top), int(right) + 1, int(bottom) + 1)


def normalize_block(img: Image.Image, output_size: int = 128, fill_ratio: float = 0.90) -> Image.Image:
    """
    標準化單張方塊：
    1. 偵測內容邊界，裁切出方塊
    2. 等比縮放到 output_size × fill_ratio
    3. 置中貼回 output_size × output_size 畫布
    """
    # 偵測內容區域
    left, top, right, bottom = find_content_bbox(img)
    content = img.crop((left, top, right, bottom))
    content_w, content_h = content.size

    # 目標內容尺寸（佔畫布的 fill_ratio）
    target_inner = int(output_size * fill_ratio)

    # 等比縮放（取長邊 fit）
    scale = target_inner / max(content_w, content_h)
    new_w = int(content_w * scale)
    new_h = int(content_h * scale)
    content_resized = content.resize((new_w, new_h), Image.LANCZOS)

    # 建立透明畫布，置中貼上
    canvas = Image.new("RGBA", (output_size, output_size), (0, 0, 0, 0))
    offset_x = (output_size - new_w) // 2
    offset_y = (output_size - new_h) // 2
    canvas.paste(content_resized, (offset_x, offset_y), content_resized)

    return canvas


def make_dark_version(img: Image.Image, darken: float = 0.45, desat: float = 0.3) -> Image.Image:
    """
    生成暗化版方塊：
    - 降低亮度到 darken (0.45 = 原始的 45%)
    - 降低飽和度到 desat (0.3 = 原始的 30%)
    - 保留原始 alpha channel
    """
    # 保存 alpha
    r, g, b, a = img.split()
    rgb = Image.merge("RGB", (r, g, b))

    # 降低飽和度
    rgb = ImageEnhance.Color(rgb).enhance(desat)
    # 降低亮度
    rgb = ImageEnhance.Brightness(rgb).enhance(darken)

    # 合併回 RGBA
    r2, g2, b2 = rgb.split()
    return Image.merge("RGBA", (r2, g2, b2, a))


def process_all(input_dir: str, output_dir: str,
                output_size: int = 128, fill_ratio: float = 0.90,
                generate_dark: bool = False):
    """批量處理所有方塊"""
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # 掃描所有 block_*.png
    png_files = sorted(input_path.glob("block_*.png"))

    # 也掃描不帶前綴的（以防命名不同）
    if not png_files:
        png_files = sorted(input_path.glob("*.png"))

    if not png_files:
        print(f"⚠️  在 {input_dir} 找不到方塊圖片")
        return

    print(f"📂 輸入：{input_dir}")
    print(f"📂 輸出：{output_dir}")
    print(f"🧩 找到 {len(png_files)} 張方塊")
    print(f"📐 輸出尺寸：{output_size}×{output_size}，填充率 {fill_ratio:.0%}\n")

    # 先掃描所有圖片的內容大小，方便比較
    stats = []
    for png_file in png_files:
        img = Image.open(png_file).convert("RGBA")
        bbox = find_content_bbox(img)
        content_w = bbox[2] - bbox[0]
        content_h = bbox[3] - bbox[1]
        ratio = max(content_w, content_h) / max(img.width, img.height)
        stats.append((png_file, img.size, content_w, content_h, ratio))

    # 顯示統計
    ratios = [s[4] for s in stats]
    print(f"📊 內容佔比統計：")
    print(f"   最小：{min(ratios):.1%}  最大：{max(ratios):.1%}  差異：{max(ratios)-min(ratios):.1%}\n")

    success = 0
    for png_file, orig_size, cw, ch, ratio in stats:
        name = png_file.stem

        try:
            img = Image.open(png_file).convert("RGBA")

            # 標準化
            normalized = normalize_block(img, output_size, fill_ratio)
            out_path = output_path / f"{name}.png"
            normalized.save(out_path, "PNG", optimize=True)

            print(f"  ✅ {name}")
            print(f"     原始 {orig_size[0]}×{orig_size[1]}，內容佔 {ratio:.0%} → 統一 {output_size}×{output_size} @ {fill_ratio:.0%}")

            # 暗化版
            if generate_dark:
                dark = make_dark_version(normalized)
                dark_path = output_path / f"{name}_dark.png"
                dark.save(dark_path, "PNG", optimize=True)
                print(f"     暗化 → {dark_path}")

            success += 1

        except Exception as e:
            print(f"  ❌ {name} — 錯誤：{e}")

    print(f"\n🎉 完成！成功處理 {success}/{len(png_files)} 張方塊")


def preview_single(image_path: str, output_dir: str,
                   output_size: int = 128, fill_ratio: float = 0.90):
    """預覽單張方塊的標準化效果"""
    img = Image.open(image_path).convert("RGBA")
    name = Path(image_path).stem

    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # Debug 圖：標示內容邊界
    bbox = find_content_bbox(img)
    content_w = bbox[2] - bbox[0]
    content_h = bbox[3] - bbox[1]
    ratio = max(content_w, content_h) / max(img.width, img.height)

    debug = img.copy()
    draw = ImageDraw.Draw(debug)
    draw.rectangle(bbox, outline=(255, 0, 0, 200), width=3)
    debug.save(output_path / f"debug_{name}.png", "PNG")

    # 標準化
    normalized = normalize_block(img, output_size, fill_ratio)
    normalized.save(output_path / f"{name}.png", "PNG", optimize=True)

    # 暗化版
    dark = make_dark_version(normalized)
    dark.save(output_path / f"{name}_dark.png", "PNG", optimize=True)

    print(f"🔍 預覽模式 — {name}")
    print(f"   原始尺寸：{img.width}×{img.height}")
    print(f"   內容邊界：{bbox}（佔比 {ratio:.0%}）")
    print(f"   debug    → debug_{name}.png（紅框=偵測到的內容區域）")
    print(f"   標準化   → {name}.png ({output_size}×{output_size})")
    print(f"   暗化版   → {name}_dark.png")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="貓咪特工 — 方塊素材標準化")
    parser.add_argument("--input", "-i", default="./raw_blocks",
                        help="原始方塊圖片資料夾 (預設: ./raw_blocks)")
    parser.add_argument("--output", "-o", default="./output/blocks",
                        help="輸出資料夾 (預設: ./output/blocks)")
    parser.add_argument("--size", "-s", type=int, default=128,
                        help="輸出尺寸 (預設: 128)")
    parser.add_argument("--fill", "-f", type=float, default=0.90,
                        help="方塊填充率 0.0-1.0 (預設: 0.90)")
    parser.add_argument("--dark", action="store_true",
                        help="同時生成暗化版")
    parser.add_argument("--preview", "-p", default=None,
                        help="預覽模式：指定單張圖片路徑")

    args = parser.parse_args()

    if args.preview:
        preview_single(args.preview, args.output, args.size, args.fill)
    else:
        process_all(args.input, args.output, args.size, args.fill, args.dark)