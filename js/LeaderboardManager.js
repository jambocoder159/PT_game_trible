// 排行榜管理器
class LeaderboardManager {
    constructor(supabaseAuth) {
        this.supabaseAuth = supabaseAuth;
        this.supabase = supabaseAuth.supabase;
        this.cache = new Map();
        this.cacheTimeout = 5 * 60 * 1000; // 5分鐘快取
    }
    
    // 獲取全域排行榜（每個玩家只顯示最高分）
    async getGlobalLeaderboard(gameMode, period = 'all', limit = 50) {
        const cacheKey = `global_${gameMode}_${period}_${limit}`;
        
        // 檢查快取
        if (this.cache.has(cacheKey)) {
            const cached = this.cache.get(cacheKey);
            if (Date.now() - cached.timestamp < this.cacheTimeout) {
                return cached.data;
            }
        }
        
        try {
            // 先獲取每個玩家的最高分記錄 ID
            let subQuery = this.supabase
                .from('game_records')
                .select('player_id, MAX(score) as max_score')
                .eq('game_mode', gameMode);
            
            // 根據時間段過濾
            if (period !== 'all') {
                const timeFilter = this.getTimeFilter(period);
                if (timeFilter) {
                    subQuery = subQuery.gte('created_at', timeFilter);
                }
            }
            
            // 使用子查詢的方式獲取每個玩家的最高分記錄
            const { data: allRecords, error: allError } = await this.supabase
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
                .eq('game_mode', gameMode);
                
            if (allError) throw allError;
            
            // 根據時間段過濾
            let filteredRecords = allRecords || [];
            if (period !== 'all') {
                const timeFilter = this.getTimeFilter(period);
                if (timeFilter) {
                    filteredRecords = filteredRecords.filter(record => 
                        new Date(record.created_at) >= new Date(timeFilter)
                    );
                }
            }
            
            // 找出每個玩家的最高分記錄
            const playerBestScores = new Map();
            filteredRecords.forEach(record => {
                const playerId = record.player_id;
                if (!playerBestScores.has(playerId) || 
                    record.score > playerBestScores.get(playerId).score) {
                    playerBestScores.set(playerId, record);
                }
            });
            
            // 轉換為數組並排序
            const leaderboard = Array.from(playerBestScores.values())
                .sort((a, b) => b.score - a.score)
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
            // 先獲取用戶的最佳成績
            const { data: userBest, error: userError } = await this.supabase
                .from('game_records')
                .select('score')
                .eq('player_id', targetUserId)
                .eq('game_mode', gameMode)
                .order('score', { ascending: false })
                .limit(1)
                .single();
                
            if (userError || !userBest) return null;
            
            // 獲取所有玩家的最高分記錄
            const { data: allRecords, error: allError } = await this.supabase
                .from('game_records')
                .select('player_id, score')
                .eq('game_mode', gameMode);
                
            if (allError) throw allError;
            
            // 計算每個玩家的最高分
            const playerBestScores = new Map();
            (allRecords || []).forEach(record => {
                const playerId = record.player_id;
                if (!playerBestScores.has(playerId) || 
                    record.score > playerBestScores.get(playerId)) {
                    playerBestScores.set(playerId, record.score);
                }
            });
            
            // 統計有多少玩家分數比用戶高
            let higherCount = 0;
            for (const [playerId, score] of playerBestScores) {
                if (score > userBest.score) {
                    higherCount++;
                }
            }
            
            return {
                rank: higherCount + 1,
                score: userBest.score,
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
            
            // 找出每個好友的最高分記錄
            const playerBestScores = new Map();
            (data || []).forEach(record => {
                const playerId = record.player_id;
                if (!playerBestScores.has(playerId) || 
                    record.score > playerBestScores.get(playerId).score) {
                    playerBestScores.set(playerId, record);
                }
            });
            
            // 轉換為數組並排序
            return Array.from(playerBestScores.values())
                .sort((a, b) => b.score - a.score)
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
}

// 全域實例
window.leaderboardManager = null; 