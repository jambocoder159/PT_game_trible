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
        // 如果是 quest 模式，使用特殊的排行榜邏輯
        if (gameMode === 'quest') {
            return await this.getQuestLeaderboard(limit);
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
            
            // 轉換為統一的排行榜格式
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
                highest_level: player.highest_level  // 保留原始欄位
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
}

// 全域實例
window.leaderboardManager = null; 