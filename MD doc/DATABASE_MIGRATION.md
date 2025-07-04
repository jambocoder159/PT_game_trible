# 資料庫遷移腳本

## 🎯 目標
優化 leaderboards 表格以更好地支援不同遊戲模式的排行榜需求。

## 📋 遷移步驟

### 第一步：備份現有數據
```sql
-- 建立備份表
CREATE TABLE leaderboards_backup AS 
SELECT * FROM leaderboards;

-- 驗證備份
SELECT COUNT(*) FROM leaderboards_backup;
```

### 第二步：為 leaderboards 表格新增欄位
```sql
-- 新增模式特定的欄位
ALTER TABLE leaderboards 
ADD COLUMN survival_time INTEGER DEFAULT 0,           -- 存活時間（秒）
ADD COLUMN completion_time INTEGER DEFAULT 0,         -- 完成時間（秒）
ADD COLUMN moves_used INTEGER DEFAULT 0,              -- 使用的移動次數
ADD COLUMN moves_remaining INTEGER DEFAULT 0,         -- 剩餘移動次數
ADD COLUMN highest_level INTEGER DEFAULT 0,           -- 最高關卡
ADD COLUMN efficiency_score DECIMAL(10,2) DEFAULT 0.0, -- 效率分數
ADD COLUMN mode_specific_data JSONB DEFAULT '{}',     -- 模式特定的額外數據
ADD COLUMN ranking_metrics JSONB DEFAULT '{}';        -- 排行指標

-- 新增索引以提升查詢效能
CREATE INDEX idx_leaderboards_survival_time ON leaderboards(survival_time DESC) WHERE game_mode = 'survival';
CREATE INDEX idx_leaderboards_completion_time ON leaderboards(completion_time ASC) WHERE game_mode = 'quest';
CREATE INDEX idx_leaderboards_highest_level ON leaderboards(highest_level DESC) WHERE game_mode = 'quest';
CREATE INDEX idx_leaderboards_game_mode_score ON leaderboards(game_mode, best_score DESC);
```

### 第三步：遷移現有數據
```sql
-- 遷移 survival 模式數據
UPDATE leaderboards 
SET 
    survival_time = best_time,
    moves_used = best_moves,
    ranking_metrics = jsonb_build_object(
        'primary_metric', 'survival_time',
        'secondary_metric', 'score',
        'sort_order', 'survival_time_desc,score_desc'
    )
WHERE game_mode = 'survival';

-- 遷移 quest 模式數據
UPDATE leaderboards 
SET 
    highest_level = best_score,
    moves_used = best_moves,
    completion_time = best_time,
    ranking_metrics = jsonb_build_object(
        'primary_metric', 'highest_level',
        'secondary_metric', 'moves_used',
        'sort_order', 'level_desc,moves_asc,time_asc'
    )
WHERE game_mode = 'quest';

-- 遷移其他模式數據
UPDATE leaderboards 
SET 
    moves_used = best_moves,
    completion_time = best_time,
    ranking_metrics = jsonb_build_object(
        'primary_metric', 'score',
        'sort_order', 'score_desc'
    )
WHERE game_mode NOT IN ('survival', 'quest');
```

### 第四步：創建優化的排行榜視圖
```sql
-- Survival 模式排行榜視圖
CREATE OR REPLACE VIEW survival_leaderboard AS
SELECT 
    ROW_NUMBER() OVER (
        ORDER BY survival_time DESC, best_score DESC
    ) as rank,
    player_id,
    l.username,
    l.avatar_url,
    best_score as score,
    survival_time,
    moves_used,
    games_played,
    latest_game,
    created_at,
    updated_at
FROM leaderboards l
JOIN players p ON l.player_id = p.id
WHERE l.game_mode = 'survival'
ORDER BY survival_time DESC, best_score DESC;

-- Quest 模式排行榜視圖
CREATE OR REPLACE VIEW quest_leaderboard AS
SELECT 
    ROW_NUMBER() OVER (
        ORDER BY highest_level DESC, moves_used ASC, completion_time ASC
    ) as rank,
    player_id,
    l.username,
    l.avatar_url,
    highest_level,
    moves_used,
    completion_time,
    games_played,
    latest_game,
    created_at,
    updated_at
FROM leaderboards l
JOIN players p ON l.player_id = p.id
WHERE l.game_mode = 'quest'
ORDER BY highest_level DESC, moves_used ASC, completion_time ASC;

-- 通用排行榜視圖
CREATE OR REPLACE VIEW general_leaderboard AS
SELECT 
    ROW_NUMBER() OVER (
        PARTITION BY game_mode
        ORDER BY best_score DESC
    ) as rank,
    player_id,
    l.username,
    l.avatar_url,
    game_mode,
    best_score,
    moves_used,
    completion_time,
    games_played,
    latest_game,
    created_at,
    updated_at
FROM leaderboards l
JOIN players p ON l.player_id = p.id
WHERE l.game_mode NOT IN ('survival', 'quest')
ORDER BY game_mode, best_score DESC;
```

### 第五步：創建存儲過程以優化排行榜更新
```sql
-- 更新排行榜記錄的存儲過程
CREATE OR REPLACE FUNCTION update_leaderboard_record(
    p_player_id UUID,
    p_game_mode TEXT,
    p_score INTEGER,
    p_moves INTEGER,
    p_time INTEGER,
    p_level INTEGER DEFAULT 1
) RETURNS VOID AS $$
BEGIN
    INSERT INTO leaderboards (
        player_id, game_mode, best_score, best_moves, best_time, 
        survival_time, completion_time, moves_used, highest_level,
        games_played, latest_game, updated_at
    ) VALUES (
        p_player_id, p_game_mode, p_score, p_moves, p_time,
        CASE WHEN p_game_mode = 'survival' THEN p_time ELSE 0 END,
        CASE WHEN p_game_mode != 'survival' THEN p_time ELSE 0 END,
        p_moves,
        CASE WHEN p_game_mode = 'quest' THEN p_score ELSE p_level END,
        1, NOW(), NOW()
    )
    ON CONFLICT (player_id, game_mode) 
    DO UPDATE SET
        best_score = CASE 
            WHEN leaderboards.game_mode = 'survival' THEN
                CASE WHEN p_score > leaderboards.best_score OR 
                         (p_time > leaderboards.survival_time AND p_score >= leaderboards.best_score)
                     THEN p_score ELSE leaderboards.best_score END
            WHEN leaderboards.game_mode = 'quest' THEN
                CASE WHEN p_score > leaderboards.best_score OR
                         (p_score = leaderboards.best_score AND p_moves < leaderboards.moves_used)
                     THEN p_score ELSE leaderboards.best_score END
            ELSE
                CASE WHEN p_score > leaderboards.best_score 
                     THEN p_score ELSE leaderboards.best_score END
        END,
        best_moves = CASE 
            WHEN leaderboards.game_mode = 'survival' THEN p_moves
            WHEN leaderboards.game_mode = 'quest' THEN
                CASE WHEN p_score > leaderboards.best_score OR
                         (p_score = leaderboards.best_score AND p_moves < leaderboards.moves_used)
                     THEN p_moves ELSE leaderboards.best_moves END
            ELSE
                CASE WHEN p_score > leaderboards.best_score 
                     THEN p_moves ELSE leaderboards.best_moves END
        END,
        best_time = CASE 
            WHEN leaderboards.game_mode = 'survival' THEN
                CASE WHEN p_time > leaderboards.survival_time 
                     THEN p_time ELSE leaderboards.best_time END
            ELSE
                CASE WHEN p_score > leaderboards.best_score 
                     THEN p_time ELSE leaderboards.best_time END
        END,
        survival_time = CASE WHEN p_game_mode = 'survival' THEN
            CASE WHEN p_time > leaderboards.survival_time 
                 THEN p_time ELSE leaderboards.survival_time END
        ELSE leaderboards.survival_time END,
        completion_time = CASE WHEN p_game_mode != 'survival' THEN
            CASE WHEN p_score > leaderboards.best_score 
                 THEN p_time ELSE leaderboards.completion_time END
        ELSE leaderboards.completion_time END,
        moves_used = p_moves,
        highest_level = CASE WHEN p_game_mode = 'quest' THEN
            CASE WHEN p_score > leaderboards.highest_level 
                 THEN p_score ELSE leaderboards.highest_level END
        ELSE leaderboards.highest_level END,
        games_played = leaderboards.games_played + 1,
        latest_game = NOW(),
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;
```

### 第六步：驗證遷移結果
```sql
-- 檢查新欄位是否正確填入
SELECT 
    game_mode,
    COUNT(*) as total_records,
    AVG(CASE WHEN survival_time > 0 THEN survival_time END) as avg_survival_time,
    AVG(CASE WHEN highest_level > 0 THEN highest_level END) as avg_highest_level,
    AVG(moves_used) as avg_moves_used
FROM leaderboards
GROUP BY game_mode;

-- 檢查排行榜視圖
SELECT * FROM survival_leaderboard LIMIT 10;
SELECT * FROM quest_leaderboard LIMIT 10;
```

## 🔧 使用新的存儲過程

### 更新遊戲記錄範例
```sql
-- 更新 survival 模式記錄
SELECT update_leaderboard_record(
    'player_id_here',
    'survival',
    15000,  -- 分數
    120,    -- 移動次數
    180,    -- 存活時間（秒）
    1       -- 關卡（survival 模式固定為 1）
);

-- 更新 quest 模式記錄
SELECT update_leaderboard_record(
    'player_id_here',
    'quest',
    25,     -- 關卡數
    45,     -- 使用步數
    120,    -- 完成時間（秒）
    25      -- 最高關卡
);
```

## 📊 效能優化建議

1. **定期更新統計信息**：
```sql
ANALYZE leaderboards;
```

2. **監控查詢效能**：
```sql
-- 檢查最常用的查詢
SELECT * FROM pg_stat_statements WHERE query LIKE '%leaderboards%';
```

3. **定期清理過期數據**：
```sql
-- 清理 30 天前的遊戲記錄（如果需要）
DELETE FROM game_records WHERE created_at < NOW() - INTERVAL '30 days';
```

## ⚠️ 注意事項

1. **執行前請務必備份數據**
2. **在測試環境中先驗證所有腳本**
3. **遷移過程中建議暫停應用程式**
4. **遷移完成後檢查所有排行榜功能**

## 🎉 完成後的優勢

- ✅ 每個遊戲模式都有清晰的排行邏輯
- ✅ 查詢效能大幅提升
- ✅ 支援更複雜的排行規則
- ✅ 易於擴展新的遊戲模式
- ✅ 數據完整性和一致性得到保障 