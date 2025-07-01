# 闖關模式資料庫設置指南

## 概述
闖關模式需要兩個新的資料表來記錄玩家的關卡進度和詳細記錄。

## 資料表結構

### 1. quest_records (關卡記錄表)
記錄每次闖關的詳細資料。

```sql
CREATE TABLE quest_records (
    id BIGSERIAL PRIMARY KEY,
    player_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    level_number INTEGER NOT NULL,
    chapter INTEGER NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    score INTEGER NOT NULL DEFAULT 0,
    moves_used INTEGER NOT NULL DEFAULT 0,
    moves_remaining INTEGER NOT NULL DEFAULT 0,
    max_combo INTEGER NOT NULL DEFAULT 0,
    action_count INTEGER NOT NULL DEFAULT 0,
    time_taken INTEGER NOT NULL DEFAULT 0, -- 秒數
    enemy_name TEXT,
    enemy_max_hp INTEGER,
    damage_dealt INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 建立索引以提升查詢效能
CREATE INDEX idx_quest_records_player_level ON quest_records(player_id, level_number);
CREATE INDEX idx_quest_records_player_chapter ON quest_records(player_id, chapter);
CREATE INDEX idx_quest_records_completed ON quest_records(player_id, is_completed);
CREATE INDEX idx_quest_records_created_at ON quest_records(created_at);
```

### 2. player_quest_progress (玩家進度表)
記錄每個玩家的最高通關關卡。

```sql
CREATE TABLE player_quest_progress (
    id BIGSERIAL PRIMARY KEY,
    player_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    highest_level_cleared INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 建立唯一索引確保每個玩家只有一筆記錄
CREATE UNIQUE INDEX idx_player_quest_progress_player ON player_quest_progress(player_id);
```

## Row Level Security (RLS) 設置

### quest_records 表的 RLS 政策

```sql
-- 啟用 RLS
ALTER TABLE quest_records ENABLE ROW LEVEL SECURITY;

-- 允許用戶查看自己的記錄
CREATE POLICY "Users can view own quest records" ON quest_records
    FOR SELECT USING (auth.uid() = player_id);

-- 允許用戶插入自己的記錄
CREATE POLICY "Users can insert own quest records" ON quest_records
    FOR INSERT WITH CHECK (auth.uid() = player_id);

-- 不允許用戶更新或刪除記錄（保持資料完整性）
```

### player_quest_progress 表的 RLS 政策

```sql
-- 啟用 RLS
ALTER TABLE player_quest_progress ENABLE ROW LEVEL SECURITY;

-- 允許用戶查看自己的進度
CREATE POLICY "Users can view own quest progress" ON player_quest_progress
    FOR SELECT USING (auth.uid() = player_id);

-- 允許用戶插入和更新自己的進度
CREATE POLICY "Users can upsert own quest progress" ON player_quest_progress
    FOR ALL USING (auth.uid() = player_id);
```

## 設置步驟

1. **登入 Supabase Dashboard**
   - 前往您的 Supabase 專案
   - 點選左側選單的「SQL Editor」

2. **執行資料表創建腳本**
   - 複製上述的 `quest_records` 表創建腳本
   - 在 SQL Editor 中執行
   - 複製上述的 `player_quest_progress` 表創建腳本
   - 在 SQL Editor 中執行

3. **設置 RLS 政策**
   - 複製上述的 RLS 政策腳本
   - 逐一在 SQL Editor 中執行

4. **驗證設置**
   - 在 Supabase Dashboard 的「Table Editor」中確認兩個表都已創建
   - 確認 RLS 已啟用（表名稱旁會顯示鎖頭圖示）

## 資料欄位說明

### quest_records 表
- `player_id`: 玩家 ID（外鍵到 auth.users）
- `level_number`: 關卡編號（1-30）
- `chapter`: 章節編號（1-3）
- `is_completed`: 是否通關
- `score`: 獲得分數
- `moves_used`: 使用步數
- `moves_remaining`: 剩餘步數
- `max_combo`: 最高連擊
- `action_count`: 總操作次數
- `time_taken`: 用時（秒）
- `enemy_name`: 敵人名稱
- `enemy_max_hp`: 敵人最大血量
- `damage_dealt`: 造成傷害

### player_quest_progress 表
- `player_id`: 玩家 ID（外鍵到 auth.users）
- `highest_level_cleared`: 最高通關關卡編號
- `updated_at`: 最後更新時間

## 查詢範例

### 獲取玩家最高通關關卡
```sql
SELECT highest_level_cleared 
FROM player_quest_progress 
WHERE player_id = auth.uid();
```

### 獲取特定關卡的最佳成績
```sql
SELECT * FROM quest_records 
WHERE player_id = auth.uid() 
  AND level_number = 5 
  AND is_completed = true 
ORDER BY score DESC 
LIMIT 1;
```

### 獲取章節通關統計
```sql
SELECT 
    chapter,
    COUNT(*) as attempts,
    COUNT(CASE WHEN is_completed THEN 1 END) as clears,
    MAX(score) as best_score
FROM quest_records 
WHERE player_id = auth.uid() 
GROUP BY chapter 
ORDER BY chapter;
```

## 注意事項

1. **資料完整性**: quest_records 表不允許更新或刪除，確保歷史記錄的完整性
2. **效能考量**: 已建立適當的索引來提升查詢效能
3. **安全性**: 使用 RLS 確保用戶只能存取自己的資料
4. **擴展性**: 表結構設計可以輕鬆支援未來的功能擴展 