# 貓咪特工 — 特效素材 (VFX) 提示詞 v2

## 特效素材的特殊性

特效跟角色、背景完全不同：
- **逐幀動畫** — 需要 4-8 幀排成一條 sprite sheet
- **透明疊加** — 播放時疊在角色/方塊上面，不能有底色
- **生命週期短** — 每幀只顯示 50-100ms，細節看不到

### AI 生圖 vs 程式碼實作

| 特效 | 推薦方式 | 理由 |
|------|---------|------|
| #69 方塊消除爆破 | ⚡ Flutter 粒子系統 | 碎片方向隨機更自然 |
| #70 連鎖波紋 | ⚡ Flutter 動畫 | 同心圓擴散用程式碼更精確 |
| #71 Combo 火焰 | 🎨 AI 生圖 | 火焰造型需要手繪感 |
| #72 技能發動 ×5 | 🎨 AI 生圖 | 五屬性各有主題，需要視覺設計 |
| #73 勝利煙火 | ⚡ Flutter 粒子系統 | 煙火用粒子更華麗且隨機 |
| #74 傷害數字 | 🎨 AI 生圖 或 字型渲染 | 風格化數字需要設計 |
| #75 能量球粒子 | 🎨 AI 生圖（一圖多切） | 超小素材，5 個一起生 |
| #76 升級光柱 | ⚡ Flutter 動畫 | 垂直光柱 + 粒子上升，程式碼更順 |

> 結論：8 組特效裡 4 組建議用程式碼、4 組用 AI 生圖。
> 以下只列 AI 生圖的 prompt，程式碼實作方案附在最後。

---

## 共用特效風格前綴（VFX Style Anchor）

```
VFX STYLE ANCHOR:

A horizontal sprite sheet animation sequence on a transparent background,
each frame is an equal-sized square arranged left to right with no overlap,
bright vivid colors with soft glow edges, slight motion blur between frames,
flat stylized coloring consistent with casual mobile puzzle games,
no black outlines on the effects (effects should feel like light/energy not solid objects),
transparent background throughout, PNG with alpha channel
```

---

## AI 生圖的特效 Prompt（4 組）

### #71 Combo 火焰特效（4 幀）

```
A horizontal sprite sheet of 4 animation frames arranged left to right, each frame is a 64x64px square, transparent background throughout, bright stylized fire effect for a casual mobile game, no black outlines, vivid orange-yellow colors with soft glow —

Frame 1 (leftmost): a tiny spark point in the center, very small bright yellow-white core with faint orange glow
Frame 2: the spark expands into a small flame shape, orange-yellow fire with a bright white center, rising upward
Frame 3: the flame is at full size, a bold stylized fire burst with orange outer flames, yellow inner flames, and white-hot core, small ember particles around it
Frame 4 (rightmost): the flame is dissipating, fading orange wisps spreading outward and upward, embers scattering, mostly transparent with fading glow
```

| 項目 | 值 |
|------|-----|
| 檔名 | `vfx_combo_fire.png` |
| 總尺寸 | 256×64px（4 幀 × 64px） |
| 生圖尺寸 | 1024×256，裁切後縮放 |

**裁切指令**：
```bash
python slice_sprites.py -i vfx_combo_fire_raw.png -o ./output/vfx --grid 1x4 --size 64 --remove-bg \
    --names vfx_combo_fire_f1,vfx_combo_fire_f2,vfx_combo_fire_f3,vfx_combo_fire_f4
```

> 或者保持為一整張 sprite sheet 不裁切，在 Flutter 中用 `SpriteWidget` 逐幀播放。

---

### #72 技能發動特效 ×5（每組 4 幀）

五個屬性各一組，共用相同的動畫結構但換顏色和元素主題。

#### 通用模板

```
A horizontal sprite sheet of 4 animation frames arranged left to right, each frame is a 128x128px square, transparent background throughout, a stylized [ELEMENT] energy burst effect for a casual mobile game, no black outlines, vivid [COLOR] colors with soft glow —

Frame 1 (leftmost): a small glowing [COLOR] energy orb in the center, pulsing with a bright white core
Frame 2: the orb cracks open, [ELEMENT_DETAIL] energy rays shooting outward in 6 directions from center
Frame 3: full burst — a large [ELEMENT_SHAPE] explosion filling most of the frame, [COLOR] with white-hot center, [ELEMENT_PARTICLES] swirling around
Frame 4 (rightmost): the energy dissipates into fading [COLOR] wisps and scattered [ELEMENT_PARTICLES], mostly transparent
```

#### 五屬性替換表

| 屬性 | ELEMENT | COLOR | ELEMENT_DETAIL | ELEMENT_SHAPE | ELEMENT_PARTICLES |
|------|---------|-------|----------------|---------------|-------------------|
| A 火 | fire | coral red and orange (#FF6F59) | flame-like | fiery starburst | small ember sparks |
| B 水 | water | teal blue and cyan (#2B82D9) | flowing wave-like | water splash ring | small water droplets |
| C 自然 | nature | mint green and leaf green (#43AA8B) | vine-like spiral | swirling leaf storm | small floating leaves |
| D 雷 | lightning | amber gold and electric yellow (#D4A017) | jagged bolt-like | electric starburst | small electric sparks |
| E 暗 | shadow | rose pink and dark magenta (#EF3054) | curved crescent-like | dark energy vortex | small shadow wisps |

#### 完整範例 — 屬性 A（火）

```
A horizontal sprite sheet of 4 animation frames arranged left to right, each frame is a 128x128px square, transparent background throughout, a stylized fire energy burst effect for a casual mobile game, no black outlines, vivid coral red and orange (#FF6F59) colors with soft glow —

Frame 1 (leftmost): a small glowing coral red energy orb in the center, pulsing with a bright white core
Frame 2: the orb cracks open, flame-like energy rays shooting outward in 6 directions from center
Frame 3: full burst — a large fiery starburst explosion filling most of the frame, coral red and orange with white-hot center, small ember sparks swirling around
Frame 4 (rightmost): the energy dissipates into fading coral red wisps and scattered small ember sparks, mostly transparent
```

| 屬性 | 檔名 | 總尺寸 |
|------|------|--------|
| A 火 | `vfx_skill_a.png` | 512×128px |
| B 水 | `vfx_skill_b.png` | 512×128px |
| C 自然 | `vfx_skill_c.png` | 512×128px |
| D 雷 | `vfx_skill_d.png` | 512×128px |
| E 暗 | `vfx_skill_e.png` | 512×128px |

**生圖建議**：每組生成 1024×256，最終縮放到 512×128。

---

### #74 傷害數字（0-9，一圖多切）

```
A sprite sheet of 10 bold damage numbers (0 through 9) arranged in a single row of 10 evenly-spaced columns on a transparent background, each number occupies an equal-sized cell, the numbers are in a chunky bold cartoon style with thick dark red (#8B0000) outlines (3px), bright red (#FF1744) fill with a slight orange highlight on the upper-left of each number suggesting light, slight 3D depth with a dark drop shadow offset down-right by 2px, fun energetic game damage number style —

Left to right: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
```

| 項目 | 值 |
|------|-----|
| 檔名 | `font_damage_0.png` ~ `font_damage_9.png` |
| 個別尺寸 | 32×48px |
| 生圖尺寸 | 1280×192（10 格），縮放後裁切 |

**裁切指令**：
```bash
python slice_sprites.py -i damage_numbers_raw.png -o ./output/vfx --grid 1x10 --size 48 --remove-bg \
    --names font_damage_0,font_damage_1,font_damage_2,font_damage_3,font_damage_4,font_damage_5,font_damage_6,font_damage_7,font_damage_8,font_damage_9
```

> **替代方案**：用 Google Fonts 找一個粗體卡通字型（如 Bungee, Luckiest Guy, Fredoka One），
> 在 Flutter 中用 `Text` + `TextStyle` + `Shadow` 直接渲染，省去圖片管理。

---

### #75 能量球粒子 ×5（一圖多切）

```
A sprite sheet of 5 small glowing energy orbs arranged in a single row of 5 evenly-spaced columns on a transparent background, each orb is a simple soft circular glow, no black outlines, each orb has a bright white center that fades into its color at the edges, casual mobile game particle style —

Left to right:
1. coral red (#FF6F59) glowing orb
2. teal blue (#2B82D9) glowing orb
3. mint green (#43AA8B) glowing orb
4. amber gold (#D4A017) glowing orb
5. rose pink (#EF3054) glowing orb
```

| 項目 | 值 |
|------|-----|
| 檔名 | `vfx_orb_a.png` ~ `vfx_orb_e.png` |
| 個別尺寸 | 16×16px |
| 生圖尺寸 | 640×128（5 格），大幅縮放 |

**裁切指令**：
```bash
python slice_sprites.py -i energy_orbs_raw.png -o ./output/vfx --grid 1x5 --size 16 --remove-bg \
    --names vfx_orb_a,vfx_orb_b,vfx_orb_c,vfx_orb_d,vfx_orb_e
```

> **替代方案**：能量球就是「模糊的彩色圓點」，用 Flutter `RadialGradient` 畫更精準：
> ```dart
> Container(
>   width: 16, height: 16,
>   decoration: BoxDecoration(
>     shape: BoxShape.circle,
>     gradient: RadialGradient(
>       colors: [Colors.white, Color(0xFFFF6F59), Color(0x00FF6F59)],
>       stops: [0.0, 0.4, 1.0],
>     ),
>   ),
> )
> ```

---

## Flutter 程式碼實作方案（4 組）

以下特效建議用 Flutter 動畫/粒子系統實作，效果更好且不佔素材空間。

### #69 方塊消除爆破

```dart
// 概念：在方塊位置生成 8-12 個小方形碎片，隨機方向飛出 + 旋轉 + 縮小消失
class BlockExplodeEffect extends StatefulWidget {
  final Color blockColor;
  final Offset position;
  // ...
}

// 每個碎片：
// - 大小：方塊的 1/6 ~ 1/4
// - 初速：隨機方向，200-400 px/s
// - 旋轉：隨機角速度
// - 透明度：1.0 → 0.0 over 300ms
// - 加上 2-3 個白色小星星 sparkle 粒子
```

### #70 連鎖波紋效果

```dart
// 概念：從觸發點擴散 2-3 個同心圓環，依序放大 + 淡出
class ChainRippleEffect extends StatefulWidget {
  final Color color;
  final Offset center;
  // ...
}

// 每個圓環：
// - 初始半徑：0，結束半徑：方塊寬度 × 2
// - 線寬：3px → 1px（擴散時變細）
// - 透明度：0.8 → 0.0 over 400ms
// - 3 個圓環間隔 100ms 依序觸發
```

### #73 勝利煙火特效

```dart
// 概念：在螢幕隨機位置觸發 3-5 次煙火
// 每次煙火：
// - 上升階段：一個亮點從底部往上飛 200ms
// - 爆發階段：從頂點射出 20-30 個彩色粒子，呈放射狀
// - 粒子：隨機顏色（五屬性色），帶重力下墜 + 淡出
// - 拖尾：每個粒子留下 3-4 幀的殘影

// 推薦用 Flutter `CustomPainter` + `AnimationController`
// 或用 `flame` package 的 `ParticleSystemComponent`
```

### #76 升級光柱特效

```dart
// 概念：角色位置升起一道垂直光柱 + 向上飄升的粒子
class LevelUpPillarEffect extends StatefulWidget {
  final Offset position;
  // ...
}

// 光柱：
// - 寬度：角色寬度 × 1.5
// - 高度：0 → 螢幕高度，200ms 快速伸展
// - 顏色：中心白色，邊緣金色 (#FFB300)，用 LinearGradient
// - 透明度：0.8 → 0.0 over 800ms
//
// 粒子：
// - 20-30 個小金色光點
// - 從角色位置向上飄升，輕微水平搖擺
// - 用 sin(time) 做水平偏移
```

---

## 素材統計

| 方式 | 數量 | 檔案 |
|------|------|------|
| AI 生圖 | 8 組 sprite sheet | combo 火焰 ×1, 技能 ×5, 傷害數字 ×1, 能量球 ×1 |
| Flutter 程式碼 | 4 組 | 方塊爆破, 連鎖波紋, 勝利煙火, 升級光柱 |

AI 生圖的部分，建議保持為完整 sprite sheet（不裁切成個別幀），
在 Flutter 中用 sprite sheet animation 播放更方便：

```dart
// Flutter sprite sheet 播放範例
class SpriteSheetAnimation extends StatefulWidget {
  final String assetPath;  // 'assets/vfx/vfx_skill_a.png'
  final int frameCount;    // 4
  final Duration duration;  // Duration(milliseconds: 400)
  // ...
}
```