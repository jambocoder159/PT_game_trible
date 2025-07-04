-- 步驟 1: 刪除現有的函數和視圖
DROP FUNCTION IF EXISTS get_survival_leaderboard(INTEGER);
DROP FUNCTION IF EXISTS get_quest_leaderboard(INTEGER);
DROP VIEW IF EXISTS leaderboards;

-- 步驟 2: 創建新的 leaderboards 視圖
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

-- 步驟 3: 驗證修正結果
SELECT 
    game_mode,
    COUNT(*) as total_players,
    MAX(best_score) as max_score,
    MAX(best_time) as max_time,
    AVG(best_time) as avg_time
FROM leaderboards
GROUP BY game_mode;

-- 步驟 4: 檢查 survival 模式的前 5 名（應該按時間降序排列）
SELECT 
    username,
    best_score,
    best_time,
    best_moves,
    'survival排行應該按時間降序' as note
FROM leaderboards 
WHERE game_mode = 'survival'
ORDER BY best_time DESC, best_score DESC
LIMIT 5;

-- 步驟 5: 檢查 quest 模式的前 5 名（應該按關卡數降序排列）
SELECT 
    username,
    best_score as highest_level,
    best_moves as moves_used,
    best_time as completion_time,
    'quest排行應該按關卡數降序' as note
FROM leaderboards 
WHERE game_mode = 'quest'
ORDER BY best_score DESC, best_moves ASC, best_time ASC
LIMIT 5; 