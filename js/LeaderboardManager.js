// 排行榜管理器
class LeaderboardManager {
    constructor(supabaseAuth) {
        this.supabaseAuth = supabaseAuth;
        this.supabase = supabaseAuth.supabase;
        this.cache = new Map();
        this.cacheTimeout = 5 * 60 * 1000; // 5分鐘快取
        this.currentUser = null; // 添加當前用戶屬性
        
        // 遊戲模式配置
        this.modeConfigs = {
            survival: {
                name: '存活模式',
                primaryMetric: 'survival_time',
                secondaryMetric: 'score',
                sortFields: [
                    { column: 'best_time', ascending: false },    // 存活時間降序（越長越好）
                    { column: 'best_score', ascending: false }     // 分數降序
                ],
                displayFormat: {
                    primary: (value) => this.formatSurvivalTime(value),
                    secondary: (value) => value.toLocaleString(),
                    primaryLabel: '存活時間',
                    secondaryLabel: '分數'
                },
                description: '存活時間越長排行越高，相同時間下分數越高排行越高',
                metrics: {
                    time: { label: '存活時間', direction: 'higher_better' },
                    score: { label: '分數', direction: 'higher_better' },
                    moves: { label: '總移動', direction: 'neutral' }
                }
            },
            quest: {
                name: '任務模式',
                primaryMetric: 'highest_level',
                secondaryMetric: 'moves_efficiency',
                sortFields: [
                    { column: 'best_score', ascending: false },    // 關卡數降序
                    { column: 'best_moves', ascending: true },     // 步數升序（越少越好）
                    { column: 'best_time', ascending: true }       // 時間升序（越短越好）
                ],
                displayFormat: {
                    primary: (value) => `關卡 ${value}`,
                    secondary: (value) => `${value} 步`,
                    primaryLabel: '最高關卡',
                    secondaryLabel: '使用步數'
                },
                description: '關卡數越高排行越高，相同關卡下步數越少排行越高',
                metrics: {
                    level: { label: '關卡', direction: 'higher_better' },
                    moves: { label: '步數', direction: 'lower_better' },
                    time: { label: '用時', direction: 'lower_better' }
                }
            },
            classic: {
                name: '經典模式',
                primaryMetric: 'score',
                sortFields: [
                    { column: 'best_score', ascending: false }
                ],
                displayFormat: {
                    primary: (value) => value.toLocaleString(),
                    primaryLabel: '分數'
                },
                description: '分數越高排行越高',
                metrics: {
                    score: { label: '分數', direction: 'higher_better' },
                    moves: { label: '移動次數', direction: 'neutral' },
                    time: { label: '遊戲時間', direction: 'neutral' }
                }
            }
        };
    }
    
    // 設置當前用戶
    setCurrentUser(user) {
        this.currentUser = user;
    }
    
    // 檢查是否為當前用戶
    isCurrentUser(playerId) {
        return this.currentUser && this.currentUser.id === playerId;
    }
    
    // 獲取排名徽章的 CSS 類
    getRankBadgeClass(rank) {
        if (rank === 1) return 'rank-1 text-yellow-400 font-bold';
        if (rank === 2) return 'rank-2 text-gray-300 font-bold';
        if (rank === 3) return 'rank-3 text-orange-400 font-bold';
        return 'rank-other text-white/80';
    }
    
    // 獲取全域排行榜（每個玩家只顯示最高分）
    async getGlobalLeaderboard(gameMode, period = 'all', limit = 50) {
        // 如果是 quest 模式，使用特殊的排行榜邏輯
        if (gameMode === 'quest') {
            return await this.getQuestLeaderboard(limit);
        }
        
        // 如果是 survival 模式，使用特殊的排行榜邏輯
        if (gameMode === 'survival') {
            return await this.getSurvivalLeaderboard(limit);
        }
        
        const cacheKey = `global_${gameMode}_${period}_${limit}`;
        
        // 檢查快取
        if (this.cache.has(cacheKey)) {
            const cached = this.cache.get(cacheKey);
            if (Date.now() - cached.timestamp < this.cacheTimeout) {
                return cached.data;
            }
        }
        
        try {
            // 獲取所有遊戲記錄
            let query = this.supabase
                .from('game_records')
                .select('id, player_id, score, moves_used, time_taken, level_reached, created_at')
                .eq('game_mode', gameMode);
            
            // 根據時間段過濾
            if (period !== 'all') {
                const timeFilter = this.getTimeFilter(period);
                if (timeFilter) {
                    query = query.gte('created_at', timeFilter);
                }
            }
            
            const { data: allRecords, error: recordsError } = await query;
            
            if (recordsError) throw recordsError;
            
            // 找出每個玩家的最高分記錄
            const playerBestScores = new Map();
            (allRecords || []).forEach(record => {
                const playerId = record.player_id;
                if (!playerBestScores.has(playerId) || 
                    record.score > playerBestScores.get(playerId).score) {
                    playerBestScores.set(playerId, record);
                }
            });
            
            // 獲取所有相關玩家的資料
            const playerIds = Array.from(playerBestScores.keys());
            if (playerIds.length === 0) {
                return [];
            }
            
            const { data: playersData, error: playersError } = await this.supabase
                .from('players')
                .select('id, username, avatar_url')
                .in('id', playerIds);
                
            if (playersError) {
                console.error('獲取玩家資料失敗:', playersError);
                // 即使玩家資料獲取失敗，也可以顯示基本排行榜
            }
            
            // 建立玩家資料對照表
            const playersMap = new Map();
            (playersData || []).forEach(player => {
                playersMap.set(player.id, player);
            });
            
            // 轉換為數組並排序
            const leaderboard = Array.from(playerBestScores.values())
                .sort((a, b) => {
                    // 存活模式：先按存活時間排序，再按分數排序
                    if (gameMode === 'survival') {
                        // 首先按存活時間降序排列（時間越長越好）
                        if (a.time_taken !== b.time_taken) {
                            return b.time_taken - a.time_taken;
                        }
                        // 存活時間相同時，按分數降序排列
                        return b.score - a.score;
                    }
                    // 其他模式：按分數排序
                    return b.score - a.score;
                })
                .slice(0, limit)
                .map((record, index) => {
                    const playerInfo = playersMap.get(record.player_id);
                    return {
                        rank: index + 1,
                        id: record.id,
                        player_id: record.player_id,
                        username: playerInfo?.username || `玩家_${record.player_id.slice(-4)}`,
                        avatar_url: playerInfo?.avatar_url || null,
                        score: record.score,
                        moves: record.moves_used,
                        moves_used: record.moves_used, // 相容性欄位
                        time: record.time_taken,
                        time_taken: record.time_taken, // 相容性欄位
                        level: record.level_reached,
                        date: new Date(record.created_at).toLocaleDateString('zh-TW'),
                        created_at: record.created_at
                    };
                });
            
            // 更新快取
            this.cache.set(cacheKey, {
                data: leaderboard,
                timestamp: Date.now()
            });
            
            return leaderboard;
        } catch (error) {
            console.error('獲取全域排行榜失敗:', error);
            return [];
        }
    }
    
    // 獲取遊戲模式配置
    getModeConfig(gameMode) {
        return this.modeConfigs[gameMode] || this.modeConfigs.classic;
    }
    
    // 格式化存活時間
    formatSurvivalTime(seconds) {
        const minutes = Math.floor(seconds / 60);
        const remainingSeconds = seconds % 60;
        return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
    }
    
    // 獲取模式特定的排行榜數據
    async getLeaderboardData(gameMode, limit = 50) {
        const modeConfig = this.getModeConfig(gameMode);
        
        // 對於特殊模式，使用現有的特殊方法
        if (gameMode === 'quest') {
            return await this.getQuestLeaderboard(limit);
        }
        
        if (gameMode === 'survival') {
            return await this.getSurvivalLeaderboard(limit);
        }
        
        // 對於其他模式，使用通用方法
        return await this.getGlobalLeaderboard(gameMode, 'all', limit);
    }
    
    // 獲取 quest 模式排行榜
    async getQuestLeaderboard(limit = 50) {
        const cacheKey = `quest_leaderboard_${limit}`;
        
        // 檢查快取
        if (this.cache.has(cacheKey)) {
            const cached = this.cache.get(cacheKey);
            if (Date.now() - cached.timestamp < this.cacheTimeout) {
                return cached.data;
            }
        }
        
        try {
            const questLeaderboard = await this.supabaseAuth.getQuestLeaderboard(limit);
            
            // 轉換為統一的排行榜格式，增加模式特定的顯示信息
            const formattedLeaderboard = questLeaderboard.map(player => ({
                rank: player.rank,
                id: player.player_id,
                player_id: player.player_id,
                username: player.username,
                avatar_url: player.avatar_url,
                score: player.score,
                moves: player.moves_used,
                time: player.time_taken,
                level: player.highest_level,  // quest 模式特有：最高關卡
                date: new Date(player.achieved_at).toLocaleDateString('zh-TW'),
                highest_level: player.highest_level,  // 保留原始欄位
                moves_remaining: player.moves_remaining,
                achieved_at: player.achieved_at,
                // 新增模式特定的顯示信息
                display: {
                    primary: `關卡 ${player.highest_level || 0}`,
                    secondary: `${player.moves_used || 0} 步`,
                    primaryLabel: '最高關卡',
                    secondaryLabel: '使用步數'
                }
            }));
            
            // 更新快取
            this.cache.set(cacheKey, {
                data: formattedLeaderboard,
                timestamp: Date.now()
            });
            
            return formattedLeaderboard;
        } catch (error) {
            console.error('獲取 quest 排行榜失敗:', error);
            return [];
        }
    }
    
    // 獲取 survival 模式排行榜
    async getSurvivalLeaderboard(limit = 50) {
        const cacheKey = `survival_leaderboard_${limit}`;
        
        // 檢查快取
        if (this.cache.has(cacheKey)) {
            const cached = this.cache.get(cacheKey);
            if (Date.now() - cached.timestamp < this.cacheTimeout) {
                return cached.data;
            }
        }
        
        try {
            const survivalLeaderboard = await this.supabaseAuth.getSurvivalLeaderboard(limit);
            
            // 轉換為統一的排行榜格式，增加模式特定的顯示信息
            const formattedLeaderboard = survivalLeaderboard.map(player => ({
                rank: player.rank,
                id: player.player_id,
                player_id: player.player_id,
                username: player.username,
                avatar_url: player.avatar_url,
                score: player.score,
                moves: player.moves,
                time: player.time,
                time_taken: player.time_taken, // 存活時間
                level: player.level,
                date: player.date,
                created_at: player.created_at,
                // 新增模式特定的顯示信息
                display: {
                    primary: this.formatSurvivalTime(player.time_taken || 0),
                    secondary: (player.score || 0).toLocaleString(),
                    primaryLabel: '存活時間',
                    secondaryLabel: '分數'
                }
            }));
            
            // 更新快取
            this.cache.set(cacheKey, {
                data: formattedLeaderboard,
                timestamp: Date.now()
            });
            
            return formattedLeaderboard;
        } catch (error) {
            console.error('獲取 survival 排行榜失敗:', error);
            return [];
        }
    }
    
    // 獲取今日排行榜
    async getTodayLeaderboard(gameMode, limit = 20) {
        return await this.getGlobalLeaderboard(gameMode, 'today', limit);
    }
    
    // 獲取本週排行榜
    async getWeeklyLeaderboard(gameMode, limit = 30) {
        return await this.getGlobalLeaderboard(gameMode, 'week', limit);
    }
    
    // 獲取本月排行榜
    async getMonthlyLeaderboard(gameMode, limit = 50) {
        return await this.getGlobalLeaderboard(gameMode, 'month', limit);
    }
    
    // 獲取用戶在排行榜中的排名
    async getUserRank(gameMode, userId = null) {
        const targetUserId = userId || this.supabaseAuth.getCurrentUser()?.id;
        if (!targetUserId) return null;
        
        try {
            // 如果是 quest 模式，使用特殊的排名邏輯
            if (gameMode === 'quest') {
                // 獲取所有排行榜數據
                const allRankings = await this.getQuestLeaderboard(1000); // 獲取足夠多的數據
                
                // 找到當前用戶的排名
                const userRanking = allRankings.find(player => player.player_id === targetUserId);
                
                if (userRanking) {
                    return {
                        rank: userRanking.rank,
                        score: userRanking.highest_level, // quest 模式的「分數」是最高關卡
                        total_players: allRankings.length
                    };
                } else {
                    // 用戶沒有 quest 記錄
                    return {
                        rank: null,
                        score: 0,
                        total_players: allRankings.length
                    };
                }
            }
            
            // 如果是 survival 模式，使用特殊的排名邏輯
            if (gameMode === 'survival') {
                // 獲取所有排行榜數據
                const allRankings = await this.getSurvivalLeaderboard(1000); // 獲取足夠多的數據
                
                // 找到當前用戶的排名
                const userRanking = allRankings.find(player => player.player_id === targetUserId);
                
                if (userRanking) {
                    return {
                        rank: userRanking.rank,
                        score: userRanking.score,
                        time: userRanking.time_taken, // 存活時間
                        total_players: allRankings.length
                    };
                } else {
                    // 用戶沒有 survival 記錄
                    return {
                        rank: null,
                        score: 0,
                        time: 0,
                        total_players: allRankings.length
                    };
                }
            }
            
            // 先獲取用戶的最佳成績
            let userBestQuery = this.supabase
                .from('game_records')
                .select('score, time_taken')
                .eq('player_id', targetUserId)
                .eq('game_mode', gameMode);
                
            // 存活模式：按存活時間排序，再按分數排序
            if (gameMode === 'survival') {
                userBestQuery = userBestQuery
                    .order('time_taken', { ascending: false })
                    .order('score', { ascending: false });
            } else {
                userBestQuery = userBestQuery.order('score', { ascending: false });
            }
            
            const { data: userBest, error: userError } = await userBestQuery
                .limit(1)
                .single();
                
            if (userError || !userBest) return null;
            
            // 獲取所有玩家的記錄
            const { data: allRecords, error: allError } = await this.supabase
                .from('game_records')
                .select('player_id, score, time_taken')
                .eq('game_mode', gameMode);
                
            if (allError) throw allError;
            
            // 計算每個玩家的最佳記錄
            const playerBestScores = new Map();
            (allRecords || []).forEach(record => {
                const playerId = record.player_id;
                const currentBest = playerBestScores.get(playerId);
                
                if (!currentBest) {
                    playerBestScores.set(playerId, record);
                } else {
                    // 存活模式：先比較存活時間，再比較分數
                    if (gameMode === 'survival') {
                        if (record.time_taken > currentBest.time_taken || 
                            (record.time_taken === currentBest.time_taken && record.score > currentBest.score)) {
                            playerBestScores.set(playerId, record);
                        }
                    } else {
                        // 其他模式：只比較分數
                        if (record.score > currentBest.score) {
                            playerBestScores.set(playerId, record);
                        }
                    }
                }
            });
            
            // 統計有多少玩家成績比用戶好
            let higherCount = 0;
            for (const [playerId, record] of playerBestScores) {
                if (gameMode === 'survival') {
                    // 存活模式：先比較存活時間，再比較分數
                    if (record.time_taken > userBest.time_taken || 
                        (record.time_taken === userBest.time_taken && record.score > userBest.score)) {
                        higherCount++;
                    }
                } else {
                    // 其他模式：只比較分數
                    if (record.score > userBest.score) {
                        higherCount++;
                    }
                }
            }
            
            return {
                rank: higherCount + 1,
                score: userBest.score,
                time: userBest.time_taken || 0, // 添加時間信息
                total_players: playerBestScores.size
            };
        } catch (error) {
            console.error('獲取用戶排名失敗:', error);
            return null;
        }
    }
    
    // 獲取遊戲模式的總玩家數
    async getTotalPlayers(gameMode) {
        try {
            const { count, error } = await this.supabase
                .from('game_records')
                .select('player_id', { count: 'exact', head: true })
                .eq('game_mode', gameMode);
                
            if (error) throw error;
            return count || 0;
        } catch (error) {
            console.error('獲取總玩家數失敗:', error);
            return 0;
        }
    }
    
    // 獲取好友排行榜（如果有好友系統的話）
    async getFriendsLeaderboard(gameMode, friendIds = [], limit = 20) {
        if (friendIds.length === 0) return [];
        
        try {
            const { data, error } = await this.supabase
                .from('game_records')
                .select(`
                    id,
                    player_id,
                    score,
                    moves_used,
                    time_taken,
                    level_reached,
                    created_at,
                    players!inner (
                        username,
                        avatar_url
                    )
                `)
                .eq('game_mode', gameMode)
                .in('player_id', friendIds);
                
            if (error) throw error;
            
            // 找出每個好友的最佳記錄
            const playerBestScores = new Map();
            (data || []).forEach(record => {
                const playerId = record.player_id;
                const currentBest = playerBestScores.get(playerId);
                
                if (!currentBest) {
                    playerBestScores.set(playerId, record);
                } else {
                    // 存活模式：先比較存活時間，再比較分數
                    if (gameMode === 'survival') {
                        if (record.time_taken > currentBest.time_taken || 
                            (record.time_taken === currentBest.time_taken && record.score > currentBest.score)) {
                            playerBestScores.set(playerId, record);
                        }
                    } else {
                        // 其他模式：只比較分數
                        if (record.score > currentBest.score) {
                            playerBestScores.set(playerId, record);
                        }
                    }
                }
            });
            
            // 轉換為數組並排序
            return Array.from(playerBestScores.values())
                .sort((a, b) => {
                    // 存活模式：先按存活時間排序，再按分數排序
                    if (gameMode === 'survival') {
                        // 首先按存活時間降序排列（時間越長越好）
                        if (a.time_taken !== b.time_taken) {
                            return b.time_taken - a.time_taken;
                        }
                        // 存活時間相同時，按分數降序排列
                        return b.score - a.score;
                    }
                    // 其他模式：按分數排序
                    return b.score - a.score;
                })
                .slice(0, limit)
                .map((record, index) => ({
                    rank: index + 1,
                    id: record.id,
                    player_id: record.player_id,
                    username: record.players.username,
                    avatar_url: record.players.avatar_url,
                    score: record.score,
                    moves: record.moves_used,
                    time: record.time_taken,
                    level: record.level_reached,
                    date: new Date(record.created_at).toLocaleDateString('zh-TW')
                }));
        } catch (error) {
            console.error('獲取好友排行榜失敗:', error);
            return [];
        }
    }
    
    // 獲取遊戲統計資訊
    async getGameStats(gameMode) {
        try {
            const { data, error } = await this.supabase
                .from('game_records')
                .select('score, moves_used, time_taken')
                .eq('game_mode', gameMode);
                
            if (error) throw error;
            
            const records = data || [];
            if (records.length === 0) {
                return {
                    total_games: 0,
                    avg_score: 0,
                    max_score: 0,
                    avg_moves: 0,
                    avg_time: 0
                };
            }
            
            const scores = records.map(r => r.score);
            const moves = records.map(r => r.moves_used);
            const times = records.map(r => r.time_taken);
            
            return {
                total_games: records.length,
                avg_score: Math.round(scores.reduce((a, b) => a + b, 0) / scores.length),
                max_score: Math.max(...scores),
                avg_moves: Math.round(moves.reduce((a, b) => a + b, 0) / moves.length),
                avg_time: Math.round(times.reduce((a, b) => a + b, 0) / times.length)
            };
        } catch (error) {
            console.error('獲取遊戲統計失敗:', error);
            return null;
        }
    }
    
    // 清除排行榜快取
    clearCache() {
        this.cache.clear();
    }
    
    // 獲取時間過濾器
    getTimeFilter(period) {
        const now = new Date();
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        
        switch (period) {
            case 'today':
                return today.toISOString();
            case 'week':
                const weekStart = new Date(today);
                weekStart.setDate(today.getDate() - today.getDay());
                return weekStart.toISOString();
            case 'month':
                const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);
                return monthStart.toISOString();
            default:
                return null;
        }
    }
    
    // 即時更新排行榜（使用 Supabase 即時功能）
    subscribeToLeaderboard(gameMode, callback) {
        return this.supabase
            .channel(`leaderboard_${gameMode}`)
            .on('postgres_changes', {
                event: 'INSERT',
                schema: 'public',
                table: 'game_records',
                filter: `game_mode=eq.${gameMode}`
            }, (payload) => {
                // 清除相關快取
                this.clearCacheForGameMode(gameMode);
                callback(payload);
            })
            .subscribe();
    }
    
    // 清除特定遊戲模式的快取
    clearCacheForGameMode(gameMode) {
        for (const [key] of this.cache.entries()) {
            if (key.includes(gameMode)) {
                this.cache.delete(key);
            }
        }
    }

    // 通用獲取排行榜方法（相容性方法）
    async getLeaderboard(gameMode, limit = 50) {
        return await this.getGlobalLeaderboard(gameMode, 'all', limit);
    }

    // 獲取當前用戶的最佳成績（所有遊戲模式）
    async getUserBestScores() {
        const currentUser = this.supabaseAuth.getCurrentUser();
        if (!currentUser) {
            console.log('用戶未登入，無法獲取最佳成績');
            return {};
        }

        try {
            // 獲取所有遊戲模式
            const gameModes = ['classic', 'double', 'triple', 'time_limit'];
            const bestScores = {};

            for (const mode of gameModes) {
                try {
                    const { data, error } = await this.supabase
                        .from('game_records')
                        .select('score, moves_used, time_taken, level_reached, created_at')
                        .eq('player_id', currentUser.id)
                        .eq('game_mode', mode)
                        .order('score', { ascending: false })
                        .limit(1);

                    if (error) {
                        console.error(`獲取 ${mode} 模式最佳成績失敗:`, error);
                        continue;
                    }

                    if (data && data.length > 0) {
                        const record = data[0];
                        bestScores[mode] = {
                            score: record.score,
                            moves: record.moves_used,
                            time: record.time_taken,
                            level: record.level_reached,
                            date: new Date(record.created_at).toLocaleDateString('zh-TW')
                        };
                    } else {
                        bestScores[mode] = null;
                    }
                } catch (modeError) {
                    console.error(`處理 ${mode} 模式時發生錯誤:`, modeError);
                    bestScores[mode] = null;
                }
            }

            console.log('獲取用戶最佳成績成功:', bestScores);
            return bestScores;
        } catch (error) {
            console.error('獲取用戶最佳成績失敗:', error);
            return {};
        }
    }

    // 獲取用戶統計資訊
    async getUserStats() {
        const currentUser = this.supabaseAuth.getCurrentUser();
        if (!currentUser) {
            return null;
        }

        try {
            const { data, error } = await this.supabase
                .from('game_records')
                .select('game_mode, score, moves_used, time_taken, created_at')
                .eq('player_id', currentUser.id);

            if (error) throw error;

            const records = data || [];
            
            if (records.length === 0) {
                return {
                    totalGames: 0,
                    avgScore: 0,
                    bestScore: 0,
                    totalTime: 0,
                    avgTime: 0,
                    gameModes: {}
                };
            }

            // 計算總體統計
            const scores = records.map(r => r.score);
            const times = records.map(r => r.time_taken);
            
            // 按遊戲模式分組統計
            const modeStats = {};
            records.forEach(record => {
                const mode = record.game_mode;
                if (!modeStats[mode]) {
                    modeStats[mode] = {
                        games: 0,
                        totalScore: 0,
                        bestScore: 0,
                        totalTime: 0,
                        totalMoves: 0
                    };
                }
                
                modeStats[mode].games++;
                modeStats[mode].totalScore += record.score;
                modeStats[mode].bestScore = Math.max(modeStats[mode].bestScore, record.score);
                modeStats[mode].totalTime += record.time_taken;
                modeStats[mode].totalMoves += record.moves_used;
            });

            // 計算平均值
            Object.keys(modeStats).forEach(mode => {
                const stats = modeStats[mode];
                stats.avgScore = Math.round(stats.totalScore / stats.games);
                stats.avgTime = Math.round(stats.totalTime / stats.games);
                stats.avgMoves = Math.round(stats.totalMoves / stats.games);
            });

            return {
                totalGames: records.length,
                avgScore: Math.round(scores.reduce((a, b) => a + b, 0) / scores.length),
                bestScore: Math.max(...scores),
                totalTime: times.reduce((a, b) => a + b, 0),
                avgTime: Math.round(times.reduce((a, b) => a + b, 0) / times.length),
                gameModes: modeStats,
                firstPlayDate: new Date(Math.min(...records.map(r => new Date(r.created_at)))).toLocaleDateString('zh-TW'),
                lastPlayDate: new Date(Math.max(...records.map(r => new Date(r.created_at)))).toLocaleDateString('zh-TW')
            };
        } catch (error) {
            console.error('獲取用戶統計失敗:', error);
            return null;
        }
    }

    // 顯示排行榜項目
    displayLeaderboardItem(player, index, gameMode) {
        const isCurrentUser = this.isCurrentUser(player.player_id);
        const rank = player.rank || (index + 1); // 使用傳入的 rank 或計算排名
        
        // 根據遊戲模式決定顯示內容
        let scoreDisplay, detailsDisplay;
        
        if (gameMode === 'quest') {
            // Quest 模式顯示關卡數和詳細資訊
            const levelNumber = player.highest_level || player.highest_level_cleared || 0;
            scoreDisplay = `
                <div class="flex items-center gap-2">
                    <span class="text-lg font-bold text-white">關卡 ${levelNumber}</span>
                    ${player.moves_used > 0 ? `<span class="text-sm text-white/70">• 用了 ${player.moves_used} 步</span>` : ''}
                </div>
            `;
            
            // 顯示詳細的遊戲資訊
            const timeDisplay = player.time_taken > 0 ? this.formatTime(player.time_taken) : '--';
            const movesRemaining = player.moves_remaining || 0;
            
            detailsDisplay = `
                <div class="text-xs text-white/60 mt-1 space-y-1">
                    <div class="flex justify-between">
                        <span>用時：${timeDisplay}</span>
                        <span>剩餘步數：${movesRemaining}</span>
                    </div>
                    <div class="text-xs text-white/50">
                        ${this.formatDateTime(player.achieved_at)}
                    </div>
                </div>
            `;
        } else if (gameMode === 'survival') {
            // Survival 模式顯示存活時間和分數
            const survivalTime = player.time_taken || player.time || 0; // 優先使用 time_taken
            const survivalMinutes = Math.floor(survivalTime / 60);
            const survivalSeconds = survivalTime % 60;
            const timeDisplay = `${survivalMinutes}:${survivalSeconds.toString().padStart(2, '0')}`;
            
            console.log(`排行榜顯示: 玩家 ${player.username} 存活時間 ${survivalTime} 秒 (${timeDisplay})`);
            
            scoreDisplay = `
                <div class="flex flex-col items-end">
                    <div class="text-lg font-bold text-green-300">⏱️ ${timeDisplay}</div>
                    <div class="text-sm text-white/70">${(player.score || 0).toLocaleString()} 分</div>
                </div>
            `;
            
            detailsDisplay = `
                <div class="text-xs text-white/60 mt-1 space-y-1">
                    <div class="flex justify-between">
                        <span>行動次數：${player.moves || player.moves_used || 0} | </span>
                        <span>等級：${player.level || 1}</span>
                    </div>
                    <div class="text-xs text-white/50">
                        ${this.formatDateTime(player.created_at)}
                    </div>
                </div>
            `;
        } else {
            // 其他模式顯示分數
            scoreDisplay = `<span class="text-lg font-bold text-white">${(player.score || 0).toLocaleString()}</span>`;
            detailsDisplay = '';
        }

        return `
            <div class="leaderboard-item ${isCurrentUser ? 'current-user' : ''} p-4 bg-white/15 rounded-lg backdrop-blur-sm border border-white/30">
                <div class="flex items-center justify-between">
                    <div class="flex items-center gap-3">
                        <div class="rank-badge ${this.getRankBadgeClass(rank)}">
                            ${rank}
                        </div>
                        <div class="player-avatar">
                            ${player.avatar_url ? 
                                `<img src="${player.avatar_url}" alt="${player.username}" class="w-10 h-10 rounded-full">` : 
                                `<div class="w-10 h-10 rounded-full bg-gradient-to-br from-blue-400 to-purple-500 flex items-center justify-center text-white font-bold">${(player.username || 'U').charAt(0).toUpperCase()}</div>`
                            }
                        </div>
                        <div class="player-info">
                            <div class="player-name text-white font-semibold">
                                ${player.username || '未知玩家'}
                                ${isCurrentUser ? '<span class="text-yellow-300 ml-2">👑</span>' : ''}
                            </div>
                            ${detailsDisplay}
                        </div>
                    </div>
                    <div class="score text-white">
                        ${scoreDisplay}
                    </div>
                </div>
            </div>
        `;
    }
    
    // 格式化時間顯示
    formatTime(milliseconds) {
        if (!milliseconds || milliseconds === 0) return '--';
        
        const totalSeconds = Math.floor(milliseconds / 1000);
        const minutes = Math.floor(totalSeconds / 60);
        const seconds = totalSeconds % 60;
        
        if (minutes > 0) {
            return `${minutes}:${seconds.toString().padStart(2, '0')}`;
        } else {
            return `${seconds}秒`;
        }
    }
    
    // 格式化日期時間
    formatDateTime(dateString) {
        if (!dateString) return '';
        
        const date = new Date(dateString);
        const now = new Date();
        const diffMs = now - date;
        const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
        
        if (diffDays === 0) {
            return '今天 ' + date.toLocaleTimeString('zh-TW', { 
                hour: '2-digit', 
                minute: '2-digit' 
            });
        } else if (diffDays === 1) {
            return '昨天 ' + date.toLocaleTimeString('zh-TW', { 
                hour: '2-digit', 
                minute: '2-digit' 
            });
        } else if (diffDays < 7) {
            return `${diffDays}天前`;
        } else {
            return date.toLocaleDateString('zh-TW', { 
                month: 'short', 
                day: 'numeric'
            });
        }
    }

    // 獲取排行榜說明信息
    getLeaderboardDescription(gameMode) {
        const config = this.getModeConfig(gameMode);
        return {
            title: config.name,
            description: config.description,
            metrics: config.metrics
        };
    }

    // 驗證並修正排行榜數據
    validateLeaderboardData(data, gameMode) {
        const config = this.getModeConfig(gameMode);
        
        return data.map(item => {
            const validated = { ...item };
            
            // 根據模式驗證和修正數據
            if (gameMode === 'survival') {
                // 確保存活時間數據的完整性
                if (!validated.time_taken || validated.time_taken < 0) {
                    validated.time_taken = 0;
                }
                validated.display = {
                    primary: this.formatSurvivalTime(validated.time_taken),
                    secondary: (validated.score || 0).toLocaleString(),
                    primaryLabel: '存活時間',
                    secondaryLabel: '分數'
                };
            } else if (gameMode === 'quest') {
                // 確保關卡數據的完整性
                if (!validated.highest_level || validated.highest_level < 0) {
                    validated.highest_level = 0;
                }
                validated.display = {
                    primary: `關卡 ${validated.highest_level}`,
                    secondary: `${validated.moves_used || 0} 步`,
                    primaryLabel: '最高關卡',
                    secondaryLabel: '使用步數'
                };
            } else {
                // 其他模式
                validated.display = {
                    primary: (validated.score || 0).toLocaleString(),
                    primaryLabel: '分數'
                };
            }
            
            return validated;
        });
    }

    // 獲取用戶的排行統計
    async getUserRankingStats(gameMode, userId = null) {
        const targetUserId = userId || this.supabaseAuth.getCurrentUser()?.id;
        if (!targetUserId) return null;
        
        const config = this.getModeConfig(gameMode);
        const userRank = await this.getUserRank(gameMode, targetUserId);
        
        if (!userRank) return null;
        
        return {
            rank: userRank.rank,
            total_players: userRank.total_players,
            percentile: userRank.rank ? Math.round((1 - userRank.rank / userRank.total_players) * 100) : 0,
            primary_metric: {
                label: config.displayFormat.primaryLabel,
                value: gameMode === 'survival' ? 
                    this.formatSurvivalTime(userRank.time || 0) : 
                    (gameMode === 'quest' ? `關卡 ${userRank.score || 0}` : (userRank.score || 0).toLocaleString())
            },
            improvement_tips: this.getImprovementTips(gameMode, userRank)
        };
    }

    // 獲取改進建議
    getImprovementTips(gameMode, userRank) {
        const tips = [];
        
        if (gameMode === 'survival') {
            if (userRank.time < 60) {
                tips.push('嘗試更保守的策略，專注於延長存活時間');
            }
            if (userRank.score < 1000) {
                tips.push('在保持存活的同時，尋找更多連擊機會');
            }
        } else if (gameMode === 'quest') {
            if (userRank.score < 10) {
                tips.push('練習基本的三消技巧，逐步挑戰更高關卡');
            }
            tips.push('計劃你的移動，嘗試用更少的步數完成關卡');
        }
        
        return tips;
    }
}

// 全域實例
window.leaderboardManager = null; 