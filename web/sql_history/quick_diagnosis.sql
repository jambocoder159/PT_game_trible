-- 快速診斷腳本
-- 請在 Supabase SQL Editor 中執行

-- 1. 確認 leaderboards 是 table 還是 view
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'leaderboards';

-- 2. 檢查 survival 模式的數據是否合理
SELECT 
    username,
    best_score,
    best_time,
    best_moves,
    latest_game,
    CASE 
        WHEN best_time > LAG(best_time, 1, best_time + 1) OVER (ORDER BY best_time DESC) THEN '✅ 正確排序'
        ELSE '❌ 排序錯誤'
    END as sort_status
FROM leaderboards 
WHERE game_mode = 'survival'
ORDER BY best_time DESC
LIMIT 10;

-- 2a. 專門檢查 survival 模式的排序邏輯
SELECT 
    'survival模式排序檢查' as check_type,
    COUNT(*) as total_records,
    COUNT(CASE WHEN best_time > 0 THEN 1 END) as records_with_time,
    MAX(best_time) as max_survival_time,
    MIN(best_time) as min_survival_time,
    AVG(best_time) as avg_survival_time
FROM leaderboards 
WHERE game_mode = 'survival';

-- 2b. 檢查 quest 模式的數據是否合理
SELECT 
    username,
    best_score as highest_level,
    best_moves as moves_used,
    best_time as completion_time,
    CASE 
        WHEN best_score > LAG(best_score, 1, best_score + 1) OVER (ORDER BY best_score DESC) THEN '✅ 正確排序'
        ELSE '❌ 排序錯誤'
    END as sort_status
FROM leaderboards 
WHERE game_mode = 'quest'
ORDER BY best_score DESC, best_moves ASC, best_time ASC
LIMIT 10;

-- 3. 比較 game_records 和 leaderboards 的差異
SELECT 
    'game_records' as source,
    game_mode,
    COUNT(*) as total_records,
    COUNT(DISTINCT player_id) as unique_players,
    MAX(score) as max_score,
    MAX(time_taken) as max_time
FROM game_records
GROUP BY game_mode
UNION ALL
SELECT 
    'leaderboards' as source,
    game_mode,
    COUNT(*) as total_records,
    COUNT(DISTINCT player_id) as unique_players,
    MAX(best_score) as max_score,
    MAX(best_time) as max_time
FROM leaderboards
GROUP BY game_mode
ORDER BY source, game_mode; 