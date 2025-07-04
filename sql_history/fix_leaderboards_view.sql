-- 修復 leaderboards 視圖
-- 如果診斷顯示 leaderboards 是 VIEW，請執行這個腳本

-- 刪除舊的視圖
DROP VIEW IF EXISTS leaderboards;

-- 重新創建正確的 leaderboards 視圖
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

-- 驗證修復結果
SELECT 
    game_mode,
    COUNT(*) as total_players,
    MAX(best_score) as max_score,
    MAX(best_time) as max_time
FROM leaderboards
GROUP BY game_mode; 