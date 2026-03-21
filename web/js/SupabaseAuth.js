// Supabase 配置和認證管理
class SupabaseAuth {
    constructor() {
        // 等待環境配置載入
        this.envConfig = window.environmentConfig;
        
        // 使用環境配置
        if (this.envConfig) {
            this.supabaseUrl = this.envConfig.config.supabaseUrl;
            this.supabaseKey = this.envConfig.config.supabaseKey;
        } else {
            // 備用配置
            this.supabaseUrl = 'https://admkbelthyyqngsnsxmm.supabase.co';
            this.supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkbWtiZWx0aHl5cW5nc25zeG1tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzMDU4NjMsImV4cCI6MjA2NDg4MTg2M30.NdpkqWnSJsb9bHQn8H7_CgpIkwu9f5kSzLrWV39ta2w';
        }
        
        // 初始化 Supabase 客戶端
        this.supabase = window.supabase?.createClient(this.supabaseUrl, this.supabaseKey);
        
        if (!this.supabase) {
            console.error('Supabase 客戶端初始化失敗！請確保已加載 Supabase SDK');
            // 不要 return，讓類別實例完整建立
        }
        
        this.currentUser = null;
        this.authCallbacks = [];
        
        // 手動綁定所有需要外部呼叫的方法
        this.checkCurrentUser = this.checkCurrentUser.bind(this);
        this.onAuthStateChange = this.onAuthStateChange.bind(this);
        this.signInWithGoogle = this.signInWithGoogle.bind(this);
        this.signInWithGitHub = this.signInWithGitHub.bind(this);
        this.signInWithDiscord = this.signInWithDiscord.bind(this);
        this.signOut = this.signOut.bind(this);
        this.getCurrentUser = this.getCurrentUser.bind(this);
        this.isAuthenticated = this.isAuthenticated.bind(this);
        this.getUserProfile = this.getUserProfile.bind(this);
        this.createUserProfile = this.createUserProfile.bind(this);
        this.updateLastLogin = this.updateLastLogin.bind(this);
        this.saveGameRecord = this.saveGameRecord.bind(this);
        this.getPersonalBest = this.getPersonalBest.bind(this);
        this.getPersonalHistory = this.getPersonalHistory.bind(this);
        this.saveQuestRecord = this.saveQuestRecord.bind(this);
        this.updatePlayerProgress = this.updatePlayerProgress.bind(this);
        this.getPlayerQuestProgress = this.getPlayerQuestProgress.bind(this);
        this.getQuestLevelBest = this.getQuestLevelBest.bind(this);
        this.getAllQuestBestRecords = this.getAllQuestBestRecords.bind(this);
        this.getQuestLevelHistory = this.getQuestLevelHistory.bind(this);
        this.getChapterStats = this.getChapterStats.bind(this);
        this.getQuestLeaderboard = this.getQuestLeaderboard.bind(this);
        this.getSurvivalLeaderboard = this.getSurvivalLeaderboard.bind(this);

        // 監聽認證狀態變化
        if (this.supabase) {
            this.supabase.auth.onAuthStateChange((event, session) => {
                this.currentUser = session?.user || null;
                this.notifyAuthCallbacks(event, session);
            });
            // 檢查當前用戶狀態
            this.checkCurrentUser();
        }
    }
    
    // 檢查當前用戶
    async checkCurrentUser() {
        try {
            const { data: { session } } = await this.supabase.auth.getSession();
            this.currentUser = session?.user || null;
            return this.currentUser;
        } catch (error) {
            console.error('檢查用戶狀態失敗:', error);
            return null;
        }
    }
    
    // 添加認證狀態監聽器
    onAuthStateChange(callback) {
        this.authCallbacks.push(callback);
    }
    
    // 通知所有認證狀態監聽器
    notifyAuthCallbacks(event, session) {
        this.authCallbacks.forEach(callback => {
            try {
                callback(event, session);
            } catch (error) {
                console.error('認證回調執行失敗:', error);
            }
        });
    }
    
    // Google OAuth 登入
    async signInWithGoogle() {
        try {
            // 動態設定重定向 URL，適應不同環境
            const redirectTo = this.getRedirectUrl();
            console.log('Google OAuth 重定向 URL:', redirectTo);
            console.log('當前頁面 URL:', window.location.href);
            
            const { data, error } = await this.supabase.auth.signInWithOAuth({
                provider: 'google',
                options: {
                    redirectTo: redirectTo
                }
            });
            
            if (error) throw error;
            return data;
        } catch (error) {
            console.error('Google 登入失敗:', error);
            throw error;
        }
    }
    
    // GitHub OAuth 登入
    async signInWithGitHub() {
        try {
            // 動態設定重定向 URL，適應不同環境
            const redirectTo = this.getRedirectUrl();
            
            const { data, error } = await this.supabase.auth.signInWithOAuth({
                provider: 'github',
                options: {
                    redirectTo: redirectTo
                }
            });
            
            if (error) throw error;
            return data;
        } catch (error) {
            console.error('GitHub 登入失敗:', error);
            throw error;
        }
    }
    
    // Discord OAuth 登入
    async signInWithDiscord() {
        try {
            // 動態設定重定向 URL，適應不同環境
            const redirectTo = this.getRedirectUrl();
            
            const { data, error } = await this.supabase.auth.signInWithOAuth({
                provider: 'discord',
                options: {
                    redirectTo: redirectTo
                }
            });
            
            if (error) throw error;
            return data;
        } catch (error) {
            console.error('Discord 登入失敗:', error);
            throw error;
        }
    }
    
    // 獲取重定向 URL
    getRedirectUrl() {
        console.log('=== 重定向 URL 偵測開始 ===');
        console.log('當前 URL:', window.location.href);
        console.log('當前 hostname:', window.location.hostname);
        console.log('當前 origin:', window.location.origin);
        
        // 使用環境配置管理器
        if (this.envConfig) {
            console.log('使用環境配置管理器');
            console.log('偵測到的環境:', this.envConfig.environment);
            console.log('環境配置:', this.envConfig.config);
            
            // OAuth 登入後應該重定向到主選單
            const redirectUrl = this.envConfig.getRedirectUrl('/main-menu.html', '');
            console.log('環境配置重定向 URL:', redirectUrl);
            return redirectUrl;
        }
        
        // 備用邏輯（如果環境配置未載入）
        const baseUrl = window.location.origin;
        const fallbackUrl = `${baseUrl}/main-menu.html`;
        
        console.log('使用備用重定向邏輯:', {
            origin: window.location.origin,
            hostname: window.location.hostname,
            pathname: window.location.pathname,
            search: window.location.search,
            fallbackUrl: fallbackUrl
        });
        
        // 確保本地環境使用本地 URL
        if (window.location.hostname === 'localhost' || 
            window.location.hostname === '127.0.0.1' || 
            window.location.hostname.includes('localhost')) {
            console.log('強制使用本地環境 URL');
            return fallbackUrl;
        }
        
        // OAuth 登入成功後統一重定向到主選單
        return fallbackUrl;
    }
    
    // 登出
    async signOut() {
        try {
            const { error } = await this.supabase.auth.signOut();
            if (error) throw error;
            this.currentUser = null;
        } catch (error) {
            console.error('登出失敗:', error);
            throw error;
        }
    }
    
    // 獲取當前用戶
    getCurrentUser() {
        return this.currentUser;
    }
    
    // 檢查是否已登入
    isAuthenticated() {
        return this.currentUser !== null;
    }
    
    // 獲取用戶資訊
    async getUserProfile() {
        if (!this.currentUser) return null;
        
        try {
            const { data, error } = await this.supabase
                .from('players')
                .select('*')
                .eq('id', this.currentUser.id)
                .single();
                
            if (error && error.code === 'PGRST116') {
                // 用戶不存在，創建新用戶資料
                return await this.createUserProfile();
            }
            
            if (error) throw error;
            return data;
        } catch (error) {
            console.error('獲取用戶資料失敗:', error);
            return null;
        }
    }
    
    // 創建用戶資料
    async createUserProfile() {
        if (!this.currentUser) return null;
        
        try {
            const userProfile = {
                id: this.currentUser.id,
                email: this.currentUser.email,
                username: this.currentUser.user_metadata?.full_name || 
                         this.currentUser.user_metadata?.user_name || 
                         this.currentUser.email.split('@')[0],
                avatar_url: this.currentUser.user_metadata?.avatar_url || 
                           this.currentUser.user_metadata?.picture,
                created_at: new Date().toISOString(),
                last_login: new Date().toISOString()
            };
            
            const { data, error } = await this.supabase
                .from('players')
                .insert([userProfile])
                .select()
                .single();
                
            if (error) throw error;
            return data;
        } catch (error) {
            console.error('創建用戶資料失敗:', error);
            return null;
        }
    }
    
    // 更新最後登入時間
    async updateLastLogin() {
        if (!this.currentUser) return;
        
        try {
            await this.supabase
                .from('players')
                .update({ last_login: new Date().toISOString() })
                .eq('id', this.currentUser.id);
        } catch (error) {
            console.error('更新登入時間失敗:', error);
        }
    }
    
    // 記錄遊戲成績
    async saveGameRecord(gameData) {
        if (!this.currentUser) {
            throw new Error('用戶未登入');
        }
        
        try {
            const gameRecord = {
                player_id: this.currentUser.id,
                game_mode: gameData.mode,
                score: gameData.score,
                moves_used: gameData.moves,
                time_taken: gameData.time,
                level_reached: gameData.level || 1,
                created_at: new Date().toISOString()
            };
            
            const { data, error } = await this.supabase
                .from('game_records')
                .insert([gameRecord])
                .select()
                .single();
                
            if (error) throw error;
            return data;
        } catch (error) {
            console.error('保存遊戲記錄失敗:', error);
            throw error;
        }
    }
    
    // 獲取個人最佳成績
    async getPersonalBest(gameMode) {
        if (!this.currentUser) return null;
        
        try {
            const { data, error } = await this.supabase
                .from('game_records')
                .select('*')
                .eq('player_id', this.currentUser.id)
                .eq('game_mode', gameMode)
                .order('score', { ascending: false })
                .limit(1)
                .single();
                
            if (error && error.code === 'PGRST116') {
                return null; // 沒有記錄
            }
            
            if (error) throw error;
            return data;
        } catch (error) {
            console.error('獲取個人最佳成績失敗:', error);
            return null;
        }
    }
    
    // 獲取個人遊戲歷史
    async getPersonalHistory(gameMode, limit = 10) {
        if (!this.currentUser) return [];
        
        try {
            let query = this.supabase
                .from('game_records')
                .select('*')
                .eq('player_id', this.currentUser.id)
                .order('created_at', { ascending: false })
                .limit(limit);
                
            if (gameMode) {
                query = query.eq('game_mode', gameMode);
            }
            
            const { data, error } = await query;
            if (error) throw error;
            return data || [];
        } catch (error) {
            console.error('獲取個人歷史失敗:', error);
            return [];
        }
    }

    // ===== 闖關模式專用方法 =====
    
    // 保存關卡記錄
    async saveQuestRecord(questData) {
        if (!this.currentUser) {
            throw new Error('用戶未登入');
        }
        
        try {
            const questRecord = {
                player_id: this.currentUser.id,
                level_number: questData.levelNumber,
                chapter: Math.ceil(questData.levelNumber / 10), // 計算章節
                is_completed: questData.isCompleted,
                score: questData.score,
                moves_used: questData.movesUsed,
                moves_remaining: questData.movesRemaining,
                max_combo: questData.maxCombo,
                action_count: questData.actionCount,
                time_taken: questData.timeTaken,
                enemy_name: questData.enemyName,
                enemy_max_hp: questData.enemyMaxHP,
                damage_dealt: questData.damageDealt,
                created_at: new Date().toISOString()
            };
            
            const { data, error } = await this.supabase
                .from('quest_records')
                .insert([questRecord])
                .select()
                .single();
                
            if (error) throw error;
            
            // 如果是首次通關，更新玩家進度
            if (questData.isCompleted) {
                await this.updatePlayerProgress(questData.levelNumber);
            }
            
            return data;
        } catch (error) {
            console.error('保存闖關記錄失敗:', error);
            throw error;
        }
    }
    
    // 更新玩家闖關進度
    async updatePlayerProgress(levelNumber) {
        if (!this.currentUser) return null;

        // 暫時限制只能玩到第10關
        if (levelNumber > 10) {
            console.log(`關卡 ${levelNumber} 暫未開放，最高只能到第10關`);
            return null;
        }

        try {
            // 首先，獲取玩家當前的最高通關記錄
            const { data: currentProgress, error: selectError } = await this.supabase
                .from('player_quest_progress')
                .select('highest_level_cleared')
                .eq('player_id', this.currentUser.id)
                .single();

            // 如果查詢出錯，但不是因為「找不到記錄」，則拋出錯誤
            if (selectError && selectError.code !== 'PGRST116') {
                throw selectError;
            }

            const currentHighest = currentProgress?.highest_level_cleared || 0;

            // 只有在新完成的關卡比最高紀錄更高時，才進行更新
            if (levelNumber > currentHighest) {
                const { data, error: upsertError } = await this.supabase
                    .from('player_quest_progress')
                    .upsert({
                        player_id: this.currentUser.id,
                        highest_level_cleared: levelNumber, // 使用正確的欄位名稱
                        updated_at: new Date().toISOString()
                    }, {
                        onConflict: 'player_id'
                    })
                    .select()
                    .single();

                if (upsertError) throw upsertError;

                console.log('玩家進度更新成功:', data);
                return data;
            } else {
                console.log(`不更新玩家進度，因為目前最高關卡 (${currentHighest}) 已高於或等於完成的關卡 (${levelNumber})。`);
                return currentProgress;
            }
        } catch (error) {
            console.error('更新玩家進度失敗:', error);
            return null;
        }
    }
    
    // 獲取玩家闖關進度
    async getPlayerQuestProgress() {
        if (!this.currentUser) return { highest_level_cleared: 0 };
        
        try {
            const { data, error } = await this.supabase
                .from('player_quest_progress')
                .select('highest_level_cleared')
                .eq('player_id', this.currentUser.id)
                .single();
                
            if (error && error.code === 'PGRST116') {
                // 沒有記錄，返回預設值
                return { highest_level_cleared: 0 };
            }
            
            if (error) throw error;
            return data || { highest_level_cleared: 0 };
        } catch (error) {
            console.error('獲取玩家進度失敗:', error);
            return { highest_level_cleared: 0 };
        }
    }
    
    // 獲取特定關卡的最佳記錄
    async getQuestLevelBest(levelNumber) {
        if (!this.currentUser) return null;
        
        try {
            const { data, error } = await this.supabase
                .from('quest_records')
                .select('*')
                .eq('player_id', this.currentUser.id)
                .eq('level_number', levelNumber)
                .eq('is_completed', true)
                .order('score', { ascending: false })
                .limit(1)
                .single();
                
            if (error && error.code === 'PGRST116') {
                return null; // 沒有記錄
            }
            
            if (error) throw error;
            return data;
        } catch (error) {
            console.error('獲取關卡最佳記錄失敗:', error);
            return null;
        }
    }
    
    // 批量獲取所有關卡的最佳記錄
    async getAllQuestBestRecords() {
        if (!this.currentUser) return [];
        
        try {
            // 使用子查詢獲取每個關卡的最佳分數記錄
            const { data, error } = await this.supabase
                .from('quest_records')
                .select('level_number, score, max_combo, time_taken, created_at')
                .eq('player_id', this.currentUser.id)
                .eq('is_completed', true)
                .order('level_number')
                .order('score', { ascending: false });
                
            if (error) throw error;
            
            // 處理數據，為每個關卡只保留最佳記錄
            const bestRecords = {};
            if (data && data.length > 0) {
                data.forEach(record => {
                    const levelNumber = record.level_number;
                    if (!bestRecords[levelNumber] || record.score > bestRecords[levelNumber].score) {
                        bestRecords[levelNumber] = record;
                    }
                });
            }
            
            // 轉換為數組格式返回
            return Object.values(bestRecords);
        } catch (error) {
            console.error('批量獲取關卡最佳記錄失敗:', error);
            return [];
        }
    }
    
    // 獲取特定關卡的所有嘗試記錄
    async getQuestLevelHistory(levelNumber, limit = 10) {
        if (!this.currentUser) return [];
        
        try {
            const { data, error } = await this.supabase
                .from('quest_records')
                .select('*')
                .eq('player_id', this.currentUser.id)
                .eq('level_number', levelNumber)
                .order('created_at', { ascending: false })
                .limit(limit);
                
            if (error) throw error;
            return data || [];
        } catch (error) {
            console.error('獲取關卡歷史失敗:', error);
            return [];
        }
    }
    
    // 獲取所有章節的通關統計
    async getChapterStats() {
        if (!this.currentUser) return [];
        
        try {
            const { data, error } = await this.supabase
                .from('quest_records')
                .select('chapter, level_number, is_completed')
                .eq('player_id', this.currentUser.id)
                .eq('is_completed', true)
                .order('level_number');
                
            if (error) throw error;
            
            // 統計每章節的通關數
            const chapterStats = [
                { chapter: 1, cleared: 0, total: 10 },
                { chapter: 2, cleared: 0, total: 10 },
                { chapter: 3, cleared: 0, total: 10 }
            ];
            
            if (data) {
                data.forEach(record => {
                    const chapterIndex = record.chapter - 1;
                    if (chapterIndex >= 0 && chapterIndex < chapterStats.length) {
                        chapterStats[chapterIndex].cleared++;
                    }
                });
            }
            
            return chapterStats;
        } catch (error) {
            console.error('獲取章節統計失敗:', error);
            return [];
        }
    }
    
    // 獲取 quest 模式排行榜 (按最高關卡、步數、時間排序)
    async getQuestLeaderboard(limit = 50) {
        try {
            console.log('開始獲取 quest 排行榜（優化SQL查詢）...');
            
            // 使用複雜查詢一次性獲取所有資料
            // 邏輯：對每個玩家，找到他們最高關卡的最佳記錄（步數最少，時間最短）
            const { data: leaderboardData, error } = await this.supabase
                .rpc('get_quest_leaderboard', { result_limit: limit });
                
            console.log('RPC查詢結果:', { leaderboardData, error });
            
            if (error) {
                console.error('RPC查詢失敗，使用備用查詢:', error);
                
                // 備用方案：分步查詢然後合併
                return await this.getQuestLeaderboardFallback(limit);
            }
            
            if (!leaderboardData || leaderboardData.length === 0) {
                console.log('沒有找到任何排行榜資料');
                return [];
            }
            
            // 格式化結果
            const result = leaderboardData.map((item, index) => ({
                rank: index + 1,
                player_id: item.player_id,
                username: item.username || `玩家_${item.player_id.slice(-4)}`,
                avatar_url: item.avatar_url,
                highest_level: item.highest_level_cleared,
                score: item.highest_level_cleared, // 使用關卡數作為分數
                moves_used: item.moves_used || 0,
                moves_remaining: item.moves_remaining || 0, // 剩餘步數
                time_taken: item.time_taken || 0,
                achieved_at: item.achieved_at,
                progress_updated_at: item.progress_updated_at
            }));
            
            console.log('最終排行榜結果:', result);
            return result;
            
        } catch (error) {
            console.error('獲取 quest 排行榜失敗:', error);
            // 使用備用查詢
            return await this.getQuestLeaderboardFallback(limit);
        }
    }
    
    // 備用查詢方法（分步查詢）
    async getQuestLeaderboardFallback(limit = 50) {
        try {
            console.log('使用備用查詢方法...');
            
            // 先獲取所有玩家的進度記錄
            const { data: progressData, error: progressError } = await this.supabase
                .from('player_quest_progress')
                .select('player_id, highest_level_cleared, updated_at')
                .order('highest_level_cleared', { ascending: false })
                .order('updated_at', { ascending: true })
                .limit(limit * 2); // 取更多資料確保有足夠玩家
                
            console.log('進度資料:', { progressData, progressError });
                
            if (progressError || !progressData) return [];
            
            // 獲取所有玩家基本資料
            const playerIds = progressData.map(p => p.player_id);
            const { data: playersData, error: playersError } = await this.supabase
                .from('players')
                .select('id, username, avatar_url')
                .in('id', playerIds);
                
            console.log('玩家資料:', { playersData, playersError });
            
            // 建立玩家資料對照表
            const playersMap = new Map();
            (playersData || []).forEach(player => {
                playersMap.set(player.id, player);
            });
            
            // 批量獲取所有相關的 quest 記錄
            const allLevels = [...new Set(progressData.map(p => p.highest_level_cleared).filter(level => level > 0))];
            const { data: allQuestRecords, error: recordsError } = await this.supabase
                .from('quest_records')
                .select('player_id, level_number, score, moves_used, moves_remaining, time_taken, created_at')
                .in('player_id', playerIds)
                .in('level_number', allLevels)
                .eq('is_completed', true)
                .order('moves_used', { ascending: true })
                .order('time_taken', { ascending: true })
                .order('created_at', { ascending: true });
                
            console.log('Quest記錄資料:', { allQuestRecords, recordsError });
            
            // 為每個玩家建立記錄對照表（找最佳記錄）
            const recordsMap = new Map();
            (allQuestRecords || []).forEach(record => {
                const key = `${record.player_id}_${record.level_number}`;
                if (!recordsMap.has(key)) {
                    recordsMap.set(key, record); // 已經按最佳條件排序，取第一筆
                }
            });
            
            // 合併資料
            const leaderboard = [];
            for (const progress of progressData) {
                const playerInfo = playersMap.get(progress.player_id);
                if (!playerInfo || progress.highest_level_cleared === 0) continue;
                
                const recordKey = `${progress.player_id}_${progress.highest_level_cleared}`;
                const bestRecord = recordsMap.get(recordKey);
                
                leaderboard.push({
                    player_id: progress.player_id,
                    username: playerInfo.username,
                    avatar_url: playerInfo.avatar_url,
                    highest_level: progress.highest_level_cleared,
                    score: progress.highest_level_cleared,
                    moves_used: bestRecord?.moves_used || 0,
                    moves_remaining: bestRecord?.moves_remaining || 0,
                    time_taken: bestRecord?.time_taken || 0,
                    achieved_at: bestRecord?.created_at || progress.updated_at,
                    progress_updated_at: progress.updated_at
                });
            }
            
            // 最終排序：關卡高 -> 步數少 -> 時間短 -> 達成時間早
            leaderboard.sort((a, b) => {
                if (a.highest_level !== b.highest_level) {
                    return b.highest_level - a.highest_level;
                }
                if (a.moves_used !== b.moves_used) {
                    return a.moves_used - b.moves_used;
                }
                if (a.time_taken !== b.time_taken) {
                    return a.time_taken - b.time_taken;
                }
                return new Date(a.achieved_at) - new Date(b.achieved_at);
            });
            
            // 添加排名並限制結果
            return leaderboard.slice(0, limit).map((player, index) => ({
                ...player,
                rank: index + 1
            }));
            
        } catch (error) {
            console.error('備用查詢也失敗:', error);
            return [];
        }
    }
    
    // 獲取存活模式排行榜 (按存活時間、分數排序)
    async getSurvivalLeaderboard(limit = 50) {
        try {
            console.log('開始獲取存活模式排行榜...');
            
            // 查詢 leaderboards 表，篩選存活模式的記錄
            const { data: leaderboardData, error } = await this.supabase
                .from('leaderboards')
                .select(`
                    *,
                    players!inner (
                        username,
                        avatar_url
                    )
                `)
                .eq('game_mode', 'survival')
                .order('best_time', { ascending: false }) // 先按存活時間排序（時間越長越好）
                .order('best_score', { ascending: false }) // 再按最佳分數排序
                .limit(limit);
                
            console.log('存活模式排行榜查詢結果:', { leaderboardData, error });
            
            if (error) {
                console.error('查詢 leaderboards 表失敗，嘗試查詢 game_records 表:', error);
                
                // 備用方案：查詢 game_records 表
                return await this.getSurvivalLeaderboardFromGameRecords(limit);
            }
            
            if (!leaderboardData || leaderboardData.length === 0) {
                console.log('leaderboards 表中沒有存活模式資料，嘗試 game_records 表');
                return await this.getSurvivalLeaderboardFromGameRecords(limit);
            }
            
            // 格式化結果
            const result = leaderboardData.map((item, index) => ({
                rank: index + 1,
                player_id: item.player_id,
                username: item.players?.username || `玩家_${item.player_id.slice(-4)}`,
                avatar_url: item.players?.avatar_url,
                score: item.best_score || 0,
                time: item.best_time || 0,
                time_taken: item.best_time || 0,
                moves: item.best_moves || 0,
                moves_used: item.best_moves || 0,
                level: item.level_reached || 1,
                date: new Date(item.latest_play || item.created_at).toLocaleDateString('zh-TW'),
                created_at: item.latest_play || item.created_at
            }));
            
            console.log('存活模式排行榜結果:', result);
            return result;
            
        } catch (error) {
            console.error('獲取存活模式排行榜失敗:', error);
            // 備用方案
            return await this.getSurvivalLeaderboardFromGameRecords(limit);
        }
    }
    
    // 從 game_records 表獲取存活模式排行榜（備用方案）
    async getSurvivalLeaderboardFromGameRecords(limit = 50) {
        try {
            console.log('從 game_records 表獲取存活模式排行榜...');
            
            // 獲取所有存活模式記錄
            const { data: allRecords, error: recordsError } = await this.supabase
                .from('game_records')
                .select('id, player_id, score, moves_used, time_taken, level_reached, created_at')
                .eq('game_mode', 'survival');
            
            if (recordsError) throw recordsError;
            
            console.log('找到的存活模式記錄:', allRecords);
            
            if (!allRecords || allRecords.length === 0) {
                console.log('沒有找到任何存活模式記錄');
                return [];
            }
            
            // 找出每個玩家的最佳記錄（先按時間，再按分數）
            const playerBestRecords = new Map();
            allRecords.forEach(record => {
                const playerId = record.player_id;
                const currentBest = playerBestRecords.get(playerId);
                
                if (!currentBest) {
                    playerBestRecords.set(playerId, record);
                } else {
                    // 先比較存活時間，再比較分數
                    if (record.time_taken > currentBest.time_taken || 
                        (record.time_taken === currentBest.time_taken && record.score > currentBest.score)) {
                        playerBestRecords.set(playerId, record);
                    }
                }
            });
            
            // 獲取玩家資料
            const playerIds = Array.from(playerBestRecords.keys());
            const { data: playersData, error: playersError } = await this.supabase
                .from('players')
                .select('id, username, avatar_url')
                .in('id', playerIds);
                
            if (playersError) {
                console.error('獲取玩家資料失敗:', playersError);
            }
            
            // 建立玩家資料對照表
            const playersMap = new Map();
            (playersData || []).forEach(player => {
                playersMap.set(player.id, player);
            });
            
            // 轉換並排序
            const leaderboard = Array.from(playerBestRecords.values())
                .sort((a, b) => {
                    // 先按存活時間降序排列（時間越長越好）
                    if (a.time_taken !== b.time_taken) {
                        return b.time_taken - a.time_taken;
                    }
                    // 存活時間相同時，按分數降序排列
                    return b.score - a.score;
                })
                .slice(0, limit)
                .map((record, index) => {
                    const playerInfo = playersMap.get(record.player_id);
                    return {
                        rank: index + 1,
                        player_id: record.player_id,
                        username: playerInfo?.username || `玩家_${record.player_id.slice(-4)}`,
                        avatar_url: playerInfo?.avatar_url,
                        score: record.score,
                        time: record.time_taken,
                        time_taken: record.time_taken,
                        moves: record.moves_used,
                        moves_used: record.moves_used,
                        level: record.level_reached,
                        date: new Date(record.created_at).toLocaleDateString('zh-TW'),
                        created_at: record.created_at
                    };
                });
            
            console.log('從 game_records 獲取的存活模式排行榜:', leaderboard);
            return leaderboard;
            
        } catch (error) {
            console.error('從 game_records 獲取存活模式排行榜失敗:', error);
            return [];
        }
    }
}

// 全域實例
window.supabaseAuth = new SupabaseAuth(); 