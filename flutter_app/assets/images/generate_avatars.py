"""
貓咪特工 — 角色素材批量生成腳本
================================
從 1024×1024 原始立繪自動產生三組素材：
  1. 角色立繪 (512×512) — characters/char_{name}.png
  2. 圓形頭像 (128×128) — avatars/avatar_{name}.png
  3. 縮圖圖示 (64×64)   — icons/icon_{name}.png

用法：
  # 批量處理
  python generate_avatars.py -i ./raw -o ./output

  # 先用一張圖測試裁切效果
  python generate_avatars.py --preview ./raw/char_lightning_claw.png -o ./test

資料夾結構（輸入）：
  raw/
    char_lightning_claw.png   (1024×1024)
    char_flame_fang.png
    ...

資料夾結構（輸出）：
  output/
    characters/
      char_lightning_claw.png   (512×512)
    avatars/
      avatar_lightning_claw.png (128×128 圓形)
    icons/
      icon_lightning_claw.png   (64×64)
"""

import argparse
import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import numpy as np


# ── 角色名稱對照表（檔名 → 輸出名稱）──────────────────────
CHAR_NAMES = [
    "lightning_claw",   # 閃電爪
    "flame_fang",       # 烈焰牙
    "crimson_shadow",   # 赤紅影
    "storm_blade",      # 風暴刃
    "ice_eye",          # 寒冰瞳
    "azure_star",       # 蒼藍星
    "jade_leaf",        # 翡翠葉
    "venom_mist",       # 毒霧蛇
    "forest_guardian",  # 森林守護
    "thunder_claw",     # 雷光爪
    "golden_sand",      # 金沙瞳
    "sun_herald",       # 日輪使
    "rose_thorn",       # 薔薇刺
    "blood_moon",       # 血月牙
    "moonlight",        # 月華影
]


def find_content_bbox(img: Image.Image) -> tuple[int, int, int, int]:
    """
    找到圖片中非透明像素的邊界框。
    回傳 (left, top, right, bottom)
    """
    alpha = np.array(img.split()[-1])  # 取 alpha channel
    rows = np.any(alpha > 10, axis=1)
    cols = np.any(alpha > 10, axis=0)

    if not rows.any() or not cols.any():
        # 全透明，回傳整張圖
        return (0, 0, img.width, img.height)

    top, bottom = np.where(rows)[0][[0, -1]]
    left, right = np.where(cols)[0][[0, -1]]
    return (int(left), int(top), int(right) + 1, int(bottom) + 1)


def find_head_region(img: Image.Image, head_ratio: float = 0.55) -> tuple[int, int, int, int]:
    """
    估算頭部區域：
    - 2 頭身角色，頭部大約佔上半部 55%
    - 以非透明區域的上半段為基準，取正方形裁切
    """
    left, top, right, bottom = find_content_bbox(img)
    content_h = bottom - top
    content_w = right - left

    # 頭部 = 內容區上方 head_ratio 的高度
    head_h = int(content_h * head_ratio)
    head_center_x = (left + right) // 2

    # 取正方形邊長（頭寬和頭高取較大值，加 padding）
    # 先估計頭部寬度（上半部的水平範圍）
    alpha = np.array(img.split()[-1])
    head_slice = alpha[top : top + head_h, :]
    head_cols = np.any(head_slice > 10, axis=0)

    if head_cols.any():
        h_left, h_right = np.where(head_cols)[0][[0, -1]]
        head_w = h_right - h_left
    else:
        head_w = content_w

    # 正方形邊長 = max(頭寬, 頭高) + 10% padding
    side = int(max(head_w, head_h) * 1.1)
    side = min(side, img.width, img.height)  # 不超出圖片

    # 計算裁切框（以頭部中心為基準）
    head_center_y = top + head_h // 2

    crop_left = max(0, head_center_x - side // 2)
    crop_top = max(0, head_center_y - side // 2)
    crop_right = min(img.width, crop_left + side)
    crop_bottom = min(img.height, crop_top + side)

    # 修正邊界溢出
    if crop_right - crop_left < side:
        crop_left = max(0, crop_right - side)
    if crop_bottom - crop_top < side:
        crop_top = max(0, crop_bottom - side)

    return (crop_left, crop_top, crop_right, crop_bottom)


def make_circle_mask(size: int) -> Image.Image:
    """產生圓形遮罩（帶抗鋸齒）"""
    # 用 4x 超採樣再縮小，達到平滑邊緣
    big = size * 4
    mask = Image.new("L", (big, big), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse([0, 0, big - 1, big - 1], fill=255)
    mask = mask.resize((size, size), Image.LANCZOS)
    return mask


def generate_avatar(img: Image.Image, size: int = 128) -> Image.Image:
    """
    從立繪生成圓形頭像：
    1. 偵測頭部區域
    2. 裁切正方形
    3. 縮放到目標尺寸
    4. 套用圓形遮罩
    """
    # 裁切頭部
    crop_box = find_head_region(img)
    head = img.crop(crop_box)

    # 縮放
    head = head.resize((size, size), Image.LANCZOS)

    # 套用圓形遮罩
    circle_mask = make_circle_mask(size)

    # 合成：保留原始 RGB，alpha = 原始 alpha × 圓形遮罩
    r, g, b, a = head.split()
    # 將圓形遮罩與原始 alpha 相乘
    a = Image.fromarray(
        (np.array(a).astype(float) * np.array(circle_mask).astype(float) / 255)
        .clip(0, 255)
        .astype(np.uint8)
    )
    avatar = Image.merge("RGBA", (r, g, b, a))

    return avatar


def generate_icon(img: Image.Image, size: int = 64) -> Image.Image:
    """
    從立繪生成縮圖圖示：
    1. 偵測內容邊界
    2. 等比縮放塞進目標尺寸（保留透明背景）
    """
    left, top, right, bottom = find_content_bbox(img)

    # 裁切到內容區域
    content = img.crop((left, top, right, bottom))

    # 加一點 padding（留 10% 邊距）
    inner_size = int(size * 0.85)

    # 等比縮放
    content.thumbnail((inner_size, inner_size), Image.LANCZOS)

    # 置中放到目標尺寸畫布
    icon = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    offset_x = (size - content.width) // 2
    offset_y = (size - content.height) // 2
    icon.paste(content, (offset_x, offset_y), content)

    return icon


def process_all(input_dir: str, output_dir: str,
                char_size: int = 512, avatar_size: int = 128, icon_size: int = 64):
    """
    批量處理所有角色，輸出三個資料夾：
      characters/  — 1024→512 縮圖後的角色立繪
      avatars/     — 128×128 圓形頭像
      icons/       — 64×64 縮圖圖示
    """
    input_path = Path(input_dir)
    output_path = Path(output_dir)

    # 建立三個輸出資料夾
    char_dir = output_path / "characters"
    avatar_dir = output_path / "avatars"
    icon_dir = output_path / "icons"
    char_dir.mkdir(parents=True, exist_ok=True)
    avatar_dir.mkdir(parents=True, exist_ok=True)
    icon_dir.mkdir(parents=True, exist_ok=True)

    # 掃描所有 char_*.png
    png_files = sorted(input_path.glob("char_*.png"))

    if not png_files:
        print(f"⚠️  在 {input_dir} 找不到 char_*.png 檔案")
        print(f"   請確認檔案命名格式：char_lightning_claw.png, char_flame_fang.png ...")
        return

    print(f"📂 輸入資料夾：{input_dir}")
    print(f"📂 輸出資料夾：{output_dir}")
    print(f"🐱 找到 {len(png_files)} 個角色檔案\n")

    success = 0
    for png_file in png_files:
        name = png_file.stem  # e.g. "char_lightning_claw"
        short_name = name.replace("char_", "")  # e.g. "lightning_claw"

        try:
            img = Image.open(png_file).convert("RGBA")
            orig_w, orig_h = img.size

            # Step 1: 縮圖到 512×512（如果原圖較大）
            if orig_w > char_size or orig_h > char_size:
                img_resized = img.resize((char_size, char_size), Image.LANCZOS)
                print(f"  📐 {short_name}: {orig_w}×{orig_h} → {char_size}×{char_size}")
            else:
                img_resized = img.copy()
                print(f"  📐 {short_name}: 已經是 {orig_w}×{orig_h}，不縮放")

            # 儲存角色立繪
            char_path = char_dir / f"char_{short_name}.png"
            img_resized.save(char_path, "PNG", optimize=True)

            # Step 2: 從縮圖後的 512 版本生成頭像
            avatar = generate_avatar(img_resized, avatar_size)
            avatar_path = avatar_dir / f"avatar_{short_name}.png"
            avatar.save(avatar_path, "PNG", optimize=True)

            # Step 3: 從縮圖後的 512 版本生成圖示
            icon = generate_icon(img_resized, icon_size)
            icon_path = icon_dir / f"icon_{short_name}.png"
            icon.save(icon_path, "PNG", optimize=True)

            print(f"  ✅ {short_name}")
            print(f"     角色 → {char_path}  ({char_size}×{char_size})")
            print(f"     頭像 → {avatar_path}  ({avatar_size}×{avatar_size})")
            print(f"     圖示 → {icon_path}  ({icon_size}×{icon_size})")
            success += 1

        except Exception as e:
            print(f"  ❌ {short_name} — 錯誤：{e}")

    print(f"\n🎉 完成！成功處理 {success}/{len(png_files)} 個角色")
    print(f"   角色 → {char_dir}/")
    print(f"   頭像 → {avatar_dir}/")
    print(f"   圖示 → {icon_dir}/")


# ── 預覽模式：用單張圖片測試效果 ─────────────────────────
def preview_single(image_path: str, output_dir: str, char_size: int = 512):
    """用單張圖片測試，方便調參"""
    img = Image.open(image_path).convert("RGBA")
    name = Path(image_path).stem.replace("char_", "")
    orig_w, orig_h = img.size

    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # Step 1: 縮圖
    if orig_w > char_size or orig_h > char_size:
        img = img.resize((char_size, char_size), Image.LANCZOS)
        print(f"  📐 {orig_w}×{orig_h} → {char_size}×{char_size}")

    # 頭部偵測視覺化（畫出裁切框）
    debug = img.copy()
    draw = ImageDraw.Draw(debug)
    box = find_head_region(img)
    draw.rectangle(box, outline=(255, 0, 0, 200), width=3)
    bbox = find_content_bbox(img)
    draw.rectangle(bbox, outline=(0, 255, 0, 128), width=2)
    debug.save(output_path / f"debug_{name}.png", "PNG")

    # 生成三組素材
    img.save(output_path / f"char_{name}.png", "PNG", optimize=True)

    avatar = generate_avatar(img)
    avatar.save(output_path / f"avatar_{name}.png", "PNG", optimize=True)

    icon = generate_icon(img)
    icon.save(output_path / f"icon_{name}.png", "PNG", optimize=True)

    print(f"🔍 預覽模式 — {name}")
    print(f"   debug  → debug_{name}.png （紅框=頭部裁切區, 綠框=內容邊界）")
    print(f"   角色   → char_{name}.png ({char_size}×{char_size})")
    print(f"   頭像   → avatar_{name}.png (128×128)")
    print(f"   圖示   → icon_{name}.png (64×64)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="貓咪特工 — 批量生成角色立繪、頭像、圖示")
    parser.add_argument("--input", "-i", default="./raw",
                        help="原始 1024×1024 立繪資料夾路徑 (預設: ./raw)")
    parser.add_argument("--output", "-o", default="./output",
                        help="輸出資料夾路徑 (預設: ./output)")
    parser.add_argument("--char-size", type=int, default=512,
                        help="角色立繪目標尺寸 (預設: 512)")
    parser.add_argument("--avatar-size", type=int, default=128,
                        help="頭像尺寸 (預設: 128)")
    parser.add_argument("--icon-size", type=int, default=64,
                        help="圖示尺寸 (預設: 64)")
    parser.add_argument("--preview", "-p", default=None,
                        help="預覽模式：指定單張圖片路徑測試效果")

    args = parser.parse_args()

    if args.preview:
        preview_single(args.preview, args.output)
    else:
        process_all(args.input, args.output, args.char_size, args.avatar_size, args.icon_size)