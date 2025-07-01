class QuestMode {
    constructor() {
        this.questData = {
            chapters: [
                { name: "第一章：甦醒森林", levels: 10 },
                { name: "第二章：熔岩洞窟", levels: 10 },
                { name: "第三章：天空之城", levels: 10 }
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
        // 導航到遊戲頁面，並帶上關卡參數
        // TODO: 未來將 mode=quest 傳遞給遊戲引擎
        window.location.href = `game.html?mode=quest&level=${levelNumber}`;
    }
} 