# 三消挑戰 - 遊戲流程說明

## 🎮 完整遊戲流程

### 1. 起始畫面 (`start-screen.html`)
- **功能**: 遊戲歡迎畫面
- **特色**: 
  - 動畫LOGO展示
  - 浮動方塊背景效果
  - 載入進度模擬
- **互動**: 點擊「開始遊戲」進入主選單
- **快捷鍵**: Enter 或 空白鍵

### 2. 主選單 (`main-menu.html`)
- **功能**: 遊戲主要導航中心
- **包含功能**:
  - 用戶登入/登出系統
  - 遊戲模式選擇
  - 排行榜入口
  - 個人統計
  - 遊戲設定
- **遊戲模式**:
  - 🎯 經典單排 (`game.html?mode=classic`)
  - 🚀 進階三排 (`game.html?mode=triple`)
  - ⏰ 限時挑戰 (`game.html?mode=timeLimit`)
- **快捷鍵**: 數字鍵 1-3 選擇模式

### 3. 遊戲頁面 (`game.html`)
- **功能**: 實際遊戲進行
- **特色**:
  - 統一遊戲引擎
  - 模組化模式切換
  - 即時成績保存
- **支援模式**: 通過 URL 參數切換不同模式

### 4. 排行榜 (`leaderboard.html`)
- **功能**: 查看全球排行榜和個人統計
- **特色**:
  - 分模式排行榜
  - 個人成績追蹤
  - 即時數據更新
- **返回**: 可返回主選單

## 📱 頁面跳轉邏輯

```
起始畫面 (start-screen.html)
    ↓ 點擊開始遊戲
主選單 (main-menu.html)
    ├─ 選擇模式 → 遊戲頁面 (game.html?mode=...)
    ├─ 排行榜 → 排行榜頁面 (leaderboard.html)
    ├─ 個人統計 → (開發中)
    └─ 設定 → (開發中)

遊戲頁面 (game.html)
    └─ 遊戲結束 → 可返回主選單

排行榜頁面 (leaderboard.html)
    ├─ 返回主選單 → 主選單 (main-menu.html)
    └─ 快速開始 → 遊戲頁面 (game.html?mode=...)
```

## 🎯 使用方式

### 第一次進入
1. 訪問 `start-screen.html`
2. 點擊開始遊戲
3. 進入主選單，可選擇登入
4. 選擇遊戲模式開始遊戲

### 直接進入遊戲
- 直接訪問 `main-menu.html` 進入主選單
- 或直接訪問 `game.html?mode=classic` 開始特定模式

### 查看排行榜
- 從主選單點擊排行榜
- 或直接訪問 `leaderboard.html`

## ⚙️ 配置說明

### 遊戲模式配置
- 所有模式配置在 `js/GameModes.js`
- 可輕鬆添加新模式
- 統一的遊戲引擎處理所有模式

### 用戶系統
- OAuth 登入支援（Google、GitHub、Discord）
- 自動成績保存
- 即時排行榜更新

## 🚀 部署建議

### 開發環境
1. 使用本地服務器運行（避免 CORS 問題）
2. 從 `start-screen.html` 開始測試完整流程

### 生產環境
1. 確保所有頁面都能正確訪問
2. 設定 Supabase 配置
3. 配置 OAuth 重定向 URL
4. 測試所有頁面跳轉

### URL 結構
```
https://your-domain.com/
├── start-screen.html (起始畫面)
├── main-menu.html (主選單)
├── game.html (遊戲頁面)
├── leaderboard.html (排行榜)
└── js/ (JavaScript 文件)
    ├── GameEngine.js
    ├── GameModes.js
    └── ... (其他模組)
```

## 📋 TODO 列表

### 已完成
- ✅ 起始畫面設計
- ✅ 主選單功能
- ✅ 排行榜頁面
- ✅ 遊戲模式整合
- ✅ 用戶系統整合

### 待完成
- ⏳ 個人統計詳細頁面
- ⏳ 遊戲設定頁面
- ⏳ 關於遊戲頁面
- ⏳ 素材資源整合
- ⏳ 音效系統
- ⏳ PWA 支援

這個流程設計讓你的遊戲有完整的用戶體驗，從歡迎到遊戲到成績追蹤，一氣呵成！ 