"""
貓咪特工 — Sprite Sheet 清理 & 標準化腳本
==========================================
處理 AI 生成的 JPEG sprite sheet 的兩大問題：
  1. JPEG 沒有透明度 → 偵測棋盤格/白色/灰色背景並轉為透明
  2. 各幀大小不一 → 統一每幀尺寸並等距排列

支援兩種輸出模式：
  - sprite sheet（預設）：輸出一整條水平排列的 PNG（Flutter 直接用）
  - individual：輸出個別幀 PNG

用法：
  # 清理 + 標準化 sprite sheet（4 幀水平排列）
  python clean_spritesheet.py -i vfx_skill_c.jpg -o ./output/vfx --frames 4 --name vfx_skill_c

  # 指定每幀輸出尺寸
  python clean_spritesheet.py -i vfx_skill_c.jpg -o ./output/vfx --frames 4 --size 128 --name vfx_skill_c

  # 輸出個別幀（不合併）
  python clean_spritesheet.py -i vfx_skill_c.jpg -o ./output/vfx --frames 4 --individual --name vfx_skill_c

  # 批量處理資料夾內所有 sprite sheet
  python clean_spritesheet.py -i ./raw_vfx/ -o ./output/vfx --frames 4

  # 預覽偵測結果
  python clean_spritesheet.py -i vfx_skill_c.jpg --frames 4 --preview

  # 處理數字 sprite sheet（2 行排列）
  python clean_spritesheet.py -i damage_numbers.jpg -o ./output/vfx --grid 2x5 --size 48 --name font_damage
"""

import argparse
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
from typing import Optional


# ── 背景移除 ───────────────────────────────────────────

# 預設背景色對照表
BG_PRESETS = {
    "green":   (0, 255, 0),      # 綠幕 #00FF00
    "magenta": (255, 0, 255),    # 洋紅 #FF00FF
    "black":   (0, 0, 0),        # 黑底
    "white":   (255, 255, 255),  # 白底
    "blue":    (0, 0, 255),      # 藍幕
    "auto":    None,             # 自動偵測
}


def remove_keyed_bg(img: Image.Image, key_color: tuple[int, int, int],
                    tolerance: int = 50, edge_feather: bool = True) -> Image.Image:
    """
    移除指定色背景（色鍵去背，類似影片綠幕）。
    key_color: (R, G, B) 要移除的背景色
    tolerance: 容差，越大移除範圍越廣
    edge_feather: 是否柔化邊緣
    """
    arr = np.array(img.convert("RGB")).astype(float)
    h, w, _ = arr.shape
    kr, kg, kb = float(key_color[0]), float(key_color[1]), float(key_color[2])

    # 計算每個像素與 key_color 的歐幾里得距離
    dist = np.sqrt(
        (arr[:, :, 0] - kr) ** 2 +
        (arr[:, :, 1] - kg) ** 2 +
        (arr[:, :, 2] - kb) ** 2
    )

    # 距離 → alpha（近=透明，遠=不透明）
    # 使用漸變邊緣而非硬切，讓發光特效的半透明邊緣更自然
    max_dist = tolerance * 1.732  # √3，三通道最大距離

    if edge_feather:
        # 漸變：距離 0~max_dist 對應 alpha 0~255
        alpha = np.clip((dist - max_dist * 0.6) / (max_dist * 0.4) * 255, 0, 255)
    else:
        # 硬切
        alpha = np.where(dist < max_dist, 0, 255)

    alpha = alpha.astype(np.uint8)

    # 特殊處理：黑底去背時保留發光漸層
    if key_color == (0, 0, 0):
        # 黑底模式：用亮度作為 alpha（越亮越不透明）
        brightness = np.max(arr, axis=2)  # 取 RGB 最大值而非平均，保留彩色
        alpha_bright = np.clip(brightness * 1.5, 0, 255).astype(np.uint8)
        # 跟距離法取較大值（兼顧純色區域和漸變區域）
        alpha = np.maximum(alpha, alpha_bright)

    rgba = np.dstack([arr.astype(np.uint8), alpha])
    return Image.fromarray(rgba, "RGBA")


def remove_checker_bg(img: Image.Image, tolerance: int = 35) -> Image.Image:
    """
    移除 JPEG 中的棋盤格透明背景模擬。
    """
    arr = np.array(img.convert("RGB")).astype(float)
    h, w, _ = arr.shape
    alpha = np.full((h, w), 255, dtype=np.uint8)

    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    max_rgb = np.maximum(np.maximum(r, g), b)
    min_rgb = np.minimum(np.minimum(r, g), b)
    saturation = max_rgb - min_rgb
    brightness = (r + g + b) / 3

    is_grey = (saturation < tolerance) & (brightness > 60) & (brightness < 245)
    is_white = (saturation < 15) & (brightness > 240)
    bg_mask = is_grey | is_white
    alpha[bg_mask] = 0

    from PIL import ImageFilter
    alpha_img = Image.fromarray(alpha).filter(ImageFilter.SMOOTH)
    alpha = np.where(np.array(alpha_img) > 128, 255, 0).astype(np.uint8)

    rgba = np.dstack([arr.astype(np.uint8), alpha])
    return Image.fromarray(rgba, "RGBA")


def auto_remove_bg(img: Image.Image) -> Image.Image:
    """自動偵測背景類型並移除。"""
    arr = np.array(img.convert("RGB")).astype(float)

    # 取四角 20×20 的平均顏色
    corners = []
    for cy, cx in [(10, 10), (10, -10), (-10, 10), (-10, -10)]:
        patch = arr[cy-5:cy+5, cx-5:cx+5] if cy > 0 and cx > 0 else \
                arr[cy-5:cy+5, cx-5:cx+5] if cy > 0 else arr[cy-5:, cx-5:cx+5]
        corners.append(np.mean(arr[:20, :20], axis=(0, 1)))
        # 簡化：直接取四角
    corner_samples = [
        np.mean(arr[:20, :20], axis=(0, 1)),
        np.mean(arr[:20, -20:], axis=(0, 1)),
        np.mean(arr[-20:, :20], axis=(0, 1)),
        np.mean(arr[-20:, -20:], axis=(0, 1)),
    ]
    avg_color = np.mean(corner_samples, axis=0)
    r, g, b = avg_color

    # 判斷背景類型
    if g > 200 and r < 80 and b < 80:
        print(f"   偵測到綠幕背景")
        return remove_keyed_bg(img, (0, 255, 0))
    elif r > 200 and b > 200 and g < 80:
        print(f"   偵測到洋紅背景")
        return remove_keyed_bg(img, (255, 0, 255))
    elif r < 30 and g < 30 and b < 30:
        print(f"   偵測到黑底背景")
        return remove_keyed_bg(img, (0, 0, 0))
    elif r > 230 and g > 230 and b > 230:
        print(f"   偵測到白底背景")
        return remove_keyed_bg(img, (255, 255, 255))
    else:
        brightness = (r + g + b) / 3
        if brightness < 80:
            print(f"   偵測到深色棋盤格背景")
            return remove_checker_bg(img)
        else:
            print(f"   偵測到淺色棋盤格背景")
            return remove_checker_bg(img)


def get_bg_remover(bg_mode: str):
    """
    根據 --bg 參數回傳對應的去背函式。
    回傳 callable(img) -> img_rgba
    """
    if bg_mode == "auto" or bg_mode is None:
        return auto_remove_bg

    if bg_mode in BG_PRESETS and BG_PRESETS[bg_mode] is not None:
        color = BG_PRESETS[bg_mode]
        return lambda img: remove_keyed_bg(img, color)

    # 嘗試解析 hex color（如 #FF00FF）
    if bg_mode.startswith("#") and len(bg_mode) == 7:
        r = int(bg_mode[1:3], 16)
        g = int(bg_mode[3:5], 16)
        b = int(bg_mode[5:7], 16)
        return lambda img: remove_keyed_bg(img, (r, g, b))

    print(f"⚠️  未知背景模式: {bg_mode}，使用自動偵測")
    return auto_remove_bg


# ── 幀偵測 & 標準化 ───────────────────────────────────

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


def extract_frames_grid(img: Image.Image, rows: int, cols: int) -> list[Image.Image]:
    """用 grid 均分方式提取幀"""
    cell_w = img.width // cols
    cell_h = img.height // rows
    frames = []
    for r in range(rows):
        for c in range(cols):
            x1 = c * cell_w
            y1 = r * cell_h
            frame = img.crop((x1, y1, x1 + cell_w, y1 + cell_h))
            frames.append(frame)
    return frames


def normalize_frame(frame: Image.Image, target_size: int, padding_pct: float = 0.05) -> Image.Image:
    """
    標準化單幀：
    1. 偵測內容邊界
    2. 裁切出內容
    3. 等比縮放到 target_size × (1 - padding)
    4. 置中到 target_size × target_size 畫布
    """
    bbox = find_content_bbox(frame)
    content = frame.crop(bbox)

    if content.width == 0 or content.height == 0:
        return Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))

    inner = int(target_size * (1 - padding_pct * 2))
    content.thumbnail((inner, inner), Image.LANCZOS)

    canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    ox = (target_size - content.width) // 2
    oy = (target_size - content.height) // 2
    canvas.paste(content, (ox, oy), content)
    return canvas


def assemble_spritesheet(frames: list[Image.Image]) -> Image.Image:
    """把多幀水平拼接成一條 sprite sheet"""
    if not frames:
        return Image.new("RGBA", (1, 1), (0, 0, 0, 0))

    frame_w = frames[0].width
    frame_h = frames[0].height
    sheet = Image.new("RGBA", (frame_w * len(frames), frame_h), (0, 0, 0, 0))

    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * frame_w, 0), frame)

    return sheet


# ── 預覽 ───────────────────────────────────────────────

def preview_frames(img: Image.Image, rows: int, cols: int, output_path: Path):
    """畫出幀切割線 + 內容邊界框"""
    debug = img.convert("RGBA").copy()
    draw = ImageDraw.Draw(debug)

    cell_w = img.width // cols
    cell_h = img.height // rows

    # 畫 grid 線
    for c in range(1, cols):
        draw.line([(c * cell_w, 0), (c * cell_w, img.height)], fill=(255, 255, 0, 200), width=2)
    for r in range(1, rows):
        draw.line([(0, r * cell_h), (img.width, r * cell_h)], fill=(255, 255, 0, 200), width=2)

    # 每格內偵測內容邊界
    for r in range(rows):
        for c in range(cols):
            x1, y1 = c * cell_w, r * cell_h
            cell = img.crop((x1, y1, x1 + cell_w, y1 + cell_h))
            if cell.mode != "RGBA":
                cell = cell.convert("RGBA")
            bbox = find_content_bbox(cell)
            # 轉換成全圖座標
            draw.rectangle(
                [x1 + bbox[0], y1 + bbox[1], x1 + bbox[2], y1 + bbox[3]],
                outline=(0, 255, 0, 180), width=2
            )

    output_path.mkdir(parents=True, exist_ok=True)
    debug.save(output_path / "preview_frames.png", "PNG")
    print(f"🔍 預覽 → {output_path / 'preview_frames.png'}")
    print(f"   黃線=幀分割線, 綠框=各幀內容邊界")


# ── 主流程 ─────────────────────────────────────────────

def process_single(input_path: str, output_dir: str,
                   rows: int, cols: int, frame_size: int,
                   output_name: str, bg_mode: str = "auto",
                   individual: bool = False, do_preview: bool = False):
    """處理單張 sprite sheet"""
    img = Image.open(input_path)
    name = output_name or Path(input_path).stem
    remove_bg = get_bg_remover(bg_mode)

    print(f"📂 輸入：{input_path} ({img.width}×{img.height})")
    print(f"   格式：{img.mode}, grid: {rows}×{cols}, 每幀目標: {frame_size}px, 去背: {bg_mode}")

    output_path = Path(output_dir)

    # 預覽模式
    if do_preview:
        img_clean = remove_bg(img)
        preview_frames(img_clean, rows, cols, output_path)
        return

    # Step 1: 去背
    img_clean = remove_bg(img)
    print(f"🎨 背景移除完成")

    # Step 2: 提取幀
    frames = extract_frames_grid(img_clean, rows, cols)
    print(f"✂️  提取 {len(frames)} 幀")

    # Step 3: 標準化每幀
    normalized = [normalize_frame(f, frame_size) for f in frames]
    print(f"📐 標準化完成 → 每幀 {frame_size}×{frame_size}")

    # Step 4: 輸出
    output_path.mkdir(parents=True, exist_ok=True)

    if individual:
        for i, frame in enumerate(normalized):
            out_file = output_path / f"{name}_f{i+1}.png"
            frame.save(out_file, "PNG", optimize=True)
            print(f"  ✅ {out_file.name}")
    else:
        sheet = assemble_spritesheet(normalized)
        out_file = output_path / f"{name}.png"
        sheet.save(out_file, "PNG", optimize=True)
        print(f"  ✅ {out_file.name} ({sheet.width}×{sheet.height})")

    print(f"\n🎉 完成！")


def process_batch(input_dir: str, output_dir: str,
                  rows: int, cols: int, frame_size: int,
                  bg_mode: str = "auto", individual: bool = False):
    """批量處理資料夾內所有圖片"""
    input_path = Path(input_dir)
    files = sorted(list(input_path.glob("*.jpg")) +
                   list(input_path.glob("*.jpeg")) +
                   list(input_path.glob("*.png")))

    if not files:
        print(f"⚠️  在 {input_dir} 找不到圖片")
        return

    print(f"📂 批量處理 {len(files)} 張圖片\n")

    for f in files:
        process_single(str(f), output_dir, rows, cols, frame_size,
                       output_name=f.stem, bg_mode=bg_mode, individual=individual)
        print()


def main():
    parser = argparse.ArgumentParser(
        description="貓咪特工 — Sprite Sheet 清理 & 標準化（支援 Flux JPEG 去背）",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
範例：
  # 綠幕去背 + 4 幀 sprite sheet
  python clean_spritesheet.py -i vfx_skill_a.jpg -o ./vfx --frames 4 --bg green --name vfx_skill_a

  # 洋紅去背（綠色系特效用）
  python clean_spritesheet.py -i vfx_skill_c.jpg -o ./vfx --frames 4 --bg magenta --name vfx_skill_c

  # 黑底去背（發光體用，保留漸層）
  python clean_spritesheet.py -i vfx_orbs.jpg -o ./vfx --frames 5 --bg black --size 16 --name vfx_orbs

  # 自訂 hex 色去背
  python clean_spritesheet.py -i xxx.jpg --frames 4 --bg "#FF8800"

  # 自動偵測背景色
  python clean_spritesheet.py -i vfx.jpg --frames 4 --bg auto

  # 預覽裁切框
  python clean_spritesheet.py -i vfx.jpg --frames 4 --bg green --preview

背景色預設值：
  green    = #00FF00（綠幕，最常用）
  magenta  = #FF00FF（洋紅，綠色特效用）
  black    = #000000（黑底，發光體用）
  white    = #FFFFFF（白底）
  blue     = #0000FF（藍幕）
  auto     = 自動偵測（預設）
        """)

    parser.add_argument("-i", "--input", required=True,
                        help="輸入圖片路徑或資料夾（批量模式）")
    parser.add_argument("-o", "--output", default="./output/vfx",
                        help="輸出資料夾 (預設: ./output/vfx)")
    parser.add_argument("--frames", type=int, default=None,
                        help="水平幀數（簡寫，等同 --grid 1xN）")
    parser.add_argument("--grid", default=None,
                        help="Grid 排列：ROWSxCOLS (例: 1x4, 2x5)")
    parser.add_argument("--size", type=int, default=128,
                        help="每幀輸出尺寸 (預設: 128)")
    parser.add_argument("--bg", default="auto",
                        help="背景色模式：green / magenta / black / white / auto / #HEX (預設: auto)")
    parser.add_argument("--name", default=None,
                        help="輸出檔名（不含副檔名）")
    parser.add_argument("--individual", action="store_true",
                        help="輸出個別幀而非合併 sprite sheet")
    parser.add_argument("--preview", action="store_true",
                        help="預覽模式")

    args = parser.parse_args()

    # 解析 grid
    if args.frames:
        rows, cols = 1, args.frames
    elif args.grid:
        parts = args.grid.lower().split("x")
        rows, cols = int(parts[0]), int(parts[1])
    else:
        print("⚠️  請指定 --frames N 或 --grid ROWSxCOLS")
        return

    # 判斷是單檔還是資料夾
    input_path = Path(args.input)
    if input_path.is_dir():
        process_batch(str(input_path), args.output, rows, cols, args.size,
                      bg_mode=args.bg, individual=args.individual)
    else:
        process_single(args.input, args.output, rows, cols, args.size,
                       args.name, bg_mode=args.bg,
                       individual=args.individual, do_preview=args.preview)


if __name__ == "__main__":
    main()