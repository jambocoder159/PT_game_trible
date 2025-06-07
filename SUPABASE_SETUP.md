# Supabase 設定指南

## 📋 概述

本遊戲使用 Supabase 作為後端服務，提供用戶認證和排行榜功能。

## 🚀 Supabase 項目設定

### 1. 創建 Supabase 項目

1. 前往 [Supabase](https://supabase.com/)
2. 點擊 "Start your project"
3. 創建新組織或選擇現有組織
4. 創建新項目：
   - Project name: `match3-game`
   - Database password: 設定強密碼 /83YuTwru4TA0Z8YS
   - Region: 選擇就近區域

### 2. 獲取項目配置

在項目 Dashboard > Settings > API 中獲取：
- Project URL 
    - admkbelthyyqngsnsxmm
- anon public key
    - eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkbWtiZWx0aHl5cW5nc25zeG1tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzMDU4NjMsImV4cCI6MjA2NDg4MTg2M30.NdpkqWnSJsb9bHQn8H7_CgpIkwu9f5kSzLrWV39ta2w

## 🗄️ 資料庫設定

### 建立資料表

在 Supabase Dashboard > Table Editor 中執行以下 SQL：

```sql
-- 建立玩家資料表
CREATE TABLE players (
    id UUID PRIMARY KEY DEFAULT auth.uid(),
    email TEXT UNIQUE NOT NULL,
    username TEXT NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 建立遊戲記錄表
CREATE TABLE game_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID REFERENCES players(id) ON DELETE CASCADE,
    game_mode TEXT NOT NULL,
    score INTEGER NOT NULL DEFAULT 0,
    moves_used INTEGER NOT NULL DEFAULT 0,
    time_taken INTEGER NOT NULL DEFAULT 0,
    level_reached INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 建立索引以提升查詢效能
CREATE INDEX idx_game_records_player_id ON game_records(player_id);
CREATE INDEX idx_game_records_game_mode ON game_records(game_mode);
CREATE INDEX idx_game_records_score ON game_records(score DESC);
CREATE INDEX idx_game_records_created_at ON game_records(created_at DESC);

-- 建立排行榜視圖
CREATE VIEW leaderboards AS
SELECT 
    game_mode,
    player_id,
    p.username,
    p.avatar_url,
    MAX(score) as best_score,
    MIN(moves_used) as best_moves,
    MIN(time_taken) as best_time,
    COUNT(*) as games_played,
    MAX(created_at) as latest_game
FROM game_records gr
JOIN players p ON p.id = gr.player_id
GROUP BY game_mode, player_id, p.username, p.avatar_url
ORDER BY best_score DESC;
```

### 設定 Row Level Security (RLS)

```sql
-- 啟用 RLS
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_records ENABLE ROW LEVEL SECURITY;

-- 玩家資料表權限
CREATE POLICY "用戶可以查看所有玩家基本資訊" ON players FOR SELECT USING (true);
CREATE POLICY "用戶可以更新自己的資料" ON players FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "用戶可以插入自己的資料" ON players FOR INSERT WITH CHECK (auth.uid() = id);

-- 遊戲記錄表權限
CREATE POLICY "用戶可以查看所有遊戲記錄" ON game_records FOR SELECT USING (true);
CREATE POLICY "用戶可以插入自己的遊戲記錄" ON game_records FOR INSERT WITH CHECK (auth.uid() = player_id);
CREATE POLICY "用戶可以查看自己的遊戲記錄" ON game_records FOR SELECT USING (true);
```

## 🔐 OAuth 設定

### Google OAuth

1. 前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 創建新項目或選擇現有項目
3. 啟用 Google+ API
4. 創建 OAuth 2.0 客戶端 ID：
   - 應用程式類型：網路應用程式
   - 授權重新導向 URI：`https://你的supabase項目.supabase.co/auth/v1/callback`
5. 在 Supabase Dashboard > Authentication > Providers 中設定 Google：
   - 啟用 Google provider
   - 輸入 Client ID 和 Client Secret

### GitHub OAuth

1. 前往 GitHub Settings > Developer settings > OAuth Apps
2. 創建新的 OAuth App：
   - Application name: `Match3 Game`
   - Homepage URL: `你的網站URL`
   - Authorization callback URL: `https://你的supabase項目.supabase.co/auth/v1/callback`
3. 在 Supabase Dashboard > Authentication > Providers 中設定 GitHub：
   - 啟用 GitHub provider
   - 輸入 Client ID 和 Client Secret

### Discord OAuth

1. 前往 [Discord Developer Portal](https://discord.com/developers/applications)
2. 創建新應用程式
3. 在 OAuth2 設定中：
   - Redirects: `https://你的supabase項目.supabase.co/auth/v1/callback`
   - Scopes: `identify`, `email`
4. 在 Supabase Dashboard > Authentication > Providers 中設定 Discord：
   - 啟用 Discord provider
   - 輸入 Client ID 和 Client Secret

## ⚙️ 前端配置

更新 `js/SupabaseAuth.js` 中的配置：

```javascript
// Supabase 配置
this.supabaseUrl = 'https://你的項目ID.supabase.co';
this.supabaseKey = '你的anon-public-key';
```

## 🔧 測試設定

1. 啟動本地服務器
2. 開啟遊戲頁面
3. 嘗試使用各種 OAuth 提供商登入
4. 玩一局遊戲並檢查成績是否正確保存
5. 查看排行榜是否正常顯示

## 📈 性能優化建議

### 資料庫索引
- 已建立必要的索引以提升查詢效能
- 可根據實際使用情況添加更多索引

### 快取策略
- 排行榜資料設定 5 分鐘快取
- 個人統計資料可增加快取時間

### 即時更新
- 使用 Supabase Realtime 功能實現排行榜即時更新
- 可選擇性啟用特定表的即時功能

## 🛡️ 安全注意事項

1. **RLS 設定**：確保所有表都啟用了適當的 Row Level Security
2. **API 金鑰**：不要將 service role key 暴露在前端代碼中
3. **資料驗證**：在前端和後端都進行資料驗證
4. **速率限制**：設定適當的 API 請求速率限制

## 📞 支援

如有問題，請查看：
- [Supabase 官方文檔](https://supabase.com/docs)
- [Supabase Discord 社群](https://discord.supabase.com/)
- 項目 Issues 頁面 