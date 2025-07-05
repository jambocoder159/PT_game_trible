# 資料庫診斷指南

## 🔍 檢查 Table 與 View 的狀況

### 第一步：確認資料庫結構

```sql
-- 1. 檢查所有表格和視圖
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- 2. 檢查所有視圖
SELECT 
    schemaname,
    viewname,
    viewowner
FROM pg_views 
WHERE schemaname = 'public'
ORDER BY viewname;

-- 3. 檢查 leaderboards 是表格還是視圖
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'leaderboards';
```

### 第二步：檢查數據一致性

```sql
-- 檢查各表的記錄數量
SELECT 'players' as table_name, COUNT(*) as count FROM players
UNION ALL
SELECT 'game_records', COUNT(*) FROM game_records
UNION ALL
SELECT 'quest_records', COUNT(*) FROM quest_records
UNION ALL
SELECT 'player_quest_progress', COUNT(*) FROM player_quest_progress
UNION ALL
SELECT 'leaderboards', COUNT(*) FROM leaderboards;

-- 檢查 game_records 中的遊戲模式分布
SELECT 
    game_mode,
    COUNT(*) as records_count,
    COUNT(DISTINCT player_id) as unique_players,
    MAX(score) as max_score,
    MAX(time_taken) as max_time
FROM game_records
GROUP BY game_mode
ORDER BY records_count DESC;
```

### 第三步：檢查 leaderboards 表/視圖的數據

```sql
-- 檢查 leaderboards 的結構
\d leaderboards;

-- 檢查 leaderboards 的數據樣本
SELECT 
    player_id,
    game_mode,
    best_score,
    best_moves,
    best_time,
    games_played,
    latest_game
FROM leaderboards
LIMIT 10;

-- 檢查不同模式的 leaderboards 數據
SELECT 
    game_mode,
    COUNT(*) as player_count,
    AVG(best_score) as avg_score,
    MAX(best_score) as max_score,
    AVG(best_time) as avg_time,
    MAX(best_time) as max_time
FROM leaderboards
GROUP BY game_mode;
```

### 第四步：數據一致性檢查

```sql
-- 檢查 game_records 與 leaderboards 的數據一致性
WITH game_stats AS (
    SELECT 
        player_id,
        game_mode,
        MAX(score) as max_score_in_records,
        COUNT(*) as games_played_in_records,
        MAX(time_taken) as max_time_in_records
    FROM game_records
    GROUP BY player_id, game_mode
),
leaderboard_stats AS (
    SELECT 
        player_id,
        game_mode,
        best_score,
        games_played,
        best_time
    FROM leaderboards
)
SELECT 
    g.player_id,
    g.game_mode,
    g.max_score_in_records,
    l.best_score,
    CASE 
        WHEN g.max_score_in_records != l.best_score THEN 'MISMATCH' 
        ELSE 'OK' 
    END as score_status,
    g.games_played_in_records,
    l.games_played,
    CASE 
        WHEN g.games_played_in_records != l.games_played THEN 'MISMATCH' 
        ELSE 'OK' 
    END as games_status
FROM game_stats g
FULL OUTER JOIN leaderboard_stats l 
    ON g.player_id = l.player_id AND g.game_mode = l.game_mode
WHERE g.max_score_in_records != l.best_score 
   OR g.games_played_in_records != l.games_played
   OR g.player_id IS NULL 
   OR l.player_id IS NULL
LIMIT 20;
```

## 🔧 常見問題及解決方案

### 問題 1：leaderboards 是過期的視圖

如果 `leaderboards` 是一個基於舊邏輯的視圖：

```sql
-- 刪除舊視圖
DROP VIEW IF EXISTS leaderboards;

-- 重新創建正確的視圖
CREATE VIEW leaderboards AS
WITH player_best_records AS (
    SELECT 
        gr.player_id,
        gr.game_mode,
        p.username,
        p.avatar_url,
        -- 根據不同模式計算最佳記錄
        CASE 
            WHEN gr.game_mode = 'survival' THEN
                -- Survival 模式：按存活時間排序，再按分數
                ROW_NUMBER() OVER (
                    PARTITION BY gr.player_id, gr.game_mode 
                    ORDER BY gr.time_taken DESC, gr.score DESC
                )
            WHEN gr.game_mode = 'quest' THEN
                -- Quest 模式：按關卡數排序，再按步數和時間
                ROW_NUMBER() OVER (
                    PARTITION BY gr.player_id, gr.game_mode 
                    ORDER BY gr.score DESC, gr.moves_used ASC, gr.time_taken ASC
                )
            ELSE
                -- 其他模式：按分數排序
                ROW_NUMBER() OVER (
                    PARTITION BY gr.player_id, gr.game_mode 
                    ORDER BY gr.score DESC
                )
        END as rn,
        gr.score as best_score,
        gr.moves_used as best_moves,
        gr.time_taken as best_time,
        COUNT(*) OVER (PARTITION BY gr.player_id, gr.game_mode) as games_played,
        MAX(gr.created_at) OVER (PARTITION BY gr.player_id, gr.game_mode) as latest_game,
        gr.level_reached,
        gr.created_at
    FROM game_records gr
    JOIN players p ON gr.player_id = p.id
)
SELECT 
    player_id,
    game_mode,
    username,
    avatar_url,
    best_score,
    best_moves,
    best_time,
    games_played,
    latest_game,
    level_reached,
    created_at
FROM player_best_records 
WHERE rn = 1;
```

### 問題 2：leaderboards 是表格但數據過期

如果 `leaderboards` 是一個表格，需要同步數據：

```sql
-- 方案 A：清空並重新填入正確數據
TRUNCATE leaderboards;

INSERT INTO leaderboards (
    player_id, game_mode, username, avatar_url, 
    best_score, best_moves, best_time, games_played, latest_game
)
WITH player_best_records AS (
    SELECT 
        gr.player_id,
        gr.game_mode,
        p.username,
        p.avatar_url,
        -- 使用與上面視圖相同的邏輯
        CASE 
            WHEN gr.game_mode = 'survival' THEN
                ROW_NUMBER() OVER (
                    PARTITION BY gr.player_id, gr.game_mode 
                    ORDER BY gr.time_taken DESC, gr.score DESC
                )
            WHEN gr.game_mode = 'quest' THEN
                ROW_NUMBER() OVER (
                    PARTITION BY gr.player_id, gr.game_mode 
                    ORDER BY gr.score DESC, gr.moves_used ASC, gr.time_taken ASC
                )
            ELSE
                ROW_NUMBER() OVER (
                    PARTITION BY gr.player_id, gr.game_mode 
                    ORDER BY gr.score DESC
                )
        END as rn,
        gr.score,
        gr.moves_used,
        gr.time_taken,
        COUNT(*) OVER (PARTITION BY gr.player_id, gr.game_mode) as games_played,
        MAX(gr.created_at) OVER (PARTITION BY gr.player_id, gr.game_mode) as latest_game
    FROM game_records gr
    JOIN players p ON gr.player_id = p.id
)
SELECT 
    player_id, game_mode, username, avatar_url,
    score, moves_used, time_taken, games_played, latest_game
FROM player_best_records 
WHERE rn = 1;
```

### 問題 3：Survival 模式數據邏輯錯誤

檢查 survival 模式的數據：

```sql
-- 檢查 survival 模式的數據是否符合邏輯
SELECT 
    player_id,
    best_score,
    best_time,
    best_moves,
    -- 檢查時間是否合理（應該是存活時間）
    CASE 
        WHEN best_time > 0 AND best_time <= 300 THEN 'NORMAL'  -- 5分鐘內
        WHEN best_time > 300 THEN 'SUSPICIOUS'  -- 超過5分鐘
        ELSE 'INVALID'  -- 0或負數
    END as time_status
FROM leaderboards 
WHERE game_mode = 'survival'
ORDER BY best_time DESC;
```

## 🚀 建議的修復步驟

### 步驟 1：備份現有數據
```sql
CREATE TABLE leaderboards_backup_$(date +%Y%m%d) AS 
SELECT * FROM leaderboards;
```

### 步驟 2：執行診斷腳本
運行上面的診斷 SQL，找出具體問題

### 步驟 3：根據問題選擇解決方案
- 如果是視圖問題 → 重新創建視圖
- 如果是表格數據問題 → 重新同步數據
- 如果是邏輯問題 → 修正計算邏輯

### 步驟 4：驗證修復結果
```sql
-- 驗證修復後的數據
SELECT 
    game_mode,
    COUNT(*) as total_players,
    MIN(best_score) as min_score,
    MAX(best_score) as max_score,
    MIN(best_time) as min_time,
    MAX(best_time) as max_time
FROM leaderboards
GROUP BY game_mode;
```

## 💡 預防未來問題的建議

1. **使用觸發器自動更新 leaderboards**：
```sql
CREATE OR REPLACE FUNCTION update_leaderboard()
RETURNS TRIGGER AS $$
BEGIN
    -- 在 game_records 插入新記錄時自動更新 leaderboards
    INSERT INTO leaderboards (player_id, game_mode, best_score, best_moves, best_time, games_played, latest_game)
    VALUES (NEW.player_id, NEW.game_mode, NEW.score, NEW.moves_used, NEW.time_taken, 1, NEW.created_at)
    ON CONFLICT (player_id, game_mode) DO UPDATE SET
        best_score = CASE 
            WHEN leaderboards.game_mode = 'survival' THEN
                CASE WHEN NEW.time_taken > leaderboards.best_time OR 
                         (NEW.time_taken = leaderboards.best_time AND NEW.score > leaderboards.best_score)
                     THEN NEW.score ELSE leaderboards.best_score END
            ELSE
                CASE WHEN NEW.score > leaderboards.best_score 
                     THEN NEW.score ELSE leaderboards.best_score END
        END,
        best_time = CASE 
            WHEN leaderboards.game_mode = 'survival' THEN
                CASE WHEN NEW.time_taken > leaderboards.best_time 
                     THEN NEW.time_taken ELSE leaderboards.best_time END
            ELSE
                CASE WHEN NEW.score > leaderboards.best_score 
                     THEN NEW.time_taken ELSE leaderboards.best_time END
        END,
        games_played = leaderboards.games_played + 1,
        latest_game = NEW.created_at;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_leaderboard_trigger
    AFTER INSERT ON game_records
    FOR EACH ROW EXECUTE FUNCTION update_leaderboard();
```

2. **定期驗證數據一致性**
3. **使用視圖而非表格以確保數據即時性** 