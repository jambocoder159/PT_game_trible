# 貓咪特工 — 稀有度框 & 按鈕面板提示詞 v2

---

## 一、稀有度框（4 種）

### 設計邏輯

稀有度框是「套在角色卡牌外面的裝飾邊框」，中間是透明的，用來疊在角色立繪上面。  
4 個等級的區分靠**邊框顏色 + 角裝飾複雜度**遞增：

| 等級 | 顏色 | 邊框特徵 | 角裝飾 |
|------|------|---------|--------|
| N | 灰色 #9E9E9E | 細線簡框 | 無裝飾 |
| R | 藍色 #2B82D9 | 中等線框 | 四角小圓點 |
| SR | 紫色 #7B1FA2 | 粗線框 | 四角小菱形寶石 |
| SSR | 金色 #FFB300 | 粗線框 + 內發光 | 四角華麗花紋 + 頂部小皇冠 |

### Sheet G — 稀有度框（1×4 grid，一圖多切）

```
A sprite sheet of 4 card border frames arranged in a single row of 4 evenly-spaced columns on a white background, each frame occupies an equal-sized square cell with clear gaps between them, flat cel-shaded style, thick clean black outlines (2-3px weight), each frame is a rounded rectangle border with a FULLY TRANSPARENT center (only the border is visible), cute cartoon mobile game card rarity style —

Left to right:
1. N-RARITY — a simple thin grey (#9E9E9E) rounded rectangle border frame, no corner decorations, clean and minimal
2. R-RARITY — a medium-thickness blue (#2B82D9) rounded rectangle border frame, small blue circular dots at each of the four corners
3. SR-RARITY — a thick purple (#7B1FA2) rounded rectangle border frame, small diamond-shaped purple gems at each of the four corners, slightly more ornate
4. SSR-RARITY — a thick gold (#FFB300) rounded rectangle border frame with a subtle inner golden glow line, elaborate small golden scroll ornaments at each corner, a tiny golden crown decoration centered at the top edge, the most ornate of all four
```

**輸出設定**：2048×512  
**裁切指令**：
```bash
python slice_sprites.py -i sheet_g_rarity.png -o ./output/frames --grid 1x4 --size 128 --remove-bg \
    --names frame_rarity_n,frame_rarity_r,frame_rarity_sr,frame_rarity_ssr
```

### ⚠️ 重要提醒：AI 生圖的限制

稀有度框的「中間必須透明」對 AI 來說很難做到。AI 傾向填滿畫面，容易在框內畫東西或加底色。

**如果 AI 生的框中間不透明**，兩個解法：

**解法 A — 後處理去中心**：生成後用腳本把框內區域挖空
```python
from PIL import Image, ImageDraw

img = Image.open("frame_rarity_ssr.png").convert("RGBA")
# 建立遮罩：保留邊緣 N px，中間設為透明
mask = Image.new("L", img.size, 255)
draw = ImageDraw.Draw(mask)
border_width = 12  # 邊框寬度（像素），依實際生成結果調整
draw.rounded_rectangle(
    [border_width, border_width,
     img.width - border_width, img.height - border_width],
    radius=8, fill=0
)
img.putalpha(mask)
img.save("frame_rarity_ssr_hollow.png")
```

**解法 B（推薦）— 直接用 SVG 手做**：稀有度框造型極簡，SVG 更精準：

```svg
<!-- N 級 — 灰框 -->
<svg width="128" height="128" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg">
  <rect x="3" y="3" width="122" height="122" rx="12" ry="12"
        fill="none" stroke="#9E9E9E" stroke-width="3"/>
</svg>

<!-- R 級 — 藍框 + 四角圓點 -->
<svg width="128" height="128" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg">
  <rect x="3" y="3" width="122" height="122" rx="12" ry="12"
        fill="none" stroke="#2B82D9" stroke-width="4"/>
  <circle cx="12" cy="12" r="4" fill="#2B82D9"/>
  <circle cx="116" cy="12" r="4" fill="#2B82D9"/>
  <circle cx="12" cy="116" r="4" fill="#2B82D9"/>
  <circle cx="116" cy="116" r="4" fill="#2B82D9"/>
</svg>

<!-- SR 級 — 紫框 + 四角菱形 -->
<svg width="128" height="128" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg">
  <rect x="3" y="3" width="122" height="122" rx="12" ry="12"
        fill="none" stroke="#7B1FA2" stroke-width="5"/>
  <polygon points="12,6 18,12 12,18 6,12" fill="#7B1FA2"/>
  <polygon points="116,6 122,12 116,18 110,12" fill="#7B1FA2"/>
  <polygon points="12,110 18,116 12,122 6,116" fill="#7B1FA2"/>
  <polygon points="116,110 122,116 116,122 110,116" fill="#7B1FA2"/>
</svg>

<!-- SSR 級 — 金框 + 內光 + 皇冠 -->
<svg width="128" height="128" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg">
  <!-- 外框 -->
  <rect x="3" y="3" width="122" height="122" rx="12" ry="12"
        fill="none" stroke="#FFB300" stroke-width="5"/>
  <!-- 內光線 -->
  <rect x="8" y="8" width="112" height="112" rx="9" ry="9"
        fill="none" stroke="#FFD54F" stroke-width="1" opacity="0.6"/>
  <!-- 四角花紋（簡化渦捲） -->
  <circle cx="12" cy="12" r="5" fill="none" stroke="#FFB300" stroke-width="2"/>
  <circle cx="116" cy="12" r="5" fill="none" stroke="#FFB300" stroke-width="2"/>
  <circle cx="12" cy="116" r="5" fill="none" stroke="#FFB300" stroke-width="2"/>
  <circle cx="116" cy="116" r="5" fill="none" stroke="#FFB300" stroke-width="2"/>
  <!-- 頂部小皇冠 -->
  <polygon points="54,2 58,8 62,2 66,8 70,2 74,8 74,12 54,12" fill="#FFB300"/>
</svg>
```

> 建議：稀有度框用 SVG，存成 PNG 後放進 Flutter assets。這是最穩的做法。

---

## 二、按鈕與面板（6 項）

### 設計邏輯

按鈕和面板是**可拉伸的 UI 元素**，原始設計用 9-patch，但生圖很難做出精確的 9-patch。
策略是：**AI 生成視覺風格參考 → 用 SVG 或 Flutter 程式碼實作最終版**。

不過 prompt 還是可以先生成來確認視覺方向。

### 按鈕 & 面板的風格跟角色差異

| 差異點 | 角色/敵人 | 按鈕/面板 |
|--------|----------|-----------|
| 線條 | 粗描邊 3-4px | 細描邊 1-2px |
| 上色 | 完全平塗 | 允許微漸層（增加按鈕立體感） |
| 造型 | 圓潤生物體 | 幾何圓角矩形 |
| 質感 | 無 | 按鈕有輕微浮雕 bevel |

### Sheet H — 按鈕 ×3（1×3 grid，一圖多切）

```
A sprite sheet of 3 game UI buttons arranged in a single row of 3 evenly-spaced columns on a white background, each button is a wide rounded rectangle (roughly 3:1 width-to-height ratio), thick clean black outlines (2px weight), each button has a subtle top-to-bottom two-tone color fill (lighter top, slightly darker bottom) for a soft bevel effect, cute cartoon mobile game UI style, each button centered in its grid cell —

Left to right:
1. PRIMARY BUTTON — purple theme, top half #7B4FAA bottom half #533483, a thin lighter purple (#9B6FC0) highlight line along the top edge inside the border
2. SECONDARY BUTTON — dark navy blue theme, top half #1A5276 bottom half #0F3460, a thin lighter blue (#2B6FA0) highlight line along the top edge inside the border
3. DANGER BUTTON — red theme, top half #F05A6A bottom half #E94560, a thin lighter red (#F5838F) highlight line along the top edge inside the border
```

**輸出設定**：1536×512  
**裁切指令**：
```bash
python slice_sprites.py -i sheet_h_buttons.png -o ./output/ui --grid 1x3 --size 192x64 --remove-bg \
    --names btn_primary,btn_secondary,btn_danger
```

> ⚠️ 注意：按鈕是 192×64 非正方形。`slice_sprites.py` 的 grid 模式會按格子均分，
> 裁出來的比例可能不對。建議裁切後手動調整，或直接用下方的 SVG / Flutter 方案。

**對應檔名**：

| 格子 | 檔名 |
|------|------|
| C1 | `btn_primary.9.png` |
| C2 | `btn_secondary.9.png` |
| C3 | `btn_danger.9.png` |

---

### 卡牌背景面板（單獨生成）

```
2D casual mobile game UI card panel, a dark navy blue (#0F3460) rounded rectangle panel, thick clean black outline (2px weight), a thin lighter blue (#1A5276) inner border line 2px from the edge, very subtle vertical gradient (top #154360 to bottom #0F3460), soft rounded corners (radius ~12px), clean and minimal, transparent background, 512x256px canvas, the panel fills 90% of the canvas
```

| 項目 | 值 |
|------|-----|
| 檔名 | `panel_card.9.png` |
| 輸出 | 256×128 (從 512×256 縮圖) |

---

### 木紋欄（上 + 下，一圖兩切）

```
A sprite sheet of 2 horizontal wooden plank bars stacked vertically on a white background with clear space between them, flat cel-shaded coloring with minimal wood grain detail, thick clean black outlines (2px weight), warm brown color scheme, cute cartoon medieval fantasy game style —

Top bar:
a horizontal wooden plank with slightly darker brown (#8B6914) bottom edge and lighter brown (#C4A24E) top surface, 2-3 simple curved lines suggesting wood grain running left to right, small round nail heads at each end

Bottom bar:
same wooden plank but flipped — lighter brown (#C4A24E) on bottom edge and darker brown (#8B6914) on top surface, wood grain lines mirrored, small round nail heads at each end
```

**輸出設定**：1024×512  
**裁切指令**：
```bash
python slice_sprites.py -i sheet_wood_bars.png -o ./output/ui --grid 2x1 --remove-bg \
    --names bar_wood_top,bar_wood_bottom
```

> 木紋欄是全寬元素，裁切後需要手動調整為目標比例（全寬 × 64px）。

---

## 三、推薦方案：按鈕 & 面板用程式碼實作

老實說，按鈕和面板這類可拉伸 UI 元素，**用 Flutter 程式碼做比 AI 生圖更好**：

```dart
// Flutter — 主按鈕
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF7B4FAA), Color(0xFF533483)],
    ),
    border: Border.all(color: Colors.black, width: 2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        offset: const Offset(0, 3),
        blurRadius: 0, // 硬陰影更有卡通感
      ),
    ],
  ),
  child: const Text('開始戰鬥'),
)

// Flutter — 卡牌面板
Container(
  decoration: BoxDecoration(
    color: const Color(0xFF0F3460),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFF1A5276), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        offset: const Offset(0, 2),
        blurRadius: 0,
      ),
    ],
  ),
)

// Flutter — 木紋欄
Container(
  height: 48,
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFC4A24E), Color(0xFF8B6914)],
    ),
    border: Border.all(color: Colors.black, width: 2),
  ),
)
```

### 為什麼程式碼比 AI 生圖好？

| 比較 | AI 生圖 | 程式碼 |
|------|---------|--------|
| 可拉伸 | 需要做 9-patch，AI 做不精準 | 天然響應式 |
| 像素完美 | 圓角、邊框粗細不可控 | 完全精準 |
| 改色 | 要重新生成 | 改一個 hex code |
| 一致性 | 每次生成略有差異 | 100% 一致 |
| 效能 | 載入圖片資源 | GPU 直接繪製，更省記憶體 |

**建議**：
- **稀有度框** → SVG 手做（已附模板）或 Flutter `CustomPainter`
- **按鈕** → Flutter `Container` + `BoxDecoration`
- **面板** → Flutter `Container` + `BoxDecoration`
- **木紋欄** → AI 先生成確認視覺方向，最終用圖片或 Flutter 實作皆可