# 貓咪特工 (Cat Agent Puzzle) — 手機版遊戲素材清單

## Context
基於 Flutter 手機遊戲專案 (`flutter_app/`) 的完整程式碼分析，列出所有畫面所需的圖片/音效/字型素材。目前遊戲全部使用 emoji + CustomPaint 作為 placeholder，以下為正式上線所需的完整素材清單。

---

## 一、角色素材 (Characters)

| # | 素材名稱 | 素材類型 | 素材尺寸 | Prompt |
|---|---------|---------|---------|--------|
| 1 | 閃電爪 (屬性A・突擊手・N) | 角色立繪 PNG | 512×512px (2x: 1024×1024) | A cute cartoon orange tabby cat in spy/agent outfit, dynamic attack pose, coral red theme, chibi style, transparent background |
| 2 | 烈焰牙 (屬性A・破壞者・R) | 角色立繪 PNG | 512×512px | A fierce cartoon red cat with flame patterns, wearing spy gear, aggressive stance, coral red theme, chibi style, transparent background |
| 3 | 赤紅影 (屬性A・潛行者・SR) | 角色立繪 PNG | 512×512px | A sleek dark red cat in stealth ninja outfit, mysterious pose, crimson theme, chibi style, transparent background |
| 4 | 風暴刃 (屬性B・防衛者・N) | 角色立繪 PNG | 512×512px | A sturdy cartoon blue cat in shield-bearer armor, defensive pose, teal blue theme, chibi style, transparent background |
| 5 | 寒冰瞳 (屬性B・支援者・R) | 角色立繪 PNG | 512×512px | A graceful cartoon ice-blue cat with crystal accessories, healing pose, teal blue theme, chibi style, transparent background |
| 6 | 蒼藍星 (屬性B・突擊者・SR) | 角色立繪 PNG | 512×512px | A heroic cartoon navy blue cat with star motif cape, charging pose, deep blue theme, chibi style, transparent background |
| 7 | 翡翠葉 (屬性C・支援者・N) | 角色立繪 PNG | 512×512px | A gentle cartoon green cat with leaf accessories, supportive pose, mint green theme, chibi style, transparent background |
| 8 | 毒霧蛇 (屬性C・潛行者・R) | 角色立繪 PNG | 512×512px | A sly cartoon emerald cat with poison-themed markings, sneaky pose, dark green theme, chibi style, transparent background |
| 9 | 森林守護 (屬性C・防衛者・SR) | 角色立繪 PNG | 512×512px | A majestic cartoon forest-green cat in nature armor, guardian stance, forest green theme, chibi style, transparent background |
| 10 | 雷光爪 (屬性D・破壞者・N) | 角色立繪 PNG | 512×512px | A energetic cartoon yellow cat with lightning bolt patterns, destructive pose, golden yellow theme, chibi style, transparent background |
| 11 | 金沙瞳 (屬性D・突擊者・R) | 角色立繪 PNG | 512×512px | A desert-themed cartoon golden cat with sand swirl effects, attack pose, amber gold theme, chibi style, transparent background |
| 12 | 日輪使 (屬性D・支援者・SR) | 角色立繪 PNG | 512×512px | A radiant cartoon sun-gold cat with halo effects, blessing pose, bright gold theme, chibi style, transparent background |
| 13 | 薔薇刺 (屬性E・潛行者・N) | 角色立繪 PNG | 512×512px | A cute cartoon pink cat with rose thorn accessories, stealthy pose, rose pink theme, chibi style, transparent background |
| 14 | 血月牙 (屬性E・破壞者・R) | 角色立繪 PNG | 512×512px | A fierce cartoon crimson-pink cat with crescent moon motif, powerful stance, deep rose theme, chibi style, transparent background |
| 15 | 月華影 (屬性E・防衛者・SSR) | 角色立繪 PNG | 512×512px | A majestic cartoon moonlight silver-pink cat in elegant armor, noble pose, moonlit rose theme, sparkle effects, chibi style, transparent background |

### 角色衍生素材

| # | 素材名稱 | 素材類型 | 素材尺寸 | Prompt |
|---|---------|---------|---------|--------|
| 16 | 角色頭像 ×15 | 圓形頭像 PNG | 128×128px | Cropped circular headshot of [character name], consistent with full portrait style |
| 17 | 角色小圖示 ×15 | 縮圖 Icon PNG | 64×64px | Tiny icon version of [character name], simplified features, recognizable silhouette |
| 18 | 進化立繪 (每角色 2-3 階) | 角色立繪 PNG | 512×512px | [Character name] evolved form, more elaborate outfit/armor, glowing effects, enhanced weapon |

---

## 二、方塊素材 (Puzzle Blocks)

| # | 素材名稱 | 素材類型 | 素材尺寸 | Prompt |
|---|---------|---------|---------|--------|
| 19 | 珊瑚方塊 (Coral ●) | 方塊圖片 PNG | 128×128px | A glossy rounded square gem block, coral red (#FF6F59) gradient, circle symbol etched in center, subtle inner glow, game puzzle style |
| 20 | 天藍方塊 (Teal ◆) | 方塊圖片 PNG | 128×128px | A glossy rounded square gem block, teal blue (#2B82D9) gradient, diamond symbol etched in center, subtle inner glow, game puzzle style |
| 21 | 薄荷方塊 (Mint ▲) | 方塊圖片 PNG | 128×128px | A glossy rounded square gem block, mint green (#43AA8B) gradient, triangle symbol etched in center, subtle inner glow, game puzzle style |
| 22 | 琥珀方塊 (Gold ■) | 方塊圖片 PNG | 128×128px | A glossy rounded square gem block, amber gold (#D4C96A) gradient, square symbol etched in center, subtle inner glow, game puzzle style |
| 23 | 玫瑰方塊 (Rose ★) | 方塊圖片 PNG | 128×128px | A glossy rounded square gem block, rose pink (#EF3054) gradient, star symbol etched in center, subtle inner glow, game puzzle style |
| 24 | 暗化方塊 ×5 | 方塊圖片 PNG | 128×128px | Same as above but darkened/desaturated version, cracked appearance, dimmed glow |
| 25 | 方塊消除粒子 ×5 | Sprite Sheet PNG | 256×64px (4 frames) | Sparkle particle burst in [color], 4-frame animation strip, transparent background |

---

## 三、敵人素材 (Enemies)

| # | 素材名稱 | 素材類型 | 素材尺寸 | Prompt |
|---|---------|---------|---------|--------|
| 26 | 普通敵人 - 小狼 | 敵人立繪 PNG | 256×256px | A cartoon wolf enemy, menacing but cute, dark fur, red eyes, game monster style, transparent background |
| 27 | 普通敵人 - 狐狸 | 敵人立繪 PNG | 256×256px | A cunning cartoon fox enemy, sly expression, orange fur, game monster style, transparent background |
| 28 | 普通敵人 - 黑熊 | 敵人立繪 PNG | 256×256px | A bulky cartoon bear enemy, muscular, dark brown fur, game monster style, transparent background |
| 29 | 普通敵人 - 毒蛇 | 敵人立繪 PNG | 256×256px | A venomous cartoon snake enemy, green scales, forked tongue, game monster style, transparent background |
| 30 | 普通敵人 - 鷹隼 | 敵人立繪 PNG | 256×256px | A fierce cartoon hawk enemy, sharp talons, golden feathers, game monster style, transparent background |
| 31 | 章節 Boss ×6 | Boss 立繪 PNG | 512×512px | A powerful cartoon [boss type] boss monster, imposing size, glowing aura, detailed armor/markings, game boss style, transparent background |

---

## 四、UI 介面素材 (UI Elements)

### 4.1 圖示 Icons

| # | 素材名稱 | 素材類型 | 素材尺寸 | Prompt |
|---|---------|---------|---------|--------|
| 32 | 金幣圖示 | UI Icon PNG | 64×64px | A shiny gold coin icon, simple cartoon style, slight 3D effect, transparent background |
| 33 | 鑽石圖示 | UI Icon PNG | 64×64px | A sparkling blue diamond icon, faceted gem, cartoon style, transparent background |
| 34 | 體力圖示 (閃電) | UI Icon PNG | 64×64px | A yellow lightning bolt energy icon, glowing, cartoon style, transparent background |
| 35 | 攻擊力圖示 (劍) | UI Icon PNG | 48×48px | A crossed swords attack icon, metallic, cartoon style, transparent background |
| 36 | 防禦力圖示 (盾) | UI Icon PNG | 48×48px | A shield defense icon, metallic blue, cartoon style, transparent background |
| 37 | 生命值圖示 (愛心) | UI Icon PNG | 48×48px | A red heart HP icon, glossy, cartoon style, transparent background |
| 38 | 星星評價 (空/半/滿) | UI Icon PNG | 48×48px ×3 | A star rating icon in three states: empty outline, half-filled gold, fully filled gold, game UI style |
| 39 | 鎖定圖示 | UI Icon PNG | 64×64px | A padlock locked icon, metallic grey, cartoon style, transparent background |
| 40 | 屬性圖示 ×5 | UI Icon PNG | 48×48px | Five elemental attribute icons: fire/water/nature/lightning/shadow, circular badge, colored ([5 colors]), game RPG style |
| 41 | 職業圖示 ×5 | UI Icon PNG | 48×48px | Five role icons: sword (striker), shield (defender), cross (supporter), bomb (destroyer), mask (infiltrator), simple silhouette style |
| 42 | 稀有度框 ×4 | UI 裝飾框 PNG | 128×128px | Card border frame for rarity: N(grey), R(blue), SR(purple), SSR(gold), ornate corner details, transparent center |
| 43 | 寶箱圖示 (關/開) | UI Icon PNG | 64×64px ×2 | A wooden treasure chest icon, two states: closed and open with golden glow, cartoon style |
| 44 | 返回按鈕 | UI Icon PNG | 48×48px | A left arrow back button, rounded, white on transparent, clean UI style |
| 45 | 暫停按鈕 | UI Icon PNG | 48×48px | A pause button icon, two vertical bars, white on transparent, clean UI style |
| 46 | 設定齒輪 | UI Icon PNG | 48×48px | A settings gear icon, metallic, cartoon style, transparent background |

### 4.2 按鈕與面板

| # | 素材名稱 | 素材類型 | 素材尺寸 | Prompt |
|---|---------|---------|---------|--------|
| 47 | 主按鈕背景 (紫色) | 9-patch PNG | 192×64px | A rounded rectangle button, purple gradient (#533483), slight bevel, game UI style |
| 48 | 次按鈕背景 (深藍) | 9-patch PNG | 192×64px | A rounded rectangle button, dark blue gradient (#0F3460), subtle border, game UI style |
| 49 | 警告按鈕 (紅色) | 9-patch PNG | 192×64px | A rounded rectangle button, red gradient (#E94560), slight glow, game UI style |
| 50 | 卡牌背景面板 | 9-patch PNG | 256×128px | A dark blue (#0F3460) rounded card panel, subtle gradient, thin border highlight, game UI style |
| 51 | 木紋頂欄 | UI 裝飾 PNG | 全寬×64px | A horizontal wooden plank bar, warm brown gradient (#C4A24E→#8B6914), medieval fantasy game style |
| 52 | 木紋底欄 | UI 裝飾 PNG | 全寬×64px | Same as top bar but mirrored grain direction, warm brown gradient, medieval fantasy game style |

### 4.3 進度條與狀態

| # | 素材名稱 | 素材類型 | 素材尺寸 | Prompt |
|---|---------|---------|---------|--------|
| 53 | HP 血條背景 | UI Element PNG | 128×16px | A dark rounded HP bar background, subtle inner shadow, game UI style |
| 54 | HP 血條填充 (綠→紅漸層) | UI Element PNG | 128×16px | A green-to-red gradient HP bar fill, glossy highlight, game UI style |
| 55 | 技能能量環 | UI Element PNG | 96×96px | A circular energy ring, segmented arc, glowing blue, transparent center, game UI style |
| 56 | 技能就緒光效 | 特效 PNG | 128×128px | A golden amber glow burst effect, radial light rays, transparent background, game UI style |
| 57 | 經驗值條背景 | UI Element PNG | 256×12px | A thin dark rounded EXP bar background, subtle texture, game UI style |
| 58 | 經驗值條填充 | UI Element PNG | 256×12px | A blue-purple gradient EXP bar fill, glossy highlight, game UI style |

---

## 五、背景素材 (Backgrounds)

| # | 素材名稱 | 素材類型 | 素材尺寸 | Prompt |
|---|---------|---------|---------|--------|
| 59 | 主頁面背景 | 背景圖 PNG/JPG | 1080×1920px | A dark navy blue (#1A1A2E) spy headquarters interior, subtle geometric patterns, neon accent lights, cyberpunk cat agency vibe |
| 60 | 戰鬥場景背景 - 第1章 森林 | 背景圖 PNG | 1080×1920px | A mysterious dark forest scene, moonlit, glowing fireflies, fantasy game background, vertical mobile layout |
| 61 | 戰鬥場景背景 - 第2章 洞窟 | 背景圖 PNG | 1080×1920px | A deep crystal cave scene, glowing minerals, underground river, fantasy game background, vertical mobile layout |
| 62 | 戰鬥場景背景 - 第3章 城堡 | 背景圖 PNG | 1080×1920px | A dark medieval castle interior, torchlit corridors, stone walls, fantasy game background, vertical mobile layout |
| 63 | 戰鬥場景背景 - 第4章 雪山 | 背景圖 PNG | 1080×1920px | A snowy mountain peak scene, blizzard effects, ice formations, fantasy game background, vertical mobile layout |
| 64 | 戰鬥場景背景 - 第5章 火山 | 背景圖 PNG | 1080×1920px | A volcanic landscape, flowing lava, dark red sky, fantasy game background, vertical mobile layout |
| 65 | 戰鬥場景背景 - 第6章 魔王城 | 背景圖 PNG | 1080×1920px | A dark demon lord castle throne room, ominous purple energy, dramatic lighting, final boss arena, fantasy game background |
| 66 | 方塊面板底圖 | 背景圖 PNG | 512×1024px | A dark subtle grid pattern background, slight blue tint, game puzzle board backing, clean |
| 67 | 商店背景 | 背景圖 PNG | 1080×1920px | A cozy cartoon shop interior, wooden shelves, glowing items, warm lighting, game shop background |
| 68 | 角色資訊背景 | 背景圖 PNG | 1080×1920px | A sleek dark tech interface background, holographic grid, spy agency dossier style, vertical mobile layout |

---

## 六、特效素材 (VFX / Animations)

| # | 素材名稱 | 素材類型 | 素材尺寸 | Prompt |
|---|---------|---------|---------|--------|
| 69 | 方塊消除爆破 | Sprite Sheet PNG | 512×128px (4 frames) | A block shattering explosion effect, 4-frame sequence, sparkle debris, transparent background |
| 70 | 連鎖波紋效果 | Sprite Sheet PNG | 512×128px (4 frames) | Expanding concentric ring ripple effect, 4-frame sequence, glowing edges, transparent background |
| 71 | Combo 火焰特效 | Sprite Sheet PNG | 256×64px (4 frames) | A small fire burst combo effect, 4 frames, orange-yellow flames, transparent background |
| 72 | 技能發動特效 ×5 | Sprite Sheet PNG | 512×128px ×5 (4 frames each) | Skill activation effect in [attribute color], energy burst with elemental theme, 4-frame sequence, transparent background |
| 73 | 勝利煙火特效 | Sprite Sheet PNG | 512×256px (8 frames) | Victory celebration fireworks, 8-frame sequence, colorful sparkles, transparent background |
| 74 | 傷害數字彈出 | 字型/預渲染 | 各數字 32×48px | Damage number font set (0-9), bold impact style, red with dark outline, game damage text |
| 75 | 能量球粒子 | 小圖 PNG | 16×16px ×5 | Five small glowing energy orb particles, one per attribute color, soft glow, circular, transparent background |
| 76 | 升級光柱特效 | Sprite Sheet PNG | 256×512px (6 frames) | A vertical golden light pillar level-up effect, 6-frame sequence, sparkles rising, transparent background |

---

## 七、音效素材 (Sound Effects - SFX)

| # | 素材名稱 | 素材類型 | 素材尺寸 | Prompt/Description |
|---|---------|---------|---------|--------|
| 77 | 方塊消除音效 | SFX WAV/OGG | ≤1秒 | Short crisp pop/shatter sound, satisfying puzzle block elimination |
| 78 | 連鎖消除音效 (2-5連) | SFX WAV/OGG | ≤1秒 ×4 | Ascending pitch chain combo sounds, each slightly higher and more rewarding |
| 79 | 方塊落下音效 | SFX WAV/OGG | ≤0.5秒 | Soft thud/click sound, blocks landing in place |
| 80 | 方塊移動音效 | SFX WAV/OGG | ≤0.5秒 | Quick swoosh/slide sound, block being dragged |
| 81 | 按鈕點擊音效 | SFX WAV/OGG | ≤0.3秒 | Clean UI tap/click, subtle and responsive |
| 82 | 技能發動音效 | SFX WAV/OGG | ≤2秒 | Energetic skill activation whoosh with magic sparkle |
| 83 | 攻擊命中音效 | SFX WAV/OGG | ≤1秒 | Impact hit sound, satisfying damage dealt |
| 84 | 暴擊音效 | SFX WAV/OGG | ≤1秒 | Heavy critical hit impact, more powerful than normal |
| 85 | 勝利音效 | SFX Jingle WAV/OGG | 2-3秒 | Victory fanfare jingle, triumphant and cheerful |
| 86 | 失敗音效 | SFX Jingle WAV/OGG | 2-3秒 | Defeat sound, sad/deflating but not harsh |
| 87 | 金幣獲得音效 | SFX WAV/OGG | ≤1秒 | Coin collect chime, satisfying cha-ching |
| 88 | 寶箱開啟音效 | SFX WAV/OGG | 1-2秒 | Treasure chest opening, magical sparkle reveal |
| 89 | 升級音效 | SFX WAV/OGG | 1-2秒 | Level up celebration chime, ascending notes |
| 90 | 進化音效 | SFX WAV/OGG | 2-3秒 | Evolution transformation sound, dramatic magical |
| 91 | 錯誤/不可操作音效 | SFX WAV/OGG | ≤0.5秒 | Error buzz/denied sound, gentle but clear |
| 92 | 頁面切換音效 | SFX WAV/OGG | ≤0.5秒 | Page transition swoosh, clean UI transition |

---

## 八、背景音樂 (BGM)

| # | 素材名稱 | 素材類型 | 素材尺寸 | Prompt/Description |
|---|---------|---------|---------|--------|
| 93 | 主頁面 BGM | BGM MP3/OGG | 60-120秒 loop | Chill spy agency lounge music, jazzy/electronic, relaxed but mysterious, loopable |
| 94 | 戰鬥 BGM (一般) | BGM MP3/OGG | 60-120秒 loop | Upbeat action puzzle battle music, energetic electronic, exciting but not overwhelming, loopable |
| 95 | 戰鬥 BGM (Boss 戰) | BGM MP3/OGG | 60-120秒 loop | Intense boss battle music, dramatic orchestral+electronic, high tension, loopable |
| 96 | 商店 BGM | BGM MP3/OGG | 60-90秒 loop | Cheerful shop browsing music, lighthearted, cozy, loopable |
| 97 | 勝利結算 BGM | BGM Jingle MP3/OGG | 10-15秒 | Victory results screen music, triumphant and rewarding |
| 98 | 失敗結算 BGM | BGM Jingle MP3/OGG | 5-10秒 | Defeat results screen music, melancholic but encouraging to retry |

---

## 九、字型素材 (Fonts)

| # | 素材名稱 | 素材類型 | 素材尺寸 | Prompt/Description |
|---|---------|---------|---------|--------|
| 99 | NotoSansTC-Regular | 字型 TTF | N/A | Google Noto Sans Traditional Chinese Regular - 主要 UI 文字 |
| 100 | NotoSansTC-Bold | 字型 TTF | N/A | Google Noto Sans Traditional Chinese Bold (weight: 700) - 標題/強調文字 |

---

## 素材統計摘要

| 分類 | 數量 | 備註 |
|------|------|------|
| 角色立繪 | 15 張 + 進化版約 30-45 張 | 含 15 頭像 + 15 小圖示 |
| 方塊 | 10 張 (5色 × 正常+暗化) + 5 粒子 | |
| 敵人 | 5 普通 + 6 Boss = 11 張 | 可按需擴充 |
| UI 圖示 | 約 30 張 | 含按鈕、面板、進度條 |
| 背景 | 10 張 | 6 戰鬥場景 + 4 系統頁面 |
| 特效 | 8 組 Sprite Sheet | |
| 音效 SFX | 16 個 | |
| 背景音樂 BGM | 6 首 | |
| 字型 | 2 個 | NotoSansTC |
| **合計** | **約 130+ 素材項目** | |

---

## 驗證方式
1. 將素材放入 `flutter_app/assets/` 對應子目錄
2. 更新 `pubspec.yaml` 的 assets 宣告
3. 逐步替換各 Widget 中的 emoji/CustomPaint 為 Image.asset()
4. 在模擬器上逐頁面檢查素材顯示是否正常
