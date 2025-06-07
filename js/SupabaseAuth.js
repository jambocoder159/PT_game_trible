// Supabase 配置和認證管理
class SupabaseAuth {
    constructor() {
        // Supabase 配置
        this.supabaseUrl = 'https://admkbelthyyqngsnsxmm.supabase.co';
        this.supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkbWtiZWx0aHl5cW5nc25zeG1tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzMDU4NjMsImV4cCI6MjA2NDg4MTg2M30.NdpkqWnSJsb9bHQn8H7_CgpIkwu9f5kSzLrWV39ta2w';
        
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
            const { data, error } = await this.supabase.auth.signInWithOAuth({
                provider: 'google',
                options: {
                    redirectTo: window.location.origin + '/game.html'
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
            const { data, error } = await this.supabase.auth.signInWithOAuth({
                provider: 'github',
                options: {
                    redirectTo: window.location.origin + '/game.html'
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
            const { data, error } = await this.supabase.auth.signInWithOAuth({
                provider: 'discord',
                options: {
                    redirectTo: window.location.origin + '/game.html'
                }
            });
            
            if (error) throw error;
            return data;
        } catch (error) {
            console.error('Discord 登入失敗:', error);
            throw error;
        }
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