class GameEngine {
    constructor(config) {
        this.config = {
            numCols: 1,
            numRows: 10,
            blockHeight: 34,
            actionPointsStart: 5,
            gameAreaTopPadding: 10,
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
        
        if (restartBtn) restartBtn.addEventListener('click', () => this.resetGame());
        if (modalRestartBtn) modalRestartBtn.addEventListener('click', () => this.resetGame());
        if (backToIntroBtn) backToIntroBtn.addEventListener('click', () => window.location.href = 'index.html');
        if (modalBackToIntroBtn) modalBackToIntroBtn.addEventListener('click', () => window.location.href = 'index.html');

        // 視窗大小調整
        window.addEventListener('resize', () => this.resizeCanvas());
    }

    setupUI() {
        this.scoreDisplay = document.getElementById('score');
        this.comboDisplay = document.getElementById('combo');
        this.actionPointsDisplay = document.getElementById('action-points');
        this.timeLeftDisplay = document.getElementById('time-left');
        this.gameOverModal = document.getElementById('gameOverModal');
        this.finalScoreDisplay = document.getElementById('finalScore');
        this.finalMaxComboDisplay = document.getElementById('finalMaxCombo');
        this.finalActionCountDisplay = document.getElementById('finalActionCount');
        this.nextBlockPreviewContainer = document.getElementById('nextBlockPreviewContainer');
        
        if (this.config.hasSkills) {
            this.skillRemoveSingleUsesEl = document.getElementById('skillRemoveSingleUses');
            this.skillRerollNextUsesEl = document.getElementById('skillRerollNextUses');
            this.skillRerollBoardUsesEl = document.getElementById('skillRerollBoardUses');
        }

        // 設置主題
        document.body.className = `theme-${this.config.theme} flex flex-col items-center justify-center min-h-screen p-2 sm:p-4`;
    }

    getRandomColorName() {
        return this.colorNames[Math.floor(Math.random() * this.colorNames.length)];
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
        this.gameStartTime = performance.now();

        if (this.config.hasSkills) {
            this.skillUses = { removeSingle: 3, rerollNext: 3, rerollBoard: 3 };
        }

        this.generateNextBlockColor();
        this.createInitialGrid();
        this.updateBlockPositions();
        this.updateUI();
        
        if (this.config.hasSkills) {
            this.updateSkillButtonsUI();
        }

        if (this.gameOverModal) {
            this.gameOverModal.classList.remove('active');
            const modalContent = this.gameOverModal.querySelector('.modal-content');
            if (modalContent) {
                modalContent.style.opacity = '0';
                modalContent.style.transform = 'scale(0.95)';
            }
        }

        this.canvas.classList.remove('canvas-skill-target-mode');
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
        const style = getComputedStyle(container);
        const containerClientWidth = container.clientWidth;
        const paddingLeft = parseFloat(style.paddingLeft);
        const paddingRight = parseFloat(style.paddingRight);
        const availableWidth = containerClientWidth - paddingLeft - paddingRight;
        
        this.canvas.width = availableWidth;
        
        if (this.config.numCols === 1) {
            this.blockWidth = this.canvas.width * this.config.blockWidthPercent;
        } else {
            this.columnWidth = this.canvas.width / this.config.numCols;
            this.blockWidth = this.columnWidth * 0.8;
        }
        
        this.canvas.height = (this.config.blockHeight * this.config.numRows) + 
                           (this.config.gameAreaTopPadding * 2) + 
                           (this.config.numRows * 1.5);

        if (!this.gameOver) {
            this.updateBlockPositions();
        }
    }

    updateUI() {
        if (this.scoreDisplay) this.scoreDisplay.textContent = this.score;
        if (this.comboDisplay) this.comboDisplay.textContent = this.consecutiveSuccessfulActions;
        if (this.actionPointsDisplay) this.actionPointsDisplay.textContent = this.actionPoints;
        
        // 更新最高連擊記錄
        if (this.consecutiveSuccessfulActions > this.maxCombo) {
            this.maxCombo = this.consecutiveSuccessfulActions;
        }

        // 時間相關UI（限時模式）
        if (this.config.hasTimer && this.timeLeftDisplay) {
            const secondsLeft = Math.ceil(Math.max(0, this.timeLeft / 1000));
            this.timeLeftDisplay.textContent = secondsLeft;
            
            if (secondsLeft <= 5) {
                this.timeLeftDisplay.classList.add('time-warning');
            } else {
                this.timeLeftDisplay.classList.remove('time-warning');
            }
        }
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
            
            btn.classList.remove('ring-4', 'ring-offset-2', 'ring-sky-300', 'opacity-80');
            if (this.activeSkill && btn.id.toLowerCase().includes(this.activeSkill.toLowerCase())) {
                btn.classList.add('ring-4', 'ring-offset-2', 'ring-sky-300', 'opacity-80');
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
        
        this.drawParticles();
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
        for (let i = 0; i < this.config.particleCount; i++) {
            this.particles.push({
                x: x + width / 2,
                y: y + height / 2,
                vx: (Math.random() - 0.5) * 8,
                vy: (Math.random() - 0.5) * 8 - 2,
                life: this.config.particleLifespan,
                maxLife: this.config.particleLifespan,
                color: colorHex,
                size: Math.random() * 4 + 2
            });
        }
    }

    updateParticles(deltaTime) {
        for (let i = this.particles.length - 1; i >= 0; i--) {
            const particle = this.particles[i];
            particle.x += particle.vx * deltaTime / 16.67;
            particle.y += particle.vy * deltaTime / 16.67;
            particle.vy += 0.15 * (deltaTime / 16.67); // 重力
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
            this.ctx.globalAlpha = alpha;
            this.ctx.fillStyle = particle.color;
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
        let lastTime = 0;
        const gameLoop = (timestamp) => {
            if (!lastTime) lastTime = timestamp;
            const deltaTime = timestamp - lastTime;
            lastTime = timestamp;

            if (!this.gameOver) {
                // 時間更新（限時模式）
                if (this.config.hasTimer) {
                    const elapsedTime = performance.now() - this.gameStartTime;
                    this.timeLeft = this.config.gameDuration - elapsedTime;
                    if (this.timeLeft <= 0) {
                        this.timeLeft = 0;
                        this.triggerGameOver();
                    }
                    this.updateUI();
                }
            }

            this.updateParticles(deltaTime);
            this.drawCanvasContent();
            requestAnimationFrame(gameLoop);
        };
        
        requestAnimationFrame(gameLoop);
    }

    triggerGameOver() {
        if (this.gameOver) return;
        this.gameOver = true;
        this.isAnimating = true;
        
        if (this.finalScoreDisplay) this.finalScoreDisplay.textContent = this.score;
        if (this.finalMaxComboDisplay) this.finalMaxComboDisplay.textContent = this.maxCombo;
        if (this.finalActionCountDisplay) this.finalActionCountDisplay.textContent = this.actionCount;
        
        if (this.gameOverModal) {
            this.gameOverModal.classList.add('active');
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
        const { colIndex, rowIndex } = location;
        if (this.isAnimating) return;
        
        // 驗證位置
        if (this.config.numCols === 1) {
            if (!this.grid[0] || !this.grid[0][rowIndex]) return;
        } else {
            if (!this.grid[colIndex] || !this.grid[colIndex][rowIndex]) return;
        }
        
        this.isAnimating = true;
        this.actionCount++;
        
        if (this.config.hasSkills) {
            this.updateSkillButtonsUI();
        }
        
        let overallTurnSuccess = false;

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
            if (passHadEliminations) overallTurnSuccess = true;
            
            this.updateBlockPositions();
            const refilled = this.refillGrid();
            this.updateBlockPositions();
            
            if (!passHadEliminations && !refilled) break;
        }

        if (overallTurnSuccess) {
            if (actionType !== "remove_directly") this.consecutiveSuccessfulActions++;
        } else {
            if (!this.config.hasTimer) {
                this.actionPoints--;
                this.consecutiveSuccessfulActions = 0;
            }
        }

        this.updateUI();
        this.isAnimating = false;
        
        if (this.config.hasSkills) {
            this.updateSkillButtonsUI();
        }
        
        if (!this.config.hasTimer && this.actionPoints <= 0 && !this.gameOver) {
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
                this.score += 10 * matches.size * internalCascadeCount;

                matches.forEach(matchInfo => {
                    const { colIndex, rowIndex } = JSON.parse(matchInfo);
                    const targetGrid = this.config.numCols === 1 ? this.grid[0] : this.grid[colIndex];
                    if (targetGrid && targetGrid[rowIndex]) {
                        targetGrid[rowIndex].isEliminating = true;
                        targetGrid[rowIndex].eliminationStartTime = Date.now();
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

        this.activeSkill = (this.activeSkill === skillName) ? null : skillName;
        this.canvas.classList.toggle('canvas-skill-target-mode', 
                                   this.activeSkill === 'removeSingle' || this.activeSkill === 'rerollBoard');
        this.updateSkillButtonsUI();
    }

    async useSkillRerollNext() {
        if (!this.config.hasSkills || this.isAnimating || this.skillUses.rerollNext <= 0) return;
        
        this.isAnimating = true;
        this.updateSkillButtonsUI();
        this.skillUses.rerollNext--;
        this.generateNextBlockColor();
        await new Promise(resolve => setTimeout(resolve, 50));
        this.isAnimating = false;
        this.updateUI();
        this.updateSkillButtonsUI();
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
        this.canvas.classList.remove('canvas-skill-target-mode');

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

        this.updateUI();
        this.isAnimating = false;
        this.updateSkillButtonsUI();
        
        if (!this.config.hasTimer && this.actionPoints <= 0 && !this.gameOver) {
            this.triggerGameOver();
        }
    }
}

// 導出類
if (typeof module !== 'undefined' && module.exports) {
    module.exports = GameEngine;
} 