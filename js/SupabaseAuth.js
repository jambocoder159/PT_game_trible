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
            return;
        }
        
        this.currentUser = null;
        this.authCallbacks = [];
        
        // 監聽認證狀態變化
        this.supabase.auth.onAuthStateChange((event, session) => {
            this.currentUser = session?.user || null;
            this.notifyAuthCallbacks(event, session);
        });
        
        // 檢查當前用戶狀態
        this.checkCurrentUser();
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
        // 使用環境配置管理器
        if (this.envConfig) {
            // OAuth 登入後應該重定向到主選單
            const redirectUrl = this.envConfig.getRedirectUrl('/main-menu.html', '');
            console.log('環境配置重定向 URL:', redirectUrl);
            return redirectUrl;
        }
        
        // 備用邏輯（如果環境配置未載入）
        const baseUrl = window.location.origin;
        
        console.log('使用備用重定向邏輯:', {
            origin: window.location.origin,
            hostname: window.location.hostname,
            pathname: window.location.pathname,
            search: window.location.search
        });
        
        // OAuth 登入成功後統一重定向到主選單
        return `${baseUrl}/main-menu.html`;
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
}

// 全域實例
window.supabaseAuth = new SupabaseAuth(); 