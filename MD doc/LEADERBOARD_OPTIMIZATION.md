# 排行榜系統優化方案

## 📋 問題描述

目前系統中不同遊戲模式的排行規則不一致：
- **Survival 模式**: 存活時間越長排行越高（時間是正向指標）
- **Quest 模式**: 完成時間越短排行越高（時間是負向指標）
- **其他模式**: 主要以分數為準

現有的 `leaderboards` 表格中 `best_time` 和 `best_moves` 欄位含義模糊，導致排行邏輯混亂。

## 🔧 解決方案

### 方案一：重新設計 leaderboards 表格（推薦）

```sql
-- 重新設計 leaderboards 表格，增加模式特定欄位
ALTER TABLE leaderboards 
ADD COLUMN survival_time INTEGER DEFAULT 0,           -- 存活時間（秒）
ADD COLUMN completion_time INTEGER DEFAULT 0,         -- 完成時間（秒）
ADD COLUMN moves_used INTEGER DEFAULT 0,              -- 使用的移動次數
ADD COLUMN moves_remaining INTEGER DEFAULT 0,         -- 剩餘移動次數
ADD COLUMN highest_level INTEGER DEFAULT 0,           -- 最高關卡
ADD COLUMN efficiency_score DECIMAL(10,2) DEFAULT 0.0; -- 效率分數

-- 創建模式特定的索引
CREATE INDEX idx_leaderboards_survival_time ON leaderboards(survival_time DESC) WHERE game_mode = 'survival';
CREATE INDEX idx_leaderboards_completion_time ON leaderboards(completion_time ASC) WHERE game_mode = 'quest';
CREATE INDEX idx_leaderboards_highest_level ON leaderboards(highest_level DESC) WHERE game_mode = 'quest';
```

### 方案二：創建模式特定的視圖

```sql
-- Survival 模式排行榜視圖
CREATE VIEW survival_leaderboard AS
SELECT 
    player_id,
    username,
    avatar_url,
    best_score as score,
    best_time as survival_time,    -- 存活時間
    best_moves as total_moves,     -- 總移動次數
    games_played,
    latest_game,
    ROW_NUMBER() OVER (
        ORDER BY best_time DESC, best_score DESC
    ) as rank
FROM leaderboards l
JOIN players p ON l.player_id = p.id
WHERE l.game_mode = 'survival'
ORDER BY best_time DESC, best_score DESC;

-- Quest 模式排行榜視圖
CREATE VIEW quest_leaderboard AS
SELECT 
    player_id,
    username,
    avatar_url,
    best_score as highest_level,   -- 最高關卡
    best_moves as moves_used,      -- 使用步數
    best_time as completion_time,  -- 完成時間
    games_played,
    latest_game,
    ROW_NUMBER() OVER (
        ORDER BY best_score DESC, best_moves ASC, best_time ASC
    ) as rank
FROM leaderboards l
JOIN players p ON l.player_id = p.id
WHERE l.game_mode = 'quest'
ORDER BY best_score DESC, best_moves ASC, best_time ASC;
```

### 方案三：在應用層面處理（最簡單的過渡方案）

修改 `LeaderboardManager` 類別，明確區分不同模式的排行邏輯：

```javascript
// 獲取排行榜數據的統一方法
async getLeaderboardData(gameMode, limit = 50) {
    const modeConfig = this.getModeConfig(gameMode);
    
    let query = this.supabase
        .from('leaderboards')
        .select(`
            *,
            players!inner (
                username,
                avatar_url
            )
        `)
        .eq('game_mode', gameMode);
    
    // 根據模式應用不同的排序規則
    if (modeConfig.sortFields) {
        modeConfig.sortFields.forEach(field => {
            query = query.order(field.column, { ascending: field.ascending });
        });
    }
    
    const { data, error } = await query.limit(limit);
    
    if (error) throw error;
    
    return this.formatLeaderboardData(data, gameMode);
}

// 獲取遊戲模式配置
getModeConfig(gameMode) {
    const configs = {
        survival: {
            primaryMetric: 'survival_time',
            secondaryMetric: 'score',
            sortFields: [
                { column: 'best_time', ascending: false },    // 存活時間降序
                { column: 'best_score', ascending: false }     // 分數降序
            ],
            displayFormat: {
                primary: (value) => this.formatSurvivalTime(value),
                secondary: (value) => value.toLocaleString()
            }
        },
        quest: {
            primaryMetric: 'highest_level',
            secondaryMetric: 'moves_efficiency',
            sortFields: [
                { column: 'best_score', ascending: false },    // 關卡數降序
                { column: 'best_moves', ascending: true },     // 步數升序
                { column: 'best_time', ascending: true }       // 時間升序
            ],
            displayFormat: {
                primary: (value) => `關卡 ${value}`,
                secondary: (value) => `${value} 步`
            }
        },
        classic: {
            primaryMetric: 'score',
            sortFields: [
                { column: 'best_score', ascending: false }
            ],
            displayFormat: {
                primary: (value) => value.toLocaleString()
            }
        }
    };
    
    return configs[gameMode] || configs.classic;
}
```

## 🚀 實施建議

### 階段一：立即優化（應用層面）

1. **修改 LeaderboardManager 類別**，增加模式特定的排行邏輯
2. **更新前端顯示**，根據不同模式顯示不同的指標
3. **增加資料驗證**，確保不同模式的數據正確性

### 階段二：資料庫優化

1. **新增模式特定欄位**到 leaderboards 表格
2. **遷移現有數據**到新的欄位結構
3. **創建優化的索引**提升查詢效能

### 階段三：長期優化

1. **實施資料分析**，監控不同模式的遊戲平衡性
2. **動態調整排行規則**，基於玩家反饋優化
3. **增加更多統計指標**，如效率分數、一致性分數等

## 📈 預期效果

- **明確的排行規則**：每個模式都有清晰的排行邏輯
- **更好的玩家體驗**：玩家能清楚了解自己的排名依據
- **系統擴展性**：容易添加新的遊戲模式和排行規則
- **數據一致性**：避免不同模式間的數據混淆

## 🔍 監控指標

建議追蹤以下指標來評估優化效果：
- 不同模式的玩家參與度
- 排行榜更新頻率
- 玩家對排行系統的滿意度
- 系統查詢效能

## 💡 額外建議

1. **增加排行榜說明**：在 UI 中清楚說明每個模式的排行規則
2. **實施 A/B 測試**：測試不同的排行規則效果
3. **定期重新平衡**：根據遊戲數據調整排行權重
4. **考慮季度排行榜**：增加時間限制的競爭性 