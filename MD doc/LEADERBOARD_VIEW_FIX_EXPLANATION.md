# Leaderboards 視圖修正說明

## 🔍 問題分析

### 原始問題
您在 `MD doc/SUPABASE_SETUP.md` 中定義的 leaderboards 視圖存在邏輯錯誤：

```sql
CREATE VIEW leaderboards AS
SELECT 
    game_mode,
    player_id,
    p.username,
    p.avatar_url,
    MAX(score) as best_score,
    MIN(moves_used) as best_moves,      -- ❌ 問題：對所有模式都取最小值
    MIN(time_taken) as best_time,       -- ❌ 問題：對所有模式都取最小值
    COUNT(*) as games_played,
    MAX(created_at) as latest_game
FROM game_records gr
JOIN players p ON p.id = gr.player_id
GROUP BY game_mode, player_id, p.username, p.avatar_url
ORDER BY best_score DESC;
```

### 具體問題
1. **Survival 模式**：
   - `MIN(time_taken)` 找的是最短時間，但 survival 模式應該找**最長存活時間**
   - `MIN(moves_used)` 找的是最少移動，但應該找**最佳成績對應的移動次數**

2. **Quest 模式**：
   - 雖然 `MIN(moves_used)` 和 `MIN(time_taken)` 對 quest 模式是合理的（步數越少越好，時間越短越好）
   - 但是這樣的聚合方式會導致最高分數、最少步數、最短時間來自不同的遊戲記錄

## 🔧 修正方案

### 核心概念
使用 `ROW_NUMBER()` 窗口函數為每個玩家的每個遊戲模式找到**最佳單場記錄**，而不是使用聚合函數混合不同記錄的數據。

### 修正邏輯
```sql
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
        -- 保留完整的單場記錄數據
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
WHERE record_rank = 1  -- 只取每個玩家在每個模式下的最佳記錄
```

## 🎯 修正後的行為

### Survival 模式
- **排序邏輯**：存活時間越長排行越高，相同時間下分數越高排行越高
- **數據來源**：所有數據來自同一場遊戲記錄（存活時間最長的那場）
- **best_time**：真正的最長存活時間
- **best_moves**：該場遊戲中的實際移動次數

### Quest 模式
- **排序邏輯**：關卡數越高排行越高，相同關卡下步數越少排行越高，相同步數下時間越短排行越高
- **數據來源**：所有數據來自同一場遊戲記錄（最高關卡的最佳記錄）
- **best_score**：最高通關關卡數
- **best_moves**：達到最高關卡時使用的步數
- **best_time**：達到最高關卡時花費的時間

## 🚀 實施步驟

1. **執行修正腳本**：
   ```bash
   # 在 Supabase SQL Editor 中執行
   psql -f fix_leaderboards_view_corrected.sql
   ```

2. **驗證修正結果**：
   - 檢查 survival 模式排行榜是否按時間降序排列
   - 檢查 quest 模式排行榜是否按關卡數降序排列
   - 確保所有數據來自同一場遊戲記錄

3. **更新應用程式**：
   - 前端代碼不需要修改，因為視圖的欄位名稱保持不變
   - 可以使用新的 RPC 函數 `get_survival_leaderboard()` 和 `get_quest_leaderboard()` 來獲取排行榜

## 📊 額外優化

### 新增的 RPC 函數
1. **`get_survival_leaderboard(result_limit)`**：
   - 專門用於獲取 survival 模式排行榜
   - 自動按正確的邏輯排序
   - 包含排名信息

2. **`get_quest_leaderboard(result_limit)`**：
   - 專門用於獲取 quest 模式排行榜
   - 自動按正確的邏輯排序
   - 包含排名信息

### 使用方式
```sql
-- 獲取 survival 模式前 10 名
SELECT * FROM get_survival_leaderboard(10);

-- 獲取 quest 模式前 20 名
SELECT * FROM get_quest_leaderboard(20);
```

## 🎯 預期效果

修正後，您的排行榜將會：
- **Survival 模式**：按存活時間長短正確排序，時間越長排行越高
- **Quest 模式**：按關卡數高低正確排序，關卡越高排行越高
- **數據一致性**：每行數據都來自同一場遊戲，避免混合不同場次的數據
- **效能提升**：使用窗口函數和 RPC 函數提高查詢效率 