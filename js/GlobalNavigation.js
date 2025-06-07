// 全局導航組件
class GlobalNavigation {
    constructor(supabaseAuth, userManager) {
        this.supabaseAuth = supabaseAuth;
        this.userManager = userManager;
        this.isExpanded = false;
        this.currentUser = null;
        this.userProfile = null;
        
        // 監聽認證狀態變化
        this.supabaseAuth.onAuthStateChange((event, session) => {
            this.handleAuthStateChange(event, session);
        });
        
        this.init();
    }
    
    // 初始化導航
    init() {
        this.createNavigationHTML();
        this.bindEvents();
        this.updateNavigationContent();
        // 確保導航初始為關閉狀態
        this.closeNavigation();
    }
    
    // 處理認證狀態變化
    async handleAuthStateChange(event, session) {
        if (event === 'SIGNED_IN' && session) {
            this.currentUser = session.user;
            await this.loadUserProfile();
        } else if (event === 'SIGNED_OUT') {
            this.currentUser = null;
            this.userProfile = null;
        }
        this.updateNavigationContent();
    }
    
    // 載入用戶資料
    async loadUserProfile() {
        try {
            this.userProfile = await this.supabaseAuth.getUserProfile();
        } catch (error) {
            console.error('載入用戶資料失敗:', error);
        }
    }
    
    // 創建導航HTML
    createNavigationHTML() {
        // 移除現有的導航（如果存在）
        const existingNav = document.getElementById('globalNavigation');
        if (existingNav) {
            existingNav.remove();
        }
        
        const navHTML = `
            <div id="globalNavigation" class="fixed top-4 right-4 z-50">
                <!-- 導航圖標 -->
                <div id="navIcon" class="nav-icon">
                    <div class="w-12 h-12 bg-white/90 backdrop-blur-md rounded-full shadow-lg flex items-center justify-center cursor-pointer hover:bg-white transition-all duration-300">
                        <span id="navIconContent" class="text-2xl">👤</span>
                    </div>
                </div>
                
                <!-- 展開的導航面板 -->
                <div id="navPanel" class="nav-panel">
                    <div class="bg-white/95 backdrop-blur-md rounded-xl shadow-xl p-4 w-80 max-w-[calc(100vw-2rem)] transform transition-all duration-300 origin-top-right scale-0 opacity-0">
                        <div id="navContent">
                            <!-- 內容將由 updateNavigationContent 填充 -->
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', navHTML);
        
        // 添加CSS樣式
        this.addNavigationStyles();
    }
    
    // 添加導航樣式
    addNavigationStyles() {
        const styles = `
            <style id="globalNavStyles">
                .nav-icon {
                    transition: all 0.3s ease;
                    pointer-events: auto;
                    position: relative;
                    z-index: 1000;
                }
                
                .nav-panel {
                    position: absolute;
                    top: 60px;
                    right: 0;
                    pointer-events: none;
                    z-index: 999;
                }
                
                .nav-panel.expanded {
                    pointer-events: auto;
                }
                
                .nav-panel.expanded > div {
                    transform: scale(1);
                    opacity: 1;
                }
                
                .nav-icon:hover {
                    transform: scale(1.05);
                }
                
                .user-avatar {
                    transition: all 0.3s ease;
                }
                
                .user-avatar:hover {
                    transform: scale(1.1);
                }
                
                /* 確保導航不會影響遊戲區域 */
                #globalNavigation {
                    pointer-events: none;
                }
                
                #globalNavigation .nav-icon {
                    pointer-events: auto;
                }
                
                #globalNavigation .nav-panel.expanded {
                    pointer-events: auto;
                }
                
                @media (max-width: 480px) {
                    .nav-panel > div {
                        width: calc(100vw - 2rem);
                    }
                }
            </style>
        `;
        
        if (!document.getElementById('globalNavStyles')) {
            document.head.insertAdjacentHTML('beforeend', styles);
        }
    }
    
    // 綁定事件
    bindEvents() {
        const navIcon = document.getElementById('navIcon');
        const navPanel = document.getElementById('navPanel');
        
        if (navIcon) {
            navIcon.addEventListener('click', (e) => {
                e.stopPropagation();
                this.toggleNavigation();
            });
        }
        
        // 點擊外部關閉導航
        document.addEventListener('click', (e) => {
            if (!navPanel?.contains(e.target) && !navIcon?.contains(e.target)) {
                this.closeNavigation();
            }
        });
        
        // ESC 鍵關閉導航
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.closeNavigation();
            }
        });
    }
    
    // 切換導航狀態
    toggleNavigation() {
        if (this.isExpanded) {
            this.closeNavigation();
        } else {
            this.openNavigation();
        }
    }
    
    // 打開導航
    openNavigation() {
        const navPanel = document.getElementById('navPanel');
        if (navPanel) {
            navPanel.classList.add('expanded');
            this.isExpanded = true;
            this.updateNavigationContent();
        }
    }
    
    // 關閉導航
    closeNavigation() {
        const navPanel = document.getElementById('navPanel');
        if (navPanel) {
            navPanel.classList.remove('expanded');
            this.isExpanded = false;
        }
    }
    
    // 更新導航內容
    updateNavigationContent() {
        const navContent = document.getElementById('navContent');
        const navIconContent = document.getElementById('navIconContent');
        
        if (!navContent || !navIconContent) return;
        
        if (this.currentUser && this.userProfile) {
            // 已登入狀態
            navIconContent.innerHTML = this.userProfile.avatar_url ? 
                `<img src="${this.userProfile.avatar_url}" alt="用戶頭像" class="w-8 h-8 rounded-full user-avatar">` : 
                '👤';
            
            navContent.innerHTML = this.createUserProfileContent();
        } else {
            // 未登入狀態
            navIconContent.textContent = '🔐';
            navContent.innerHTML = this.createLoginContent();
        }
    }
    
    // 創建用戶資料內容
    createUserProfileContent() {
        return `
            <div class="space-y-4">
                <!-- 用戶資訊 -->
                <div class="flex items-center gap-3 pb-3 border-b border-gray-200">
                    <img 
                        src="${this.userProfile.avatar_url || 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDgiIGhlaWdodD0iNDgiIHZpZXdCb3g9IjAgMCA0OCA0OCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iMjQiIGN5PSIyNCIgcj0iMjQiIGZpbGw9IiNGM0Y0RjYiLz4KPGNpcmNsZSBjeD0iMjQiIGN5PSIyMCIgcj0iOCIgZmlsbD0iIzlDQTNBRiIvPgo8cGF0aCBkPSJNMTAgMzZDMTAgMzEuNTgxNyAxMy41ODE3IDI4IDE4IDI4SDMwQzM0LjQxODMgMjggMzggMzEuNTgxNyAzOCAzNlY0MEgxMFYzNloiIGZpbGw9IiM5Q0EzQUYiLz4KPC9zdmc+Cg=='}" 
                        alt="用戶頭像" 
                        class="w-10 h-10 rounded-full border-2 border-blue-200"
                    >
                    <div class="flex-1">
                        <h3 class="font-bold text-gray-800 text-sm">${this.userProfile.username}</h3>
                        <p class="text-xs text-gray-600">${this.userProfile.email}</p>
                    </div>
                    <button 
                        onclick="globalNav.signOut()" 
                        class="text-gray-400 hover:text-red-500 transition-colors"
                        title="登出"
                    >
                        ⬅️
                    </button>
                </div>
                
                <!-- 功能按鈕 -->
                <div class="grid grid-cols-2 gap-2">
                    <button 
                        onclick="globalNav.showPersonalStats()" 
                        class="bg-blue-50 hover:bg-blue-100 text-blue-700 font-medium py-2 px-3 rounded-lg transition-colors text-sm"
                    >
                        📊 我的成績
                    </button>
                    <button 
                        onclick="globalNav.showLeaderboard()" 
                        class="bg-yellow-50 hover:bg-yellow-100 text-yellow-700 font-medium py-2 px-3 rounded-lg transition-colors text-sm"
                    >
                        🏆 排行榜
                    </button>
                </div>
                
                <!-- 導航連結 -->
                <div class="pt-2 border-t border-gray-200">
                    <div class="grid grid-cols-2 gap-2 text-xs">
                        <a href="index.html" class="text-gray-600 hover:text-blue-600 transition-colors text-center py-1">
                            🏠 首頁
                        </a>
                        <a href="game.html?mode=classic" class="text-gray-600 hover:text-blue-600 transition-colors text-center py-1">
                            🎮 遊戲
                        </a>
                    </div>
                </div>
            </div>
        `;
    }
    
    // 創建登入內容
    createLoginContent() {
        return `
            <div class="space-y-4">
                <div class="text-center">
                    <h3 class="font-bold text-gray-800 mb-2">🎮 登入開始遊戲</h3>
                    <p class="text-gray-600 text-xs mb-4">登入後可保存成績並參與排行榜競賽！</p>
                </div>
                
                <div class="space-y-2">
                    <button 
                        onclick="globalNav.signInWithGoogle()" 
                        class="w-full bg-red-500 hover:bg-red-600 text-white font-medium py-2 px-3 rounded-lg flex items-center justify-center gap-2 transition-colors text-sm"
                    >
                        🔍 Google 登入
                    </button>
                    <button 
                        onclick="globalNav.signInWithGitHub()" 
                        class="w-full bg-gray-800 hover:bg-gray-900 text-white font-medium py-2 px-3 rounded-lg flex items-center justify-center gap-2 transition-colors text-sm"
                    >
                        🐙 GitHub 登入
                    </button>
                    <button 
                        onclick="globalNav.signInWithDiscord()" 
                        class="w-full bg-indigo-500 hover:bg-indigo-600 text-white font-medium py-2 px-3 rounded-lg flex items-center justify-center gap-2 transition-colors text-sm"
                    >
                        💬 Discord 登入
                    </button>
                </div>
                
                <!-- 導航連結 -->
                <div class="pt-3 border-t border-gray-200">
                    <div class="grid grid-cols-2 gap-2 text-xs">
                        <a href="index.html" class="text-gray-600 hover:text-blue-600 transition-colors text-center py-1">
                            🏠 首頁
                        </a>
                        <a href="game.html?mode=classic" class="text-gray-600 hover:text-blue-600 transition-colors text-center py-1">
                            🎮 遊戲
                        </a>
                    </div>
                </div>
            </div>
        `;
    }
    
    // 登入方法
    async signInWithGoogle() {
        try {
            await this.supabaseAuth.signInWithGoogle();
            this.closeNavigation();
        } catch (error) {
            this.userManager.showError('Google 登入失敗: ' + error.message);
        }
    }
    
    async signInWithGitHub() {
        try {
            await this.supabaseAuth.signInWithGitHub();
            this.closeNavigation();
        } catch (error) {
            this.userManager.showError('GitHub 登入失敗: ' + error.message);
        }
    }
    
    async signInWithDiscord() {
        try {
            await this.supabaseAuth.signInWithDiscord();
            this.closeNavigation();
        } catch (error) {
            this.userManager.showError('Discord 登入失敗: ' + error.message);
        }
    }
    
    // 登出
    async signOut() {
        try {
            await this.supabaseAuth.signOut();
            this.closeNavigation();
        } catch (error) {
            this.userManager.showError('登出失敗: ' + error.message);
        }
    }
    
    // 顯示個人統計
    showPersonalStats() {
        this.userManager.showPersonalStats();
        this.closeNavigation();
    }
    
    // 顯示排行榜
    showLeaderboard() {
        this.userManager.showLeaderboard();
        this.closeNavigation();
    }
    
    // 銷毀導航
    destroy() {
        const nav = document.getElementById('globalNavigation');
        const styles = document.getElementById('globalNavStyles');
        
        if (nav) nav.remove();
        if (styles) styles.remove();
    }
}

// 全域實例
window.globalNav = null; 