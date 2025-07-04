-- 修復 leaderboards 表格
-- 如果診斷顯示 leaderboards 是 TABLE，請執行這個腳本

-- 1. 備份現有數據
CREATE TABLE leaderboards_backup AS 
SELECT * FROM leaderboards;

-- 2. 清空現有數據
TRUNCATE leaderboards;

-- 3. 重新填入正確的數據
INSERT INTO leaderboards (
    player_id, game_mode, username, avatar_url, 
    best_score, best_moves, best_time, games_played, latest_game,
    level_reached, created_at
)
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
        gr.score,
        gr.moves_used,
        gr.time_taken,
        COUNT(*) OVER (PARTITION BY gr.player_id, gr.game_mode) as games_played,
        MAX(gr.created_at) OVER (PARTITION BY gr.player_id, gr.game_mode) as latest_game,
        gr.level_reached,
        gr.created_at
    FROM game_records gr
    JOIN players p ON gr.player_id = p.id
)
SELECT 
    player_id, game_mode, username, avatar_url,
    score, moves_used, time_taken, games_played, latest_game,
    level_reached, created_at
FROM player_best_records 
WHERE rn = 1;

-- 4. 創建觸發器以保持數據同步
CREATE OR REPLACE FUNCTION update_leaderboard()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO leaderboards (
        player_id, game_mode, username, avatar_url,
        best_score, best_moves, best_time, games_played, latest_game,
        level_reached, created_at
    )
    SELECT 
        NEW.player_id, 
        NEW.game_mode, 
        p.username, 
        p.avatar_url,
        NEW.score, 
        NEW.moves_used, 
        NEW.time_taken, 
        1, 
        NEW.created_at,
        NEW.level_reached,
        NEW.created_at
    FROM players p WHERE p.id = NEW.player_id
    
    ON CONFLICT (player_id, game_mode) DO UPDATE SET
        best_score = CASE 
            WHEN leaderboards.game_mode = 'survival' THEN
                CASE WHEN NEW.time_taken > leaderboards.best_time OR 
                         (NEW.time_taken = leaderboards.best_time AND NEW.score > leaderboards.best_score)
                     THEN NEW.score ELSE leaderboards.best_score END
            WHEN leaderboards.game_mode = 'quest' THEN
                CASE WHEN NEW.score > leaderboards.best_score OR
                         (NEW.score = leaderboards.best_score AND NEW.moves_used < leaderboards.best_moves)
                     THEN NEW.score ELSE leaderboards.best_score END
            ELSE
                CASE WHEN NEW.score > leaderboards.best_score 
                     THEN NEW.score ELSE leaderboards.best_score END
        END,
        best_moves = CASE 
            WHEN leaderboards.game_mode = 'survival' THEN NEW.moves_used
            WHEN leaderboards.game_mode = 'quest' THEN
                CASE WHEN NEW.score > leaderboards.best_score OR
                         (NEW.score = leaderboards.best_score AND NEW.moves_used < leaderboards.best_moves)
                     THEN NEW.moves_used ELSE leaderboards.best_moves END
            ELSE
                CASE WHEN NEW.score > leaderboards.best_score 
                     THEN NEW.moves_used ELSE leaderboards.best_moves END
        END,
        best_time = CASE 
            WHEN leaderboards.game_mode = 'survival' THEN
                CASE WHEN NEW.time_taken > leaderboards.best_time 
                     THEN NEW.time_taken ELSE leaderboards.best_time END
            WHEN leaderboards.game_mode = 'quest' THEN
                CASE WHEN NEW.score > leaderboards.best_score OR
                         (NEW.score = leaderboards.best_score AND NEW.moves_used < leaderboards.best_moves)
                     THEN NEW.time_taken ELSE leaderboards.best_time END
            ELSE
                CASE WHEN NEW.score > leaderboards.best_score 
                     THEN NEW.time_taken ELSE leaderboards.best_time END
        END,
        games_played = leaderboards.games_played + 1,
        latest_game = NEW.created_at,
        level_reached = GREATEST(leaderboards.level_reached, NEW.level_reached);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 創建觸發器
DROP TRIGGER IF EXISTS update_leaderboard_trigger ON game_records;
CREATE TRIGGER update_leaderboard_trigger
    AFTER INSERT ON game_records
    FOR EACH ROW EXECUTE FUNCTION update_leaderboard();

-- 5. 驗證修復結果
SELECT 
    game_mode,
    COUNT(*) as total_players,
    MAX(best_score) as max_score,
    MAX(best_time) as max_time
FROM leaderboards
GROUP BY game_mode;

-- 6. 檢查 survival 模式的數據
SELECT 
    username,
    best_score,
    best_time,
    best_moves
FROM leaderboards 
WHERE game_mode = 'survival'
ORDER BY best_time DESC
LIMIT 5; 