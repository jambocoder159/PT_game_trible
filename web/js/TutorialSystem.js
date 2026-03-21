class TutorialSystem {
    constructor(gameEngine) {
        this.gameEngine = gameEngine;
        this.currentStep = 0;
        this.isActive = false;
        this.tutorialSteps = [];
        this.originalGameOverHandler = null;
        this.tutorialScenarios = {};
        
        this.setupTutorialSteps();
        this.setupTutorialScenarios();
    }

    setupUIElements() {
        this.overlay = document.getElementById('tutorialOverlay');
        this.dialog = document.getElementById('tutorialDialog');
        this.arrow = document.getElementById('tutorialArrow');
        this.title = document.getElementById('tutorialTitle');
        this.content = document.getElementById('tutorialContent');
        this.prevBtn = document.getElementById('tutorialPrevBtn');
        this.nextBtn = document.getElementById('tutorialNextBtn');
        this.stepCounter = document.getElementById('tutorialStepCounter');
        this.hand = document.getElementById('tutorialHand');
        this.skipBtn = document.getElementById('tutorialSkipBtn');
        this.progress = document.getElementById('tutorialProgress');
        this.progressFill = document.getElementById('tutorialProgressFill');
    }

    setupEventListeners() {
        console.log('設置教學事件監聽器...');
        console.log('prevBtn:', this.prevBtn);
        console.log('nextBtn:', this.nextBtn);
        console.log('skipBtn:', this.skipBtn);
        
        if (this.prevBtn) {
            this.prevBtn.addEventListener('click', () => {
                console.log('點擊上一步');
                this.previousStep();
            });
        }
        
        if (this.nextBtn) {
            this.nextBtn.addEventListener('click', () => {
                console.log('點擊下一步');
                this.nextStep();
            });
        }
        
        if (this.skipBtn) {
            this.skipBtn.addEventListener('click', () => {
                console.log('點擊跳過');
                this.skip();
            });
        }
        
        // ESC 鍵跳過教學
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.isActive) {
                this.skip();
            }
        });
        
        console.log('教學事件監聽器設置完成');
    }

    setupTutorialScenarios() {
        // 定義教學場景的固定遊戲狀態
        this.tutorialScenarios = {
            // 步驟1: 初始場景 - [b,b,r,r,b,b,r,r,b,b]
            step1_initial: {
                blocks: [
                    { col: 0, row: 0, color: 'blue' },   // 第1個 b (最底部)
                    { col: 0, row: 1, color: 'blue' },   // 第2個 b
                    { col: 0, row: 2, color: 'red' },    // 第3個 r
                    { col: 0, row: 3, color: 'red' },    // 第4個 r (目標方塊)
                    { col: 0, row: 4, color: 'blue' },   // 第5個 b
                    { col: 0, row: 5, color: 'blue' },   // 第6個 b
                    { col: 0, row: 6, color: 'red' },    // 第7個 r
                    { col: 0, row: 7, color: 'red' },    // 第8個 r
                    { col: 0, row: 8, color: 'blue' },   // 第9個 b
                    { col: 0, row: 9, color: 'blue' }    // 第10個 b (最頂部)
                ],
                nextColors: ['yellow'],
                description: '初始場景 - 將第四個紅色方塊移動到最上面'
            },
            
            // 步驟2: 第四個紅色方塊移動到頂部後 - [r,b,b,r,b,b,r,r,b,b]
            step2_after_move_up: {
                blocks: [
                    { col: 0, row: 0, color: 'red' },    // 移動到頂部的紅色方塊
                    { col: 0, row: 1, color: 'blue' },   
                    { col: 0, row: 2, color: 'blue' },   
                    { col: 0, row: 3, color: 'red' },    
                    { col: 0, row: 4, color: 'blue' },   
                    { col: 0, row: 5, color: 'blue' },   
                    { col: 0, row: 6, color: 'red' },    
                    { col: 0, row: 7, color: 'red' },    
                    { col: 0, row: 8, color: 'blue' },   
                    { col: 0, row: 9, color: 'blue' }    
                ],
                nextColors: ['yellow'],
                description: '將最上面的紅色方塊移動到最底層'
            },
            
            // 步驟3: 最上面的紅色方塊移動到底部後 - [b,b,r,b,b,r,r,b,b,r]
            step3_after_move_down: {
                blocks: [
                    { col: 0, row: 0, color: 'blue' },   
                    { col: 0, row: 1, color: 'blue' },   
                    { col: 0, row: 2, color: 'red' },    
                    { col: 0, row: 3, color: 'blue' },   
                    { col: 0, row: 4, color: 'blue' },   
                    { col: 0, row: 5, color: 'red' },    
                    { col: 0, row: 6, color: 'red' },    
                    { col: 0, row: 7, color: 'blue' },   
                    { col: 0, row: 8, color: 'blue' },   
                    { col: 0, row: 9, color: 'red' }     // 移動到底部的紅色方塊
                ],
                nextColors: ['yellow'],
                description: '消除第四個藍色方塊'
            },
            
            // 步驟4: 消除第四個藍色方塊後，黃色方塊落下 - 設置三消場景
            step4_after_remove_blue: {
                blocks: [
                    { col: 0, row: 0, color: 'yellow' }, // 黃色方塊落下
                    { col: 0, row: 1, color: 'blue' },   
                    { col: 0, row: 2, color: 'blue' },    // 第3個紅色方塊
                    { col: 0, row: 3, color: 'red' },    // 第4個紅色方塊（目標，消除後形成三消）
                    { col: 0, row: 4, color: 'blue' },   
                    { col: 0, row: 5, color: 'red' },    
                    { col: 0, row: 6, color: 'red' },    
                    { col: 0, row: 7, color: 'blue' },   
                    { col: 0, row: 8, color: 'blue' },   
                    { col: 0, row: 9, color: 'red' }     
                ],
                nextColors: ['purple'],
                description: '消除第四個紅色方塊體驗三消'
            },
            
            // 其他場景保持不變...
            basicMove: {
                blocks: [
                    { col: 0, row: 9, color: 'blue' }
                ],
                nextColors: ['green'],
                description: '基本移動練習 - 上移方塊'
            },
            
            // 基本下移練習場景
            basicMove2: {
                blocks: [
                    { col: 0, row: 9, color: 'red' } // 在底部放置一個紅色方塊
                ],
                nextColors: ['yellow'],
                description: '基本移動練習 - 下移方塊'
            },
            
            // 基本消除練習場景
            basicMove3: {
                blocks: [
                    { col: 0, row: 9, color: 'green' } // 在底部放置一個綠色方塊
                ],
                nextColors: ['purple'],
                description: '基本消除練習'
            },
            
            // 三消練習場景
            matchThree: {
                blocks: [
                    { col: 0, row: 7, color: 'red' },   // 底部紅色
                    { col: 0, row: 8, color: 'red' },   // 中間紅色
                    { col: 0, row: 9, color: 'blue' }   // 頂部藍色
                ],
                nextColors: ['red'],
                description: '三消練習 - 創造垂直三消'
            },
            
            // 連鎖反應場景
            chainReaction: {
                blocks: [
                    { col: 0, row: 5, color: 'green' },
                    { col: 0, row: 6, color: 'green' },
                    { col: 0, row: 7, color: 'red' },
                    { col: 0, row: 8, color: 'red' },
                    { col: 0, row: 9, color: 'yellow' }
                ],
                nextColors: ['green'],
                description: '連鎖反應示範'
            },
            
            // 技能示範場景 - 移除技能
            skillRemove: {
                blocks: [
                    { col: 0, row: 6, color: 'green' },
                    { col: 0, row: 7, color: 'green' },
                    { col: 0, row: 8, color: 'purple' }, // 阻擋的紫色方塊
                    { col: 0, row: 9, color: 'green' }
                ],
                nextColors: ['red'],
                description: '移除技能示範'
            },
            
            // 技能示範場景 - 變色技能  
            skillRecolor: {
                blocks: [
                    { col: 0, row: 5, color: 'blue' },
                    { col: 0, row: 6, color: 'yellow' },
                    { col: 0, row: 7, color: 'blue' },
                    { col: 0, row: 8, color: 'red' },
                    { col: 0, row: 9, color: 'blue' }
                ],
                nextColors: ['green'],
                description: '變色技能示範'
            }
        };
    }

    // 設置特定的遊戲場景
    setGameScenario(scenarioName) {
        const scenario = this.tutorialScenarios[scenarioName];
        if (!scenario || !this.gameEngine) {
            console.error('無法設置場景:', scenarioName);
            return;
        }

        console.log('設置教學場景:', scenarioName, scenario);
        
        // 清空現有遊戲狀態
        this.gameEngine.grid = [];
        this.gameEngine.particles = [];
        
        // 初始化空的網格
        for (let col = 0; col < this.gameEngine.config.numCols; col++) {
            this.gameEngine.grid[col] = [];
            for (let row = 0; row < this.gameEngine.config.numRows; row++) {
                this.gameEngine.grid[col][row] = null;
            }
        }
        
        // 根據場景設置方塊
        if (scenario.blocks) {
            scenario.blocks.forEach(blockData => {
                const { col, row, color } = blockData;
                
                if (col < this.gameEngine.config.numCols && row < this.gameEngine.config.numRows && row >= 0) {
                    // 獲取顏色的十六進制值
                    const colorHex = this.gameEngine.getColorHexFromName(color);
                    
                    this.gameEngine.grid[col][row] = {
                        color: color,
                        colorHex: colorHex, // 添加colorHex屬性
                        height: this.gameEngine.config.blockHeight,
                        width: this.gameEngine.blockWidth,
                        x: 0,
                        y: 0,
                        drawY: 0,
                        targetY: 0,
                        isAnimating: false,
                        isAnimatingSwap: false,
                        isExploding: false,
                        isEliminating: false
                    };
                    console.log(`在位置 [${col}][${row}] 放置 ${color} 方塊，顏色值: ${colorHex}`);
                } else {
                    console.warn(`位置 [${col}][${row}] 超出範圍`);
                }
            });
        }
        
        // 設置下個方塊顏色
        if (scenario.nextColors && scenario.nextColors.length > 0) {
            this.gameEngine.nextBlockColors = [...scenario.nextColors];
            if (this.gameEngine.updateNextBlockPreviewUI) {
                this.gameEngine.updateNextBlockPreviewUI();
            }
        }
        
        // 重置分數和狀態
        this.gameEngine.score = 0;
        this.gameEngine.consecutiveSuccessfulActions = 0;
        this.gameEngine.actionPoints = this.gameEngine.config.actionPointsStart;
        
        // 更新方塊位置和UI
        this.gameEngine.updateBlockPositions();
        this.gameEngine.updateUI();
        
        // 強制重繪畫面並等待完成
        return new Promise((resolve) => {
            setTimeout(() => {
                this.gameEngine.drawCanvasContent();
                console.log('場景設置完成，當前網格狀態:', this.gameEngine.grid);
                
                // 驗證方塊位置是否正確設置
                if (scenario.blocks) {
                    scenario.blocks.forEach(blockData => {
                        const { col, row, color } = blockData;
                        const block = this.gameEngine.grid[col] && this.gameEngine.grid[col][row];
                        if (block) {
                            console.log(`方塊 [${col}][${row}] ${color} 位置: x=${block.x}, y=${block.y}`);
                        }
                    });
                }
                
                resolve();
            }, 200); // 增加等待時間確保渲染完成
        });
    }

    // 添加直接跳到特定步驟的方法
    jumpToStep(stepIndex) {
        if (stepIndex >= 0 && stepIndex < this.tutorialSteps.length) {
            console.log(`跳轉到步驟 ${stepIndex}`);
            this.showStep(stepIndex);
        }
    }

    // 添加直接開始連續教學的方法（從第四步驟開始）
    startContinuousTutorial() {
        this.isActive = true;
        
        // 設置UI元素和事件監聽器
        this.setupUIElements();
        this.setupEventListeners();
        
        // 暫停遊戲引擎的自動更新
        if (this.gameEngine) {
            this.originalGameOverHandler = this.gameEngine.triggerGameOver;
            this.originalPerformPlayerAction = this.gameEngine.performPlayerAction;
            this.gameEngine.triggerGameOver = () => {};
        }
        
        this.showUI();
        // 直接跳到步驟1：上移練習（索引3，因為從0開始）
        this.jumpToStep(3);
    }

    // 高亮特定位置的方塊
    highlightBlock(col, row, message = '') {
        const canvas = this.gameEngine.canvas;
        const block = this.gameEngine.grid[col] && this.gameEngine.grid[col][row];
        
        if (!block || !canvas) {
            console.error(`無法高亮方塊 [${col}][${row}]，方塊:`, block, 'canvas:', canvas);
            return;
        }
        
        console.log(`高亮方塊 [${col}][${row}]，位置: x=${block.x}, y=${block.y}`);
        
        // 獲取canvas的相對位置
        const canvasRect = canvas.getBoundingClientRect();
        
        // 創建高亮效果
        const highlightDiv = document.createElement('div');
        highlightDiv.className = 'tutorial-block-highlight';
        highlightDiv.style.cssText = `
            position: absolute;
            width: ${this.gameEngine.blockWidth}px;
            height: ${this.gameEngine.config.blockHeight}px;
            left: ${canvasRect.left + block.x}px;
            top: ${canvasRect.top + block.y}px;
            border: 3px solid #3b82f6;
            border-radius: 6px;
            background: rgba(59, 130, 246, 0.2);
            pointer-events: none;
            z-index: 1001;
            animation: tutorialBlockPulse 1.5s infinite;
        `;
        
        // 添加CSS動畫
        if (!document.querySelector('#tutorialBlockCSS')) {
            const style = document.createElement('style');
            style.id = 'tutorialBlockCSS';
            style.textContent = `
                @keyframes tutorialBlockPulse {
                    0%, 100% { 
                        transform: scale(1);
                        opacity: 0.8;
                    }
                    50% { 
                        transform: scale(1.05);
                        opacity: 1;
                    }
                }
                .tutorial-block-highlight,
                .tutorial-block-message {
                    pointer-events: none !important;
                }
            `;
            document.head.appendChild(style);
        }
        
        document.body.appendChild(highlightDiv);
        
        // 添加文字提示
        if (message) {
            const messageDiv = document.createElement('div');
            messageDiv.className = 'tutorial-block-message';
            messageDiv.style.cssText = `
                position: absolute;
                left: ${canvasRect.left + block.x + this.gameEngine.blockWidth / 2}px;
                top: ${canvasRect.top + block.y - 30}px;
                transform: translateX(-50%);
                background: rgba(0, 0, 0, 0.8);
                color: white;
                padding: 4px 8px;
                border-radius: 4px;
                font-size: 12px;
                white-space: nowrap;
                pointer-events: none;
                z-index: 1002;
            `;
            messageDiv.textContent = message;
            document.body.appendChild(messageDiv);
        }
        
        return highlightDiv;
    }

    // 高亮方塊的特定動作區域
    highlightBlockAction(col, row, actionType) {
        const canvas = this.gameEngine.canvas;
        const block = this.gameEngine.grid[col] && this.gameEngine.grid[col][row];
        
        if (!block || !canvas) {
            console.error(`方塊不存在於位置 [${col}][${row}]，方塊:`, block, 'canvas:', canvas);
            
            // 嘗試尋找實際的方塊位置
            console.log('嘗試尋找實際方塊位置...');
            for (let r = 0; r < this.gameEngine.config.numRows; r++) {
                const testBlock = this.gameEngine.grid[col] && this.gameEngine.grid[col][r];
                if (testBlock) {
                    const testBlockColor = testBlock.colorName || testBlock.color;
                    console.log(`找到方塊在 [${col}][${r}]:`, testBlockColor, `位置: x=${testBlock.x}, y=${testBlock.y}`);
                }
            }
            return;
        }
        
        console.log(`高亮動作區域 [${col}][${row}] ${actionType}，方塊位置: x=${block.x}, y=${block.y}`);
        
        // 獲取canvas的相對位置
        const canvasRect = canvas.getBoundingClientRect();
        
        // 計算動作區域的位置和寬度
        const actionAreaWidth = this.gameEngine.blockWidth / 3;
        let areaLeft = block.x;
        let areaColor = '#3b82f6';
        let actionText = '';
        
        switch(actionType) {
            case 'move_to_top':
                areaLeft = block.x; // 左1/3
                areaColor = '#10b981'; // 綠色
                actionText = '⬆️ 上移';
                break;
            case 'remove_directly':
                areaLeft = block.x + actionAreaWidth; // 中間1/3
                areaColor = '#ef4444'; // 紅色
                actionText = '❌ 消除';
                break;
            case 'insert_at_bottom':
                areaLeft = block.x + (actionAreaWidth * 2); // 右1/3
                areaColor = '#f59e0b'; // 橙色
                actionText = '⬇️ 下移';
                break;
        }
        
        // 特殊處理：如果是主要教學場景的第四個紅色方塊
        const blockColor = block.colorName || block.color;
        if (col === 0 && row === 3 && blockColor === 'red') {
            // 添加特殊的方塊標識
            const labelDiv = document.createElement('div');
            labelDiv.className = 'tutorial-block-message';
            labelDiv.style.cssText = `
                position: absolute;
                left: ${canvasRect.left + block.x + this.gameEngine.blockWidth / 2}px;
                top: ${canvasRect.top + block.y + this.gameEngine.config.blockHeight + 10}px;
                transform: translateX(-50%);
                background: #ef4444;
                color: white;
                padding: 4px 8px;
                border-radius: 4px;
                font-size: 11px;
                font-weight: bold;
                white-space: nowrap;
                pointer-events: none;
                z-index: 1003;
                animation: tutorialBlockPulse 1.5s infinite;
            `;
            labelDiv.textContent = '第4個紅色方塊';
            document.body.appendChild(labelDiv);
        }
        
        // 創建高亮效果
        const highlightDiv = document.createElement('div');
        highlightDiv.className = 'tutorial-block-highlight';
        highlightDiv.style.cssText = `
            position: absolute;
            width: ${actionAreaWidth}px;
            height: ${this.gameEngine.config.blockHeight}px;
            left: ${canvasRect.left + areaLeft}px;
            top: ${canvasRect.top + block.y}px;
            border: 4px solid ${areaColor};
            border-radius: 8px;
            background: ${areaColor}22;
            pointer-events: none !important;
            z-index: 999;
            animation: tutorialBlockPulse 1.5s infinite;
            box-shadow: 0 0 0 2px ${areaColor}44;
        `;
        
        document.body.appendChild(highlightDiv);
        
        // 添加動作說明文字
        const messageDiv = document.createElement('div');
        messageDiv.className = 'tutorial-block-message';
        messageDiv.style.cssText = `
            position: absolute;
            left: ${canvasRect.left + areaLeft + actionAreaWidth / 2}px;
            top: ${canvasRect.top + block.y - 35}px;
            transform: translateX(-50%);
            background: ${areaColor};
            color: white;
            padding: 6px 10px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: bold;
            white-space: nowrap;
            pointer-events: none;
            z-index: 1002;
            box-shadow: 0 2px 8px rgba(0,0,0,0.3);
        `;
        messageDiv.textContent = actionText;
        document.body.appendChild(messageDiv);
        
        // 添加整個方塊的淡化邊框來顯示上下文
        const contextDiv = document.createElement('div');
        contextDiv.className = 'tutorial-block-highlight';
        contextDiv.style.cssText = `
            position: absolute;
            width: ${this.gameEngine.blockWidth}px;
            height: ${this.gameEngine.config.blockHeight}px;
            left: ${canvasRect.left + block.x}px;
            top: ${canvasRect.top + block.y}px;
            border: 2px dashed #94a3b8;
            border-radius: 6px;
            background: transparent;
            pointer-events: none !important;
            z-index: 998;
        `;
        document.body.appendChild(contextDiv);
        
        return highlightDiv;
    }

    // 清除方塊高亮
    clearBlockHighlights() {
        document.querySelectorAll('.tutorial-block-highlight, .tutorial-block-message').forEach(el => {
            el.remove();
        });
    }

    setupTutorialSteps() {
        this.tutorialSteps = [
            {
                title: "歡迎來到三消挑戰！",
                content: "這是一個充滿策略性的三消遊戲。我將帶您了解所有的遊戲機制和操作方式。",
                target: null,
                position: 'center',
                action: 'none',
                autoNext: false
            },
            {
                title: "遊戲畫面介紹",
                content: "這是遊戲的主要區域。方塊會從上方落下，您需要將三個或更多相同顏色的方塊排列在一起來消除它們。",
                target: '#gameCanvas',
                position: 'right',
                action: 'highlight',
                autoNext: false
            },
            {
                title: "基本操作：上移方塊",
                content: "現在我們來學習移動方塊！每個方塊分為三個區域：\n\n• 左1/3：上移到頂部 ⬆️\n• 中間1/3：直接消除 ❌\n• 右1/3：下移到底部 ⬇️\n\n現在我們設置了一個具體的場景來練習。",
                target: '#gameCanvas',
                position: 'right',
                action: 'none',
                autoNext: false,
                scenario: 'step1_initial'
            },
            {
                title: "步驟1：上移練習",
                content: "現在您看到遊戲板面有10個方塊：[藍,藍,紅,紅,藍,藍,紅,紅,藍,藍]\n\n下個方塊是黃色(Y)。\n\n請點擊「第四個紅色方塊」的左側區域，將它移動到最上面！",
                target: '#gameCanvas',
                position: 'right',
                action: 'waitForSpecificAction',
                autoNext: true,
                scenario: 'step1_initial',
                targetBlock: { col: 0, row: 3 }, // 第四個紅色方塊
                actionType: 'move_to_top',
                instruction: "點擊第四個紅色方塊的左側來上移",
                nextScenario: 'step2_after_move_up'
            },
            {
                title: "步驟2：下移練習",
                content: "很好！現在盤面變成：[紅,藍,藍,紅,藍,藍,紅,紅,藍,藍]\n\n接下來請將「最上面的紅色方塊」移動到最底層。\n\n點擊最上面紅色方塊的右側區域！",
                target: '#gameCanvas',
                position: 'right',
                action: 'waitForSpecificAction',
                autoNext: true,
                scenario: 'step2_after_move_up',
                targetBlock: { col: 0, row: 0 }, // 最上面的紅色方塊
                actionType: 'insert_at_bottom',
                instruction: "點擊最上面紅色方塊的右側來下移",
                nextScenario: 'step3_after_move_down'
            },
            {
                title: "步驟3：消除練習",
                content: "太棒了！現在盤面變成：[藍,藍,紅,藍,藍,紅,紅,藍,藍,紅]\n\n現在我們來體驗消除操作。請將「第四個藍色方塊」直接消除。\n\n點擊第四個方塊（藍色）的中間區域！",
                target: '#gameCanvas',
                position: 'right',
                action: 'waitForSpecificAction',
                autoNext: true,
                scenario: 'step3_after_move_down',
                targetBlock: { col: 0, row: 3 }, // 第四個藍色方塊
                actionType: 'remove_directly',
                instruction: "點擊第四個藍色方塊的中間來消除",
                nextScenario: 'step4_after_remove_blue'
            },
            {
                title: "步驟4：三消體驗",
                content: "完美！黃色方塊落下，現在盤面有三個連續的紅色方塊。\n\n最後體驗三消的感覺！請將「第四個紅色方塊」直接消除。\n\n這會觸發三個連續紅色方塊的消除！",
                target: '#gameCanvas',
                position: 'right',
                action: 'waitForSpecificAction',
                autoNext: true,
                scenario: 'step4_after_remove_blue',
                targetBlock: { col: 0, row: 3 }, // 第四個紅色方塊
                actionType: 'remove_directly',
                instruction: "點擊第四個紅色方塊的中間來體驗三消"
            },
            {
                title: "太棒了！",
                content: "您已經完成了所有基本操作的學習！\n\n• 上移方塊到頂部\n• 下移方塊到底部\n• 直接消除單個方塊\n• 體驗三消的快感\n\n現在您已經掌握了遊戲的核心機制！",
                target: null,
                position: 'center',
                action: 'none',
                autoNext: false
            },
            {
                title: "分數顯示",
                content: "這裡顯示您目前的分數。消除方塊和達成連擊都會增加分數。",
                target: '#score',
                position: 'bottom',
                action: 'highlight',
                autoNext: false
            },
            {
                title: "連擊系統",
                content: "連擊顯示您連續成功操作的次數。連擊越高，獲得的分數加成越多！",
                target: '#combo',
                position: 'bottom',
                action: 'highlight',
                autoNext: false
            },
            {
                title: "行動點數",
                content: "每次操作會消耗行動點數。當行動點數歸零時遊戲結束，所以要謹慎使用！",
                target: '#action-points',
                position: 'bottom',
                action: 'highlight',
                autoNext: false
            },
            {
                title: "技能系統介紹",
                content: "遊戲提供三種強大的技能來幫助您。每種技能都有使用次數限制，要明智地使用！",
                target: '.flex.gap-1',
                position: 'bottom',
                action: 'highlight',
                autoNext: false
            },
            {
                title: "教學完成！",
                content: "恭喜您完成了教學！現在您已經掌握了所有基本操作和進階技巧。準備好挑戰真正的遊戲了嗎？",
                target: null,
                position: 'center',
                action: 'none',
                autoNext: false,
                finalStep: true
            }
        ];
    }

    start() {
        this.isActive = true;
        this.currentStep = 0;
        
        // 設置UI元素和事件監聽器
        this.setupUIElements();
        this.setupEventListeners();
        
        // 暫停遊戲引擎的自動更新
        if (this.gameEngine) {
            this.originalGameOverHandler = this.gameEngine.triggerGameOver;
            this.originalPerformPlayerAction = this.gameEngine.performPlayerAction; // 保存原始處理器
            this.gameEngine.triggerGameOver = () => {}; // 防止教學期間遊戲結束
        }
        
        this.showUI();
        this.showStep(0);
    }

    stop() {
        this.isActive = false;
        this.hideUI();
        this.clearHighlights();
        
        // 恢復遊戲引擎
        if (this.gameEngine && this.originalGameOverHandler) {
            this.gameEngine.triggerGameOver = this.originalGameOverHandler;
        }
    }

    skip() {
        this.stop();
        // 跳轉到主選單或開始正常遊戲
        if (confirm('確定要跳過教學嗎？您可以直接開始遊戲。')) {
            window.location.href = 'main-menu.html';
        }
    }

    showUI() {
        this.skipBtn?.classList.remove('hidden');
        this.progress?.classList.remove('hidden');
    }

    hideUI() {
        this.overlay?.classList.add('hidden');
        this.skipBtn?.classList.add('hidden');
        this.progress?.classList.add('hidden');
        this.hand?.classList.add('hidden');
    }

    async showStep(stepIndex) {
        if (stepIndex < 0 || stepIndex >= this.tutorialSteps.length) return;
        
        this.currentStep = stepIndex;
        const step = this.tutorialSteps[stepIndex];
        
        console.log(`顯示步驟 ${stepIndex}:`, step.title);
        
        // 清理之前的狀態
        this.clearHighlights();
        this.clearBlockHighlights();
        
        // 重置遊戲引擎的事件處理器
        if (this.gameEngine && this.gameEngine.performPlayerAction !== this.originalPerformPlayerAction) {
            this.gameEngine.performPlayerAction = this.originalPerformPlayerAction || this.gameEngine.performPlayerAction;
        }
        
        // 重新啟用自動消除（如果之前被禁用）
        if (this.gameEngine) {
            // 對於最後一步（三消體驗），保持自動消除開啟
            const isLastStep = stepIndex === 6; // 步驟4：三消體驗
            this.gameEngine.autoProcessMatches = true;
            console.log(`步驟 ${stepIndex} 自動消除狀態:`, this.gameEngine.autoProcessMatches);
        }
        
        this.updateStepContent(step);
        this.updateProgress();
        this.positionDialog(step);
        
        // 顯示覆蓋層
        if (this.overlay) {
            this.overlay.classList.remove('hidden');
        }
        
        await this.handleStepAction(step);
        
        // 更新按鈕狀態
        if (this.prevBtn) {
            this.prevBtn.disabled = stepIndex === 0;
        }
        
        if (this.nextBtn) {
            const isInteractive = this.isInteractiveStep(step);
            this.nextBtn.style.display = isInteractive ? 'none' : 'inline-block';
        }
    }

    updateStepContent(step) {
        if (this.title) this.title.textContent = step.title;
        if (this.content) this.content.textContent = step.content;
        if (this.stepCounter) {
            this.stepCounter.textContent = `${this.currentStep + 1} / ${this.tutorialSteps.length}`;
        }
        
        // 更新按鈕狀態
        if (this.prevBtn) {
            this.prevBtn.disabled = this.currentStep === 0;
        }
        
        if (this.nextBtn) {
            if (step.finalStep) {
                this.nextBtn.textContent = '完成教學';
            } else {
                this.nextBtn.textContent = step.autoNext ? '我知道了' : '下一步';
            }
        }
    }

    updateProgress() {
        const progress = ((this.currentStep + 1) / this.tutorialSteps.length) * 100;
        if (this.progressFill) {
            this.progressFill.style.width = `${progress}%`;
        }
    }

    positionDialog(step) {
        if (!step.target || step.position === 'center') {
            this.centerDialog();
            return;
        }

        const target = document.querySelector(step.target);
        if (!target) {
            this.centerDialog();
            return;
        }

        const targetRect = target.getBoundingClientRect();
        const dialogRect = this.dialog?.getBoundingClientRect();
        
        if (!dialogRect) return;

        let x, y;
        let arrowClass = '';

        switch (step.position) {
            case 'top':
                x = targetRect.left + (targetRect.width - dialogRect.width) / 2;
                y = targetRect.top - dialogRect.height - 20;
                arrowClass = 'bottom';
                break;
            case 'bottom':
                x = targetRect.left + (targetRect.width - dialogRect.width) / 2;
                y = targetRect.bottom + 20;
                arrowClass = 'top';
                break;
            case 'left':
                x = targetRect.left - dialogRect.width - 20;
                y = targetRect.top + (targetRect.height - dialogRect.height) / 2;
                arrowClass = 'right';
                break;
            case 'right':
                x = targetRect.right + 20;
                y = targetRect.top + (targetRect.height - dialogRect.height) / 2;
                arrowClass = 'left';
                break;
        }

        // 確保對話框在視窗內
        x = Math.max(20, Math.min(x, window.innerWidth - dialogRect.width - 20));
        y = Math.max(20, Math.min(y, window.innerHeight - dialogRect.height - 20));

        if (this.dialog) {
            this.dialog.style.position = 'fixed';
            this.dialog.style.left = `${x}px`;
            this.dialog.style.top = `${y}px`;
            this.dialog.style.transform = 'none';
        }

        // 更新箭頭
        if (this.arrow) {
            this.arrow.className = `tutorial-arrow ${arrowClass}`;
        }
    }

    centerDialog() {
        if (this.dialog) {
            this.dialog.style.position = 'relative';
            this.dialog.style.left = 'auto';
            this.dialog.style.top = 'auto';
            this.dialog.style.transform = 'none';
        }
        
        if (this.arrow) {
            this.arrow.className = 'tutorial-arrow hidden';
        }
    }

    async handleStepAction(step) {
        this.clearHighlights();
        this.clearBlockHighlights();
        
        // 設置場景（如果指定）
        if (step.scenario) {
            console.log('設置場景:', step.scenario);
            await this.setGameScenario(step.scenario);
            console.log('場景設置完成，開始處理動作:', step.action);
        }
        
        // 等待一小段時間確保場景完全設置
        await new Promise(resolve => setTimeout(resolve, 100));
        
        switch (step.action) {
            case 'highlight':
                this.highlightElement(step.target);
                break;
            case 'waitForMove':
                this.waitForPlayerMove();
                break;
            case 'waitForSpecificMove':
                this.waitForSpecificMove(step.targetBlock, step.targetPosition);
                break;
            case 'waitForSpecificAction':
                console.log('開始等待特定動作:', step.targetBlock, step.actionType);
                this.waitForSpecificAction(step.targetBlock, step.actionType);
                break;
            case 'waitForMatch':
                this.waitForMatch();
                break;
            case 'waitForSpecificMatch':
                this.waitForSpecificMove(step.targetBlock, step.targetPosition, true);
                break;
            case 'waitForSkillUse':
                this.waitForSkillUse(step.skillType);
                break;
            case 'waitForSpecificSkillUse':
                this.waitForSpecificSkillUse(step.skillType, step.targetBlock);
                break;
            case 'waitForReroll':
                this.waitForReroll();
                break;
        }
    }

    highlightElement(selector) {
        if (!selector) return;
        
        const element = document.querySelector(selector);
        if (element) {
            element.classList.add('highlight-element');
        }
    }

    clearHighlights() {
        document.querySelectorAll('.highlight-element').forEach(el => {
            el.classList.remove('highlight-element');
        });
        this.hand?.classList.add('hidden');
    }

    showHand(x, y) {
        if (this.hand) {
            this.hand.style.left = `${x}px`;
            this.hand.style.top = `${y}px`;
            this.hand.classList.remove('hidden');
        }
    }

    waitForPlayerMove() {
        const originalHandler = this.gameEngine.performPlayerAction;
        
        this.gameEngine.performPlayerAction = async (location, actionType) => {
            const result = await originalHandler.call(this.gameEngine, location, actionType);
            
            if (actionType === 'move') {
                // 恢復原始處理器
                this.gameEngine.performPlayerAction = originalHandler;
                // 自動進入下一步
                setTimeout(() => this.nextStep(), 1000);
            }
            
            return result;
        };
    }

    waitForMatch() {
        const originalProcessMatches = this.gameEngine.processSingleWaveOfMatchesAndCascades;
        
        this.gameEngine.processSingleWaveOfMatchesAndCascades = async () => {
            const result = await originalProcessMatches.call(this.gameEngine);
            
            if (result.matchesFound && result.matchesFound.length > 0) {
                // 恢復原始處理器
                this.gameEngine.processSingleWaveOfMatchesAndCascades = originalProcessMatches;
                // 自動進入下一步
                setTimeout(() => this.nextStep(), 2000);
            }
            
            return result;
        };
    }

    waitForSkillUse(skillType) {
        // 監聽技能按鈕點擊  
        const skillIdMap = {
            'removeSingle': 'skillRemoveSingle',
            'rerollNext': 'skillRerollNext', 
            'rerollBoard': 'skillRerollBoard'
        };
        
        const skillButton = document.getElementById(skillIdMap[skillType]);
        if (!skillButton) return;

        const originalClickHandler = skillButton.onclick;
        
        skillButton.onclick = () => {
            // 執行原始點擊處理
            if (originalClickHandler) {
                originalClickHandler.call(skillButton);
            }
            
            // 如果技能被啟動，等待技能使用
            if (this.gameEngine.activeSkill === skillType) {
                const originalProcessSkill = this.gameEngine.processActiveSkillOnBlock;
                
                this.gameEngine.processActiveSkillOnBlock = async (location) => {
                    const result = await originalProcessSkill.call(this.gameEngine, location);
                    
                    // 恢復原始處理器
                    this.gameEngine.processActiveSkillOnBlock = originalProcessSkill;
                    skillButton.onclick = originalClickHandler;
                    
                    // 自動進入下一步
                    setTimeout(() => this.nextStep(), 1000);
                    
                    return result;
                };
            }
        };
    }

    waitForReroll() {
        console.log('等待重骰操作');
        
        const skillButton = document.getElementById('skillRerollNext');
        if (!skillButton) {
            console.error('找不到skillRerollNext按鈕');
            return;
        }
        
        const originalHandler = skillButton.onclick;
        
        skillButton.onclick = () => {
            console.log('重骰按鈕被點擊');
            
            // 執行原始點擊處理
            if (originalHandler) {
                originalHandler.call(skillButton);
            } else {
                // 如果沒有原始處理器，直接調用useSkillRerollNext
                this.gameEngine.useSkillRerollNext();
            }
            
            // 恢復原始處理器
            skillButton.onclick = originalHandler;
            
            // 自動進入下一步
            setTimeout(() => this.nextStep(), 1000);
        };
    }

    nextStep() {
        console.log('nextStep 被調用，當前步驟:', this.currentStep);
        const currentStepData = this.tutorialSteps[this.currentStep];
        
        if (currentStepData?.finalStep) {
            console.log('到達最後一步，完成教學');
            this.completeTutorial();
            return;
        }
        
        if (this.currentStep < this.tutorialSteps.length - 1) {
            console.log('前進到步驟:', this.currentStep + 1);
            this.showStep(this.currentStep + 1);
        } else {
            console.log('已經是最後一步');
        }
    }

    previousStep() {
        console.log('previousStep 被調用，當前步驟:', this.currentStep);
        if (this.currentStep > 0) {
            console.log('返回到步驟:', this.currentStep - 1);
            this.showStep(this.currentStep - 1);
        } else {
            console.log('已經是第一步');
        }
    }

    // 等待特定的移動操作
    waitForSpecificMove(targetBlock, targetPosition, expectMatch = false) {
        console.log('等待特定移動:', targetBlock, 'to', targetPosition);
        console.log('當前網格狀態:', this.gameEngine.grid);
        
        // 檢查目標方塊是否存在
        const block = this.gameEngine.grid[targetBlock.col] && this.gameEngine.grid[targetBlock.col][targetBlock.row];
        console.log(`目標方塊 [${targetBlock.col}][${targetBlock.row}]:`, block);
        
        if (!block) {
            console.error('目標方塊不存在，嘗試尋找實際方塊位置');
            // 尋找實際的方塊位置
            for (let row = 0; row < this.gameEngine.config.numRows; row++) {
                const gridBlock = this.gameEngine.grid[targetBlock.col] && this.gameEngine.grid[targetBlock.col][row];
                if (gridBlock) {
                    console.log(`找到方塊在 [${targetBlock.col}][${row}]:`, gridBlock);
                }
            }
        }
        
        // 高亮目標方塊
        this.highlightBlock(targetBlock.col, targetBlock.row, '點擊這個方塊');
        
        const originalHandler = this.gameEngine.performPlayerAction;
        let selectedBlock = null;
        
        this.gameEngine.performPlayerAction = async (location, actionType) => {
            console.log('玩家操作:', location, actionType);
            
            if (actionType === 'select') {
                selectedBlock = location;
                // 檢查是否選擇了正確的方塊
                if (location.col === targetBlock.col && location.row === targetBlock.row) {
                    // 清除舊高亮，高亮目標位置
                    this.clearBlockHighlights();
                    this.highlightEmptyPosition(targetPosition.col, targetPosition.row, '移動到這裡');
                }
                return;
            }
            
            if (actionType === 'move' && selectedBlock) {
                const isCorrectMove = 
                    selectedBlock.col === targetBlock.col && 
                    selectedBlock.row === targetBlock.row &&
                    location.col === targetPosition.col &&
                    location.row === targetPosition.row;
                
                if (isCorrectMove) {
                    // 執行正確的移動
                    const result = await originalHandler.call(this.gameEngine, location, actionType);
                    
                    // 恢復原始處理器
                    this.gameEngine.performPlayerAction = originalHandler;
                    this.clearBlockHighlights();
                    
                    // 如果期待消除，等待一下讓動畫完成
                    if (expectMatch) {
                        setTimeout(() => this.nextStep(), 2000);
                    } else {
                        setTimeout(() => this.nextStep(), 1000);
                    }
                    
                    return result;
                } else {
                    // 錯誤的移動，給予提示
                    this.showTemporaryMessage('請按照指示進行正確的移動操作！');
                }
            }
            
            // 對於其他操作，不處理
        };
    }

    // 等待特定的動作（上移、下移、消除）
    waitForSpecificAction(targetBlock, actionType) {
        console.log('等待特定動作:', targetBlock, actionType);
        console.log('當前網格狀態:', this.gameEngine.grid);
        
        // 對於最後一步（三消體驗），保持自動消除開啟
        const isLastStep = this.currentStep === 6; // 步驟4：三消體驗
        console.log(`步驟 ${this.currentStep}，是否為最後一步: ${isLastStep}`);
        
        // 在這裡不修改 autoProcessMatches，讓 performTutorialAction 來處理
        
        // 直接檢查指定位置是否有方塊
        const block = this.gameEngine.grid[targetBlock.col] && this.gameEngine.grid[targetBlock.col][targetBlock.row];
        if (!block) {
            console.error(`指定位置 [${targetBlock.col}][${targetBlock.row}] 沒有方塊`);
            // 如果指定位置沒有方塊，嘗試尋找實際位置
            const actualTargetBlock = this.findActualBlockPosition(targetBlock.col, actionType);
            if (!actualTargetBlock) {
                console.error('無法找到可用的方塊');
                return;
            }
            // 使用找到的實際位置
            this.highlightBlockAction(actualTargetBlock.col, actualTargetBlock.row, actionType);
            targetBlock = actualTargetBlock;
        } else {
            // 使用指定位置
            console.log(`在指定位置 [${targetBlock.col}][${targetBlock.row}] 找到方塊:`, block.color);
            this.highlightBlockAction(targetBlock.col, targetBlock.row, actionType);
        }
        
        const originalHandler = this.gameEngine.performPlayerAction;
        
        this.gameEngine.performPlayerAction = async (location, performedActionType) => {
            console.log('玩家執行動作:', location, performedActionType);
            console.log('期待的動作:', actionType, '目標方塊:', targetBlock);
            
            // 檢查是否是正確的方塊和動作
            const isCorrectBlock = location.colIndex === targetBlock.col && location.rowIndex === targetBlock.row;
            const isCorrectAction = performedActionType === actionType;
            
            if (isCorrectBlock && isCorrectAction) {
                console.log('✅ 正確的操作！');
                
                // 恢復原始處理器
                this.gameEngine.performPlayerAction = originalHandler;
                this.clearBlockHighlights();
                
                // 執行真正的遊戲操作（包含動畫和消除邏輯）
                await this.performTutorialAction(location, performedActionType);
                
                // 如果有下一個場景，設置它
                const currentStep = this.tutorialSteps[this.currentStep];
                if (currentStep && currentStep.nextScenario) {
                    setTimeout(() => {
                        this.setGameScenario(currentStep.nextScenario);
                        this.nextStep();
                    }, isLastStep ? 3000 : 1000); // 最後一步等待更久讓三消完成
                } else {
                    // 自動進入下一步
                    setTimeout(() => this.nextStep(), isLastStep ? 3000 : 1500);
                }
                
                return;
            } else if (isCorrectBlock && !isCorrectAction) {
                // 正確的方塊，錯誤的動作
                console.log('❌ 正確方塊，錯誤動作');
                let expectedActionText = '';
                switch(actionType) {
                    case 'move_to_top': expectedActionText = '左側（上移）'; break;
                    case 'remove_directly': expectedActionText = '中間（消除）'; break;
                    case 'insert_at_bottom': expectedActionText = '右側（下移）'; break;
                }
                this.showTemporaryMessage(`請點擊方塊的${expectedActionText}區域！`);
            } else {
                // 錯誤的方塊
                console.log('❌ 錯誤的方塊');
                this.showTemporaryMessage('請點擊指定的高亮方塊！');
            }
            
            // 對於錯誤操作，不執行原始處理器
        };
    }

    // 執行教學專用的操作，保留動畫效果
    async performTutorialAction(location, actionType) {
        console.log('執行教學動作:', location, actionType);
        
        const isLastStep = this.currentStep === 6; // 步驟4：三消體驗
        
        if (isLastStep) {
            // 最後一步：使用完整的遊戲邏輯
            console.log('最後一步：使用完整遊戲邏輯');
            const result = await this.originalPerformPlayerAction.call(this.gameEngine, location, actionType);
            console.log('三消體驗完成');
            return result;
        } else {
            // 前三步：手動執行操作，不觸發連鎖消除
            console.log('教學模式：手動執行操作，無連鎖消除');
            
            const { colIndex, rowIndex } = location;
            const targetGrid = this.gameEngine.config.numCols === 1 ? this.gameEngine.grid[0] : this.gameEngine.grid[colIndex];
            
            if (!targetGrid || !targetGrid[rowIndex]) {
                console.error('無效的方塊位置');
                return;
            }
            
            // 設置動畫狀態
            this.gameEngine.isAnimating = true;
            
            try {
                if (actionType === "move_to_top") {
                    // 上移動畫
                    const direction = -1;
                    let currentRow = rowIndex;
                    while (true) {
                        const nextRow = currentRow + direction;
                        if (nextRow < 0 || nextRow >= targetGrid.length) break;
                        
                        // 執行交換動畫
                        if (this.gameEngine.animateBlockSwap) {
                            await this.gameEngine.animateBlockSwap(colIndex, currentRow, nextRow);
                        }
                        
                        // 交換方塊
                        [targetGrid[currentRow], targetGrid[nextRow]] = [targetGrid[nextRow], targetGrid[currentRow]];
                        this.gameEngine.updateBlockPositions();
                        currentRow = nextRow;
                        
                        if (currentRow === 0) break;
                    }
                } else if (actionType === "insert_at_bottom") {
                    // 下移動畫
                    const direction = 1;
                    let currentRow = rowIndex;
                    while (true) {
                        const nextRow = currentRow + direction;
                        if (nextRow < 0 || nextRow >= targetGrid.length) break;
                        
                        // 執行交換動畫
                        if (this.gameEngine.animateBlockSwap) {
                            await this.gameEngine.animateBlockSwap(colIndex, currentRow, nextRow);
                        }
                        
                        // 交換方塊
                        [targetGrid[currentRow], targetGrid[nextRow]] = [targetGrid[nextRow], targetGrid[currentRow]];
                        this.gameEngine.updateBlockPositions();
                        currentRow = nextRow;
                        
                        if (currentRow === targetGrid.length - 1) break;
                    }
                } else if (actionType === "remove_directly") {
                    // 消除動畫
                    const block = targetGrid[rowIndex];
                    this.gameEngine.createParticleExplosion(block.x, block.drawY, block.width, block.height, block.colorHex);
                    block.isExploding = true;
                    await new Promise(resolve => setTimeout(resolve, 50));
                    targetGrid.splice(rowIndex, 1);
                }
                
                // 更新位置
                this.gameEngine.updateBlockPositions();
                
                // 等待動畫完成
                await new Promise(resolve => setTimeout(resolve, 500));
                
                console.log('教學動作完成（無連鎖消除）');
                
            } finally {
                // 恢復動畫狀態
                this.gameEngine.isAnimating = false;
            }
        }
    }

    // 高亮空位置
    highlightEmptyPosition(col, row, message = '') {
        const canvas = this.gameEngine.canvas;
        if (!canvas) return;
        
        // 計算位置（使用與GameEngine相同的方法）
        let x, y;
        
        if (this.gameEngine.config.numCols === 1) {
            // 單列模式
            x = (canvas.width - this.gameEngine.blockWidth) / 2;
        } else {
            // 多列模式
            const totalGridWidth = this.gameEngine.columnWidth * this.gameEngine.config.numCols;
            const startX = (canvas.width - totalGridWidth) / 2;
            x = startX + col * this.gameEngine.columnWidth + (this.gameEngine.columnWidth - this.gameEngine.blockWidth) / 2;
        }
        
        y = row * this.gameEngine.config.blockHeight + this.gameEngine.config.gameAreaTopPadding;
        
        // 獲取canvas的相對位置
        const canvasRect = canvas.getBoundingClientRect();
        
        const highlightDiv = document.createElement('div');
        highlightDiv.className = 'tutorial-block-highlight';
        highlightDiv.style.cssText = `
            position: absolute;
            width: ${this.gameEngine.blockWidth}px;
            height: ${this.gameEngine.config.blockHeight}px;
            left: ${canvasRect.left + x}px;
            top: ${canvasRect.top + y}px;
            border: 3px dashed #10b981;
            border-radius: 6px;
            background: rgba(16, 185, 129, 0.1);
            pointer-events: none;
            z-index: 1001;
            animation: tutorialBlockPulse 1.5s infinite;
        `;
        
        document.body.appendChild(highlightDiv);
        
        if (message) {
            const messageDiv = document.createElement('div');
            messageDiv.className = 'tutorial-block-message';
            messageDiv.style.cssText = `
                position: absolute;
                left: ${canvasRect.left + x + this.gameEngine.blockWidth / 2}px;
                top: ${canvasRect.top + y - 30}px;
                transform: translateX(-50%);
                background: rgba(16, 185, 129, 0.9);
                color: white;
                padding: 4px 8px;
                border-radius: 4px;
                font-size: 12px;
                white-space: nowrap;
                pointer-events: none;
                z-index: 1002;
            `;
            messageDiv.textContent = message;
            document.body.appendChild(messageDiv);
        }
    }

    // 顯示臨時訊息
    showTemporaryMessage(message) {
        const messageDiv = document.createElement('div');
        messageDiv.style.cssText = `
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(239, 68, 68, 0.9);
            color: white;
            padding: 12px 20px;
            border-radius: 8px;
            font-size: 14px;
            z-index: 2000;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
        `;
        messageDiv.textContent = message;
        document.body.appendChild(messageDiv);
        
        setTimeout(() => {
            messageDiv.remove();
        }, 2000);
    }

    // 檢查是否為需要用戶互動的步驟
    isInteractiveStep(step) {
        const interactiveActions = [
            'waitForSpecificAction',
            'waitForSpecificMove', 
            'waitForSpecificMatch',
            'waitForSpecificSkillUse',
            'waitForMove',
            'waitForMatch',
            'waitForSkillUse',
            'waitForReroll'
        ];
        return interactiveActions.includes(step.action);
    }

    // 讓覆蓋層允許點擊穿透
    makeOverlayClickThrough() {
        if (this.overlay) {
            this.overlay.style.pointerEvents = 'none';
            this.overlay.style.background = 'rgba(0, 0, 0, 0.1)';
        }
        if (this.dialog) {
            this.dialog.style.pointerEvents = 'auto';
        }
    }

    // 尋找實際的方塊位置（當指定位置沒有方塊時）
    findActualBlockPosition(targetCol, actionType) {
        console.log('尋找實際方塊位置:', targetCol, actionType);
        console.log('當前網格狀態:', this.gameEngine.grid);
        
        // 首先檢查指定列是否存在
        if (!this.gameEngine.grid[targetCol]) {
            console.error(`列 ${targetCol} 不存在`);
            return null;
        }
        
        // 對於教學場景，我們需要找到所有存在的方塊
        const existingBlocks = [];
        for (let row = 0; row < this.gameEngine.config.numRows; row++) {
            const block = this.gameEngine.grid[targetCol][row];
            if (block && block.color) {
                existingBlocks.push({ row: row, block: block });
            }
        }
        
        console.log('找到的方塊:', existingBlocks);
        
        // 如果有方塊存在，返回第一個找到的方塊
        if (existingBlocks.length > 0) {
            const firstBlock = existingBlocks[0];
            console.log(`返回方塊在位置 [${targetCol}][${firstBlock.row}]:`, firstBlock.block.color);
            return { col: targetCol, row: firstBlock.row, block: firstBlock.block };
        }
        
        console.error(`在列 ${targetCol} 中找不到任何方塊`);
        return null;
    }

    // 讓覆蓋層變為正常狀態（可以接收點擊事件）
    makeOverlayNormal() {
        if (this.overlay) {
            this.overlay.style.pointerEvents = 'auto';
        }
    }

    // 完成教學
    completeTutorial() {
        this.stop();
        // 可以在這裡添加完成教學後的邏輯，例如跳轉到主遊戲
        alert('教學完成！準備開始正式遊戲了！');
        window.location.href = 'index.html';
    }
}

// 確保在全域範圍可用
window.TutorialSystem = TutorialSystem;

// 添加全域函數來快速開始連續教學
window.startContinuousTutorial = function() {
    if (window.gameEngine && window.gameEngine.tutorialSystem) {
        console.log('開始連續教學（從第四步驟開始）');
        window.gameEngine.tutorialSystem.startContinuousTutorial();
    } else {
        console.error('遊戲引擎或教學系統未初始化');
    }
};

// 添加全域函數來跳到特定步驟
window.jumpToTutorialStep = function(stepIndex) {
    if (window.gameEngine && window.gameEngine.tutorialSystem) {
        console.log(`跳轉到教學步驟 ${stepIndex}`);
        window.gameEngine.tutorialSystem.jumpToStep(stepIndex);
    } else {
        console.error('遊戲引擎或教學系統未初始化');
    }
}; 