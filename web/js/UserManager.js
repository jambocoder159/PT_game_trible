// 用戶界面管理器
class UserManager {
    constructor(supabaseAuth, leaderboardManager) {
        this.supabaseAuth = supabaseAuth;
        this.leaderboardManager = leaderboardManager;
        this.currentUser = null;
        this.userProfile = null;
        
        // 監聽認證狀態變化
        this.supabaseAuth.onAuthStateChange((event, session) => {
            this.handleAuthStateChange(event, session);
        });
    }
    
    // 處理認證狀態變化
    async handleAuthStateChange(event, session) {
        if (event === 'SIGNED_IN' && session) {
            this.currentUser = session.user;
            await this.loadUserProfile();
            this.updateUI();
            this.supabaseAuth.updateLastLogin();
        } else if (event === 'SIGNED_OUT') {
            this.currentUser = null;
            this.userProfile = null;
            this.updateUI();
        }
    }
    
    // 載入用戶資料
    async loadUserProfile() {
        try {
            this.userProfile = await this.supabaseAuth.getUserProfile();
        } catch (error) {
            console.error('載入用戶資料失敗:', error);
        }
    }
    
    // 更新用戶界面
    updateUI() {
        this.updateAuthSection();
        this.updateUserInfo();
        this.updateGameButtons();
    }
    
    // 更新認證區域
    updateAuthSection() {
        const authSection = document.getElementById('authSection');
        if (!authSection) return;
        
        if (this.currentUser && this.userProfile) {
            authSection.innerHTML = this.createUserProfileHTML();
        } else {
            authSection.innerHTML = this.createLoginHTML();
        }
    }
    
    // 創建登入界面HTML
    createLoginHTML() {
        return `
            <div class="bg-white/90 backdrop-blur-md rounded-xl p-6 shadow-lg">
                <h3 class="text-lg font-bold text-slate-800 mb-4 text-center">🎮 登入開始遊戲</h3>
                <p class="text-slate-600 text-sm mb-4 text-center">登入後可保存成績並參與排行榜競賽！</p>
                <div class="space-y-3">
                    <button 
                        onclick="userManager.signInWithGoogle()" 
                        class="w-full bg-red-500 hover:bg-red-600 text-white font-medium py-3 px-4 rounded-lg flex items-center justify-center gap-2 transition-colors"
                    >
                        <span>🔍</span>
                        Google 登入
                    </button>
                    <button 
                        onclick="userManager.signInWithGitHub()" 
                        class="w-full bg-gray-800 hover:bg-gray-900 text-white font-medium py-3 px-4 rounded-lg flex items-center justify-center gap-2 transition-colors"
                    >
                        <span>🐙</span>
                        GitHub 登入
                    </button>
                    <button 
                        onclick="userManager.signInWithDiscord()" 
                        class="w-full bg-indigo-500 hover:bg-indigo-600 text-white font-medium py-3 px-4 rounded-lg flex items-center justify-center gap-2 transition-colors"
                    >
                        <span>💬</span>
                        Discord 登入
                    </button>
                </div>
                <p class="text-xs text-slate-500 mt-4 text-center">
                    點擊登入即表示您同意我們的服務條款
                </p>
            </div>
        `;
    }
    
    // 創建用戶資料界面HTML
    createUserProfileHTML() {
        return `
            <div class="bg-white/90 backdrop-blur-md rounded-xl p-6 shadow-lg">
                <div class="flex items-center gap-4 mb-4">
                    <div class="relative">
                        <img 
                            src="${this.userProfile.avatar_url || 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDgiIGhlaWdodD0iNDgiIHZpZXdCb3g9IjAgMCA0OCA0OCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iMjQiIGN5PSIyNCIgcj0iMjQiIGZpbGw9IiNGM0Y0RjYiLz4KPGNpcmNsZSBjeD0iMjQiIGN5PSIyMCIgcj0iOCIgZmlsbD0iIzlDQTNBRiIvPgo8cGF0aCBkPSJNMTAgMzZDMTAgMzEuNTgxNyAxMy41ODE3IDI4IDE4IDI4SDMwQzM0LjQxODMgMjggMzggMzEuNTgxNyAzOCAzNlY0MEgxMFYzNloiIGZpbGw9IiM5Q0EzQUYiLz4KPC9zdmc+Cg=='}" 
                            alt="用戶頭像" 
                            class="w-12 h-12 rounded-full border-2 border-blue-200"
                        >
                        <div class="absolute -top-1 -right-1 w-4 h-4 bg-green-500 rounded-full border-2 border-white"></div>
                    </div>
                    <div class="flex-1">
                        <h3 class="font-bold text-slate-800">${this.userProfile.username}</h3>
                        <p class="text-sm text-slate-600">${this.userProfile.email}</p>
                    </div>
                    <button 
                        onclick="userManager.signOut()" 
                        class="text-slate-500 hover:text-red-500 transition-colors"
                        title="登出"
                    >
                        ⬅️
                    </button>
                </div>
                
                <div class="grid grid-cols-2 gap-4 text-center">
                    <button 
                        onclick="userManager.showPersonalStats()" 
                        class="bg-blue-50 hover:bg-blue-100 text-blue-700 font-medium py-2 px-3 rounded-lg transition-colors"
                    >
                        📊 我的成績
                    </button>
                    <button 
                        onclick="userManager.showLeaderboard()" 
                        class="bg-yellow-50 hover:bg-yellow-100 text-yellow-700 font-medium py-2 px-3 rounded-lg transition-colors"
                    >
                        🏆 排行榜
                    </button>
                </div>
            </div>
        `;
    }
    
    // 更新用戶資訊區域
    updateUserInfo() {
        const userInfoSection = document.getElementById('userInfoSection');
        if (!userInfoSection) return;
        
        if (this.currentUser && this.userProfile) {
            userInfoSection.classList.remove('hidden');
        } else {
            userInfoSection.classList.add('hidden');
        }
    }
    
    // 更新遊戲按鈕
    updateGameButtons() {
        // 可以在這裡根據登入狀態調整遊戲按鈕的樣式或功能
    }
    
    // Google 登入
    async signInWithGoogle() {
        try {
            await this.supabaseAuth.signInWithGoogle();
        } catch (error) {
            this.showError('Google 登入失敗: ' + error.message);
        }
    }
    
    // GitHub 登入
    async signInWithGitHub() {
        try {
            await this.supabaseAuth.signInWithGitHub();
        } catch (error) {
            this.showError('GitHub 登入失敗: ' + error.message);
        }
    }
    
    // Discord 登入
    async signInWithDiscord() {
        try {
            await this.supabaseAuth.signInWithDiscord();
        } catch (error) {
            this.showError('Discord 登入失敗: ' + error.message);
        }
    }
    
    // 登出
    async signOut() {
        try {
            await this.supabaseAuth.signOut();
        } catch (error) {
            this.showError('登出失敗: ' + error.message);
        }
    }
    
    // 顯示個人統計
    async showPersonalStats() {
        const modal = this.createModal();
        modal.innerHTML = `
            <div class="bg-white rounded-xl p-6 max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
                <div class="flex justify-between items-center mb-4">
                    <h2 class="text-xl font-bold text-slate-800">📊 我的遊戲統計</h2>
                    <button onclick="this.closest('.fixed').remove()" class="text-slate-500 hover:text-slate-700">
                        ❌
                    </button>
                </div>
                <div id="personalStatsContent">
                    <div class="text-center py-8">
                        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto"></div>
                        <p class="mt-2 text-slate-600">載入中...</p>
                    </div>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
        
        // 載入個人統計資料
        await this.loadPersonalStats();
    }
    
    // 載入個人統計資料
    async loadPersonalStats() {
        const content = document.getElementById('personalStatsContent');
        if (!content) return;
        
        try {
            const gameModes = ['classic', 'double', 'triple', 'timeLimit'];
            const stats = {};
            
            for (const mode of gameModes) {
                const personalBest = await this.supabaseAuth.getPersonalBest(mode);
                const history = await this.supabaseAuth.getPersonalHistory(mode, 5);
                const rank = await this.leaderboardManager.getUserRank(mode);
                
                stats[mode] = {
                    personalBest,
                    history,
                    rank
                };
            }
            
            content.innerHTML = this.createPersonalStatsHTML(stats);
        } catch (error) {
            content.innerHTML = `
                <div class="text-center py-8">
                    <p class="text-red-600">載入統計資料失敗：${error.message}</p>
                </div>
            `;
        }
    }
    
    // 創建個人統計HTML
    createPersonalStatsHTML(stats) {
        const modeNames = {
            classic: '👾 經典模式',
            double: '🚀 快速模式',
            triple: '🌟 進階模式',
            timeLimit: '⏳ 限時模式'
        };
        
        let html = '<div class="space-y-6">';
        
        for (const [mode, data] of Object.entries(stats)) {
            html += `
                <div class="bg-slate-50 rounded-lg p-4">
                    <h3 class="font-bold text-slate-800 mb-3">${modeNames[mode]}</h3>
                    
                    ${data.personalBest ? `
                        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4">
                            <div class="text-center">
                                <p class="text-2xl font-bold text-blue-600">${data.personalBest.score}</p>
                                <p class="text-xs text-slate-600">最高分</p>
                            </div>
                            <div class="text-center">
                                <p class="text-2xl font-bold text-green-600">${data.personalBest.moves_used}</p>
                                <p class="text-xs text-slate-600">步數</p>
                            </div>
                            <div class="text-center">
                                <p class="text-2xl font-bold text-purple-600">${Math.round(data.personalBest.time_taken / 1000)}s</p>
                                <p class="text-xs text-slate-600">用時</p>
                            </div>
                            <div class="text-center">
                                <p class="text-2xl font-bold text-orange-600">${data.rank ? `#${data.rank.rank}` : '-'}</p>
                                <p class="text-xs text-slate-600">排名</p>
                            </div>
                        </div>
                    ` : `
                        <p class="text-slate-500 text-center py-4">尚未遊玩此模式</p>
                    `}
                    
                    ${data.history.length > 0 ? `
                        <div>
                            <h4 class="font-medium text-slate-700 mb-2">最近記錄</h4>
                            <div class="space-y-2">
                                ${data.history.slice(0, 3).map(record => `
                                    <div class="flex justify-between items-center text-sm">
                                        <span class="text-slate-600">${new Date(record.created_at).toLocaleDateString('zh-TW')}</span>
                                        <span class="font-medium">${record.score} 分</span>
                                        <span class="text-slate-500">${record.moves_used} 步</span>
                                    </div>
                                `).join('')}
                            </div>
                        </div>
                    ` : ''}
                </div>
            `;
        }
        
        html += '</div>';
        return html;
    }
    
    // 顯示排行榜
    async showLeaderboard() {
        const modal = this.createModal();
        modal.innerHTML = `
            <div class="bg-white rounded-xl p-6 max-w-4xl w-full mx-4 max-h-[90vh] overflow-y-auto">
                <div class="flex justify-between items-center mb-4">
                    <h2 class="text-xl font-bold text-slate-800">🏆 遊戲排行榜</h2>
                    <button onclick="this.closest('.fixed').remove()" class="text-slate-500 hover:text-slate-700">
                        ❌
                    </button>
                </div>
                
                <div class="flex flex-wrap gap-2 mb-4">
                    <button onclick="userManager.loadLeaderboard('classic')" class="leaderboard-tab-btn px-4 py-2 rounded-lg bg-blue-100 text-blue-700">👾 經典</button>
                    <button onclick="userManager.loadLeaderboard('double')" class="leaderboard-tab-btn px-4 py-2 rounded-lg bg-slate-100 text-slate-700">🚀 快速</button>
                    <button onclick="userManager.loadLeaderboard('triple')" class="leaderboard-tab-btn px-4 py-2 rounded-lg bg-slate-100 text-slate-700">🌟 進階</button>
                    <button onclick="userManager.loadLeaderboard('timeLimit')" class="leaderboard-tab-btn px-4 py-2 rounded-lg bg-slate-100 text-slate-700">⏳ 限時</button>
                </div>
                
                <div id="leaderboardContent">
                    <div class="text-center py-8">
                        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto"></div>
                        <p class="mt-2 text-slate-600">載入中...</p>
                    </div>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
        
        // 載入經典模式排行榜
        await this.loadLeaderboard('classic');
    }
    
    // 載入排行榜
    async loadLeaderboard(gameMode) {
        const content = document.getElementById('leaderboardContent');
        if (!content) return;
        
        // 更新標籤樣式
        document.querySelectorAll('.leaderboard-tab-btn').forEach(btn => {
            btn.className = 'leaderboard-tab-btn px-4 py-2 rounded-lg bg-slate-100 text-slate-700';
        });
        event?.target?.classList.add('bg-blue-100', 'text-blue-700');
        event?.target?.classList.remove('bg-slate-100', 'text-slate-700');
        
        content.innerHTML = `
            <div class="text-center py-8">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto"></div>
                <p class="mt-2 text-slate-600">載入中...</p>
            </div>
        `;
        
        try {
            const leaderboard = await this.leaderboardManager.getGlobalLeaderboard(gameMode, 'all', 20);
            content.innerHTML = this.createLeaderboardHTML(leaderboard);
        } catch (error) {
            content.innerHTML = `
                <div class="text-center py-8">
                    <p class="text-red-600">載入排行榜失敗：${error.message}</p>
                </div>
            `;
        }
    }
    
    // 創建排行榜HTML
    createLeaderboardHTML(leaderboard) {
        if (leaderboard.length === 0) {
            return `
                <div class="text-center py-8">
                    <p class="text-slate-500">暫無排行榜資料</p>
                </div>
            `;
        }
        
        return `
            <div class="space-y-2">
                ${leaderboard.map(player => `
                    <div class="flex items-center gap-4 p-3 rounded-lg ${player.username === this.userProfile?.username ? 'bg-blue-50 border border-blue-200' : 'bg-slate-50'}">
                        <div class="flex-shrink-0 w-8 text-center">
                            ${player.rank <= 3 ? 
                                ['🥇', '🥈', '🥉'][player.rank - 1] : 
                                `<span class="text-slate-600 font-bold">${player.rank}</span>`
                            }
                        </div>
                        <img 
                            src="${player.avatar_url || 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHZpZXdCb3g9IjAgMCAzMiAzMiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iMTYiIGN5PSIxNiIgcj0iMTYiIGZpbGw9IiNGM0Y0RjYiLz4KPGNpcmNsZSBjeD0iMTYiIGN5PSIxMiIgcj0iNSIgZmlsbD0iIzlDQTNBRiIvPgo8cGF0aCBkPSJNNyAyNEM3IDIwLjY4NjMgOS42ODYyOSAxOCAxMyAxOEgxOUMyMi4zMTM3IDE4IDI1IDIwLjY4NjMgMjUgMjRWMjZIN1YyNFoiIGZpbGw9IiM5Q0EzQUYiLz4KPC9zdmc+Cg=='}" 
                            alt="${player.username}" 
                            class="w-8 h-8 rounded-full"
                        >
                        <div class="flex-1">
                            <p class="font-medium text-slate-800">${player.username}</p>
                            <p class="text-xs text-slate-500">${player.date}</p>
                        </div>
                        <div class="text-right">
                            <p class="font-bold text-slate-800">${player.score.toLocaleString()}</p>
                            <p class="text-xs text-slate-500">${player.moves} 步</p>
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
    }
    
    // 創建模態框
    createModal() {
        const modal = document.createElement('div');
        modal.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50';
        modal.onclick = (e) => {
            if (e.target === modal) {
                modal.remove();
            }
        };
        return modal;
    }
    
    // 顯示錯誤訊息
    showError(message) {
        const toast = document.createElement('div');
        toast.className = 'fixed top-4 right-4 bg-red-500 text-white px-4 py-2 rounded-lg shadow-lg z-50';
        toast.textContent = message;
        document.body.appendChild(toast);
        
        setTimeout(() => {
            toast.remove();
        }, 3000);
    }
    
    // 顯示成功訊息
    showSuccess(message) {
        const toast = document.createElement('div');
        toast.className = 'fixed top-4 right-4 bg-green-500 text-white px-4 py-2 rounded-lg shadow-lg z-50';
        toast.textContent = message;
        document.body.appendChild(toast);
        
        setTimeout(() => {
            toast.remove();
        }, 3000);
    }
}

// 全域實例
window.userManager = null; 