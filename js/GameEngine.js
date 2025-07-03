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
        // 確保初始化後方塊位置正確
        this.updateBlockPositions();
        this.startGameLoop();
    }

    setupCanvas() {
        this.canvas = document.getElementById('gameCanvas');
        this.ctx = this.canvas.getContext('2d');
        // 確保 Canvas 尺寸正確設置
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
        this.timeLeft = this.config.gameDuration;
        
        // RPG系統狀態
        if (this.config.hasRPGSystem) {
            this.level = this.config.rpgConfig?.initialLevel || 1;
            this.exp = 0;
            this.expToNextLevel = SkillSystem.calculateExpRequired(this.level);
            this.gold = 0;
            this.playerSkills = {}; // 玩家已獲取的技能及等級
            this.isLevelUpInProgress = false; // 是否正在升級流程中
            this.isPaused = false; // 遊戲是否暫停
            this.processingTimeoutPenalty = false; // 是否正在處理超時懲罰
            this.isTimerPaused = false; // 計時器是否暫停（用戶操作時）
            
            // 存活模式狀態
            if (this.config.isSurvivalMode) {
                this.survivalTime = 0; // 累積存活時間（只有倒數時才計算）
                this.totalGameTime = 0; // 總遊戲時間
                this.challengesTriggered = []; // 已觸發的挑戰里程碑
                this.activeChallenges = []; // 當前生效的挑戰
                // 黑色方塊信息現在直接存儲在方塊對象上，不再需要 Map 追蹤
                this.clearancesCount = 0; // 消除次數計數器
                this.hasUsedFreeReroll = false; // 是否已使用免費重抽
                
                console.log('🔄 存活模式狀態初始化完成:', {
                    isSurvivalMode: this.config.isSurvivalMode,
                    survivalConfig: this.config.survivalConfig,
                    challengeMilestones: this.config.survivalConfig?.challengeMilestones,
                    challengeTypes: this.config.survivalConfig?.challengeTypes
                });
            }
            
            // 設置當前等級對應的計時器時間
            this.timeLeft = this.calculateTimerForLevel(this.level);
            
            console.log('RPG系統已初始化:', {
                level: this.level,
                exp: this.exp,
                expToNextLevel: this.expToNextLevel,
                gold: this.gold,
                timeLeft: this.timeLeft
            });
        }
        
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
        this.pendingDamage = 0;        // 闖關模式累積傷害
        
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
        const colorMap = {
            red: '紅', blue: '藍', green: '綠',
            yellow: '黃', purple: '紫'
        };

        // 檢查關卡限制條件
        if (this.config.mode === 'quest') {
            // 檢查最低 Combo 需求
            if (restrictions.minComboForDamage && this.consecutiveSuccessfulActions < restrictions.minComboForDamage) {
                console.log(`限制生效：Combo數 ${this.consecutiveSuccessfulActions} 未達到 ${restrictions.minComboForDamage}`);
                // 顯示Toast提示
                UIManager.showActionResultToast({
                    isBlocked: true,
                    reason: 'minCombo',
                    required: restrictions.minComboForDamage,
                    current: this.consecutiveSuccessfulActions
                });
                return { finalScore: 0, isBlocked: true, reason: 'minCombo' };
            }
            // 檢查最低 Chain 需求
            if (restrictions.minChainForDamage && chainLevel < restrictions.minChainForDamage) {
                console.log(`限制生效：Chain數 ${chainLevel} 未達到 ${restrictions.minChainForDamage}`);
                UIManager.showActionResultToast({
                    isBlocked: true,
                    reason: 'minChain',
                    required: restrictions.minChainForDamage,
                    current: chainLevel
                });
                return { finalScore: 0, isBlocked: true, reason: 'minChain' };
            }
        }

        let validBlocks = [];
        let blockedColors = [];
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
                        if (!blockedColors.includes(block.colorName)) {
                            blockedColors.push(block.colorName);
                        }
                        console.log(`限制生效：顏色 ${block.colorName} 無法造成傷害`);
                    }
                    // 檢查僅限傷害顏色
                    if (restrictions.damageOnlyColors && !restrictions.damageOnlyColors.includes(block.colorName)) {
                        isValid = false;
                        if (!blockedColors.includes(block.colorName)) {
                            blockedColors.push(block.colorName);
                        }
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
            // 顯示顏色限制提示
            if (blockedColors.length > 0) {
                const blockedColorNames = blockedColors.map(c => colorMap[c] || c).join('');
                if (restrictions.noDamageColors) {
                    UIManager.showActionResultToast({
                        isBlocked: true,
                        reason: 'colorBlocked',
                        blockedColors: blockedColorNames
                    });
                } else if (restrictions.damageOnlyColors) {
                    const allowedColorNames = restrictions.damageOnlyColors.map(c => colorMap[c] || c).join('');
                    UIManager.showActionResultToast({
                        isBlocked: true,
                        reason: 'colorOnly',
                        allowedColors: allowedColorNames
                    });
                }
            }
            return { finalScore: 0, isBlocked: true, reason: 'colorRestriction' };
        }

        // 基礎分數 = 消除方塊數 × 基礎分數
        let baseScore = blocksEliminated * scoring.baseScore;
        
        // 連擊倍數：1 + (連擊數 × 連擊倍數)
        let comboMultiplier = 1 + (this.consecutiveSuccessfulActions * scoring.comboMultiplier);
        
        // 連鎖倍數：連鎖等級 × 連鎖倍數
        const chainMultiplier = chainLevel * scoring.chainMultiplier;
        
        // 應用RPG技能加成
        if (this.config.hasRPGSystem && window.SkillSystem) {
            // 獲取消除的方塊顏色列表
            const matchedColors = validBlocks.map(block => block.colorName);
            
            // 應用被動技能效果
            baseScore = SkillSystem.applyPassiveSkillEffects(baseScore, matchedColors, this.playerSkills);
            
            // 應用連擊倍率加成技能
            if (this.playerSkills['COMBO_MULTIPLIER_BONUS']) {
                const skillData = SkillSystem.getSkillData('COMBO_MULTIPLIER_BONUS', this.playerSkills['COMBO_MULTIPLIER_BONUS']);
                if (skillData) {
                    const bonus = skillData.currentLevel.value / 100;
                    comboMultiplier *= (1 + bonus);
                }
            }
        }
        
        // 計算最終分數
        const finalScore = Math.floor(baseScore * comboMultiplier * chainMultiplier);
        
        // 在闖關模式，累積傷害但不立即扣血
        if (this.config.mode === 'quest' && finalScore > 0) {
            // 累積這次的傷害，但不立即扣血
            if (!this.pendingDamage) this.pendingDamage = 0;
            this.pendingDamage += finalScore;
        }

        // 顯示成功的Toast
        if (finalScore > 0) {
            const result = {
                isBlocked: false,
                combo: this.consecutiveSuccessfulActions,
                damage: this.config.mode === 'quest' ? finalScore : 0,
                score: this.config.mode !== 'quest' ? finalScore : 0
            };
            UIManager.showActionResultToast(result);
        }

        return {
            baseScore,
            comboMultiplier,
            chainMultiplier,
            finalScore,
            isBlocked: false
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
        
        // 顯示Toast提示
        const damageText = this.config.mode === 'quest' ? '傷害' : '分';
        UIManager.showToast(`🏆 ${milestone}連擊里程碑！獲得 ${bonus} ${damageText}`, 'milestone', 3000);
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
        console.log('開始重置遊戲');
        
        // 停止遊戲循環
        this.gameLoopRunning = false;
        if (this.gameLoopId) {
            cancelAnimationFrame(this.gameLoopId);
            this.gameLoopId = null;
        }
        
        // 關閉遊戲結束彈窗
        if (this.gameOverModal && this.gameOverModal.classList) {
            this.gameOverModal.classList.remove('active');
            this.gameOverModal.style.display = 'none'; // 確保彈窗被隱藏
            const modalContent = this.gameOverModal.querySelector('.modal-content');
            if (modalContent) {
                modalContent.classList.remove('animate-scale-in');
            }
        }

        // 移除任何現有的toast
        const existingToast = document.getElementById('game-toast');
        if (existingToast) {
            existingToast.remove();
        }

        // 重置遊戲狀態
        this.setupGameState();
        this.createInitialGrid();
        this.generateNextBlockColor();
        this.updateNextBlockPreviewUI();
        
        // 重置時間相關變數，避免 deltaTime 計算錯誤
        this.lastFrameTime = null;
        
        // 確保方塊位置正確設置
        this.updateBlockPositions();
        
        this.updateUI();
        this.updateSkillButtonsUI();

        // 闖關模式UI重置
        if (this.config.mode === 'quest') {
            UIManager.updateQuestUI({
                mode: this.config.mode,
                enemy: this.enemy,
                movesLeft: this.movesLeft
            });
            
            // 重置限制顯示
            const urlParams = new URLSearchParams(window.location.search);
            const levelNumber = parseInt(urlParams.get('level')) || 1;
            const levelDetails = GameModes.quest.levelDetails[levelNumber];
            const restrictions = levelDetails?.restrictions || {};
            UIManager.updateQuestRestrictionsDisplay(restrictions, 0);
        }

        // 設置開始時間 - 統一使用 performance.now()
        if (this.config.hasTimer) {
            this.gameStartTime = performance.now();
            this.timeLeft = this.config.gameDuration; // 重置時間
        } else {
            // 即使沒有計時器，也要設置開始時間供其他功能使用
            this.gameStartTime = performance.now();
        }
        
        // 確保遊戲迴圈正在運行（只有在遊戲沒有結束時才啟動）
        if (!this.gameOver) {
            this.gameLoopRunning = false; // 重置標誌
            this.startGameLoop();
            console.log('遊戲已重置，遊戲循環已啟動');
        } else {
            console.log('遊戲已重置，但遊戲處於結束狀態，不啟動遊戲循環');
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
        
        // 更新RPG模式UI
        if (this.config.hasRPGSystem) {
            const rpgData = {
                level: this.level,
                exp: this.exp,
                expToNextLevel: this.expToNextLevel,
                gold: this.gold,
                actionPoints: this.actionPoints,
                playerSkills: this.playerSkills
            };
            
            // 如果是存活模式，添加存活模式數據
            if (this.config.isSurvivalMode) {
                rpgData.isSurvivalMode = true;
                rpgData.survivalTime = this.survivalTime || 0;
                rpgData.targetSurvivalTime = this.config.survivalConfig?.targetSurvivalTime || 180000;
            }
            
            UIManager.updateRPGStatsUI(rpgData);
        }
        
        // 更新闖關模式UI
        if (this.config.mode === 'quest') {
            UIManager.updateQuestUI({
                mode: this.config.mode,
                enemy: this.enemy,
                movesLeft: this.movesLeft
            });

            // 更新限制顯示
            const urlParams = new URLSearchParams(window.location.search);
            const levelNumber = parseInt(urlParams.get('level')) || 1;
            const levelDetails = GameModes.quest.levelDetails[levelNumber];
            const restrictions = levelDetails?.restrictions || {};
            UIManager.updateQuestRestrictionsDisplay(restrictions, this.consecutiveSuccessfulActions);
        }
        
        // 更新最高連擊記錄
        if (this.consecutiveSuccessfulActions > this.maxCombo) {
            this.maxCombo = this.consecutiveSuccessfulActions;
        }

        // 時間相關UI（限時模式）
        if (this.config.hasTimer && this.timeLeftDisplay) {
            const secondsLeft = Math.max(0, this.timeLeft / 1000);
            const displayTime = Math.ceil(secondsLeft) + 's';
            
            // 只在時間真正改變時更新顯示，避免不必要的DOM操作
            if (this.timeLeftDisplay.textContent !== displayTime) {
                this.timeLeftDisplay.textContent = displayTime;
                
                // RPG模式的調試信息
                if (this.config.hasRPGSystem) {
                    console.log(`UI更新: 計時器顯示 ${displayTime}, 實際剩餘 ${secondsLeft.toFixed(1)}秒`);
                }
            }

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
        
        // 檢查是否為黑色方塊
        if (block.isBlackened) {
            this.ctx.fillStyle = '#222222'; // 深灰色/黑色
        } else {
            this.ctx.fillStyle = block.colorHex;
        }
        this.ctx.fill();

        this.ctx.strokeStyle = 'rgba(0,0,0,0.1)';
        this.ctx.lineWidth = 1.5 / scale;
        this.ctx.stroke();

        this.ctx.restore();

        // 繪製操作提示（黑色方塊不顯示操作提示）
        if (block && !block.isEliminating && !block.isExploding && opacity > 0.5 && !this.activeSkill && !block.isBlackened) {
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
        
        // 繪製黑色方塊的剩餘回合數
        if (block && block.isBlackened && !block.isEliminating && !block.isExploding && opacity > 0.5) {
            this.ctx.fillStyle = `rgba(255,255,255,${0.9 * opacity})`;
            this.ctx.font = `bold ${Math.min(24, block.height * 0.5)}px 'Poppins'`;
            this.ctx.textAlign = 'center';
            this.ctx.textBaseline = 'middle';
            const textX = block.x + block.width / 2;
            const textY = currentDrawY + block.height / 2;
            
            // 顯示剩餘回合數
            const remainingTurns = block.blackenedClearancesRequired || 0;
            this.ctx.fillText(remainingTurns.toString(), textX, textY);
            
            // 在數字下方顯示小圖標
            this.ctx.font = `${Math.min(12, block.height * 0.2)}px 'Poppins'`;
            this.ctx.fillStyle = `rgba(255,255,255,${0.7 * opacity})`;
            this.ctx.fillText('🔒', textX, textY + block.height * 0.25);
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
            } else if (particle.isCelebration) {
                // 慶祝粒子效果
                particle.vy += 0.05 * (deltaTime / 16.67); // 很慢的重力
                // 添加閃爍和旋轉效果
                particle.opacity = 0.8 + 0.2 * Math.sin(Date.now() * 0.005);
                particle.rotation = (particle.rotation || 0) + 0.1 * (deltaTime / 16.67);
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
            } else if (particle.isCelebration) {
                // 慶祝粒子特殊渲染
                this.ctx.globalAlpha = (particle.opacity || 1) * alpha;
                // 添加彩色光暈效果
                const gradient = this.ctx.createRadialGradient(
                    particle.x, particle.y, 0,
                    particle.x, particle.y, particle.size * 1.5
                );
                gradient.addColorStop(0, particle.color);
                gradient.addColorStop(1, 'rgba(255, 255, 255, 0)');
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
                if (!block || block.isEliminating || block.isBlackened) {
                    r++;
                    continue;
                }
                
                let count = 1;
                const currentColorName = block.colorName;
                let next_r = r + 1;
                
                while (next_r < column.length && column[next_r] && 
                       column[next_r].colorName === currentColorName && 
                       !column[next_r].isEliminating && !column[next_r].isBlackened) {
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
                    if (!block || block.isEliminating || block.isBlackened) {
                        r++;
                        continue;
                    }
                    
                    let count = 1;
                    const currentColorName = block.colorName;
                    let next_r = r + 1;
                    
                    while (next_r < column.length && column[next_r] && 
                           column[next_r].colorName === currentColorName && 
                           !column[next_r].isEliminating && !column[next_r].isBlackened) {
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

                        if (!b1 || !b2 || !b3 || b1.isEliminating || b2.isEliminating || b3.isEliminating || 
                            b1.isBlackened || b2.isBlackened || b3.isBlackened) {
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
                                   !this.grid[temp_c][r].isEliminating && !this.grid[temp_c][r].isBlackened) {
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
        if (this.gameLoopId) {
            cancelAnimationFrame(this.gameLoopId);
            this.gameLoopId = null;
        }
        
        // 如果遊戲已結束，不要開始新的遊戲循環
        if (this.gameOver) {
            console.log('遊戲已結束，不啟動遊戲循環');
            return;
        }
        
        this.gameLoopRunning = true;
        
        const gameLoop = (timestamp) => {
            if (this.gameOver || !this.gameLoopRunning) {
                this.gameLoopRunning = false;
                this.gameLoopId = null;
                console.log('遊戲循環已停止');
                return;
            }

            const deltaTime = timestamp - (this.lastFrameTime || timestamp);
            this.lastFrameTime = timestamp;

            // 處理計時器 - 統一使用 performance.now()
            if (this.config.hasTimer && this.gameStartTime > 0) {
                // RPG模式在暫停時不更新計時器
                if (this.config.hasRPGSystem && (this.isPaused || this.isLevelUpInProgress || this.isTimerPaused)) {
                    // 暫停時，調整遊戲開始時間以補償暫停的時間
                    this.gameStartTime = performance.now() - (this.config.gameDuration - this.timeLeft);
                } else {
                    const elapsedTime = performance.now() - this.gameStartTime;
                    this.timeLeft = Math.max(0, this.config.gameDuration - elapsedTime);
                    
                    // 存活模式：更新存活時間（獨立於8秒計時器）
                    if (this.config.isSurvivalMode) {
                        this.updateSurvivalTime(deltaTime);
                        this.checkSurvivalMilestones();
                        // 檢查是否達到3分鐘勝利條件
                        this.checkSurvivalWinCondition();
                    }
                    
                    if (this.timeLeft <= 0) {
                        this.timeLeft = 0;
                        
                        // RPG模式：計時結束時扣除行動點而不是直接結束遊戲
                        if (this.config.hasRPGSystem && !this.isLevelUpInProgress) {
                            this.handleTimeoutPenalty();
                            // 不要return，讓遊戲循環繼續
                        } else if (!this.config.hasRPGSystem) {
                            this.triggerGameOver();
                            return;
                        }
                    }
                }
            }
            
            this.updateParticles(deltaTime);
            this.drawCanvasContent();
            
            // 更新UI以顯示當前時間
            this.updateUI();

            if (this.gameLoopRunning && !this.gameOver) {
                this.gameLoopId = requestAnimationFrame(gameLoop);
            }
        };
        this.gameLoopId = requestAnimationFrame(gameLoop);
    }

    triggerGameOver() {
        if (this.gameOver) return;

        // 闖關模式的勝負判斷
        if (this.config.mode === 'quest') {
            if (this.enemy.hp <= 0) {
                this.gameOver = true;
                this.gameLoopRunning = false;
                if (this.gameLoopId) {
                    cancelAnimationFrame(this.gameLoopId);
                    this.gameLoopId = null;
                }
                
                console.log('闖關模式勝利，顯示勝利彈窗');
                setTimeout(() => {
                    UIManager.showGameOverModal(this.score, this.maxCombo, this.actionCount, 'quest_win');
                }, 100);
                
                // 只在通關成功時保存記錄
                this.saveQuestRecord().catch(err => console.error("儲存闖關記錄失敗:", err));
                return;
            }
            if (this.movesLeft <= 0) {
                this.gameOver = true;
                this.gameLoopRunning = false;
                if (this.gameLoopId) {
                    cancelAnimationFrame(this.gameLoopId);
                    this.gameLoopId = null;
                }
                
                console.log('闖關模式失敗，顯示失敗彈窗');
                setTimeout(() => {
                    UIManager.showGameOverModal(this.score, this.maxCombo, this.actionCount, 'quest_loss');
                }, 100);
                
                // 失敗時不保存記錄，只顯示結果
                console.log("闖關失敗，不保存記錄");
                return;
            }
            // 如果是闖關模式，且不滿足輸贏條件，則不應結束遊戲
            return;
        }
        
        // 原有的遊戲結束邏輯 (例如計時器或行動點數)
        this.gameOver = true;
        this.gameLoopRunning = false;
        if (this.gameLoopId) {
            cancelAnimationFrame(this.gameLoopId);
            this.gameLoopId = null;
        }
        
        console.log('三排強攻遊戲結束，觸發結算彈窗');
        
        // 確保彈窗顯示在下一個事件循環中，避免被其他操作截斷
        setTimeout(() => {
            UIManager.showGameOverModal(this.score, this.maxCombo, this.actionCount, 'default');
            console.log('結算彈窗已顯示');
        }, 100);

        // 異步保存記錄，不阻塞彈窗顯示
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
        if (this.gameOver || this.isAnimating) {
            console.log('遊戲已結束或正在執行動畫，忽略點擊');
            return;
        }
        
        const rect = this.canvas.getBoundingClientRect();
        const scaleX = this.canvas.width / rect.width;
        const scaleY = this.canvas.height / rect.height;
        const mouseX = (event.clientX - rect.left) * scaleX;
        const mouseY = (event.clientY - rect.top) * scaleY;

        // 先檢查是否點擊了黑色方塊，如果是則不重置計時器
        let clickedBlackenedBlock = false;

        if (this.config.numCols === 1) {
            // 單排模式
            for (let i = 0; i < this.grid[0].length; i++) {
                const block = this.grid[0][i];
                if (!block || block.isEliminating || block.isExploding) continue;
                
                if (mouseX >= block.x && mouseX <= block.x + block.width && 
                    mouseY >= block.y && mouseY <= block.y + block.height) {
                    
                    // 檢查是否為黑色方塊
                    if (block.isBlackened) {
                        clickedBlackenedBlock = true;
                        // 顯示黑色方塊不能操作的提示
                        try {
                            if (typeof UIManager !== 'undefined' && UIManager.showToast) {
                                UIManager.showToast('🔒 黑色方塊無法操作！', 'warning', 2000);
                            }
                        } catch (error) {
                            console.error('顯示黑色方塊提示出錯:', error);
                        }
                        return;
                    }
                    
                    // RPG模式：用戶點擊有效方塊時立即重置計時器並暫停倒數
                    if (this.config.hasRPGSystem && !this.isLevelUpInProgress) {
                        this.resetTimerAndPause();
                    }
                    
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
                        
                        // 檢查是否為黑色方塊
                        if (block.isBlackened) {
                            clickedBlackenedBlock = true;
                            // 顯示黑色方塊不能操作的提示
                            try {
                                if (typeof UIManager !== 'undefined' && UIManager.showToast) {
                                    UIManager.showToast('🔒 黑色方塊無法操作！', 'warning', 2000);
                                }
                            } catch (error) {
                                console.error('顯示黑色方塊提示出錯:', error);
                            }
                            return;
                        }
                        
                        // RPG模式：用戶點擊有效方塊時立即重置計時器並暫停倒數
                        if (this.config.hasRPGSystem && !this.isLevelUpInProgress) {
                            this.resetTimerAndPause();
                        }
                        
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

        const { colIndex, rowIndex } = location;
        if (this.config.numCols === 1) {
            if (!this.grid[0] || !this.grid[0][rowIndex]) return;
        } else {
            if (!this.grid[colIndex] || !this.grid[colIndex][rowIndex]) return;
        }

        // 黑色方塊檢查已在 handleCanvasClick 中處理，這裡不再需要

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
            // 處理失誤懲罰
            this.consecutiveSuccessfulActions = 0;
            this.lastComboScore = 0;
            
            // 根據不同模式處理行動點數扣除和顯示Toast
            if (this.config.mode === 'quest') {
                // 闖關模式不扣除行動點數，步數已在開始時扣除
                UIManager.showToast('❌ 沒有消除方塊', 'error', 1500);
            } else if (this.config.actionPointsStart > 0) {
                // 有行動點數限制的模式（包括三排限時強攻）
                this.actionPoints--;
                UIManager.showToast(`❌ 沒有消除方塊 (剩餘 ${this.actionPoints} 點)`, 'error', 2000);
                if (this.config.title === '三排限時強攻') {
                    this.handlePenalty(); // 額外的震動效果
                }
            } else if (this.config.hasRPGSystem) {
                // RPG模式：無效移動觸發晃動效果
                UIManager.showToast('❌ 沒有消除方塊', 'error', 1500);
                this.triggerShakeEffect(); // RPG模式的晃動效果
            } else {
                // actionPointsStart = 0 的模式（如45秒限時）不扣除行動點數
                UIManager.showToast('❌ 沒有消除方塊', 'error', 1500);
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
        
        // RPG模式：操作完成後恢復計時器倒數
        if (this.config.hasRPGSystem && !this.isLevelUpInProgress) {
            this.resumeTimer();
        }
        
        // 檢查遊戲結束條件
        if (this.config.mode === 'quest') {
            // 闖關模式：檢查敵人血量和剩餘步數
            this.triggerGameOver();
        } else if (this.config.actionPointsStart > 0 && this.actionPoints <= 0 && !this.gameOver) {
            // 有行動點數限制的模式：檢查行動點數用盡
            console.log('行動點數用盡，觸發遊戲結束');
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
                
                // 存活模式：增加消除次數計數器
                if (this.config.isSurvivalMode) {
                    this.clearancesCount++;
                    console.log(`消除次數: ${this.clearancesCount}`);
                    this.updateBlackenedBlocks();
                }
                
                // 使用新的連擊分數計算系統
                const scoreInfo = this.calculateComboScore(matches, internalCascadeCount);
                this.score += scoreInfo.finalScore;
                this.lastComboScore = scoreInfo.finalScore;
                
                // RPG系統：處理經驗值和金幣
                if (this.config.hasRPGSystem && window.SkillSystem && scoreInfo.finalScore > 0) {
                    this.addExp(scoreInfo.finalScore);
                    this.addGold(scoreInfo.finalScore);
                }
            
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
        
        // RPG模式：選擇技能本身不重置計時器，只有使用技能後才重置
        // 移除了這裡的計時器重置邏輯
        
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
        
        // RPG模式：使用技能時重置計時器
        if (this.config.hasRPGSystem && !this.isLevelUpInProgress) {
            this.resetTimer();
        }
        
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
        
        // RPG模式：使用技能後重置並恢復計時器倒數
        if (this.config.hasRPGSystem && skillEffectApplied && !this.isLevelUpInProgress) {
            this.resetTimerAndPause();
            this.resumeTimer();
        }
        
        // 檢查遊戲結束條件
        if (this.config.mode === 'quest') {
            this.triggerGameOver();
        } else if (this.config.actionPointsStart > 0 && this.actionPoints <= 0 && !this.gameOver) {
            console.log('技能使用後行動點數用盡，觸發遊戲結束');
            this.triggerGameOver();
        }
    }

    handlePenalty() {
        // 震動效果
        const gameContainer = document.querySelector('.game-container');
        if (gameContainer) {
            gameContainer.classList.add('screen-shake');
            setTimeout(() => {
                gameContainer.classList.remove('screen-shake');
            }, 500);
        }

        this.updateUI();

        // 三排限時強攻模式的行動點數已在 performPlayerAction 中處理
        // 這裡只需要提供視覺反饋
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

    // ===== RPG系統方法 =====
    
    // 處理計時器超時懲罰
    handleTimeoutPenalty() {
        if (!this.config.hasRPGSystem || this.isLevelUpInProgress || this.gameOver) return;
        
        // 防止重複調用
        if (this.processingTimeoutPenalty) return;
        this.processingTimeoutPenalty = true;
        
        console.log(`計時器超時！當前行動點: ${this.actionPoints}`);
        
        // 扣除行動點
        this.actionPoints--;
        console.log(`扣除行動點，剩餘: ${this.actionPoints}`);
        
        // 重置combo（超時懲罰也會中斷連擊）
        this.consecutiveSuccessfulActions = 0;
        this.lastComboScore = 0;
        console.log('超時懲罰：重置combo');
        
        // 觸發晃動特效
        this.triggerShakeEffect();
        
        // 顯示懲罰提示
        try {
            if (typeof UIManager !== 'undefined' && UIManager.showToast) {
                UIManager.showToast(`⏰ 時間到！扣除行動點 (剩餘 ${this.actionPoints} 點)`, 'error', 2000);
            }
        } catch (error) {
            console.error('顯示Toast出錯:', error);
        }
        
        // 檢查是否遊戲結束
        if (this.actionPoints <= 0) {
            console.log('行動點歸零，觸發遊戲結束');
            this.processingTimeoutPenalty = false;
            
            // 存活模式：行動點歸零就是失敗
            if (this.config.isSurvivalMode) {
                this.triggerSurvivalGameOver();
            } else {
                this.triggerGameOver();
            }
            return;
        }
        
        // 重置計時器 - 確保恢復正常計時
        console.log('準備重置計時器...');
        this.resetTimer();
        
        // 確保遊戲狀態正確恢復
        this.isPaused = false;
        this.isAnimating = false;
        this.isLevelUpInProgress = false;  // 確保不在升級流程中
        
        console.log(`計時器重置完成，恢復計時，遊戲狀態已恢復 - isPaused:${this.isPaused}, isAnimating:${this.isAnimating}`);
        
        // 更新UI
        this.updateUI();
        
        // 重置處理標誌，確保下次超時可以正常處理
        this.processingTimeoutPenalty = false;
    }
    
    // 觸發晃動特效
    triggerShakeEffect() {
        const gameContainer = document.getElementById('game-container');
        const rpgStats = document.getElementById('rpg-stats');
        
        if (gameContainer) {
            gameContainer.classList.add('shake-effect');
            setTimeout(() => {
                gameContainer.classList.remove('shake-effect');
            }, 500);
        }
        
        if (rpgStats) {
            rpgStats.classList.add('shake-effect');
            setTimeout(() => {
                rpgStats.classList.remove('shake-effect');
            }, 500);
        }
    }
    
    // 計算當前等級對應的計時器時間（毫秒）
    calculateTimerForLevel(level) {
        if (!this.config.hasRPGSystem) return this.config.gameDuration;
        
        const baseTimer = this.config.rpgConfig?.baseTimer || 13;
        const reduction = (level - 1) * (this.config.rpgConfig?.timerReductionPerLevel || 0.5);
        const minTimer = this.config.rpgConfig?.minTimer || 8;
        
        const currentTimer = Math.max(baseTimer - reduction, minTimer);
        return currentTimer * 1000; // 轉換為毫秒
    }
    
    // 重置計時器到當前等級對應的時間
    resetTimer() {
        if (!this.config.hasRPGSystem) return;
        
        const newTimeLeft = this.calculateTimerForLevel(this.level);
        this.timeLeft = newTimeLeft;
        
        // 重置遊戲開始時間以確保計時器正確計算
        const currentTime = performance.now();
        this.gameStartTime = currentTime;
        this.config.gameDuration = newTimeLeft;
        
        console.log(`計時器重置: timeLeft=${this.timeLeft}ms, gameDuration=${this.config.gameDuration}ms, gameStartTime=${this.gameStartTime}`);
        
        // 確保UI立即更新
        if (this.timeLeftDisplay) {
            const secondsLeft = Math.max(0, this.timeLeft / 1000);
            const displayTime = Math.ceil(secondsLeft) + 's';
            this.timeLeftDisplay.textContent = displayTime;
            console.log(`UI已更新顯示: ${displayTime}`);
        }
        
        console.log('計時器重置完成，下次遊戲循環將開始新的倒數');
    }
    
    // 重置計時器並暫停倒數（用戶點擊時）
    resetTimerAndPause() {
        if (!this.config.hasRPGSystem) return;
        
        const newTimeLeft = this.calculateTimerForLevel(this.level);
        this.timeLeft = newTimeLeft;
        this.config.gameDuration = newTimeLeft;
        
        // 暫停計時器：設置一個未來的開始時間
        this.isTimerPaused = true;
        
        console.log(`計時器重置並暫停: timeLeft=${this.timeLeft}ms, 等待操作完成後恢復倒數`);
        
        // 更新UI顯示
        if (this.timeLeftDisplay) {
            const secondsLeft = Math.max(0, this.timeLeft / 1000);
            const displayTime = Math.ceil(secondsLeft) + 's';
            this.timeLeftDisplay.textContent = displayTime;
        }
    }
    
    // 恢復計時器倒數（操作完成後）
    resumeTimer() {
        if (!this.config.hasRPGSystem || !this.isTimerPaused) return;
        
        // 恢復計時：重新設置開始時間
        this.gameStartTime = performance.now();
        this.isTimerPaused = false;
        
        console.log(`計時器恢復倒數: gameStartTime=${this.gameStartTime}, timeLeft=${this.timeLeft}ms`);
    }
    
    // 增加經驗值
    addExp(baseScore) {
        if (!this.config.hasRPGSystem || this.isLevelUpInProgress) return;
        
        const expGained = SkillSystem.calculateExpGained(baseScore, this.level);
        this.exp += expGained;
        
        console.log(`獲得經驗值: ${expGained}, 當前經驗: ${this.exp}/${this.expToNextLevel}`);
        
        // 檢查是否升級
        if (this.exp >= this.expToNextLevel) {
            this.levelUp();
        }
    }
    
    // 增加金幣
    addGold(baseScore) {
        if (!this.config.hasRPGSystem) return;
        
        const goldGained = SkillSystem.calculateGoldGained(baseScore);
        this.gold += goldGained;
        
        console.log(`獲得金幣: ${goldGained}, 當前金幣: ${this.gold}`);
    }
    
    // 升級
    levelUp() {
        if (!this.config.hasRPGSystem || this.isLevelUpInProgress) return;
        
        // 檢查是否達到最大等級
        const maxLevel = this.config.rpgConfig?.maxLevel || 10;
        if (this.level >= maxLevel) {
            console.log(`已達到最大等級 ${maxLevel}，不再升級`);
            return;
        }
        
        this.isLevelUpInProgress = true;
        this.isPaused = true; // 暫停遊戲計時
        this.level++;
        this.exp -= this.expToNextLevel;
        this.expToNextLevel = SkillSystem.calculateExpRequired(this.level);
        
        console.log(`升級到 ${this.level} 級！`);
        
        // 暫停遊戲並顯示技能選擇
        this.showLevelUpModal();
    }
    
    // 顯示升級模式彈窗
    showLevelUpModal() {
        // 獲取技能選項（支持升級系統）
        const skillOptions = SkillSystem.getRandomSkillOptions(this.playerSkills, 2);
        
        // 暫停遊戲
        this.isAnimating = true;
        
        // 重置免費重抽標誌
        this.hasUsedFreeReroll = false;
        
        // 創建升級彈窗
        try {
            if (typeof UIManager !== 'undefined' && UIManager.showLevelUpModal) {
                UIManager.showLevelUpModal({
                    level: this.level,
                    skillOptions: skillOptions,
                    playerGold: this.gold,
                    playerSkills: this.playerSkills,
                    hasUsedFreeReroll: this.hasUsedFreeReroll,
                    onSkillPurchase: (skillId) => this.purchaseSkill(skillId),
                    onSkipUpgrade: () => this.skipUpgrade(),
                    onRerollOptions: (isFree) => this.handleRerollOptions(isFree)
                });
            } else if (typeof UI !== 'undefined' && UI.showLevelUpModal) {
                UI.showLevelUpModal({
                    level: this.level,
                    skillOptions: skillOptions,
                    playerGold: this.gold,
                    playerSkills: this.playerSkills,
                    hasUsedFreeReroll: this.hasUsedFreeReroll,
                    onSkillPurchase: (skillId) => this.purchaseSkill(skillId),
                    onSkipUpgrade: () => this.skipUpgrade(),
                    onRerollOptions: (isFree) => this.handleRerollOptions(isFree)
                });
            } else {
                console.error('UI管理器未找到，無法顯示升級彈窗');
                // 直接跳過升級
                this.skipUpgrade();
            }
        } catch (error) {
            console.error('顯示升級彈窗時出錯:', error);
            // 直接跳過升級
            this.skipUpgrade();
        }
    }
    
    // 購買技能
    purchaseSkill(skillId) {
        if (!this.config.hasRPGSystem || !skillId) {
            this.resumeGame();
            return;
        }
        
        const currentLevel = this.playerSkills[skillId] || 0;
        const nextLevel = currentLevel + 1;
        const skillData = SkillSystem.getSkillData(skillId, nextLevel);
        
        if (!skillData || this.gold < skillData.currentLevel.cost) {
            console.log('金幣不足或技能無效');
            this.resumeGame();
            return;
        }
        
        // 扣除金幣
        this.gold -= skillData.currentLevel.cost;
        
        // 更新技能等級
        this.playerSkills[skillId] = nextLevel;
        
        // 應用即時效果技能
        SkillSystem.applyInstantSkillEffect(skillId, nextLevel, this);
        
        const isUpgrade = currentLevel > 0;
        console.log(`${isUpgrade ? '升級' : '獲得'}技能: ${skillData.name} (等級 ${nextLevel}), 花費: ${skillData.currentLevel.cost} 金幣`);
        
        // 重置免費重抽標誌
        this.hasUsedFreeReroll = false;
        
        this.resumeGame();
    }
    
    // 處理重抽選項
    handleRerollOptions(isFree = false) {
        if (!isFree && this.hasUsedFreeReroll) {
            const rerollCost = 50;
            if (this.gold < rerollCost) {
                console.log('金幣不足，無法重抽！');
                return;
            }
            this.gold -= rerollCost;
        } else if (isFree) {
            this.hasUsedFreeReroll = true;
        }
        
        // 獲取新的技能選項
        const newOptions = SkillSystem.getRandomSkillOptions(this.playerSkills, 2);
        
        // 更新彈窗顯示
        try {
            if (typeof UIManager !== 'undefined' && UIManager.updateLevelUpModal) {
                UIManager.updateLevelUpModal({
                    skillOptions: newOptions,
                    playerGold: this.gold,
                    hasUsedFreeReroll: this.hasUsedFreeReroll
                });
            }
        } catch (error) {
            console.error('更新升級彈窗時出錯:', error);
        }
        
        console.log('重抽技能選項:', newOptions);
    }
    
    // 跳過升級（不購買技能）
    skipUpgrade() {
        console.log('跳過升級，不購買技能');
        this.resumeGame();
    }
    
    // 恢復遊戲
    resumeGame() {
        console.log('開始恢復遊戲...');
        
        this.isLevelUpInProgress = false;
        this.isAnimating = false;
        
        // 如果是RPG模式，恢復計時並重置計時器
        if (this.config.hasRPGSystem) {
            this.isPaused = false;
            this.resetTimer();
            console.log('RPG計時器已恢復並重置');
        }
        
        // 關閉升級彈窗
        try {
            if (typeof UIManager !== 'undefined' && UIManager.closeLevelUpModal) {
                UIManager.closeLevelUpModal();
            } else if (typeof UI !== 'undefined' && UI.closeLevelUpModal) {
                UI.closeLevelUpModal();
            } else {
                // 手動關閉彈窗
                const modal = document.getElementById('levelUpModal');
                if (modal && modal.parentNode) {
                    modal.parentNode.removeChild(modal);
                }
            }
        } catch (error) {
            console.error('關閉升級彈窗時出錯:', error);
            // 手動關閉彈窗
            const modal = document.getElementById('levelUpModal');
            if (modal && modal.parentNode) {
                modal.parentNode.removeChild(modal);
            }
        }
        
        // 更新UI
        this.updateUI();
        
        console.log('遊戲恢復完成');
    }

    // ===== 存活模式方法 =====
    
    // 更新存活時間（一直計算，直到遊戲結束）
    updateSurvivalTime(deltaTime) {
        if (!this.config.isSurvivalMode) return;
        
        // 存活時間一直累積，不依賴8秒計時器狀態
        if (!this.isPaused && !this.isLevelUpInProgress && !this.gameOver) {
            this.survivalTime += deltaTime;
            this.totalGameTime += deltaTime;
            
            // 每5秒打印一次存活時間用於調試
            if (Math.floor(this.survivalTime / 5000) > Math.floor((this.survivalTime - deltaTime) / 5000)) {
                console.log(`⏰ 存活時間更新: ${Math.floor(this.survivalTime / 1000)} 秒`);
            }
        }
    }
    
    // 檢查存活里程碑
    checkSurvivalMilestones() {
        if (!this.config.isSurvivalMode || !this.config.survivalConfig) {
            console.log('❌ 存活里程碑檢查失敗:', {
                isSurvivalMode: this.config.isSurvivalMode,
                hasSurvivalConfig: !!this.config.survivalConfig
            });
            return;
        }
        
        const milestones = this.config.survivalConfig.challengeMilestones;
        const challenges = this.config.survivalConfig.challengeTypes;
        
        console.log('🔍 檢查存活里程碑:', {
            survivalTime: this.survivalTime,
            milestones: milestones,
            challengesTriggered: this.challengesTriggered
        });
        
        for (let i = 0; i < milestones.length; i++) {
            const milestone = milestones[i];
            if (this.survivalTime >= milestone && !this.challengesTriggered.includes(milestone)) {
                this.challengesTriggered.push(milestone);
                console.log(`🎯 存活時間達到 ${milestone/1000} 秒！觸發挑戰`);
                
                // 根據里程碑選擇對應的黑色方塊挑戰
                const selectedChallenge = challenges[i]; // 直接使用索引對應的挑戰
                console.log('🔥 選擇的挑戰:', selectedChallenge);
                
                this.triggerChallenge(selectedChallenge);
            }
        }
    }
    
    // 觸發挑戰
    triggerChallenge(challenge) {
        if (!challenge) {
            console.log('❌ 觸發挑戰失敗: 挑戰為空');
            return;
        }
        
        console.log(`🚨 觸發挑戰: ${challenge.name}`, challenge);
        this.activeChallenges.push(challenge);
        
        switch (challenge.type) {
            case 'blackenBlocks':
                console.log(`🎯 執行黑色方塊挑戰: ${challenge.blocksCount} 個方塊，${challenge.clearancesRequired} 次消除`);
                this.blackenRandomBlocks(challenge.blocksCount, challenge.clearancesRequired);
                break;
            default:
                console.log(`❌ 未知的挑戰類型: ${challenge.type}`);
                break;
        }
        
        // 顯示挑戰通知
        this.showChallengeNotification(challenge);
    }
    
    // 黑化隨機方塊
    blackenRandomBlocks(count, clearancesRequired) {
        console.log(`🎯 開始黑化方塊: 目標 ${count} 個，需要 ${clearancesRequired} 次消除`);
        
        const availableBlocks = [];
        for (let col = 0; col < this.grid.length; col++) {
            for (let row = 0; row < this.grid[col].length; row++) {
                const block = this.grid[col][row];
                if (block && !block.isBlackened) {
                    availableBlocks.push({ block, col, row });
                }
            }
        }
        
        console.log(`📋 可用方塊: ${availableBlocks.length} 個`);
        
        const shuffled = availableBlocks.sort(() => 0.5 - Math.random());
        const actualCount = Math.min(count, shuffled.length);
        
        for (let i = 0; i < actualCount; i++) {
            const { block, col, row } = shuffled[i];
            
            // 直接在方塊對象上存儲黑化信息
            block.isBlackened = true;
            block.originalColor = block.colorName;
            block.originalColorHex = block.colorHex;
            block.blackenedClearancesRequired = clearancesRequired; // 剩餘需要的消除次數
            
            console.log(`⚫ 方塊 [${col}][${row}] 已變黑，原色: ${block.originalColor}，需要 ${clearancesRequired} 次消除`);
        }
        
        console.log(`✅ 成功黑化了 ${actualCount} 個方塊，需要 ${clearancesRequired} 次消除來解除`);
    }
    
    // 顯示挑戰通知
    showChallengeNotification(challenge) {
        try {
            if (typeof UIManager !== 'undefined' && UIManager.showToast) {
                UIManager.showToast(`⚠️ 挑戰出現！${challenge.name}: ${challenge.description}`, 'warning', 4000);
            }
        } catch (error) {
            console.error('顯示挑戰通知出錯:', error);
        }
    }
    
    // 檢查存活勝利條件
    checkSurvivalWinCondition() {
        if (!this.config.isSurvivalMode || !this.config.survivalConfig) return;
        
        const targetTime = this.config.survivalConfig.targetSurvivalTime;
        if (this.survivalTime >= targetTime) {
            console.log('🎉 存活模式勝利！');
            this.gameOver = true;
            this.gameLoopRunning = false;
            if (this.gameLoopId) {
                cancelAnimationFrame(this.gameLoopId);
                this.gameLoopId = null;
            }
            
            // 保存存活模式記錄
            this.saveSurvivalRecord(true);
            
            setTimeout(() => {
                this.showSurvivalVictoryModal();
            }, 100);
        }
    }

    // 觸發存活模式遊戲結束
    triggerSurvivalGameOver() {
        if (!this.config.isSurvivalMode || !this.config.survivalConfig) return;
        
        console.log('存活模式遊戲結束！');
        this.gameOver = true;
        this.gameLoopRunning = false;
        if (this.gameLoopId) {
            cancelAnimationFrame(this.gameLoopId);
            this.gameLoopId = null;
        }
        
        // 檢查是否達成目標
        const targetTime = this.config.survivalConfig.targetSurvivalTime;
        const isSuccess = this.survivalTime >= targetTime;
        
        // 保存存活模式記錄（無論成功或失敗）
        this.saveSurvivalRecord(isSuccess);
        
        setTimeout(() => {
            if (isSuccess) {
                this.showSurvivalVictoryModal();
            } else {
                this.showSurvivalFailureModal();
            }
        }, 100);
    }
    
    // 保存存活模式記錄
    async saveSurvivalRecord(isSuccess) {
        if (!window.supabaseAuth || !window.supabaseAuth.isAuthenticated()) {
            console.log("用戶未登入，不儲存存活模式記錄。");
            return;
        }

        const survivalTimeInSeconds = Math.round(this.survivalTime / 1000);

        const gameData = {
            mode: 'survival', // 存活模式
            score: this.score,
            moves: this.actionCount,
            time: survivalTimeInSeconds, // time_take 欄位存入存活時間（秒）
            level: this.level || 1,
            isCompleted: isSuccess, // 是否成功通關
            challengesSurvived: this.challengesTriggered.length, // 存活的挑戰數
            maxCombo: this.maxCombo
        };

        try {
            console.log("正在儲存存活模式記錄:", gameData);
            const savedRecord = await window.supabaseAuth.saveGameRecord(gameData);
            console.log("存活模式記錄儲存成功:", savedRecord);
        } catch (error) {
            console.error("儲存存活模式記錄失敗:", error);
        }
    }
    
    // 顯示存活勝利彈窗
    showSurvivalVictoryModal() {
        const survivalMinutes = Math.floor(this.survivalTime / 60000);
        const survivalSeconds = Math.floor((this.survivalTime % 60000) / 1000);
        
        // 觸發慶祝效果
        this.triggerCelebrationEffect();
        
        try {
            if (typeof UIManager !== 'undefined' && UIManager.showGameOverModal) {
                UIManager.showGameOverModal(
                    this.score, 
                    this.maxCombo, 
                    this.actionCount, 
                    'survival_victory',
                    {
                        survivalTime: `${survivalMinutes}:${survivalSeconds.toString().padStart(2, '0')}`,
                        challengesSurvived: this.challengesTriggered.length,
                        level: this.level,
                        skillsObtained: Object.keys(this.playerSkills).length
                    }
                );
            }
        } catch (error) {
            console.error('顯示勝利彈窗出錯:', error);
        }
    }

    // 顯示存活失敗彈窗
    showSurvivalFailureModal() {
        const survivalMinutes = Math.floor(this.survivalTime / 60000);
        const survivalSeconds = Math.floor((this.survivalTime % 60000) / 1000);
        
        try {
            if (typeof UIManager !== 'undefined' && UIManager.showGameOverModal) {
                UIManager.showGameOverModal(
                    this.score, 
                    this.maxCombo, 
                    this.actionCount, 
                    'survival_failure',
                    {
                        survivalTime: `${survivalMinutes}:${survivalSeconds.toString().padStart(2, '0')}`,
                        challengesSurvived: this.challengesTriggered.length,
                        level: this.level,
                        skillsObtained: Object.keys(this.playerSkills).length
                    }
                );
            }
        } catch (error) {
            console.error('顯示失敗彈窗出錯:', error);
        }
    }

    // 觸發慶祝效果
    triggerCelebrationEffect() {
        // 創建慶祝粒子效果
        const centerX = this.canvas.width / 2;
        const centerY = this.canvas.height / 2;
        
        for (let i = 0; i < 50; i++) {
            const angle = (Math.PI * 2 * i) / 50;
            const speed = Math.random() * 6 + 4;
            const vx = Math.cos(angle) * speed;
            const vy = Math.sin(angle) * speed;
            
            this.particles.push({
                x: centerX,
                y: centerY,
                vx: vx,
                vy: vy,
                life: 2000,
                maxLife: 2000,
                color: ['#FFD700', '#FF6B6B', '#4ECDC4', '#45B7D1', '#FFA07A'][Math.floor(Math.random() * 5)],
                size: Math.random() * 6 + 4,
                isCelebration: true
            });
        }
        
        // 顯示慶祝文字
        try {
            if (typeof UIManager !== 'undefined' && UIManager.showToast) {
                UIManager.showToast('🎉 挑戰成功！存活3分鐘達成！', 'success', 3000);
            }
        } catch (error) {
            console.error('顯示慶祝提示出錯:', error);
        }
    }
    
    // 更新黑色方塊狀態（消除次數達標時解除）
    updateBlackenedBlocks() {
        if (!this.config.isSurvivalMode) return;
        
        let removedCount = 0;
        
        // 遍歷所有方塊，檢查黑色方塊狀態
        for (let col = 0; col < this.grid.length; col++) {
            for (let row = 0; row < this.grid[col].length; row++) {
                const block = this.grid[col][row];
                if (!block || !block.isBlackened) continue;
                
                // 遞減剩餘需要的消除次數
                if (block.blackenedClearancesRequired > 0) {
                    block.blackenedClearancesRequired--;
                    console.log(`⚫ 方塊 [${col}][${row}] 還需要 ${block.blackenedClearancesRequired} 次消除`);
                    
                    // 如果達到解除條件
                    if (block.blackenedClearancesRequired <= 0) {
                        // 恢復方塊的原始顏色
                        block.isBlackened = false;
                        block.colorName = block.originalColor || this.getRandomColorName();
                        block.colorHex = block.originalColorHex || this.config.colors[block.colorName].hex;
                        
                        // 清理黑化相關屬性
                        delete block.originalColor;
                        delete block.originalColorHex;
                        delete block.blackenedClearancesRequired;
                        
                        removedCount++;
                        console.log(`🔓 方塊 [${col}][${row}] 已解除，恢復為 ${block.colorName}`);
                    }
                }
            }
        }
        
        // 顯示解除提示
        if (removedCount > 0) {
            try {
                if (typeof UIManager !== 'undefined' && UIManager.showToast) {
                    UIManager.showToast(`🔓 ${removedCount} 個黑色方塊已解除！`, 'success', 2000);
                }
            } catch (error) {
                console.error('顯示黑色方塊解除提示出錯:', error);
            }
        }
    }

    // 重抽技能選項
    rerollSkillOptions(isFree = false) {
        if (!isFree) {
            const rerollCost = 50; // 重抽費用
            if (this.gold < rerollCost) {
                console.log('金幣不足，無法重抽！');
                return null;
            }
            this.gold -= rerollCost;
        }
        
        // 獲取新的技能選項
        const newOptions = SkillSystem.getRandomSkillOptions(this.playerSkills, 2);
        console.log('重抽技能選項:', newOptions);
        
        return newOptions;
    }
}

// 導出類
if (typeof module !== 'undefined' && module.exports) {
    module.exports = GameEngine;
} 