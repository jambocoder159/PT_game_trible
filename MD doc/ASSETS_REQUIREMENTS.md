# 三消挑戰 - 素材需求清單

## 🎨 視覺素材需求

### 1. 遊戲LOGO與圖標

#### 主要LOGO
- **遊戲主LOGO**: `assets/images/logo/game-logo.png`
  - 尺寸: 512x512px (PNG, 透明背景)
  - 用途: 起始畫面、應用圖標
  - 設計風格: 現代、彩色、有吸引力

#### 應用圖標系列
- **Web圖標 (Favicon)**: `assets/images/icons/favicon.ico`
  - 尺寸: 32x32px, 16x16px
- **PWA圖標**: `assets/images/icons/`
  - 192x192px: `icon-192.png`
  - 512x512px: `icon-512.png`
  - 用途: 手機桌面圖標

### 2. 遊戲方塊素材

#### 基礎方塊 (建議尺寸: 64x64px)
- **紅色方塊**: `assets/images/blocks/red.png`
- **藍色方塊**: `assets/images/blocks/blue.png`
- **綠色方塊**: `assets/images/blocks/green.png`
- **黃色方塊**: `assets/images/blocks/yellow.png`
- **紫色方塊**: `assets/images/blocks/purple.png`

#### 特殊效果方塊
- **發光方塊**: 每種顏色的發光版本
  - 檔名格式: `red-glow.png`, `blue-glow.png` 等
- **破碎方塊**: 消除動畫用
  - 檔名格式: `red-broken.png`, `blue-broken.png` 等

### 3. UI界面素材

#### 按鈕背景
- **主要按鈕**: `assets/images/ui/button-primary.png`
  - 尺寸: 200x60px (可縮放)
  - 風格: 圓角、漸層
- **次要按鈕**: `assets/images/ui/button-secondary.png`
- **技能按鈕**: `assets/images/ui/button-skill.png`

#### 面板背景
- **遊戲面板**: `assets/images/ui/game-panel.png`
  - 尺寸: 400x600px (可調整)
  - 風格: 半透明、現代感
- **統計面板**: `assets/images/ui/stats-panel.png`
- **排行榜面板**: `assets/images/ui/leaderboard-panel.png`

#### 圖標系列 (建議尺寸: 48x48px)
- **分數圖標**: `assets/images/icons/score.png` 🏆
- **時間圖標**: `assets/images/icons/time.png` ⏰
- **連擊圖標**: `assets/images/icons/combo.png` ⚡
- **技能圖標**: `assets/images/icons/skill.png` 🎯
- **設定圖標**: `assets/images/icons/settings.png` ⚙️
- **排行榜圖標**: `assets/images/icons/leaderboard.png` 📊

### 4. 背景與裝飾

#### 背景圖片
- **主選單背景**: `assets/images/backgrounds/main-menu.jpg`
  - 尺寸: 1920x1080px
  - 風格: 科幻、漸層、低多邊體
- **遊戲背景**: `assets/images/backgrounds/game-bg.jpg`
  - 尺寸: 1920x1080px
  - 風格: 簡潔、不搶眼

#### 裝飾元素
- **粒子效果素材**: `assets/images/effects/`
  - 星星粒子: `star-particle.png` (16x16px)
  - 光點粒子: `light-particle.png` (12x12px)
  - 爆炸效果: `explosion-*.png` (動畫序列)

#### 模式特色圖標 (建議尺寸: 128x128px)
- **經典模式**: `assets/images/modes/classic.png` 🎯
- **三排模式**: `assets/images/modes/triple.png` 🚀  
- **限時模式**: `assets/images/modes/time-limit.png` ⏰

## 🔊 音效素材需求

### 1. 基礎音效

#### 界面音效
- **點擊音效**: `assets/sounds/ui/click.mp3`
  - 時長: 0.1-0.2秒
  - 風格: 清脆、現代
- **按鈕懸停**: `assets/sounds/ui/hover.mp3`
- **模態框出現**: `assets/sounds/ui/modal-open.mp3`
- **模態框關閉**: `assets/sounds/ui/modal-close.mp3`

#### 遊戲音效
- **方塊移動**: `assets/sounds/game/block-move.mp3`
- **方塊匹配**: `assets/sounds/game/match.mp3`
- **方塊消除**: `assets/sounds/game/eliminate.mp3`
- **連擊音效**: `assets/sounds/game/combo-*.mp3` (1-5級)
- **技能使用**: `assets/sounds/game/skill-use.mp3`

#### 成就音效
- **得分**: `assets/sounds/achievement/score.mp3`
- **新記錄**: `assets/sounds/achievement/new-record.mp3`
- **遊戲結束**: `assets/sounds/achievement/game-over.mp3`
- **勝利**: `assets/sounds/achievement/victory.mp3`

### 2. 背景音樂

#### 環境音樂 (建議時長: 2-3分鐘, 可循環)
- **主選單音樂**: `assets/sounds/music/main-menu.mp3`
  - 風格: 輕快、現代電子音樂
- **遊戲背景音樂**: `assets/sounds/music/gameplay.mp3`
  - 風格: 集中注意力、不搶眼
- **限時模式音樂**: `assets/sounds/music/time-attack.mp3`
  - 風格: 緊張、節奏感強

## 📱 響應式設計考量

### 螢幕尺寸適配
- **桌面**: 1920x1080px 為基準
- **平板**: 1024x768px 為基準  
- **手機**: 375x667px 為基準

### 素材準備建議
- 所有圖片提供 @1x, @2x, @3x 版本（高分辨率設備）
- SVG 格式優先（可縮放）
- PNG 格式用於複雜圖像
- JPG 格式用於背景圖片

## 🎨 設計風格指南

### 色彩主題
- **主色調**: 紫色到藍色漸層 (#667eea → #764ba2)
- **強調色**: 金黃色 (#FFD700) - 用於重要元素
- **方塊顏色**: 
  - 紅色: #F87171
  - 藍色: #60A5FA  
  - 綠色: #4ADE80
  - 黃色: #FACC15
  - 紫色: #A78BFA

### 設計風格
- **整體風格**: 現代、簡潔、科技感
- **按鈕風格**: 圓角、漸層、陰影效果
- **面板風格**: 毛玻璃效果、半透明
- **字體**: 清晰易讀、現代感

## 📂 建議目錄結構

```
assets/
├── images/
│   ├── logo/
│   │   └── game-logo.png
│   ├── icons/
│   │   ├── favicon.ico
│   │   ├── icon-192.png
│   │   ├── icon-512.png
│   │   ├── score.png
│   │   ├── time.png
│   │   └── ...
│   ├── blocks/
│   │   ├── red.png
│   │   ├── blue.png
│   │   ├── red-glow.png
│   │   └── ...
│   ├── ui/
│   │   ├── button-primary.png
│   │   ├── button-secondary.png
│   │   └── ...
│   ├── backgrounds/
│   │   ├── main-menu.jpg
│   │   └── game-bg.jpg
│   ├── modes/
│   │   ├── classic.png
│   │   ├── triple.png
│   │   └── time-limit.png
│   └── effects/
│       ├── star-particle.png
│       └── explosion-1.png
├── sounds/
│   ├── ui/
│   │   ├── click.mp3
│   │   └── hover.mp3
│   ├── game/
│   │   ├── match.mp3
│   │   └── eliminate.mp3
│   ├── achievement/
│   │   ├── score.mp3
│   │   └── victory.mp3
│   └── music/
│       ├── main-menu.mp3
│       └── gameplay.mp3
└── fonts/
    ├── game-font.woff2
    └── ui-font.woff2
```

## 🔧 技術規格

### 圖片格式建議
- **PNG**: 透明背景、UI元素、方塊
- **JPG**: 背景圖片、不需透明的大圖
- **SVG**: 簡單圖標、可縮放元素
- **WebP**: 新型格式，檔案更小（備選）

### 音效格式建議
- **MP3**: 相容性最佳
- **OGG**: 檔案較小（備選）
- **WAV**: 最高品質（僅重要音效）

### 檔案大小建議
- 單個圖片 < 100KB
- 音效文件 < 500KB
- 背景音樂 < 2MB
- 總素材包 < 20MB

## 📋 優先級排序

### 第一階段（必需）
1. 遊戲LOGO
2. 基礎方塊素材（5種顏色）
3. 基本UI按鈕
4. 基礎音效（點擊、匹配、消除）

### 第二階段（增強）
1. 特殊效果方塊
2. 背景圖片
3. 模式圖標
4. 背景音樂

### 第三階段（完善）
1. 粒子效果素材
2. 動畫序列
3. 高分辨率版本
4. 完整音效庫

這個素材清單可以讓你的遊戲有專業的視覺和聽覺體驗！你可以先從第一階段的必需素材開始製作或尋找。 