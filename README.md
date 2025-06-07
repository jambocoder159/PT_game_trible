# 三消遊戲框架

這是一個高效的模組化三消遊戲框架，解決了原版遊戲中大量重複代碼和維護困難的問題。

## 🚀 框架優勢

### 原版問題
- ❌ 每個遊戲模式一個HTML文件（4個文件）
- ❌ 大量重複的CSS和JavaScript代碼
- ❌ 修改一個小功能需要改多個地方
- ❌ 維護困難，容易出現不一致

### 框架解決方案
- ✅ 單一遊戲頁面，支援URL參數切換模式
- ✅ 模組化設計，代碼重用率高
- ✅ 一處修改，全部更新
- ✅ 易於維護和擴展新功能

## 📁 文件結構

```
game-framework/
├── game.html              # 主遊戲頁面
├── index_new.html          # 框架版介紹頁面
├── css/
│   └── game.css           # 統一樣式文件
└── js/
    ├── GameEngine.js      # 核心遊戲引擎
    ├── GameModes.js       # 遊戲模式配置
    └── UI.js              # UI組件管理器
```

## 🎮 使用方式

### 1. 直接訪問遊戲
```
game.html?mode=classic     # 經典單排模式
game.html?mode=double      # 快速雙排模式  
game.html?mode=triple      # 進階三排模式
game.html?mode=timeLimit   # 限時挑戰模式
```

### 2. 添加新遊戲模式

只需在 `js/GameModes.js` 中添加新配置：

```javascript
const GameModes = {
    // 現有模式...
    
    newMode: {
        numCols: 4,                    // 列數
        numRows: 12,                   // 行數
        theme: 'custom',               // 主題名稱
        hasSkills: true,               // 是否有技能
        hasTimer: false,               // 是否限時
        enableHorizontalMatches: true, // 是否啟用水平匹配
        title: '新模式',
        description: '新遊戲模式'
    }
};
```

### 3. 修改遊戲邏輯

所有遊戲邏輯統一在 `js/GameEngine.js` 中管理：
- 方塊移動和消除
- 匹配檢測算法
- 動畫效果
- 技能系統
- 計分系統

### 4. 調整UI和樣式

- `js/UI.js`：管理界面組件生成
- `css/game.css`：統一樣式定義

## 🔧 核心組件

### GameEngine 類
- **職責**：核心遊戲邏輯
- **特色**：
  - 統一處理單排和多排模式
  - 可配置的遊戲參數
  - 完整的動畫系統
  - 粒子效果支援

### GameModes 配置
- **職責**：遊戲模式參數定義
- **特色**：
  - 簡單的JSON配置
  - 支援所有遊戲特性開關
  - 易於擴展新模式

### UIManager 類
- **職責**：動態生成遊戲界面
- **特色**：
  - 根據模式配置自動調整UI
  - 響應式設計
  - 主題系統支援

## 🎯 新增功能示例

### 添加新遊戲模式

1. 在 `GameModes.js` 中定義：
```javascript
extreme: {
    numCols: 5,
    numRows: 15,
    theme: 'extreme',
    hasSkills: true,
    hasTimer: true,
    gameDuration: 30000,
    enableHorizontalMatches: true,
    title: '極限模式',
    description: '5列極限挑戰'
}
```

2. 在 `game.css` 中添加主題樣式：
```css
.theme-extreme { 
    background: linear-gradient(to bottom right, #dc2626, #7c2d12); 
}
```

3. 訪問：`game.html?mode=extreme`

### 修改計分系統

只需在 `GameEngine.js` 的 `processSingleWaveOfMatchesAndCascades` 方法中修改：
```javascript
// 原本：this.score += 10 * matches.size * internalCascadeCount;
// 修改為：
this.score += 15 * matches.size * internalCascadeCount; // 提高基礎分數
```

### 添加新技能

1. 在 `GameModes.js` 中的模式配置中啟用技能
2. 在 `GameEngine.js` 中添加技能邏輯
3. 在 `UI.js` 中添加技能按鈕

## 🔄 與原版對比

| 項目 | 原版 | 框架版 |
|------|------|--------|
| 檔案數量 | 5個HTML檔案 | 1個HTML檔案 |
| 代碼重複 | 大量重複 | 最小化重複 |
| 維護複雜度 | 高 | 低 |
| 擴展性 | 困難 | 簡單 |
| 一致性 | 容易不一致 | 自動保持一致 |

## 🚀 開始使用

1. 確保所有文件在正確的目錄結構中
2. 打開 `index_new.html` 查看介紹
3. 點擊遊戲模式按鈕開始遊戲
4. 或直接訪問 `game.html?mode=classic`

## 🛠️ 開發建議

1. **修改遊戲邏輯**：優先在 `GameEngine.js` 中修改
2. **添加新模式**：在 `GameModes.js` 中配置
3. **調整界面**：在 `UI.js` 和 `game.css` 中修改
4. **測試**：確保所有模式都正常工作

這個框架讓遊戲開發和維護變得更加高效，避免了重複工作，提高了代碼質量和一致性。 