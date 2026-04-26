
"""
貓咪特工 — Sprite Sheet 自動裁切腳本
=====================================
從一張包含多個圖示的 sprite sheet 中自動偵測並裁切出個別圖示。

支援兩種模式：
  1. grid 模式（推薦）：指定行列數，均分裁切
  2. auto 模式：自動偵測物件邊界，智慧分割

用法：
  # Grid 模式 — 已知排版為 2 行 3 列
  python slice_sprites.py -i sheet_a.png -o ./icons --grid 2x3 \
      --names icon_coin,icon_diamond,icon_energy,icon_chest_closed,icon_chest_open,icon_lock

  # Grid 模式 — 1 行 5 列
  python slice_sprites.py -i sheet_d.png -o ./icons --grid 1x5 \
      --names icon_attr_a,icon_attr_b,icon_attr_c,icon_attr_d,icon_attr_e

  # Auto 模式 — 自動偵測（適合不規則排版）
  python slice_sprites.py -i sheet.png -o ./icons --auto --names icon_a,icon_b,icon_c

  # 預覽模式 — 只畫出偵測框不裁切
  python slice_sprites.py -i sheet_a.png --grid 2x3 --preview

  # 自訂輸出尺寸 & 背景移除
  python slice_sprites.py -i sheet.png -o ./icons --grid 2x3 --size 64 --remove-bg
  python slice_sprites.py -i ./raw/Role_badge_icons_202603261620.jpeg -o ./icons --auto --size 64 --remove-bg
"""

import argparse
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
from typing import Optional


def remove_white_bg(img: Image.Image, tolerance: int = 30) -> Image.Image:
    """
    將白色 / 近白色背景轉為透明。
    tolerance: 0=只移除純白, 30=移除接近白色的像素
    """
    arr = np.array(img.convert("RGBA")).copy()
    # 計算每個像素與白色的距離
    white_dist = np.sqrt(
        (arr[:, :, 0].astype(float) - 255) ** 2 +
        (arr[:, :, 1].astype(float) - 255) ** 2 +
        (arr[:, :, 2].astype(float) - 255) ** 2
    )
    # 距離白色在 tolerance 內的像素設為透明
    mask = white_dist < (tolerance * 1.732)  # √3 ≈ 1.732, 因為 3 個 channel
    arr[mask, 3] = 0
    return Image.fromarray(arr)


def find_content_bbox(img: Image.Image, threshold: int = 10) -> tuple[int, int, int, int]:
    """找到非透明像素的邊界框"""
    alpha = np.array(img.split()[-1])
    rows = np.any(alpha > threshold, axis=1)
    cols = np.any(alpha > threshold, axis=0)

    if not rows.any() or not cols.any():
        return (0, 0, img.width, img.height)

    top, bottom = np.where(rows)[0][[0, -1]]
    left, right = np.where(cols)[0][[0, -1]]
    return (int(left), int(top), int(right) + 1, int(bottom) + 1)


# ── Grid 模式 ──────────────────────────────────────────

def slice_grid(img: Image.Image, rows: int, cols: int,
               output_size: int = 64, padding_pct: float = 0.05
               ) -> list[Image.Image]:
    """
    均分裁切：把圖片分成 rows × cols 格子，
    每格內偵測內容邊界，縮放到 output_size 並置中。
    """
    cell_w = img.width // cols
    cell_h = img.height // rows

    results = []
    for r in range(rows):
        for c in range(cols):
            # 裁切出這一格
            x1 = c * cell_w
            y1 = r * cell_h
            x2 = x1 + cell_w
            y2 = y1 + cell_h
            cell = img.crop((x1, y1, x2, y2))

            # 在格子內偵測實際內容
            bbox = find_content_bbox(cell)
            content = cell.crop(bbox)

            # 等比縮放置中到目標尺寸
            inner_size = int(output_size * (1 - padding_pct * 2))
            content.thumbnail((inner_size, inner_size), Image.LANCZOS)

            canvas = Image.new("RGBA", (output_size, output_size), (0, 0, 0, 0))
            ox = (output_size - content.width) // 2
            oy = (output_size - content.height) // 2
            canvas.paste(content, (ox, oy), content)

            results.append(canvas)

    return results


def get_grid_boxes(img: Image.Image, rows: int, cols: int
                   ) -> list[tuple[int, int, int, int]]:
    """取得 grid 模式每格的 bounding box（用於預覽）"""
    cell_w = img.width // cols
    cell_h = img.height // rows
    boxes = []
    for r in range(rows):
        for c in range(cols):
            boxes.append((c * cell_w, r * cell_h,
                          (c + 1) * cell_w, (r + 1) * cell_h))
    return boxes


# ── Auto 模式 ──────────────────────────────────────────

def detect_objects(img: Image.Image, min_size: int = 20, gap_threshold: int = 10
                   ) -> list[tuple[int, int, int, int]]:
    """
    自動偵測圖片中的多個獨立物件。
    用投影法找到水平和垂直方向的空白分隔帶，再組合出物件邊界。
    """
    alpha = np.array(img.split()[-1])

    # 垂直投影（每一列的非透明像素數）
    col_proj = np.sum(alpha > 10, axis=0)
    # 水平投影（每一行的非透明像素數）
    row_proj = np.sum(alpha > 10, axis=1)

    def find_segments(proj, gap_thresh):
        """在投影中找到連續非零段"""
        in_segment = False
        segments = []
        start = 0
        for i, val in enumerate(proj):
            if val > 0 and not in_segment:
                start = i
                in_segment = True
            elif val == 0 and in_segment:
                # 看是否只是小間隙
                if i + gap_thresh < len(proj) and np.any(proj[i:i + gap_thresh] > 0):
                    continue
                segments.append((start, i))
                in_segment = False
        if in_segment:
            segments.append((start, len(proj)))
        return segments

    col_segments = find_segments(col_proj, gap_threshold)
    row_segments = find_segments(row_proj, gap_threshold)

    # 組合成 bounding boxes
    boxes = []
    for rs, re in row_segments:
        for cs, ce in col_segments:
            # 確認這個區域確實有內容
            region_alpha = alpha[rs:re, cs:ce]
            if np.sum(region_alpha > 10) > min_size * min_size:
                boxes.append((cs, rs, ce, re))

    # 按位置排序（上到下，左到右）
    boxes.sort(key=lambda b: (b[1], b[0]))
    return boxes


def slice_auto(img: Image.Image, output_size: int = 64,
               padding_pct: float = 0.05) -> list[Image.Image]:
    """自動偵測物件並裁切"""
    boxes = detect_objects(img)

    results = []
    for (x1, y1, x2, y2) in boxes:
        content = img.crop((x1, y1, x2, y2))

        # 再精確裁切一次（去掉邊緣空白）
        inner_bbox = find_content_bbox(content)
        content = content.crop(inner_bbox)

        # 等比縮放置中
        inner_size = int(output_size * (1 - padding_pct * 2))
        content.thumbnail((inner_size, inner_size), Image.LANCZOS)

        canvas = Image.new("RGBA", (output_size, output_size), (0, 0, 0, 0))
        ox = (output_size - content.width) // 2
        oy = (output_size - content.height) // 2
        canvas.paste(content, (ox, oy), content)

        results.append(canvas)

    return results


# ── 預覽 ───────────────────────────────────────────────

def preview(img: Image.Image, output_path: Path,
            rows: Optional[int] = None, cols: Optional[int] = None):
    """畫出偵測框並儲存預覽圖"""
    debug = img.convert("RGBA").copy()
    draw = ImageDraw.Draw(debug)

    if rows and cols:
        boxes = get_grid_boxes(img, rows, cols)
        mode = f"grid {rows}×{cols}"
    else:
        boxes = detect_objects(img.convert("RGBA"))
        mode = f"auto ({len(boxes)} objects)"

    colors = [
        (255, 0, 0, 180), (0, 200, 0, 180), (0, 100, 255, 180),
        (255, 165, 0, 180), (200, 0, 200, 180), (0, 200, 200, 180),
    ]

    for i, box in enumerate(boxes):
        color = colors[i % len(colors)]
        draw.rectangle(box, outline=color, width=3)
        # 標號
        draw.text((box[0] + 5, box[1] + 5), str(i + 1), fill=color)

    output_path.mkdir(parents=True, exist_ok=True)
    preview_path = output_path / "preview_grid.png"
    debug.save(preview_path, "PNG")
    print(f"🔍 預覽模式 ({mode})")
    print(f"   偵測到 {len(boxes)} 個區域")
    print(f"   預覽圖 → {preview_path}")
    for i, box in enumerate(boxes):
        print(f"   [{i+1}] x:{box[0]}-{box[2]}, y:{box[1]}-{box[3]}, "
              f"size: {box[2]-box[0]}×{box[3]-box[1]}")


# ── 主流程 ─────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="貓咪特工 — Sprite Sheet 自動裁切",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
範例：
  # 2×3 grid 裁切，指定檔名
  python slice_sprites.py -i sheet_a.png -o ./icons --grid 2x3 \\
      --names icon_coin,icon_diamond,icon_energy,icon_chest_closed,icon_chest_open,icon_lock

  # 自動偵測物件
  python slice_sprites.py -i sheet.png -o ./icons --auto --names a,b,c

  # 預覽裁切框（不實際裁切）
  python slice_sprites.py -i sheet.png --grid 2x3 --preview
        """)
    parser.add_argument("-i", "--input", required=True,
                        help="輸入 sprite sheet 圖片路徑")
    parser.add_argument("-o", "--output", default="./output/icons",
                        help="輸出資料夾 (預設: ./output/icons)")
    parser.add_argument("--grid", default=None,
                        help="Grid 模式：指定 ROWSxCOLS (例: 2x3, 1x5)")
    parser.add_argument("--auto", action="store_true",
                        help="Auto 模式：自動偵測物件邊界")
    parser.add_argument("--names", default=None,
                        help="輸出檔名（逗號分隔，順序：左到右、上到下）")
    parser.add_argument("--size", type=int, default=64,
                        help="輸出每張圖的尺寸 (預設: 64)")
    parser.add_argument("--remove-bg", action="store_true",
                        help="移除白色背景轉為透明")
    parser.add_argument("--bg-tolerance", type=int, default=30,
                        help="白色背景移除容差 0-100 (預設: 30)")
    parser.add_argument("--preview", action="store_true",
                        help="預覽模式：只畫出偵測框，不實際裁切")

    args = parser.parse_args()

    # 讀取圖片
    img = Image.open(args.input).convert("RGBA")
    print(f"📂 輸入：{args.input} ({img.width}×{img.height})")

    # 去白背景
    if args.remove_bg:
        img = remove_white_bg(img, args.bg_tolerance)
        print(f"🎨 已移除白色背景 (容差: {args.bg_tolerance})")

    # 解析 grid
    grid_rows, grid_cols = None, None
    if args.grid:
        parts = args.grid.lower().split("x")
        grid_rows, grid_cols = int(parts[0]), int(parts[1])

    # 預覽模式
    if args.preview:
        output_path = Path(args.output)
        preview(img, output_path, grid_rows, grid_cols)
        return

    # 裁切
    if args.grid:
        print(f"✂️  Grid 模式：{grid_rows} 行 × {grid_cols} 列")
        results = slice_grid(img, grid_rows, grid_cols, args.size)
    elif args.auto:
        print(f"🔍 Auto 模式：偵測物件中...")
        results = slice_auto(img, args.size)
    else:
        print("⚠️  請指定 --grid 或 --auto 模式")
        return

    print(f"   裁切出 {len(results)} 張圖示\n")

    # 解析檔名
    if args.names:
        names = [n.strip() for n in args.names.split(",")]
        if len(names) < len(results):
            # 不足的用序號補
            names += [f"icon_{i+1}" for i in range(len(names), len(results))]
    else:
        names = [f"icon_{i+1}" for i in range(len(results))]

    # 儲存
    output_path = Path(args.output)
    output_path.mkdir(parents=True, exist_ok=True)

    for i, (icon, name) in enumerate(zip(results, names)):
        # 確保有 .png 副檔名
        if not name.endswith(".png"):
            name += ".png"
        out_file = output_path / name
        icon.save(out_file, "PNG", optimize=True)
        print(f"  ✅ [{i+1}] {name} ({args.size}×{args.size})")

    print(f"\n🎉 完成！{len(results)} 張圖示 → {output_path}/")


if __name__ == "__main__":
    main()