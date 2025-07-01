class QuestMode {
    constructor() {
        this.questData = {
            chapters: [
                { name: "第一章：甦醒森林", levels: 10 },
                { name: "第二章：熔岩洞窟 (即將推出)", levels: 0 },
                { name: "第三章：天空之城 (即將推出)", levels: 0 }
            ]
        };
        this.playerProgress = {
            highestClearedLevel: 0 
        };
        this.currentChapter = 0; // 從第一章開始
        this.tabsContainer = document.getElementById('chapter-tabs');
        this.levelsContainer = document.getElementById('levels-container');
        this.loadingIndicator = null;
        this.bestRecords = {}; // 緩存所有關卡的最佳記錄
    }

    async init() {
        this.showLoading();
        await this.loadPlayerProgress();
        await this.loadBestRecords(); // 一次性加載所有最佳記錄
        await this.loadProgressOverview();
        this.hideLoading();
        this.renderTabs();
        this.renderLevelsForChapter(this.currentChapter);
    }

    showLoading() {
        this.loadingIndicator = document.createElement('div');
        this.loadingIndicator.className = 'flex items-center justify-center p-8';
        this.loadingIndicator.innerHTML = `
            <div class="text-center">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto mb-2"></div>
                <div class="text-gray-600">載入進度中...</div>
            </div>
        `;
        if (this.levelsContainer) {
            this.levelsContainer.appendChild(this.loadingIndicator);
        }
    }

    hideLoading() {
        if (this.loadingIndicator && this.loadingIndicator.parentNode) {
            this.loadingIndicator.parentNode.removeChild(this.loadingIndicator);
        }
    }

    async loadPlayerProgress() {
        try {
            if (window.supabaseAuth && window.supabaseAuth.isAuthenticated()) {
                const progress = await window.supabaseAuth.getPlayerQuestProgress();
                this.playerProgress.highestClearedLevel = progress.highest_level_cleared || 0;
                console.log('載入玩家進度:', this.playerProgress);
            } else {
                console.log('用戶未登入，使用預設進度');
                // 未登入用戶可以體驗第一關
                this.playerProgress.highestClearedLevel = 0;
            }
        } catch (error) {
            console.error('載入玩家進度失敗:', error);
            // 發生錯誤時使用預設進度
            this.playerProgress.highestClearedLevel = 0;
        }
    }

    async loadBestRecords() {
        try {
            if (window.supabaseAuth && window.supabaseAuth.isAuthenticated() && this.playerProgress.highestClearedLevel > 0) {
                // 批量獲取所有已通關關卡的最佳記錄
                const allBestRecords = await window.supabaseAuth.getAllQuestBestRecords();
                
                // 將記錄組織成以關卡編號為鍵的對象
                this.bestRecords = {};
                if (allBestRecords && allBestRecords.length > 0) {
                    allBestRecords.forEach(record => {
                        this.bestRecords[record.level_number] = record;
                    });
                }
                console.log('載入最佳記錄:', this.bestRecords);
            }
        } catch (error) {
            console.error('載入最佳記錄失敗:', error);
            this.bestRecords = {};
        }
    }

    async loadProgressOverview() {
        const overviewEl = document.getElementById('progress-overview');
        if (!overviewEl) return;

        try {
            if (window.supabaseAuth && window.supabaseAuth.isAuthenticated()) {
                // 獲取總統計資料
                const totalCleared = this.playerProgress.highestClearedLevel;
                const currentChapter = Math.ceil((totalCleared + 1) / 10);
                
                // 使用已載入的最佳記錄來計算嘗試次數，避免額外的 API 調用
                const totalAttempts = Object.keys(this.bestRecords).length;

                // 更新UI
                if (document.getElementById('total-cleared')) {
                    document.getElementById('total-cleared').textContent = totalCleared;
                }
                if (document.getElementById('current-chapter')) {
                    document.getElementById('current-chapter').textContent = Math.min(currentChapter, 3);
                }
                if (document.getElementById('total-attempts')) {
                    document.getElementById('total-attempts').textContent = totalAttempts;
                }

                // 顯示進度總覽
                overviewEl.classList.remove('hidden');
            }
        } catch (error) {
            console.error('載入進度總覽失敗:', error);
        }
    }

    renderTabs() {
        this.tabsContainer.innerHTML = '';
        this.questData.chapters.forEach((chapter, index) => {
            const tab = document.createElement('button');
            tab.textContent = chapter.name;
            tab.className = 'chapter-tab';
            if (index === this.currentChapter) {
                tab.classList.add('active');
            }
            tab.onclick = () => {
                this.currentChapter = index;
                // 只重新渲染標籤和關卡，不重新載入數據
                this.renderTabs();
                this.renderLevelsForChapter(this.currentChapter);
            };
            this.tabsContainer.appendChild(tab);
        });
    }

    renderLevelsForChapter(chapterIndex) {
        this.levelsContainer.innerHTML = '';
        const chapter = this.questData.chapters[chapterIndex];
        
        // 如果是即將推出的章節（levels = 0）
        if (chapter.levels === 0) {
            const comingSoonDiv = document.createElement('div');
            comingSoonDiv.className = 'coming-soon-message text-center py-16';
            comingSoonDiv.innerHTML = `
                <div class="text-6xl mb-4">🚧</div>
                <h3 class="text-2xl font-bold text-yellow-400 mb-4">即將推出</h3>
                <p class="text-gray-300 mb-4">開發團隊正在努力製作中...</p>
                <p class="text-gray-400 text-sm">敬請期待更多精彩關卡！</p>
            `;
            this.levelsContainer.appendChild(comingSoonDiv);
            return;
        }
        
        // 正常章節的關卡渲染
        const levelsGrid = document.createElement('div');
        levelsGrid.className = 'levels-grid';

        const baseLevelOffset = chapterIndex * 10;

        for (let i = 1; i <= chapter.levels; i++) {
            const levelNumber = baseLevelOffset + i;
            const node = this.createLevelNode(levelNumber);
            levelsGrid.appendChild(node);
        }
        this.levelsContainer.appendChild(levelsGrid);
    }

    createLevelNode(levelNumber) {
        const node = document.createElement('div');
        node.className = 'level-node';
        
        const numberSpan = document.createElement('span');
        numberSpan.className = 'level-number';
        numberSpan.textContent = levelNumber;

        const statusIcon = document.createElement('span');
        statusIcon.className = 'level-status-icon';

        let status = '';

        if (levelNumber <= this.playerProgress.highestClearedLevel) {
            status = 'cleared';
            statusIcon.textContent = '✔️'; // 已破關
            
            // 為已通關的關卡添加最佳分數顯示
            this.addBestScoreToNode(node, levelNumber);
        } else if (levelNumber === this.playerProgress.highestClearedLevel + 1) {
            status = 'unlocked';
            statusIcon.textContent = '⚔️'; // 可挑戰
        } else {
            status = 'locked';
            statusIcon.textContent = '🔒'; // 未開放
        }
        
        node.classList.add(status);

        if (status === 'unlocked' || status === 'cleared') {
            node.onclick = () => this.selectLevel(levelNumber);
            node.style.cursor = 'pointer';
        }
        
        node.appendChild(numberSpan);
        node.appendChild(statusIcon);
        
        return node;
    }

    addBestScoreToNode(node, levelNumber) {
        try {
            // 使用緩存的最佳記錄，不再發送 API 請求
            const bestRecord = this.bestRecords[levelNumber];
            if (bestRecord) {
                const scoreSpan = document.createElement('div');
                scoreSpan.className = 'level-best-score';
                scoreSpan.textContent = `最佳: ${bestRecord.score}分`;
                node.appendChild(scoreSpan);
            }
        } catch (error) {
            console.error(`獲取關卡 ${levelNumber} 最佳記錄失敗:`, error);
        }
    }

    selectLevel(levelNumber) {
        console.log(`選擇關卡 ${levelNumber}`);
        this.showLevelConfirmationModal(levelNumber);
    }

    showLevelConfirmationModal(levelNumber) {
        const levelData = GameModes.quest.levelDetails[levelNumber];
        if (!levelData) {
            console.error(`找不到關卡 ${levelNumber} 的資料`);
            return;
        }

        // 創建遮罩層
        const modalOverlay = document.createElement('div');
        modalOverlay.className = 'fixed inset-0 bg-black/70 flex items-center justify-center z-50 transition-opacity duration-300';
        modalOverlay.id = 'level-confirmation-modal';
        
        const enemyImageSrc = `images/monster/ch1-${levelNumber}.png`;
        const restrictionsHTML = this.createRestrictionsHTML(levelData.restrictions);

        modalOverlay.innerHTML = `
            <div class="modal-card bg-gray-800 border-2 border-yellow-500/50 rounded-2xl shadow-lg w-full max-w-sm m-4 transform scale-95 transition-transform duration-300">
                <div class="p-6">
                    <h2 class="text-2xl font-bold text-center text-yellow-400 mb-4">關卡 ${levelNumber}</h2>
                    <div class="flex flex-col items-center">
                        <div class="w-32 h-32 bg-gray-900/50 rounded-full p-2 border-2 border-gray-700">
                            <img src="${enemyImageSrc}" alt="${levelData.name}" class="w-full h-full object-contain">
                        </div>
                        <h3 class="text-xl font-bold mt-3 text-white">${levelData.name}</h3>
                        <p class="text-sm text-gray-400 mt-1 text-center h-10">${levelData.description}</p>
                    </div>

                    <div class="grid grid-cols-2 gap-4 my-6 text-center">
                        <div>
                            <div class="font-bold text-lg text-red-400">${levelData.maxHP}</div>
                            <div class="text-sm text-gray-400">敵人血量</div>
                        </div>
                        <div>
                            <div class="font-bold text-lg text-blue-400">${levelData.moves}</div>
                            <div class="text-sm text-gray-400">可用步數</div>
                        </div>
                    </div>
                    
                    ${restrictionsHTML}

                    <div class="flex gap-4 mt-6">
                        <button id="cancel-level-btn" class="flex-1 bg-gray-600 hover:bg-gray-500 text-white font-bold py-3 rounded-lg transition-colors">返回</button>
                        <button id="start-level-btn" class="flex-1 bg-yellow-500 hover:bg-yellow-400 text-gray-900 font-bold py-3 rounded-lg transition-colors shadow-lg">開始挑戰</button>
                    </div>
                </div>
            </div>
        `;

        document.body.appendChild(modalOverlay);

        // 動畫效果
        setTimeout(() => {
            modalOverlay.classList.add('opacity-100');
            modalOverlay.querySelector('.modal-card').classList.remove('scale-95');
        }, 10);

        // 事件監聽
        modalOverlay.querySelector('#start-level-btn').onclick = () => {
            window.location.href = `game.html?mode=quest&level=${levelNumber}`;
        };

        const closeModal = () => {
            modalOverlay.classList.remove('opacity-100');
            modalOverlay.querySelector('.modal-card').classList.add('scale-95');
            setTimeout(() => {
                document.body.removeChild(modalOverlay);
            }, 300);
        };
        
        modalOverlay.querySelector('#cancel-level-btn').onclick = closeModal;
    }

    createRestrictionsHTML(restrictions) {
        if (!restrictions || Object.keys(restrictions).length === 0) {
            return '<div class="h-10"></div>'; // 佔位
        }

        const descriptions = [];
        const colorMap = {
            red: '紅色', blue: '藍色', green: '綠色',
            yellow: '黃色', purple: '紫色'
        };

        if (restrictions.minComboForDamage) {
            descriptions.push(`連擊 ≥ ${restrictions.minComboForDamage} 才能造成傷害`);
        }
        if (restrictions.minChainForDamage) {
            descriptions.push(`連鎖 ≥ ${restrictions.minChainForDamage} 才能造成傷害`);
        }
        if (restrictions.noDamageColors) {
            const colors = restrictions.noDamageColors.map(c => colorMap[c] || c).join('、');
            descriptions.push(`${colors}方塊無效`);
        }
        if (restrictions.damageOnlyColors) {
            const colors = restrictions.damageOnlyColors.map(c => colorMap[c] || c).join('、');
            descriptions.push(`僅 ${colors}方塊有效`);
        }
        if (restrictions.requireHorizontalMatch) {
            descriptions.push('僅限橫向消除有效');
        }

        if (descriptions.length === 0) return '<div class="h-10"></div>';

        return `
            <div class="bg-gray-900/70 rounded-lg p-3 text-center">
                <div class="text-sm font-bold text-yellow-300 mb-2">關卡限制</div>
                <div class="flex flex-col items-center gap-1 text-xs text-yellow-100/90">
                ${descriptions.map(desc => `<span>${desc}</span>`).join('')}
                </div>
            </div>
        `;
    }
} 