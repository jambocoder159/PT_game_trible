-- 修正 leaderboards 視圖以正確處理 survival 模式
-- 問題：當前視圖使用 MIN(time_taken) 和 MIN(moves_used)，但 survival 模式應該找最長時間和對應的移動次數

-- 刪除舊的 leaderboards 視圖
DROP VIEW IF EXISTS leaderboards;

-- 創建新的 leaderboards 視圖
CREATE VIEW leaderboards AS
WITH player_best_records AS (
    SELECT 
        gr.player_id,
        gr.game_mode,
        p.username,
        p.avatar_url,
        CASE 
            WHEN gr.game_mode = 'survival' THEN
                -- Survival 模式：按存活時間排序（越長越好），再按分數排序
                ROW_NUMBER() OVER (
                    PARTITION BY gr.player_id, gr.game_mode 
                    ORDER BY gr.time_taken DESC, gr.score DESC
                )
            WHEN gr.game_mode = 'quest' THEN
                -- Quest 模式：按關卡數排序（越高越好），再按步數排序（越少越好）
                ROW_NUMBER() OVER (
                    PARTITION BY gr.player_id, gr.game_mode 
                    ORDER BY gr.score DESC, gr.moves_used ASC, gr.time_taken ASC
                )
            ELSE
                -- 其他模式：按分數排序
                ROW_NUMBER() OVER (
                    PARTITION BY gr.player_id, gr.game_mode 
                    ORDER BY gr.score DESC, gr.moves_used ASC, gr.time_taken ASC
                )
        END as record_rank,
        gr.score,
        gr.moves_used,
        gr.time_taken,
        gr.level_reached,
        gr.created_at,
        COUNT(*) OVER (PARTITION BY gr.player_id, gr.game_mode) as games_played,
        MAX(gr.created_at) OVER (PARTITION BY gr.player_id, gr.game_mode) as latest_game
    FROM game_records gr
    JOIN players p ON p.id = gr.player_id
)
SELECT 
    game_mode,
    player_id,
    username,
    avatar_url,
    score as best_score,
    moves_used as best_moves,
    time_taken as best_time,
    games_played,
    latest_game,
    level_reached,
    created_at
FROM player_best_records 
WHERE record_rank = 1
ORDER BY 
    game_mode,
    CASE 
        WHEN game_mode = 'survival' THEN time_taken 
        ELSE score 
    END DESC,
    CASE 
        WHEN game_mode = 'survival' THEN score 
        ELSE moves_used 
    END DESC;

-- 驗證修正結果
SELECT 
    game_mode,
    COUNT(*) as total_players,
    MAX(best_score) as max_score,
    MAX(best_time) as max_time,
    AVG(best_time) as avg_time
FROM leaderboards
GROUP BY game_mode;

-- 專門檢查 survival 模式的前 10 名（應該按時間排序）
SELECT 
    username,
    best_score,
    best_time,
    best_moves,
    'survival排行應該按時間降序' as note
FROM leaderboards 
WHERE game_mode = 'survival'
ORDER BY best_time DESC, best_score DESC
LIMIT 10;

-- 檢查 quest 模式的前 10 名（應該按關卡數排序）
SELECT 
    username,
    best_score as highest_level,
    best_moves as moves_used,
    best_time as completion_time,
    'quest排行應該按關卡數降序' as note
FROM leaderboards 
WHERE game_mode = 'quest'
ORDER BY best_score DESC, best_moves ASC, best_time ASC
LIMIT 10;

-- 額外：刪除現有的 RPC 函數（如果存在）
DROP FUNCTION IF EXISTS get_survival_leaderboard(INTEGER);
DROP FUNCTION IF EXISTS get_quest_leaderboard(INTEGER);

-- 創建一個 RPC 函數來獲取正確的 survival 排行榜
CREATE OR REPLACE FUNCTION get_survival_leaderboard(result_limit INTEGER DEFAULT 50)
RETURNS TABLE (
    rank INTEGER,
    player_id UUID,
    username TEXT,
    avatar_url TEXT,
    score INTEGER,
    time_taken INTEGER,
    moves_used INTEGER,
    games_played BIGINT,
    latest_game TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ROW_NUMBER() OVER (ORDER BY l.best_time DESC, l.best_score DESC)::INTEGER as rank,
        l.player_id,
        l.username,
        l.avatar_url,
        l.best_score as score,
        l.best_time as time_taken,
        l.best_moves as moves_used,
        l.games_played,
        l.latest_game
    FROM leaderboards l
    WHERE l.game_mode = 'survival'
    ORDER BY l.best_time DESC, l.best_score DESC
    LIMIT result_limit;
END;
$$ LANGUAGE plpgsql;

-- 創建一個 RPC 函數來獲取正確的 quest 排行榜
CREATE OR REPLACE FUNCTION get_quest_leaderboard(result_limit INTEGER DEFAULT 50)
RETURNS TABLE (
    rank INTEGER,
    player_id UUID,
    username TEXT,
    avatar_url TEXT,
    highest_level_cleared INTEGER,
    moves_used INTEGER,
    time_taken INTEGER,
    achieved_at TIMESTAMP WITH TIME ZONE,
    progress_updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ROW_NUMBER() OVER (ORDER BY l.best_score DESC, l.best_moves ASC, l.best_time ASC)::INTEGER as rank,
        l.player_id,
        l.username,
        l.avatar_url,
        l.best_score as highest_level_cleared,
        l.best_moves as moves_used,
        l.best_time as time_taken,
        l.created_at as achieved_at,
        l.latest_game as progress_updated_at
    FROM leaderboards l
    WHERE l.game_mode = 'quest'
    ORDER BY l.best_score DESC, l.best_moves ASC, l.best_time ASC
    LIMIT result_limit;
END;
$$ LANGUAGE plpgsql; 