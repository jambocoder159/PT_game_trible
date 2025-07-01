class GameEngine {
    constructor(config) {
        this.config = {
            numCols: 1,
            numRows: 10,
            blockHeight: 36, // 增加初始高度以在小螢幕上更清楚
            actionPointsStart: 5,
            gameAreaTopPadding: 28, // 增加頂部間距以容納預覽方塊
            eliminationAnimationDuration: 220,
            particleCount: 20,
            particleLifespan: 500,
            blockSwapAnimationDuration: 120,
            hasSkills: true,
            hasTimer: false,
            gameDuration: 45000,
            blockWidthPercent: 0.65,
            colors: {
                red: { hex: '#F87171', text: '紅' },
                blue: { hex: '#60A5FA', text: '藍' },
                green: { hex: '#4ADE80', text: '綠' },
                yellow: { hex: '#FACC15', text: '黃' },
                purple: { hex: '#A78BFA', text: '紫' }
            },
            theme: 'classic',
            enableHorizontalMatches: false,
            ...config
        };

        this.colorNames = Object.keys(this.config.colors);
        this.init();
    }

    init() {
        this.setupGameState();
        this.setupCanvas();
        this.setupEventListeners();
        this.setupUI();
        this.resetGame();
        this.startGameLoop();
    }

    setupCanvas() {
        this.canvas = document.getElementById('gameCanvas');
        this.ctx = this.canvas.getContext('2d');
        this.resizeCanvas();
    }

    setupGameState() {
        this.grid = [];
        this.score = 0;
        this.actionPoints = this.config.actionPointsStart;
        this.consecutiveSuccessfulActions = 0;
        this.maxCombo = 0;
        this.actionCount = 0;
        this.gameOver = false;
        this.isAnimating = false;
        this.activeSkill = null;
        this.nextBlockColors = [];
        this.particles = [];
        this.gameStartTime = 0;
        this.timeLeft = this.config.gameDuration;
        
        // 闖關模式狀態
        if (this.config.mode === 'quest' && this.config.levelData) {
            this.movesLeft = this.config.levelData.moves;
            this.enemy = {
                ...this.config.levelData.enemy,
                hp: this.config.levelData.enemy.maxHP
            };
            console.log('GameEngine: 闖關模式狀態已初始化', {
                movesLeft: this.movesLeft,
                enemy: this.enemy
            });
        }
        
        // 連擊分數系統相關
        this.lastComboScore = 0;       // 上次連擊獲得的分數
        this.totalComboBonus = 0;      // 總連擊獎勵分數
        this.comboMilestoneReached = {}; // 已達成的連擊里程碑
        
        if (this.config.hasSkills) {
            this.skillUses = { removeSingle: 3, rerollNext: 3, rerollBoard: 3 };
        }
    }

    setupEventListeners() {
        this.canvas.addEventListener('click', (e) => this.handleCanvasClick(e));
        
        // 技能按鈕事件（如果啟用）
        if (this.config.hasSkills) {
            const skillRemoveBtn = document.getElementById('skillRemoveSingle');
            const skillRerollBtn = document.getElementById('skillRerollNext');
            const skillRerollBoardBtn = document.getElementById('skillRerollBoard');
            
            if (skillRemoveBtn) skillRemoveBtn.addEventListener('click', () => this.toggleSkill('removeSingle'));
            if (skillRerollBtn) skillRerollBtn.addEventListener('click', () => this.useSkillRerollNext());
            if (skillRerollBoardBtn) skillRerollBoardBtn.addEventListener('click', () => this.toggleSkill('rerollBoard'));
        }

        // 重啟按鈕
        const restartBtn = document.getElementById('restartButton');
        const modalRestartBtn = document.getElementById('modalRestartButton');
        const backToIntroBtn = document.getElementById('backToIntroButton');
        const modalBackToIntroBtn = document.getElementById('modalBackToIntroButton');
        const modalBackToQuestBtn = document.getElementById('modalBackToQuestButton');
        
        if (restartBtn) restartBtn.addEventListener('click', () => this.resetGame());
        if (modalRestartBtn) modalRestartBtn.addEventListener('click', () => this.resetGame());
        if (backToIntroBtn) backToIntroBtn.addEventListener('click', () => window.location.href = 'main-menu.html');
        if (modalBackToIntroBtn) modalBackToIntroBtn.addEventListener('click', () => window.location.href = 'main-menu.html');
        if (modalBackToQuestBtn) modalBackToQuestBtn.addEventListener('click', () => window.location.href = 'quest-mode.html');

        // 視窗大小調整
        window.addEventListener('resize', () => this.resizeCanvas());
    }

    setupUI() {
        this.scoreDisplay = document.getElementById('score');
        this.comboDisplay = document.getElementById('combo');
        this.actionPointsDisplay = document.getElementById('action-points');
        this.timeLeftDisplay = document.getElementById('time-left');
        this.timeProgressBar = document.getElementById('time-progress-bar');
        this.gameOverModal = document.getElementById('gameOverModal');
        this.finalScoreDisplay = document.getElementById('finalScore');
        this.finalMaxComboDisplay = document.getElementById('finalMaxCombo');
        this.finalActionCountDisplay = document.getElementById('finalActionCount');
        this.nextBlockPreviewContainer = document.getElementById('nextBlockPreviewContainer');
        
        // 移除連擊分數詳情UI以節省空間
        // this.comboScoreDetailsEl = document.getElementById('comboScoreDetails');
        // this.lastComboScoreEl = document.getElementById('lastComboScore');
        // this.totalComboBonusEl = document.getElementById('totalComboBonus');
        
        if (this.config.hasSkills) {
            this.skillRemoveSingleUsesEl = document.getElementById('skillRemoveSingleUses');
            this.skillRerollNextUsesEl = document.getElementById('skillRerollNextUses');
            this.skillRerollBoardUsesEl = document.getElementById('skillRerollBoardUses');
        }

        // 闖關模式UI初始化
        if (this.config.mode === 'quest') {
            UIManager.updateQuestUI({
                mode: this.config.mode,
                enemy: this.enemy,
                movesLeft: this.movesLeft
            });
        }

        // 設置主題
        document.body.className = `theme-${this.config.theme} flex flex-col items-center justify-center min-h-screen p-2 sm:p-4`;
    }

    getRandomColorName() {
        return this.colorNames[Math.floor(Math.random() * this.colorNames.length)];
    }

    // 計算連擊分數
    calculateComboScore(matches, chainLevel) {
        const scoring = this.config.scoring || {
            baseScore: 10,
            comboMultiplier: 0.5,
            chainMultiplier: 2,
            comboMilestones: {}
        };

        const restrictions = this.config.levelData?.restrictions || {};

        // 檢查關卡限制條件
        if (this.config.mode === 'quest') {
            // 檢查最低 Combo 需求
            if (restrictions.minComboForDamage && this.consecutiveSuccessfulActions < restrictions.minComboForDamage) {
                console.log(`限制生效：Combo數 ${this.consecutiveSuccessfulActions} 未達到 ${restrictions.minComboForDamage}`);
                return { finalScore: 0 };
            }
            // 檢查最低 Chain 需求
            if (restrictions.minChainForDamage && chainLevel < restrictions.minChainForDamage) {
                console.log(`限制生效：Chain數 ${chainLevel} 未達到 ${restrictions.minChainForDamage}`);
                return { finalScore: 0 };
            }
        }

        let validBlocks = [];
        matches.forEach(matchInfo => {
            const { colIndex, rowIndex } = JSON.parse(matchInfo);
            const targetGrid = this.config.numCols === 1 ? this.grid[0] : this.grid[colIndex];
            const block = targetGrid?.[rowIndex];

            if (block) {
                let isValid = true;
                if (this.config.mode === 'quest') {
                    // 檢查無效傷害顏色
                    if (restrictions.noDamageColors?.includes(block.colorName)) {
                        isValid = false;
                        console.log(`限制生效：顏色 ${block.colorName} 無法造成傷害`);
                    }
                    // 檢查僅限傷害顏色
                    if (restrictions.damageOnlyColors && !restrictions.damageOnlyColors.includes(block.colorName)) {
                        isValid = false;
                        console.log(`限制生效：只有 ${restrictions.damageOnlyColors.join(', ')} 可造成傷害，${block.colorName} 無效`);
                    }
                }
                if (isValid) {
                    validBlocks.push(block);
                }
            }
        });
        
        const blocksEliminated = validBlocks.length;
        if (blocksEliminated === 0) {
            return { finalScore: 0 };
        }

        // 基礎分數 = 消除方塊數 × 基礎分數
        let baseScore = blocksEliminated * scoring.baseScore;
        
        // 連擊倍數：1 + (連擊數 × 連擊倍數)
        const comboMultiplier = 1 + (this.consecutiveSuccessfulActions * scoring.comboMultiplier);
        
        // 連鎖倍數：連鎖等級 × 連鎖倍數
        const chainMultiplier = chainLevel * scoring.chainMultiplier;
        
        // 計算最終分數
        const finalScore = Math.floor(baseScore * comboMultiplier * chainMultiplier);
        
        // 在闖關模式，累積傷害但不立即扣血
        if (this.config.mode === 'quest' && finalScore > 0) {
            // 累積這次的傷害，但不立即扣血
            if (!this.pendingDamage) this.pendingDamage = 0;
            this.pendingDamage += finalScore;
        }

        return {
            baseScore,
            comboMultiplier,
            chainMultiplier,
            finalScore
        };
    }

    // 檢查連擊里程碑獎勵
    checkComboMilestone() {
        const scoring = this.config.scoring || { comboMilestones: {} };
        const milestones = scoring.comboMilestones;
        
        let bonusScore = 0;
        for (const [milestone, bonus] of Object.entries(milestones)) {
            const milestoneNum = parseInt(milestone);
            if (this.consecutiveSuccessfulActions >= milestoneNum && 
                !this.comboMilestoneReached[milestone]) {
                this.comboMilestoneReached[milestone] = true;
                bonusScore += bonus;
                this.totalComboBonus += bonus;
                
                // 在闖關模式，累積獎勵傷害但不立即扣血
                if (this.config.mode === 'quest') {
                    if (!this.pendingDamage) this.pendingDamage = 0;
                    this.pendingDamage += bonus;
                }
                
                // 顯示里程碑達成提示
                this.showComboMilestoneEffect(milestoneNum, bonus);
            }
        }
        
        return bonusScore;
    }

    // 顯示連擊里程碑效果
    showComboMilestoneEffect(milestone, bonus) {
        // 創建特殊的慶祝粒子效果
        const centerX = this.canvas.width / 2;
        const centerY = this.canvas.height / 2;
        
        for (let i = 0; i < 20; i++) {
            this.particles.push({
                x: centerX,
                y: centerY,
                vx: (Math.random() - 0.5) * 12,
                vy: (Math.random() - 0.5) * 12 - 3,
                life: 2000,
                maxLife: 2000,
                color: '#FFD700', // 金色
                size: Math.random() * 6 + 4,
                isMilestone: true
            });
        }
        
        // 在控制台顯示里程碑信息（之後可以改為UI提示）
        console.log(`🎉 連擊里程碑達成！${milestone}連擊獲得 ${bonus} 分獎勵！`);
    }

    generateNextBlockColor(colIndex) {
        if (colIndex !== undefined) {
            this.nextBlockColors[colIndex] = this.getRandomColorName();
        } else {
            this.nextBlockColors = Array.from({ length: this.config.numCols }, () => this.getRandomColorName());
        }
        this.updateNextBlockPreviewUI();
    }

    updateNextBlockPreviewUI() {
        // 下個方塊預覽現在在Canvas中繪製，此方法保留以供兼容性
        // Canvas中的預覽會在drawNextBlockPreview()方法中自動更新
        
        // 保留原始的隱藏容器邏輯（向後兼容）
        if (!this.nextBlockPreviewContainer) return;
        
        this.nextBlockPreviewContainer.innerHTML = '';
        this.nextBlockColors.forEach(colorName => {
            const previewBox = document.createElement('div');
            
            if (this.config.numCols === 1) {
                // 單排模式使用原來的樣式
                previewBox.className = 'w-14 h-7 sm:w-16 sm:h-8 mx-auto border-2 border-slate-300/70';
                previewBox.style.borderRadius = '0.5rem';
                previewBox.style.boxShadow = 'inset 0 1px 2px rgba(0,0,0,0.1)';
            } else {
                // 多排模式使用較小的預覽
                previewBox.className = 'next-block-preview w-12 h-6 sm:w-14 sm:h-7 border-2 border-slate-300/70';
            }
            
            previewBox.style.backgroundColor = (colorName && this.config.colors[colorName]) 
                ? this.config.colors[colorName].hex 
                : 'rgba(229, 231, 235, 0.5)';
            this.nextBlockPreviewContainer.appendChild(previewBox);
        });
    }

    resetGame() {
        this.score = 0;
        this.actionPoints = this.config.actionPointsStart;
        this.consecutiveSuccessfulActions = 0;
        this.maxCombo = 0;
        this.actionCount = 0;
        this.gameOver = false;
        this.isAnimating = false;
        this.activeSkill = null;
        this.grid = [];
        this.particles = [];
        this.timeLeft = this.config.gameDuration;
        // 只有在限時模式下才設置遊戲開始時間
        this.gameStartTime = this.config.hasTimer ? performance.now() : 0;
        this.pendingDamage = 0; // 重置累積傷害

        // 重置連擊分數系統
        this.lastComboScore = 0;
        this.totalComboBonus = 0;
        this.comboMilestoneReached = {};

        if (this.config.hasSkills) {
            this.skillUses = { removeSingle: 3, rerollNext: 3, rerollBoard: 3 };
        }

        if (this.config.mode === 'quest' && this.config.levelData) {
            this.movesLeft = this.config.levelData.moves;
            this.enemy = {
                ...this.config.levelData.enemy,
                hp: this.config.levelData.enemy.maxHP
            };
            console.log('GameEngine: 重置闖關模式狀態', {
                movesLeft: this.movesLeft,
                enemy: this.enemy
            });
        }

        this.generateNextBlockColor();
        this.createInitialGrid();
        this.updateBlockPositions();
        this.updateUI();
        
        if (this.config.hasSkills) {
            this.updateSkillButtonsUI();
        }

        if (this.gameOverModal && this.gameOverModal.classList) {
            this.gameOverModal.classList.remove('active');
            const modalContent = this.gameOverModal.querySelector('.modal-content');
            if (modalContent) {
                modalContent.style.opacity = '0';
                modalContent.style.transform = 'scale(0.95)';
            }
        }

        if (this.canvas && this.canvas.classList) {
            this.canvas.classList.remove('canvas-skill-target-mode');
        }
    }

    createInitialGrid() {
        this.grid = [];
        for (let c = 0; c < this.config.numCols; c++) {
            this.grid.push([]);
            for (let r = 0; r < this.config.numRows; r++) {
                this.addNewBlockToColumn(c, true);
            }
        }
    }

    addNewBlockToColumn(colIndex, isInitial = false, colorName = null) {
        if (!this.grid[colIndex] || this.grid[colIndex].length >= this.config.numRows + 5) return;
        
        let chosenColorName;
        if (isInitial) {
            chosenColorName = colorName || this.getRandomColorName();
        } else {
            chosenColorName = this.nextBlockColors[colIndex] || this.getRandomColorName();
            this.generateNextBlockColor(colIndex);
        }

        const newBlock = {
            id: Date.now() + Math.random(),
            col: colIndex,
            colorName: chosenColorName,
            colorHex: this.config.colors[chosenColorName].hex,
            x: 0, y: 0, drawY: 0,
            width: this.blockWidth,
            height: this.config.blockHeight,
            eliminationStartTime: 0,
            isEliminating: false,
            isExploding: false,
            isAnimatingSwap: false
        };

        if (this.config.numCols === 1) {
            // 單排模式：添加到開頭
            this.grid[0].unshift(newBlock);
        } else {
            // 多排模式：添加到每列開頭
            this.grid[colIndex].unshift(newBlock);
        }
    }

    refillGrid() {
        let refilledAny = false;
        
        if (this.config.numCols === 1) {
            // 單排模式
            while (this.grid[0] && this.grid[0].length < this.config.numRows) {
                this.addNewBlockToColumn(0);
                refilledAny = true;
            }
        } else {
            // 多排模式
            for (let c = 0; c < this.config.numCols; c++) {
                if (!this.grid[c]) continue;
                while (this.grid[c].length < this.config.numRows) {
                    this.addNewBlockToColumn(c);
                    refilledAny = true;
                }
            }
        }
        
        return refilledAny;
    }

    updateBlockPositions() {
        if (!this.grid || this.grid.length === 0) return;
        
        if (this.config.numCols === 1) {
            // 單排模式
            const gameAreaX = (this.canvas.width - this.blockWidth) / 2;
            let currentY = this.config.gameAreaTopPadding;
            
            if (!this.grid[0]) return;
            this.grid[0].forEach(block => {
                if (!block) return;
                block.x = gameAreaX;
                block.y = currentY;
                if (!block.isAnimatingSwap) {
                    block.drawY = block.y;
                }
                block.width = this.blockWidth;
                currentY += block.height;
            });
        } else {
            // 多排模式
            if (!this.columnWidth || !this.blockWidth) return;
            const totalGridWidth = this.columnWidth * this.config.numCols;
            const startX = (this.canvas.width - totalGridWidth) / 2;
            
            for (let c = 0; c < this.config.numCols; c++) {
                let currentY = this.config.gameAreaTopPadding;
                const columnX = startX + c * this.columnWidth + (this.columnWidth - this.blockWidth) / 2;
                if (!this.grid[c]) continue;
                
                this.grid[c].forEach(block => {
                    if (!block) return;
                    block.x = columnX;
                    block.y = currentY;
                    if (!block.isAnimatingSwap) block.drawY = block.y;
                    block.width = this.blockWidth;
                    currentY += block.height;
                });
            }
        }
    }

    resizeCanvas() {
        const container = document.querySelector('.game-container');
        const canvasContainer = this.canvas.parentElement;
        const style = getComputedStyle(container);
        const containerClientWidth = container.clientWidth;
        const paddingLeft = parseFloat(style.paddingLeft);
        const paddingRight = parseFloat(style.paddingRight);
        const availableWidth = containerClientWidth - paddingLeft - paddingRight;
        
        // 計算可用的高度（扣除其他UI元素）
        const containerHeight = container.clientHeight;
        const paddingTop = parseFloat(style.paddingTop);
        const paddingBottom = parseFloat(style.paddingBottom);
        
        // 計算其他UI元素的總高度
        let otherElementsHeight = 0;
        const children = container.children;
        for (let i = 0; i < children.length; i++) {
            const child = children[i];
            if (child !== canvasContainer && !child.classList.contains('modal')) {
                const childStyle = getComputedStyle(child);
                otherElementsHeight += child.offsetHeight + 
                    parseFloat(childStyle.marginTop) + 
                    parseFloat(childStyle.marginBottom);
            }
        }
        
        const availableHeight = containerHeight - paddingTop - paddingBottom - otherElementsHeight - 20; // 20px緩衝
        
        // 設置canvas尺寸
        this.canvas.width = availableWidth;
        
        // 使用配置中的 blockHeight 作為首選值，如果沒有則使用預設值
        const preferredBlockHeight = this.config.blockHeight || 36;
        
        // 檢測是否為手機裝置（基於螢幕寬度）
        const isMobile = window.innerWidth <= 768;
        
        // 為quest模式設定更高的最小高度保護
        const isQuestMode = this.config.theme === 'quest';
        const minBlockHeight = isQuestMode ? Math.max(preferredBlockHeight * 0.9, 35) : Math.max(preferredBlockHeight * 0.8, 24);
        
        // 計算理想的canvas高度
        const idealCanvasHeight = (preferredBlockHeight * this.config.numRows) + 
                                 (this.config.gameAreaTopPadding * 2) + 
                                 (this.config.numRows * 1);
        
        // 使用可用高度和理想高度中的較小值，但確保最小高度
        const canvasHeight = Math.max(Math.min(idealCanvasHeight, availableHeight), 
                                    (minBlockHeight * this.config.numRows) + (this.config.gameAreaTopPadding * 2) + 50);
        this.canvas.height = Math.max(canvasHeight, 200); // 最小高度200px
        
        // 根據實際canvas高度調整block大小
        const effectiveGameAreaHeight = this.canvas.height - (this.config.gameAreaTopPadding * 2);
        const calculatedBlockHeight = Math.floor((effectiveGameAreaHeight - this.config.numRows) / this.config.numRows);
        
        // 使用首選值和計算值中的較大者，但不低於最小高度
        this.config.blockHeight = Math.max(preferredBlockHeight, calculatedBlockHeight, minBlockHeight);
        
        if (this.config.numCols === 1) {
            if (isMobile) {
                // 手機版：減少寬度但增加高度，確保方塊更容易點擊
                this.blockWidth = Math.min(this.canvas.width * 0.55, 180); // 減少寬度到55%，最大180px
                // 如果寬度較小，增加高度補償
                if (this.blockWidth < 120) {
                    this.config.blockHeight = Math.max(this.config.blockHeight * 1.2, minBlockHeight); // 增加20%高度
                }
            } else {
                // 桌面版：使用原有比例
                this.blockWidth = this.canvas.width * this.config.blockWidthPercent;
            }
        } else {
            // 多列模式
            this.columnWidth = this.canvas.width / this.config.numCols;
            if (isMobile) {
                // 手機版多列：縮小寬度但增加高度
                this.blockWidth = this.columnWidth * 0.7;
                this.config.blockHeight = Math.max(this.config.blockHeight * 1.1, minBlockHeight); // 增加10%高度
            } else {
                this.blockWidth = this.columnWidth * 0.8;
            }
        }
        
        // 最終檢查：確保所有方塊都能顯示，但使用更寬鬆的縮放策略
        const totalNeededHeight = (this.config.blockHeight * this.config.numRows) + 
                                 (this.config.gameAreaTopPadding * 2);
        
        if (totalNeededHeight > this.canvas.height) {
            // 優先增加canvas高度而不是縮小方塊
            const neededExtraHeight = totalNeededHeight - this.canvas.height;
            this.canvas.height = Math.min(this.canvas.height + neededExtraHeight + 10, availableHeight);
            
            // 如果還是超出，才進行有限的縮放
            if (totalNeededHeight > this.canvas.height) {
                const scale = this.canvas.height / totalNeededHeight * 0.98; // 減少緩衝到2%
                const scaledHeight = Math.floor(this.config.blockHeight * scale);
                // 對quest模式使用更高的最小值保護
                this.config.blockHeight = Math.max(scaledHeight, minBlockHeight);
            }
        }

        if (!this.gameOver) {
            this.updateBlockPositions();
        }
    }

    updateUI() {
        if (this.scoreDisplay) this.scoreDisplay.textContent = this.score;
        if (this.comboDisplay) this.comboDisplay.textContent = this.consecutiveSuccessfulActions;
        if (this.actionPointsDisplay) this.actionPointsDisplay.textContent = this.actionPoints;
        
        // 更新闖關模式UI
        if (this.config.mode === 'quest') {
            UIManager.updateQuestUI({
                mode: this.config.mode,
                enemy: this.enemy,
                movesLeft: this.movesLeft
            });
        }
        
        // 更新最高連擊記錄
        if (this.consecutiveSuccessfulActions > this.maxCombo) {
            this.maxCombo = this.consecutiveSuccessfulActions;
        }

        // 時間相關UI（限時模式）
        if (this.config.hasTimer && this.timeLeftDisplay) {
            const secondsLeft = Math.max(0, this.timeLeft / 1000);
            this.timeLeftDisplay.textContent = Math.ceil(secondsLeft) + 's';

            if (this.timeProgressBar) {
                const progressPercentage = (this.timeLeft / this.config.gameDuration) * 100;
                this.timeProgressBar.style.width = `${Math.max(0, progressPercentage)}%`;
            }

            if (secondsLeft <= 5 && !this.gameOver) {
                this.timeLeftDisplay.classList.add('time-warning');
                if(this.timeProgressBar) this.timeProgressBar.classList.add('time-progress-bar-warning');
            } else {
                this.timeLeftDisplay.classList.remove('time-warning');
                if(this.timeProgressBar) this.timeProgressBar.classList.remove('time-progress-bar-warning');
            }
        }

        this.updateSkillButtonsUI();
    }

    updateSkillButtonsUI() {
        if (!this.config.hasSkills) return;
        
        if (this.skillRemoveSingleUsesEl) this.skillRemoveSingleUsesEl.textContent = this.skillUses.removeSingle;
        if (this.skillRerollNextUsesEl) this.skillRerollNextUsesEl.textContent = this.skillUses.rerollNext;
        if (this.skillRerollBoardUsesEl) this.skillRerollBoardUsesEl.textContent = this.skillUses.rerollBoard;

        const buttons = [
            document.getElementById('skillRemoveSingle'),
            document.getElementById('skillRerollNext'),
            document.getElementById('skillRerollBoard')
        ];

        buttons.forEach(btn => {
            if (!btn) return;
            
            let skillKey = '';
            if (btn.id === 'skillRemoveSingle') skillKey = 'removeSingle';
            else if (btn.id === 'skillRerollNext') skillKey = 'rerollNext';
            else if (btn.id === 'skillRerollBoard') skillKey = 'rerollBoard';

            if (skillKey && this.skillUses[skillKey] !== undefined) {
                btn.disabled = this.skillUses[skillKey] <= 0 || this.isAnimating;
            } else {
                btn.disabled = this.isAnimating;
            }
            
            if (btn.classList) {
                btn.classList.remove('ring-4', 'ring-offset-2', 'ring-sky-300', 'opacity-80');
                if (this.activeSkill && btn.id.toLowerCase().includes(this.activeSkill.toLowerCase())) {
                    btn.classList.add('ring-4', 'ring-offset-2', 'ring-sky-300', 'opacity-80');
                }
            }
        });
    }

    drawCanvasContent() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        if (this.gameOver && this.gameOverModal && this.gameOverModal.classList.contains('active')) return;
        
        if (this.config.numCols === 1) {
            // 單排模式
            this.grid[0].forEach(block => {
                if (block && !block.isExploding) this.drawBlock(block);
            });
        } else {
            // 多排模式
            this.grid.forEach(column => column.forEach(block => {
                if (block && !block.isExploding) this.drawBlock(block);
            }));
        }
        
        // 繪製下個方塊預覽（在Canvas內，使用虛線外框和斜線填充）
        this.drawNextBlockPreview();
        
        this.drawParticles();
    }
    
    drawNextBlockPreview() {
        if (!this.nextBlockColors || this.nextBlockColors.length === 0) return;
        
        const isMultiColumn = this.config.numCols > 1;
        
        // 計算預覽位置：在最上層方塊的上方一點點
        let previewY = this.config.gameAreaTopPadding - 25; // 稍微增加距離
        
        if (isMultiColumn) {
            // 多列模式：在每一列上方顯示預覽
            const totalGridWidth = this.columnWidth * this.config.numCols;
            const startX = (this.canvas.width - totalGridWidth) / 2;
            
            for (let colIndex = 0; colIndex < this.config.numCols && colIndex < this.nextBlockColors.length; colIndex++) {
                const columnX = startX + colIndex * this.columnWidth;
                const previewX = columnX + (this.columnWidth - this.blockWidth) / 2;
                const color = this.getColorHexFromName(this.nextBlockColors[colIndex]);
                
                this.drawSingleNextBlockPreview(previewX, previewY, this.blockWidth, this.config.blockHeight * 0.6, color);
            }
        } else {
            // 單列模式：在中央上方顯示一個預覽
            const previewX = (this.canvas.width - this.blockWidth) / 2;
            const color = this.getColorHexFromName(this.nextBlockColors[0]);
            
            this.drawSingleNextBlockPreview(previewX, previewY, this.blockWidth, this.config.blockHeight * 0.6, color);
        }
    }
    
    // 繪製單個下個方塊預覽（灰色虛線外框 + 淡色填充）
    drawSingleNextBlockPreview(x, y, width, height, color) {
        this.ctx.save();
        
        // 將顏色調淡 - 提取RGB值並增加透明度
        const lighterColor = this.getLighterColor(color, 0.7); // 70%透明度讓顏色更淡
        
        // 繪製淡色色塊填充
        this.ctx.fillStyle = lighterColor;
        this.ctx.fillRect(x, y, width, height);
        
        // 繪製灰色虛線外框
        this.ctx.setLineDash([3, 3]);
        this.ctx.strokeStyle = '#6B7280'; // 灰色邊框
        this.ctx.lineWidth = 2;
        this.ctx.strokeRect(x, y, width, height);
        
        this.ctx.restore();
    }
    
    // 獲取更淡的顏色
    getLighterColor(hexColor, opacity) {
        // 將hex顏色轉換為RGB，然後應用透明度
        const r = parseInt(hexColor.slice(1, 3), 16);
        const g = parseInt(hexColor.slice(3, 5), 16);
        const b = parseInt(hexColor.slice(5, 7), 16);
        
        // 混合白色讓顏色更淡
        const lighterR = Math.round(r + (255 - r) * (1 - opacity));
        const lighterG = Math.round(g + (255 - g) * (1 - opacity));
        const lighterB = Math.round(b + (255 - b) * (1 - opacity));
        
        return `rgb(${lighterR}, ${lighterG}, ${lighterB})`;
    }
    

    
    getColorHexFromName(colorName) {
        const colorMap = {
            'blue': '#3B82F6',
            'purple': '#8B5CF6', 
            'red': '#EF4444',
            'green': '#10B981',
            'yellow': '#F59E0B',
            'pink': '#EC4899'
        };
        return colorMap[colorName] || '#3B82F6';
    }

    drawBlock(block) {
        if (!block) return;
        
        let opacity = 1, scale = 1;
        let currentDrawY = block.drawY;

        if (block.isEliminating && !block.isExploding) {
            const progress = Math.min((Date.now() - block.eliminationStartTime) / this.config.eliminationAnimationDuration, 1);
            opacity = 1 - progress;
            scale = 1 - progress * 0.3;
            if (opacity <= 0.05) return;
        }

        this.ctx.save();
        this.ctx.globalAlpha = opacity;

        const blockDrawX = block.x + (block.width * (1 - scale)) / 2;
        const blockDrawRenderY = currentDrawY + (block.height * (1 - scale)) / 2;
        const blockDrawWidth = block.width * scale;
        const blockDrawHeight = block.height * scale;

        // 繪製圓角矩形
        const cornerRadius = 6;
        this.ctx.beginPath();
        this.ctx.moveTo(blockDrawX + cornerRadius, blockDrawRenderY);
        this.ctx.lineTo(blockDrawX + blockDrawWidth - cornerRadius, blockDrawRenderY);
        this.ctx.quadraticCurveTo(blockDrawX + blockDrawWidth, blockDrawRenderY, blockDrawX + blockDrawWidth, blockDrawRenderY + cornerRadius);
        this.ctx.lineTo(blockDrawX + blockDrawWidth, blockDrawRenderY + blockDrawHeight - cornerRadius);
        this.ctx.quadraticCurveTo(blockDrawX + blockDrawWidth, blockDrawRenderY + blockDrawHeight, blockDrawX + blockDrawWidth - cornerRadius, blockDrawRenderY + blockDrawHeight);
        this.ctx.lineTo(blockDrawX + cornerRadius, blockDrawRenderY + blockDrawHeight);
        this.ctx.quadraticCurveTo(blockDrawX, blockDrawRenderY + blockDrawHeight, blockDrawX, blockDrawRenderY + blockDrawHeight - cornerRadius);
        this.ctx.lineTo(blockDrawX, blockDrawRenderY + cornerRadius);
        this.ctx.quadraticCurveTo(blockDrawX, blockDrawRenderY, blockDrawX + cornerRadius, blockDrawRenderY);
        this.ctx.closePath();
        this.ctx.fillStyle = block.colorHex;
        this.ctx.fill();

        this.ctx.strokeStyle = 'rgba(0,0,0,0.1)';
        this.ctx.lineWidth = 1.5 / scale;
        this.ctx.stroke();

        this.ctx.restore();

        // 繪製操作提示
        if (block && !block.isEliminating && !block.isExploding && opacity > 0.5 && !this.activeSkill) {
            const actionAreaWidth = block.width / 3;
            const actionTexts = ["🔼", "╳", "🔽"];
            this.ctx.fillStyle = `rgba(255,255,255,${0.7 * opacity})`;
            this.ctx.font = `bold ${Math.min(15, block.height * 0.35)}px 'Poppins'`;
            this.ctx.textAlign = 'center';
            this.ctx.textBaseline = 'middle';
            
            for (let i = 0; i < 3; i++) {
                const textX = block.x + actionAreaWidth * i + actionAreaWidth / 2;
                const textY = currentDrawY + block.height / 2;
                this.ctx.fillText(actionTexts[i], textX, textY);
            }
        }
    }

    createParticleExplosion(x, y, width, height, colorHex) {
        const particleCount = this.config.particleCount;
        const isQuestMode = this.config.mode === 'quest';

        for (let i = 0; i < particleCount; i++) {
            let vx, vy;
            if (isQuestMode) {
                // 向上攻擊的粒子，目標是敵人位置
                const enemyX = this.canvas.width / 2; // 敵人在畫面中央
                const enemyY = 50; // 敵人在頂部
                
                // 計算從爆炸點到敵人的方向
                const dx = enemyX - (x + width / 2);
                const dy = enemyY - (y + height / 2);
                const distance = Math.sqrt(dx * dx + dy * dy);
                
                // 標準化方向向量並加上隨機偏移
                const speed = 8 + Math.random() * 4;
                vx = (dx / distance) * speed + (Math.random() - 0.5) * 2;
                vy = (dy / distance) * speed + (Math.random() - 0.5) * 2;
            } else {
                // 預設的爆炸效果
                vx = (Math.random() - 0.5) * 8;
                vy = (Math.random() - 0.5) * 8 - 2;
            }

            this.particles.push({
                x: x + width / 2,
                y: y + height / 2,
                vx: vx,
                vy: vy,
                life: this.config.particleLifespan,
                maxLife: this.config.particleLifespan,
                color: colorHex,
                size: Math.random() * 4 + 2,
                isQuestAttack: isQuestMode // 標記為攻擊粒子
            });
        }
    }

    updateParticles(deltaTime) {
        for (let i = this.particles.length - 1; i >= 0; i--) {
            const particle = this.particles[i];
            particle.x += particle.vx * deltaTime / 16.67;
            particle.y += particle.vy * deltaTime / 16.67;
            
            // 里程碑粒子特殊效果
            if (particle.isMilestone) {
                particle.vy += 0.1 * (deltaTime / 16.67); // 較慢的重力
                // 添加閃爍效果
                particle.opacity = 0.7 + 0.3 * Math.sin(Date.now() * 0.01);
            } else if (particle.isQuestAttack) {
                // 攻擊粒子不受重力影響，直線飛向敵人
                // 檢查是否接近敵人位置
                const enemyX = this.canvas.width / 2;
                const enemyY = 50;
                const distanceToEnemy = Math.sqrt(
                    Math.pow(particle.x - enemyX, 2) + Math.pow(particle.y - enemyY, 2)
                );
                
                // 如果粒子接近敵人，觸發攻擊效果
                if (distanceToEnemy < 30 && !particle.hitEnemy) {
                    particle.hitEnemy = true;
                    // 觸發敵人受擊動畫和UI更新
                    if (this.config.mode === 'quest') {
                        UIManager.triggerEnemyHitAnimation();
                        // 更新UI顯示最新的血量
                        this.updateUI();
                    }
                }
            } else {
                particle.vy += 0.15 * (deltaTime / 16.67); // 正常重力
            }
            
            particle.life -= deltaTime;

            if (particle.life <= 0) {
                this.particles.splice(i, 1);
            }
        }
    }

    drawParticles() {
        this.particles.forEach(particle => {
            const alpha = particle.life / particle.maxLife;
            this.ctx.save();
            
            // 里程碑粒子特殊渲染
            if (particle.isMilestone) {
                this.ctx.globalAlpha = (particle.opacity || 1) * alpha;
                // 添加光暈效果
                const gradient = this.ctx.createRadialGradient(
                    particle.x, particle.y, 0,
                    particle.x, particle.y, particle.size * 2
                );
                gradient.addColorStop(0, particle.color);
                gradient.addColorStop(1, 'rgba(255, 215, 0, 0)');
                this.ctx.fillStyle = gradient;
            } else {
                this.ctx.globalAlpha = alpha;
                this.ctx.fillStyle = particle.color;
            }
            
            this.ctx.beginPath();
            this.ctx.arc(particle.x, particle.y, particle.size * alpha, 0, Math.PI * 2);
            this.ctx.fill();
            this.ctx.restore();
        });
    }

    async animateBlockSwap(colIndex, block1RowIndex, block2RowIndex) {
        let column;
        if (this.config.numCols === 1) {
            column = this.grid[0];
        } else {
            column = this.grid[colIndex];
        }
        
        if (!column) return;
        
        const b1 = column[block1RowIndex];
        const b2 = column[block2RowIndex];
        if (!b1 || !b2) return;

        b1.isAnimatingSwap = true;
        b2.isAnimatingSwap = true;

        const b1InitialDrawY = b1.drawY;
        const b2InitialDrawY = b2.drawY;
        const b1TargetDrawY = b2.y;
        const b2TargetDrawY = b1.y;

        let startTime = null;
        return new Promise(resolve => {
            const step = (timestamp) => {
                if (!startTime) startTime = timestamp;
                const progress = Math.min((timestamp - startTime) / this.config.blockSwapAnimationDuration, 1);

                if (b1) b1.drawY = b1InitialDrawY + (b1TargetDrawY - b1InitialDrawY) * progress;
                if (b2) b2.drawY = b2InitialDrawY + (b2TargetDrawY - b2InitialDrawY) * progress;

                if (progress < 1) {
                    requestAnimationFrame(step);
                } else {
                    if (b1) {
                        b1.drawY = b1TargetDrawY;
                        b1.isAnimatingSwap = false;
                    }
                    if (b2) {
                        b2.drawY = b2TargetDrawY;
                        b2.isAnimatingSwap = false;
                    }
                    resolve();
                }
            };
            requestAnimationFrame(step);
        });
    }

    findMatches() {
        const matches = new Set();
        
        if (this.config.numCols === 1) {
            // 單排模式：只檢查垂直匹配
            const column = this.grid[0];
            if (!Array.isArray(column) || column.length < 3) return matches;
            
            for (let r = 0; r <= column.length - 3;) {
                const block = column[r];
                if (!block || block.isEliminating) {
                    r++;
                    continue;
                }
                
                let count = 1;
                const currentColorName = block.colorName;
                let next_r = r + 1;
                
                while (next_r < column.length && column[next_r] && 
                       column[next_r].colorName === currentColorName && 
                       !column[next_r].isEliminating) {
                    count++;
                    next_r++;
                }
                
                if (count >= 3) {
                    for (let k = r; k < next_r; k++) {
                        matches.add(JSON.stringify({ colIndex: 0, rowIndex: k }));
                    }
                }
                
                r = next_r;
            }
        } else {
            // 多排模式：檢查垂直匹配
            for (let c = 0; c < this.grid.length; c++) {
                const column = this.grid[c];
                if (!Array.isArray(column) || column.length < 3) continue;
                
                for (let r = 0; r <= column.length - 3;) {
                    const block = column[r];
                    if (!block || block.isEliminating) {
                        r++;
                        continue;
                    }
                    
                    let count = 1;
                    const currentColorName = block.colorName;
                    let next_r = r + 1;
                    
                    while (next_r < column.length && column[next_r] && 
                           column[next_r].colorName === currentColorName && 
                           !column[next_r].isEliminating) {
                        count++;
                        next_r++;
                    }
                    
                    if (count >= 3) {
                        for (let k = r; k < next_r; k++) {
                            matches.add(JSON.stringify({ colIndex: c, rowIndex: k }));
                        }
                    }
                    
                    r = next_r;
                }
            }
            
            // 檢查水平匹配（如果啟用）
            if (this.config.enableHorizontalMatches && this.grid.length >= 3) {
                for (let r = 0; r < this.config.numRows; r++) {
                    for (let c = 0; c <= this.grid.length - 3;) {
                        const b1 = this.grid[c]?.[r];
                        const b2 = this.grid[c + 1]?.[r];
                        const b3 = this.grid[c + 2]?.[r];

                        if (!b1 || !b2 || !b3 || b1.isEliminating || b2.isEliminating || b3.isEliminating) {
                            c++;
                            continue;
                        }

                        let count = 0;
                        let currentColorName = b1.colorName;
                        let temp_c = c;

                        if (b1.colorName === b2.colorName && b2.colorName === b3.colorName) {
                            count = 3;
                            temp_c = c + 3;
                            while (temp_c < this.grid.length && this.grid[temp_c][r] && 
                                   this.grid[temp_c][r].colorName === currentColorName && 
                                   !this.grid[temp_c][r].isEliminating) {
                                count++;
                                temp_c++;
                            }
                        }

                        if (count >= 3) {
                            for (let k = c; k < temp_c; k++) {
                                matches.add(JSON.stringify({ colIndex: k, rowIndex: r }));
                            }
                        }

                        c = temp_c > c ? temp_c : c + 1;
                    }
                }
            }
        }
        
        return matches;
    }

    startGameLoop() {
        if (this.gameLoopId) cancelAnimationFrame(this.gameLoopId);
        let lastTime = 0;
        const gameLoop = (timestamp) => {
            if (this.gameOver) return;

            const deltaTime = timestamp - (this.lastFrameTime || timestamp);
            this.lastFrameTime = timestamp;

            // 處理計時器 - 統一使用 performance.now()
            if (this.config.hasTimer && this.gameStartTime > 0) {
                const elapsedTime = performance.now() - this.gameStartTime;
                this.timeLeft = this.config.gameDuration - elapsedTime;
                if (this.timeLeft <= 0) {
                    this.timeLeft = 0;
                    this.triggerGameOver();
                }
            }
            
            this.updateParticles(deltaTime);
            this.drawCanvasContent();
            
            // 更新UI以顯示當前時間
            this.updateUI();

            this.gameLoopId = requestAnimationFrame(gameLoop);
        };
        this.gameLoopId = requestAnimationFrame(gameLoop);
    }

    triggerGameOver() {
        if (this.gameOver) return;

        // 闖關模式的勝負判斷
        if (this.config.mode === 'quest') {
            if (this.enemy.hp <= 0) {
                this.gameOver = true;
                UIManager.showGameOverModal(this.score, this.maxCombo, this.actionCount, 'quest_win');
                if (this.gameLoopId) cancelAnimationFrame(this.gameLoopId);
                // 只在通關成功時保存記錄
                this.saveQuestRecord().catch(err => console.error("儲存闖關記錄失敗:", err));
                return;
            }
            if (this.movesLeft <= 0) {
                this.gameOver = true;
                UIManager.showGameOverModal(this.score, this.maxCombo, this.actionCount, 'quest_loss');
                if (this.gameLoopId) cancelAnimationFrame(this.gameLoopId);
                // 失敗時不保存記錄，只顯示結果
                console.log("闖關失敗，不保存記錄");
                return;
            }
            // 如果是闖關模式，且不滿足輸贏條件，則不應結束遊戲
            return;
        }
        
        // 原有的遊戲結束邏輯 (例如計時器或行動點數)
        this.gameOver = true;
        if (this.gameLoopId) cancelAnimationFrame(this.gameLoopId);
        
        if (this.finalScoreDisplay) this.finalScoreDisplay.textContent = this.score;
        if (this.finalMaxComboDisplay) this.finalMaxComboDisplay.textContent = this.maxCombo;
        if (this.finalActionCountDisplay) this.finalActionCountDisplay.textContent = this.actionCount;
        
        if (this.gameOverModal && this.gameOverModal.classList) {
            this.gameOverModal.classList.add('active');
        }

        this.saveCurrentGameRecord().catch(err => console.error("儲存遊戲記錄失敗:", err));
    }

    async saveCurrentGameRecord() {
        // quest 模式有專用的保存方法，不使用此方法
        if (this.config.mode === 'quest') {
            console.log("偵測到 Quest 模式，已阻止儲存普通遊戲記錄。");
            return;
        }

        if (!window.supabaseAuth || !window.supabaseAuth.isAuthenticated()) {
            console.log("用戶未登入，不儲存遊戲記錄。");
            return;
        }

        const timeTaken = performance.now() - this.gameStartTime;

        const gameData = {
            mode: this.config.mode,
            score: this.score,
            moves: this.actionCount,
            time: Math.round(timeTaken / 1000), // 轉換為秒
            level: 1 // 目前所有模式都先當作 level 1
        };

        try {
            console.log("正在儲存遊戲記錄:", gameData);
            const savedRecord = await window.supabaseAuth.saveGameRecord(gameData);
            console.log("遊戲記錄儲存成功:", savedRecord);
            // 可以在這裡更新 UI，例如顯示一個「儲存成功」的提示
        } catch (error) {
            console.error("儲存遊戲記錄失敗:", error);
            // 可以在 UI 提示儲存失敗
        }
    }

    async saveQuestRecord() {
        if (!window.supabaseAuth || !window.supabaseAuth.isAuthenticated()) {
            console.log("用戶未登入，不儲存闖關記錄。");
            return;
        }

        // 從 URL 參數獲取關卡編號
        const urlParams = new URLSearchParams(window.location.search);
        const levelNumber = parseInt(urlParams.get('level')) || 1;
        
        const timeTaken = performance.now() - this.gameStartTime;
        const initialMoves = this.config.levelData?.moves || 15;
        const movesUsed = initialMoves - this.movesLeft;
        const damageDealt = this.enemy.maxHP - this.enemy.hp;

        const questData = {
            levelNumber: levelNumber,
            isCompleted: true, // 只有成功通關才會調用此方法
            score: this.score,
            movesUsed: movesUsed,
            movesRemaining: this.movesLeft,
            maxCombo: this.maxCombo,
            actionCount: this.actionCount,
            timeTaken: Math.round(timeTaken / 1000),
            enemyName: this.enemy.name,
            enemyMaxHP: this.enemy.maxHP,
            damageDealt: damageDealt
        };

        try {
            console.log("正在儲存通關記錄:", questData);
            const savedRecord = await window.supabaseAuth.saveQuestRecord(questData);
            console.log("通關記錄儲存成功:", savedRecord);
            
            // 在彈窗中顯示額外資訊
            this.updateGameOverModalWithQuestInfo(questData, true);
        } catch (error) {
            console.error("儲存通關記錄失敗:", error);
            // 可以在 UI 提示儲存失敗
        }
    }

    updateGameOverModalWithQuestInfo(questData, isCompleted) {
        // 找到彈窗中的訊息元素並更新
        const messageEl = document.getElementById('modal-message');
        if (messageEl) {
            if (isCompleted) {
                messageEl.innerHTML = `
                    <div class="text-green-600 font-medium mb-2">🎉 關卡 ${questData.levelNumber} 通關成功！</div>
                    <div class="text-sm text-gray-600 space-y-1">
                        <div>傷害: ${questData.damageDealt}/${questData.enemyMaxHP}</div>
                        <div>剩餘步數: ${questData.movesRemaining}</div>
                        <div>用時: ${questData.timeTaken}秒</div>
                    </div>
                `;
            } else {
                messageEl.innerHTML = `
                    <div class="text-red-600 font-medium mb-2">關卡 ${questData.levelNumber} 挑戰失敗</div>
                    <div class="text-sm text-gray-600 space-y-1">
                        <div>傷害: ${questData.damageDealt}/${questData.enemyMaxHP}</div>
                        <div>已用步數: ${questData.movesUsed}</div>
                        <div>再接再厲！</div>
                    </div>
                `;
            }
        }
    }

    async handleCanvasClick(event) {
        if (this.gameOver || this.isAnimating) return;
        
        const rect = this.canvas.getBoundingClientRect();
        const scaleX = this.canvas.width / rect.width;
        const scaleY = this.canvas.height / rect.height;
        const mouseX = (event.clientX - rect.left) * scaleX;
        const mouseY = (event.clientY - rect.top) * scaleY;

        if (this.config.numCols === 1) {
            // 單排模式
            for (let i = 0; i < this.grid[0].length; i++) {
                const block = this.grid[0][i];
                if (!block || block.isEliminating || block.isExploding) continue;
                
                if (mouseX >= block.x && mouseX <= block.x + block.width && 
                    mouseY >= block.y && mouseY <= block.y + block.height) {
                    
                    if (this.activeSkill) {
                        await this.processActiveSkillOnBlock({ colIndex: 0, rowIndex: i });
                    } else {
                        const clickXRelative = mouseX - block.x;
                        const actionAreaWidth = block.width / 3;
                        let actionType = (clickXRelative < actionAreaWidth) ? "move_to_top" : 
                                       (clickXRelative < 2 * actionAreaWidth) ? "remove_directly" : "insert_at_bottom";
                        await this.performPlayerAction({ colIndex: 0, rowIndex: i }, actionType);
                    }
                    return;
                }
            }
        } else {
            // 多排模式
            for (let c = 0; c < this.grid.length; c++) {
                if (!this.grid[c]) continue;
                for (let r = 0; r < this.grid[c].length; r++) {
                    const block = this.grid[c][r];
                    if (!block || block.isEliminating || block.isExploding) continue;
                    
                    if (mouseX >= block.x && mouseX <= block.x + block.width && 
                        mouseY >= block.y && mouseY <= block.y + block.height) {
                        
                        const location = { colIndex: c, rowIndex: r };
                        if (this.activeSkill) {
                            await this.processActiveSkillOnBlock(location);
                        } else {
                            const clickXRelative = mouseX - block.x;
                            const actionAreaWidth = block.width / 3;
                            let actionType = (clickXRelative < actionAreaWidth) ? "move_to_top" : 
                                           (clickXRelative < 2 * actionAreaWidth) ? "remove_directly" : "insert_at_bottom";
                            await this.performPlayerAction(location, actionType);
                        }
                        return;
                    }
                }
            }
        }
    }

    async performPlayerAction(location, actionType) {
        if (this.gameOver || this.isAnimating || this.activeSkill) return;

        // 在闖關模式下，每次操作即消耗步數
        if (this.config.mode === 'quest' && this.movesLeft !== undefined) {
            if (this.movesLeft > 0) {
                this.movesLeft--;
                console.log('闖關模式: 步數扣除，剩餘步數:', this.movesLeft);
            }
        }

        this.isAnimating = true;
        this.actionCount++;
        let matchFound = false;

        const { colIndex, rowIndex } = location;
        if (this.config.numCols === 1) {
            if (!this.grid[0] || !this.grid[0][rowIndex]) return;
        } else {
            if (!this.grid[colIndex] || !this.grid[colIndex][rowIndex]) return;
        }
        
        this.updateSkillButtonsUI();
        
        if (actionType === "move_to_top" || actionType === "insert_at_bottom") {
            const direction = actionType === "move_to_top" ? -1 : 1;
            let currentRow = rowIndex;
            
            const targetGrid = this.config.numCols === 1 ? this.grid[0] : this.grid[colIndex];
            
            while (true) {
                const nextRow = currentRow + direction;
                if (nextRow < 0 || nextRow >= targetGrid.length) break;
                
                await this.animateBlockSwap(colIndex, currentRow, nextRow);
                
                // 交換方塊位置
                [targetGrid[currentRow], targetGrid[nextRow]] = [targetGrid[nextRow], targetGrid[currentRow]];
                
                this.updateBlockPositions();
                currentRow = nextRow;
                
                if ((direction === -1 && currentRow === 0) || 
                    (direction === 1 && currentRow === targetGrid.length - 1)) break;
            }
        } else if (actionType === "remove_directly") {
            const targetGrid = this.config.numCols === 1 ? this.grid[0] : this.grid[colIndex];
            const block = targetGrid[rowIndex];
            
            this.createParticleExplosion(block.x, block.drawY, block.width, block.height, block.colorHex);
            block.isExploding = true;
            await new Promise(resolve => setTimeout(resolve, 50));
            targetGrid.splice(rowIndex, 1);
        }

        this.updateBlockPositions();

        // 處理連鎖消除
        while (true) {
            this.updateBlockPositions();
            const passHadEliminations = await this.processSingleWaveOfMatchesAndCascades();
            if (passHadEliminations) {
                matchFound = true;
            }

            this.updateBlockPositions();
            const refilled = this.refillGrid();
            this.updateBlockPositions();
            
            if (!passHadEliminations && !refilled) break;
        }

        // 一次操作中如果有任何消除，就計算一次連擊
        if (matchFound) {
            this.consecutiveSuccessfulActions++;
            // 檢查連擊里程碑獎勵
            const milestoneBonus = this.checkComboMilestone();
            if (milestoneBonus > 0) {
                this.score += milestoneBonus;
            }
        } else {
            if (!this.config.hasTimer && this.config.mode !== 'quest') {
                this.actionPoints--;
                this.consecutiveSuccessfulActions = 0;
                // 重置連擊相關數據
                this.lastComboScore = 0;
            }
            if (this.config.title === '三排限時強攻') {
                this.handlePenalty();
            }
        }

        // 在闖關模式中，應用累積的傷害
        if (this.config.mode === 'quest' && this.pendingDamage > 0) {
            this.enemy.hp = Math.max(0, this.enemy.hp - this.pendingDamage);
            console.log(`造成傷害: ${this.pendingDamage}, 敵人剩餘血量: ${this.enemy.hp}`);
            this.pendingDamage = 0; // 重置累積傷害
        }

        this.updateUI();
        this.isAnimating = false;
        this.updateSkillButtonsUI();
        
        // 檢查遊戲結束條件
        if (this.config.mode === 'quest') {
            // 闖關模式：檢查敵人血量和剩餘步數
            this.triggerGameOver();
        } else if (!this.config.hasTimer && this.actionPoints <= 0 && !this.gameOver) {
            // 其他模式：檢查行動點數
            this.triggerGameOver();
        }
    }

    async processSingleWaveOfMatchesAndCascades() {
        let anyEliminationThisWave = false;
        let internalCascadeCount = 0;

        while (true) {
            const matches = this.findMatches();
            if (matches.size > 0) {
                anyEliminationThisWave = true;
                internalCascadeCount++;
                
                // 使用新的連擊分數計算系統
                const scoreInfo = this.calculateComboScore(matches, internalCascadeCount);
                this.score += scoreInfo.finalScore;
                this.lastComboScore = scoreInfo.finalScore;
            
                matches.forEach(matchInfo => {
                    const { colIndex, rowIndex } = JSON.parse(matchInfo);
                    const targetGrid = this.config.numCols === 1 ? this.grid[0] : this.grid[colIndex];
                    const block = targetGrid?.[rowIndex];
                    if (block) {
                        this.createParticleExplosion(block.x, block.drawY, block.width, block.height, block.colorHex);
                        block.isEliminating = true;
                        block.eliminationStartTime = Date.now();
                    }
                });

                await new Promise(resolve => setTimeout(resolve, this.config.eliminationAnimationDuration + 30));

                // 移除被標記消除的方塊
                if (this.config.numCols === 1) {
                    for (let r = this.grid[0].length - 1; r >= 0; r--) {
                        if (this.grid[0][r] && this.grid[0][r].isEliminating) {
                            this.grid[0].splice(r, 1);
                        }
                    }
                } else {
                    for (let c = this.grid.length - 1; c >= 0; c--) {
                        if (!this.grid[c]) continue;
                        for (let r = this.grid[c].length - 1; r >= 0; r--) {
                            if (this.grid[c][r] && this.grid[c][r].isEliminating) {
                                this.grid[c].splice(r, 1);
                            }
                        }
                    }
                }

                // 重置消除狀態
                this.grid.forEach(column => {
                    if (Array.isArray(column)) {
                        column.forEach(block => {
                            if (block) {
                                block.isEliminating = false;
                                block.isExploding = false;
                            }
                        });
                    }
                });

                this.updateBlockPositions();
            } else {
                break;
            }
        }

        return anyEliminationThisWave;
    }

    toggleSkill(skillName) {
        if (!this.config.hasSkills || this.isAnimating) return;
        
        const usesLeft = this.skillUses[skillName] || 0;
        if (usesLeft <= 0 && this.activeSkill !== skillName) return;

        // 檢查是否需要顯示說明
        if (this.shouldShowSkillExplanation(skillName)) {
            // 顯示說明，確認後激活技能
            this.showSkillExplanation(skillName, () => {
                this.activateSkill(skillName);
            });
        } else {
            // 直接激活技能
            this.activateSkill(skillName);
        }
    }

    activateSkill(skillName) {
        this.activeSkill = (this.activeSkill === skillName) ? null : skillName;
        if (this.canvas && this.canvas.classList) {
            this.canvas.classList.toggle('canvas-skill-target-mode', 
                                       this.activeSkill === 'removeSingle' || this.activeSkill === 'rerollBoard');
        }
        this.updateSkillButtonsUI();
    }

    // 檢查是否應該顯示技能說明
    shouldShowSkillExplanation(skillName) {
        try {
            const preference = localStorage.getItem(`skillExplanation_${skillName}`);
            return preference !== 'false'; // 如果沒有設定或設定為true，就顯示
        } catch (error) {
            console.warn('無法讀取技能說明偏好設定:', error);
            return true; // 讀取失敗時預設顯示
        }
    }

    // 設定技能說明偏好
    setSkillExplanationPreference(skillName, shouldShow) {
        try {
            localStorage.setItem(`skillExplanation_${skillName}`, shouldShow.toString());
        } catch (error) {
            console.warn('無法保存技能說明偏好設定:', error);
        }
    }

    // 重置所有技能說明偏好設定（用於開發或重置）
    resetAllSkillExplanationPreferences() {
        try {
            const skillNames = ['removeSingle', 'rerollNext', 'rerollBoard'];
            skillNames.forEach(skillName => {
                localStorage.removeItem(`skillExplanation_${skillName}`);
            });
            console.log('所有技能說明偏好設定已重置');
        } catch (error) {
            console.warn('無法重置技能說明偏好設定:', error);
        }
    }

    showSkillExplanation(skillName, onConfirm = null) {
        const skillInfo = {
            'removeSingle': {
                title: '💥 移除單個方塊',
                description: '點擊任意方塊直接移除它。這可以幫助您打破困難的局面或創造更好的消除機會。',
                usage: '點擊要移除的方塊即可使用'
            },
            'rerollNext': {
                title: '🎲 重骰下個方塊',
                description: '改變下一個要放置的方塊顏色。當下個方塊顏色不利於當前局面時特別有用。',
                usage: '點擊確認按鈕後立即重新生成下個方塊顏色'
            },
            'rerollBoard': {
                title: '🎨 變色板面',
                description: '點擊任意方塊將其變為隨機顏色。可以用來創造更多消除機會或改變不利局面。',
                usage: '點擊要變色的方塊即可使用'
            }
        };

        const info = skillInfo[skillName];
        if (!info) return;

        // 創建彈跳視窗
        const modal = document.createElement('div');
        modal.className = 'skill-explanation-modal';
        modal.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.7);
            display: flex;
            justify-content: center;
            align-items: center;
            z-index: 10000;
            font-family: 'Noto Sans TC', sans-serif;
        `;

        const content = document.createElement('div');
        content.style.cssText = `
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 30px;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            max-width: 400px;
            margin: 20px;
            text-align: center;
            color: white;
            border: 2px solid rgba(255, 255, 255, 0.2);
        `;

        content.innerHTML = `
            <div style="font-size: 48px; margin-bottom: 20px;">${info.title.split(' ')[0]}</div>
            <h3 style="font-size: 20px; font-weight: bold; margin-bottom: 15px; color: #FFD700;">${info.title}</h3>
            <p style="font-size: 16px; line-height: 1.6; margin-bottom: 20px; color: rgba(255, 255, 255, 0.9);">${info.description}</p>
            <div style="background: rgba(255, 255, 255, 0.1); padding: 15px; border-radius: 10px; margin-bottom: 25px;">
                <p style="font-size: 14px; font-weight: 500; color: #FFD700; margin: 0;">使用方法：</p>
                <p style="font-size: 14px; margin: 5px 0 0 0; color: rgba(255, 255, 255, 0.9);">${info.usage}</p>
            </div>
            <div style="margin-bottom: 20px; text-align: left;">
                <label style="display: flex; align-items: center; cursor: pointer; color: rgba(255, 255, 255, 0.8); font-size: 14px;">
                    <input type="checkbox" id="dontShowAgain" style="margin-right: 8px; width: 16px; height: 16px; cursor: pointer;">
                    不再顯示此技能說明
                </label>
            </div>
            <div style="display: flex; gap: 10px; justify-content: center;">
                <button id="skillExplanationCancel" style="
                    background: rgba(255, 255, 255, 0.2);
                    color: rgba(255, 255, 255, 0.8);
                    border: 1px solid rgba(255, 255, 255, 0.3);
                    padding: 10px 20px;
                    border-radius: 20px;
                    font-size: 14px;
                    cursor: pointer;
                    transition: all 0.2s;
                ">取消</button>
                <button id="skillExplanationOk" style="
                    background: linear-gradient(45deg, #FF6B6B, #4ECDC4);
                    color: white;
                    border: none;
                    padding: 12px 30px;
                    border-radius: 25px;
                    font-size: 16px;
                    font-weight: bold;
                    cursor: pointer;
                    transition: transform 0.2s;
                    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
                ">我知道了</button>
            </div>
        `;

        modal.appendChild(content);
        document.body.appendChild(modal);

        // 添加按鈕事件
        const okButton = modal.querySelector('#skillExplanationOk');
        const cancelButton = modal.querySelector('#skillExplanationCancel');
        const dontShowAgainCheckbox = modal.querySelector('#dontShowAgain');

        // 確認按鈕事件
        okButton.addEventListener('click', () => {
            // 檢查是否勾選了"不再顯示"
            if (dontShowAgainCheckbox.checked) {
                this.setSkillExplanationPreference(skillName, false);
            }
            
            document.body.removeChild(modal);
            // 如果有確認回調函數，執行它
            if (onConfirm && typeof onConfirm === 'function') {
                onConfirm();
            }
        });

        // 取消按鈕事件
        cancelButton.addEventListener('click', () => {
            // 檢查是否勾選了"不再顯示"
            if (dontShowAgainCheckbox.checked) {
                this.setSkillExplanationPreference(skillName, false);
            }
            
            document.body.removeChild(modal);
            // 取消時不執行技能效果
        });

        // 按鈕hover效果
        okButton.addEventListener('mouseenter', () => {
            okButton.style.transform = 'scale(1.05)';
        });

        okButton.addEventListener('mouseleave', () => {
            okButton.style.transform = 'scale(1)';
        });

        cancelButton.addEventListener('mouseenter', () => {
            cancelButton.style.background = 'rgba(255, 255, 255, 0.3)';
        });

        cancelButton.addEventListener('mouseleave', () => {
            cancelButton.style.background = 'rgba(255, 255, 255, 0.2)';
        });

        // 點擊背景關閉
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                document.body.removeChild(modal);
                // 點擊背景關閉時不執行技能效果
            }
        });
    }

    async useSkillRerollNext() {
        if (!this.config.hasSkills || this.isAnimating || this.skillUses.rerollNext <= 0) return;
        
        // 檢查是否需要顯示說明
        if (this.shouldShowSkillExplanation('rerollNext')) {
            // 顯示說明，確認後執行技能效果
            this.showSkillExplanation('rerollNext', async () => {
                await this.executeRerollNextSkill();
            });
        } else {
            // 直接執行技能效果
            await this.executeRerollNextSkill();
        }
    }

    async executeRerollNextSkill() {
        if (!this.config.hasSkills || this.isAnimating || this.skillUses.rerollNext <= 0) return;
        
        this.isAnimating = true;
        this.updateSkillButtonsUI();
        this.skillUses.rerollNext--;
        
        // 改進的重骰邏輯，確保新顏色與原顏色不同
        this.generateNextBlockColorWithDifferentColors();
        
        await new Promise(resolve => setTimeout(resolve, 50));
        this.isAnimating = false;
        this.updateUI();
        this.updateSkillButtonsUI();
    }

    generateNextBlockColorWithDifferentColors() {
        if (this.config.numCols === 1) {
            // 單排模式
            const oldColor = this.nextBlockColors[0];
            let newColor;
            do {
                newColor = this.getRandomColorName();
            } while (newColor === oldColor && this.colorNames.length > 1);
            this.nextBlockColors[0] = newColor;
        } else {
            // 多排模式
            for (let i = 0; i < this.config.numCols; i++) {
                const oldColor = this.nextBlockColors[i];
                let newColor;
                do {
                    newColor = this.getRandomColorName();
                } while (newColor === oldColor && this.colorNames.length > 1);
                this.nextBlockColors[i] = newColor;
            }
        }
        this.updateNextBlockPreviewUI();
    }

    async processActiveSkillOnBlock(location) {
        const { colIndex, rowIndex } = location;
        if (!this.activeSkill || this.isAnimating) return;
        
        // 驗證位置
        const targetGrid = this.config.numCols === 1 ? this.grid[0] : this.grid[colIndex];
        if (!targetGrid || !targetGrid[rowIndex]) return;

        const skillUsed = this.activeSkill;
        this.isAnimating = true;
        this.actionCount++;
        this.updateSkillButtonsUI();
        let skillEffectApplied = false;

        if (skillUsed === 'removeSingle' && this.skillUses.removeSingle > 0) {
            this.skillUses.removeSingle--;
            const block = targetGrid[rowIndex];
            this.createParticleExplosion(block.x, block.drawY, block.width, block.height, block.colorHex);
            block.isExploding = true;
            await new Promise(resolve => setTimeout(resolve, 50));
            targetGrid.splice(rowIndex, 1);
            skillEffectApplied = true;
        } else if (skillUsed === 'rerollBoard' && this.skillUses.rerollBoard > 0) {
            this.skillUses.rerollBoard--;
            const block = targetGrid[rowIndex];
            const oldColor = block.colorName;
            let newColorName;
            do {
                newColorName = this.getRandomColorName();
            } while (newColorName === oldColor && this.colorNames.length > 1);
            
            block.colorName = newColorName;
            block.colorHex = this.config.colors[newColorName].hex;
            skillEffectApplied = true;
        }

        this.activeSkill = null;
        if (this.canvas && this.canvas.classList) {
            this.canvas.classList.remove('canvas-skill-target-mode');
        }

        if (skillEffectApplied) {
            this.updateBlockPositions();
            while (true) {
                this.updateBlockPositions();
                const passHadEliminations = await this.processSingleWaveOfMatchesAndCascades();
                this.updateBlockPositions();
                const refilled = this.refillGrid();
                this.updateBlockPositions();
                if (!passHadEliminations && !refilled) break;
            }
        }

        // 在闖關模式中，應用累積的傷害
        if (this.config.mode === 'quest' && this.pendingDamage > 0) {
            this.enemy.hp = Math.max(0, this.enemy.hp - this.pendingDamage);
            console.log(`技能造成傷害: ${this.pendingDamage}, 敵人剩餘血量: ${this.enemy.hp}`);
            this.pendingDamage = 0; // 重置累積傷害
        }

        this.updateUI();
        this.isAnimating = false;
        this.updateSkillButtonsUI();
        
        // 檢查遊戲結束條件
        if (this.config.mode === 'quest') {
            this.triggerGameOver();
        } else if (!this.config.hasTimer && this.actionPoints <= 0 && !this.gameOver) {
            this.triggerGameOver();
        }
    }

    handlePenalty() {
        if (this.config.actionPointsStart > 0) {
            this.actionPoints--;
        }
        
        const gameContainer = document.querySelector('.game-container');
        if (gameContainer) {
            gameContainer.classList.add('screen-shake');
            setTimeout(() => {
                gameContainer.classList.remove('screen-shake');
            }, 500);
        }

        this.updateUI();

        if (this.actionPoints <= 0 && this.config.actionPointsStart > 0) {
            this.triggerGameOver();
        }
    }

    static createQuestHeaderHTML(config) {
        const enemy = config.levelData.enemy;
        const urlParams = new URLSearchParams(window.location.search);
        const levelNumber = parseInt(urlParams.get('level')) || 1;
        const enemyImageSrc = `images/monster/ch1-${levelNumber}.png`;

        // 獨立的 tooltip 點擊事件，避免 HTML 結構複雜
        const restrictions = config.levelData.restrictions;

        return `
        <div id="quest-header" class="relative flex-shrink-0 p-2 bg-slate-800/70 rounded-t-xl text-white">
            <div id="quest-info-icon" class="absolute top-2 left-2 cursor-pointer z-20">
                <svg class="w-6 h-6 text-sky-300/70" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path></svg>
            </div>
            <div class="w-20 h-20 mx-auto relative">
                <img id="enemy-image" src="${enemyImageSrc}" alt="${enemy.name}" class="w-full h-full object-contain transition-transform duration-100">
            </div>
            <div id="enemy-info" class="text-center -mt-2">
                <h3 id="enemy-name" class="text-base font-bold text-yellow-300">${enemy.name}</h3>
                <div class="w-full bg-gray-600 rounded-full h-4 mt-1 border border-gray-500 shadow-inner">
                    <div id="enemy-hp-bar" class="bg-gradient-to-r from-red-500 to-red-700 h-full rounded-full transition-all duration-300 ease-out flex items-center justify-end pr-1">
                        <span id="enemy-hp-text" class="text-xs font-bold text-white text-shadow">${enemy.maxHP}/${enemy.maxHP}</span>
                    </div>
                </div>
            </div>
            <div class="absolute top-3 right-3 text-center">
                <div class="text-sm font-bold text-white text-shadow-lg">步數</div>
                <div id="moves-left" class="text-3xl font-black text-amber-400 text-stroke-2 text-stroke-black">${config.levelData.moves}</div>
            </div>
        </div>`;
    }

    static showRestrictionsPopup(restrictions) {
        if (!restrictions || Object.keys(restrictions).length === 0) return;

        // 如果已存在，先移除
        const existingModal = document.getElementById('restrictions-popup');
        if (existingModal) {
            existingModal.remove();
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
            descriptions.push(`<span class="text-red-400">無效顏色:</span> ${colors}`);
        }
        if (restrictions.damageOnlyColors) {
            const colors = restrictions.damageOnlyColors.map(c => colorMap[c] || c).join('、');
            descriptions.push(`<span class="text-green-400">有效顏色:</span> ${colors}`);
        }
        if (restrictions.requireHorizontalMatch) {
            descriptions.push('僅限 <span class="text-yellow-400">橫向消除</span> 有效');
        }

        const modal = document.createElement('div');
        modal.id = 'restrictions-popup';
        modal.className = 'fixed inset-0 bg-black/60 flex items-center justify-center z-50';
        modal.innerHTML = `
            <div class="bg-gray-800 text-white border-2 border-yellow-500/50 rounded-lg shadow-lg p-6 w-full max-w-xs mx-4">
                <h4 class="font-bold text-lg mb-4 text-center text-yellow-300">關卡限制</h4>
                <ul class="space-y-2">
                    ${descriptions.map(desc => `<li class="flex items-start"><span class="text-yellow-400 mr-2">&#9679;</span><span>${desc}</span></li>`).join('')}
                </ul>
                <button id="close-restrictions-popup" class="mt-6 w-full bg-yellow-500 hover:bg-yellow-400 text-gray-900 font-bold py-2 rounded-lg transition-colors">關閉</button>
            </div>
        `;
        
        document.body.appendChild(modal);

        const closeButton = modal.querySelector('#close-restrictions-popup');
        closeButton.onclick = () => modal.remove();
        modal.onclick = (e) => {
            if (e.target === modal) {
                modal.remove();
            }
        };
    }
}

// 導出類
if (typeof module !== 'undefined' && module.exports) {
    module.exports = GameEngine;
} 