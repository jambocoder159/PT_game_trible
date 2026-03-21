class UIManager {
    static createGameHTML(mode, config, gameState = null) {
        let headerHTML;
        if (mode === 'quest') {
            headerHTML = this.createQuestHeaderHTML(config);
        } else if (config.hasRPGSystem) {
            // RPG模式使用特殊的header，即使gameState為null也要創建框架
            const defaultGameState = gameState || {
                level: 1,
                exp: 0,
                expToNextLevel: 100,
                gold: 0,
                playerSkills: {},
                hasTimer: config.hasTimer || false,
                actionPoints: config.actionPointsStart || 5
            };
            headerHTML = this.createRPGHeaderHTML(mode, config, defaultGameState);
        } else {
            headerHTML = this.createStandardHeaderHTML(mode, config);
        }

        const skillsSection = config.hasSkills ? this.createSkillsSection() : '';
        const itemsSection = this.createItemsSection(); // 所有模式都顯示道具區域
        const modalStats = this.createModalStatsHTML(mode);
        const modalButtonLayout = this.createModalButtonsHTML(mode);
        const timerSection = this.createTimerHTML(config);

        return `
        <div class="game-container bg-white/80 backdrop-blur-md rounded-xl shadow-xl w-full max-w-lg">
            ${headerHTML}
            ${timerSection}

            <div class="flex-grow flex items-center justify-center game-canvas-area relative">
                <canvas id="gameCanvas" class="rounded-lg max-w-full max-h-full"></canvas>
                <div id="nextBlockPreviewContainer" class="hidden"></div>
            </div>

            <div class="flex-shrink-0 bg-slate-100/50 rounded-b-xl px-3 py-2">
                <div class="flex items-center justify-between">
                    <div class="flex items-center gap-2">
                        ${skillsSection}
                        ${itemsSection}
                    </div>
                    <button id="backToIntroButton" class="bg-gray-500 hover:bg-gray-600 text-white p-2 rounded-full action-button w-8 h-8 flex items-center justify-center" title="主選單">
                        <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path d="M10.707 2.293a1 1 0 00-1.414 0l-7 7a1 1 0 001.414 1.414L4 10.414V17a1 1 0 001 1h2a1 1 0 001-1v-2a1 1 0 011-1h2a1 1 0 011 1v2a1 1 0 001 1h2a1 1 0 001-1v-6.586l.293.293a1 1 0 001.414-1.414l-7-7z"/></svg>
                    </button>
                </div>
                <div id="itemStatus" class="text-center text-xs text-gray-600 mt-1"></div>
            </div>
        </div>

        <div id="gameOverModal" class="modal">
            <div class="modal-content">
                <h2 id="modal-title" class="text-2xl font-bold text-rose-500 mb-3">${config.hasTimer ? '時間到！' : '遊戲結束！'}</h2>
                ${modalStats}
                <p id="modal-message" class="text-slate-500 mb-4">再接再厲，挑戰更高分！</p>
                ${modalButtonLayout}
            </div>
        </div>`;
    }

    static createQuestHeaderHTML(config) {
        const enemy = config.levelData.enemy;
        
        // 從 URL 參數獲取關卡編號，預設為 1
        const urlParams = new URLSearchParams(window.location.search);
        const levelNumber = parseInt(urlParams.get('level')) || 1;
        
        // 構建對應的敵人圖片路徑
        const enemyImageSrc = `images/monster/ch1-${levelNumber}.png`;
        
        // 獲取關卡限制資訊
        const levelDetails = GameModes.quest.levelDetails[levelNumber];
        const restrictions = levelDetails?.restrictions || {};
        const restrictionsDisplay = this.createQuestRestrictionsDisplay(restrictions, 0);
        
        return `
        <div id="quest-header" class="relative flex-shrink-0 bg-slate-800/70 rounded-t-xl text-white">
            <!-- 上半部：關卡資訊和步數 -->
            <div class="flex justify-between items-start p-3 pb-2">
                <div id="quest-info-icon" class="cursor-pointer z-20 p-1">
                    <svg class="w-5 h-5 text-sky-300/80 hover:text-sky-200 transition-colors" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path>
                    </svg>
                </div>
                <div class="text-center">
                    <div class="text-xs text-slate-300">關卡 ${levelNumber}</div>
                    <div class="text-sm font-bold text-yellow-300">${enemy.name}</div>
                </div>
                <div class="text-center">
                    <div class="text-xs text-slate-300">步數</div>
                    <div id="moves-left" class="text-xl font-black text-amber-400">${config.levelData.moves}</div>
                </div>
            </div>
            
            <!-- 中間部：敵人圖片與血條/限制條件對齊 -->
            <div class="px-3 pb-3">
                <div class="flex items-start gap-3">
                    <!-- 左側：敵人圖片 -->
                    <div class="w-16 h-16 flex-shrink-0">
                        <img id="enemy-image" src="${enemyImageSrc}" alt="${enemy.name}" class="w-full h-full object-contain transition-transform duration-100">
                    </div>
                    
                    <!-- 右側：血條和限制條件垂直排列 -->
                    <div class="flex-1 h-16 flex flex-col justify-between">
                        <!-- 血條區域 -->
                        <div class="w-full bg-gray-600 rounded-full h-4 border border-gray-500 shadow-inner">
                            <div id="enemy-hp-bar" class="bg-gradient-to-r from-red-500 to-red-700 h-full rounded-full transition-all duration-300 ease-out flex items-center justify-end pr-1">
                                <span id="enemy-hp-text" class="text-xs font-bold text-white text-shadow">${enemy.maxHP}/${enemy.maxHP}</span>
                            </div>
                        </div>
                        
                        <!-- 限制條件區域 -->
                        ${restrictionsDisplay ? `
                        <div id="quest-restrictions-display" class="bg-slate-900/50 rounded-md px-2 py-1 flex-1 flex items-center">
                            ${restrictionsDisplay}
                        </div>
                        ` : '<div class="flex-1"></div>'}
                    </div>
                </div>
            </div>
        </div>`;
    }

    // 新增方法：獲取限制條件的簡短顯示文字
    static getRestrictionsDisplayText(restrictions) {
        if (!restrictions || Object.keys(restrictions).length === 0) return '';
        
        const colorMap = {
            red: '紅', blue: '藍', green: '綠',
            yellow: '黃', purple: '紫'
        };
        
        if (restrictions.minComboForDamage) {
            return `需連擊${restrictions.minComboForDamage}以上`;
        }
        if (restrictions.minChainForDamage) {
            return `需連鎖${restrictions.minChainForDamage}以上`;
        }
        if (restrictions.noDamageColors) {
            const colors = restrictions.noDamageColors.map(c => colorMap[c] || c).join('');
            return `${colors}色無效`;
        }
        if (restrictions.damageOnlyColors) {
            const colors = restrictions.damageOnlyColors.map(c => colorMap[c] || c).join('');
            return `僅${colors}色有效`;
        }
        if (restrictions.requireHorizontalMatch) {
            return '僅橫向消除';
        }
        if (restrictions.requireVerticalMatch) {
            return '僅縱向消除';
        }
        
        return '特殊限制';
    }

    static createStandardHeaderHTML(mode, config) {
        const actionPointsHTML = (config.actionPointsStart !== undefined && config.actionPointsStart > 0) ? `
        <div>
            <p class="text-slate-600">行動</p>
            <p id="action-points" class="text-sm font-bold text-purple-600">${config.actionPointsStart}</p>
        </div>` : '';

        return `
        <div class="flex-shrink-0 bg-slate-100/50 rounded-t-xl px-3 py-2">
            <div class="flex items-center justify-center">
                <div class="flex gap-6 text-center text-xs">
                    <div>
                        <p class="text-slate-600">分數</p>
                        <p id="score" class="text-sm font-bold text-sky-600">0</p>
                    </div>
                    <div>
                        <p class="text-slate-600">連擊</p>
                        <p id="combo" class="text-sm font-bold text-emerald-600">0</p>
                    </div>
                    ${actionPointsHTML}
                </div>
            </div>
        </div>`;
    }

    static createTimerHTML(config) {
        if (!config.hasTimer) return '';
        
        // RPG模式的計時器已整合到RPG狀態欄中的環形倒數器
        if (config.hasRPGSystem) {
            return '';
        }
        
        // 非RPG模式仍使用原有的橫向進度條
        return `
        <div class="timer-display-area p-2 bg-slate-100/30">
            <div class="relative w-full h-5 bg-slate-300/50 rounded-full overflow-hidden shadow-inner">
                <div id="time-progress-bar" class="h-full bg-gradient-to-r from-sky-400 to-cyan-400 rounded-full transition-all duration-200 ease-linear" style="width: 100%;"></div>
                <p id="time-left" class="absolute inset-0 flex items-center justify-center text-xs font-bold text-white text-shadow">${(config.gameDuration / 1000).toFixed(0)}s</p>
            </div>
        </div>`;
    }

    static createModalStatsHTML(mode) {
        if (mode === 'timeLimit') {
            return `<p class="text-slate-700 text-lg mb-2">最終分數: <span id="finalScore" class="font-bold text-sky-600">0</span></p>`;
        }
        return `
        <div class="bg-slate-50 rounded-lg p-3 mb-4">
            <div class="grid grid-cols-2 gap-3 text-center">
                <div>
                    <p class="text-slate-600 text-sm">最終分數</p>
                    <p id="finalScore" class="text-xl font-bold text-sky-600">0</p>
                </div>
                <div>
                    <p class="text-slate-600 text-sm">最高連擊</p>
                    <p id="finalMaxCombo" class="text-xl font-bold text-emerald-600">0</p>
                </div>
                <div class="col-span-2">
                    <p class="text-slate-600 text-sm">總操作次數</p>
                    <p id="finalActionCount" class="text-xl font-bold text-purple-600">0</p>
                </div>
            </div>
         </div>`;
    }

    static createModalButtonsHTML(mode) {
        if (mode === 'quest') {
            // 闖關模式專用按鈕
            return `
            <div class="flex gap-2">
                <button id="modalBackToQuestButton" class="flex-1 bg-blue-500 hover:bg-blue-600 text-white font-medium py-2 px-3 text-sm rounded action-button">關卡選擇</button>
                <button id="modalRestartButton" class="flex-1 bg-green-500 hover:bg-green-600 text-white font-semibold py-2.5 px-4 rounded action-button">重新挑戰</button>
                <button id="modalBackToIntroButton" class="flex-1 bg-gray-500 hover:bg-gray-600 text-white font-medium py-2 px-3 text-sm rounded action-button">主選單</button>
            </div>`;
        }
        
        const backButton = (mode !== 'timeLimit') ?
            `<button id="modalBackToIntroButton" class="flex-1 bg-gray-500 hover:bg-gray-600 text-white font-medium py-2 px-3 text-sm rounded action-button">返回主選單</button>` : '';
        
        const restartButtonClass = backButton ? "flex-1" : "";
        return `
        <div class="flex gap-3">
            ${backButton}
            <button id="modalRestartButton" class="${restartButtonClass} bg-green-500 hover:bg-green-600 text-white font-semibold py-2.5 px-4 rounded action-button">再玩一次</button>
        </div>`;
    }

    static createSkillsSection() {
        // 技能系統已整合到道具系統中，不再需要獨立的技能按鈕
        return '';
    }

    // 創建道具系統UI
    static createItemsSection() {
        return `
        <div class="flex gap-3" id="equippedItems">
            <!-- 道具按鈕將在這裡動態生成 -->
        </div>`;
    }

    // Canvas內繪製下個方塊預覽的方法
    static drawNextBlockPreview(ctx, x, y, width, height, colors, isMultiColumn = false) {
        // 繪製背景框（虛線邊框）
        ctx.save();
        ctx.setLineDash([5, 5]);
        ctx.strokeStyle = '#94a3b8';
        ctx.lineWidth = 2;
        ctx.strokeRect(x, y, width, height);
        
        // 繪製斜線填充背景
        ctx.globalAlpha = 0.1;
        ctx.strokeStyle = '#94a3b8';
        ctx.lineWidth = 1;
        ctx.setLineDash([]);
        for (let i = -height; i < width; i += 8) {
            ctx.beginPath();
            ctx.moveTo(x + i, y + height);
            ctx.lineTo(x + i + height, y);
            ctx.stroke();
        }
        ctx.globalAlpha = 1;
        
        // 繪製方塊預覽
        if (isMultiColumn) {
            // 三列模式：繪製三個小方塊
            const blockSize = Math.min(16, (width - 20) / 3);
            const startX = x + (width - blockSize * 3 - 10) / 2;
            const startY = y + (height - blockSize) / 2;
            
            for (let i = 0; i < 3 && i < colors.length; i++) {
                this.drawSingleBlock(ctx, startX + i * (blockSize + 5), startY, blockSize, colors[i]);
            }
        } else {
            // 單列模式：繪製一個方塊
            const blockSize = Math.min(24, Math.min(width, height) - 16);
            const blockX = x + (width - blockSize) / 2;
            const blockY = y + (height - blockSize) / 2;
            
            if (colors.length > 0) {
                this.drawSingleBlock(ctx, blockX, blockY, blockSize, colors[0]);
            }
        }
        
        ctx.restore();
    }
    
    // 繪製單個方塊
    static drawSingleBlock(ctx, x, y, size, color) {
        ctx.save();
        
        // 繪製方塊主體
        ctx.fillStyle = color;
        ctx.fillRect(x, y, size, size);
        
        // 繪製方塊邊框
        ctx.strokeStyle = 'rgba(255, 255, 255, 0.3)';
        ctx.lineWidth = 1;
        ctx.strokeRect(x, y, size, size);
        
        // 繪製高光效果
        ctx.fillStyle = 'rgba(255, 255, 255, 0.2)';
        ctx.fillRect(x, y, size, size * 0.3);
        
        ctx.restore();
    }

    // 新增一個方法來更新下個方塊預覽的顏色（保留向後兼容）
    static updateNextBlockPreview(colors, isMultiColumn = false) {
        // 這個方法現在主要用於Canvas內的繪製
        // 具體實現將在GameEngine中處理
    }
    
    // 創建HTML下個方塊預覽元素（使用虛線外框和斜線填充）
    static createNextBlockPreviewElements(colors, isMultiColumn = false) {
        const previewArea = document.getElementById('nextBlockPreviewArea');
        if (!previewArea) return;
        
        previewArea.innerHTML = '';
        
        if (isMultiColumn) {
            // 多列模式：顯示多個小預覽
            colors.forEach((color, index) => {
                const previewBox = this.createSinglePreviewBox(color, true);
                previewArea.appendChild(previewBox);
            });
        } else {
            // 單列模式：顯示一個較大的預覽
            if (colors.length > 0) {
                const previewBox = this.createSinglePreviewBox(colors[0], false);
                previewArea.appendChild(previewBox);
            }
        }
    }
    
    // 創建單個預覽方塊（虛線外框 + 斜線填充）
    static createSinglePreviewBox(color, isSmall = false) {
        const previewBox = document.createElement('div');
        
        // 設置基本樣式
        const baseClass = isSmall 
            ? 'w-8 h-8 relative border-2 border-dashed border-slate-400 rounded-md'
            : 'w-12 h-12 relative border-2 border-dashed border-slate-400 rounded-lg';
        
        previewBox.className = baseClass;
        
        // 創建斜線填充背景
        const striped = document.createElement('div');
        striped.className = 'absolute inset-0 rounded overflow-hidden';
        striped.style.background = `
            repeating-linear-gradient(
                45deg,
                ${color}20,
                ${color}20 4px,
                transparent 4px,
                transparent 8px
            )
        `;
        
        // 創建主色塊（中心顯示）
        const colorBlock = document.createElement('div');
        const centerSize = isSmall ? 'w-4 h-4' : 'w-6 h-6';
        colorBlock.className = `absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 ${centerSize} rounded-sm border border-slate-300/50`;
        colorBlock.style.backgroundColor = color;
        colorBlock.style.boxShadow = 'inset 0 1px 2px rgba(255,255,255,0.3), 0 1px 2px rgba(0,0,0,0.1)';
        
        previewBox.appendChild(striped);
        previewBox.appendChild(colorBlock);
        
        return previewBox;
    }

    // 新增一個方法來獲取方塊顏色的CSS值
    static getBlockColor(colorIndex) {
        const colors = [
            '#3B82F6', // 藍色
            '#8B5CF6', // 紫色
            '#EF4444', // 紅色
            '#10B981', // 綠色
            '#F59E0B', // 黃色
            '#EC4899', // 粉色
        ];
        return colors[colorIndex] || colors[0];
    }

    static createDocumentStructure(mode, config) {
        return `<!DOCTYPE html>
<html lang="zh-Hant">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${config.title}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+TC:wght@400;500;700&family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="css/game.css">
</head>
<body class="theme-${config.theme} flex flex-col items-center justify-center min-h-screen p-2">
    ${this.createGameHTML(mode, config)}
    
    <script src="js/GameEngine.js"></script>
    <script src="js/GameModes.js"></script>
    <script>
        // 初始化遊戲
        const gameEngine = new GameEngine(GameModes.${mode});
    </script>
</body>
</html>`;
    }

    static updateQuestUI(gameState) {
        if (gameState.mode !== 'quest') return;

        const hpBar = document.getElementById('enemy-hp-bar');
        const hpText = document.getElementById('enemy-hp-text');
        const movesLeft = document.getElementById('moves-left');

        if (hpBar && hpText) {
            const hpPercent = (gameState.enemy.hp / gameState.enemy.maxHP) * 100;
            hpBar.style.width = `${Math.max(0, hpPercent)}%`;
            hpText.textContent = `${gameState.enemy.hp} / ${gameState.enemy.maxHP}`;
        }

        if (movesLeft) {
            movesLeft.textContent = gameState.movesLeft;
        }
    }

    static triggerEnemyHitAnimation() {
        const enemyImage = document.getElementById('enemy-image');
        if (enemyImage) {
            enemyImage.classList.add('enemy-hit');
            setTimeout(() => enemyImage.classList.remove('enemy-hit'), 200);
        }
    }

    static showGameOverModal(score, maxCombo, actionCount, status = 'default') {
        const modal = document.getElementById('gameOverModal');
        modal.style.display = 'flex';
        
        const titleEl = document.getElementById('modal-title');
        const messageEl = document.getElementById('modal-message');

        switch(status) {
            case 'quest_win':
                titleEl.textContent = '勝利！';
                titleEl.className = 'text-2xl font-bold text-green-500 mb-3';
                messageEl.textContent = '你擊敗了敵人！準備好挑戰下一關。';
                this.updateQuestModalButtons('win');
                break;
            case 'quest_loss':
                titleEl.textContent = '失敗';
                titleEl.className = 'text-2xl font-bold text-red-500 mb-3';
                messageEl.textContent = '步數用盡，再試一次吧！';
                this.updateQuestModalButtons('loss');
                break;
            case 'survival_victory':
                titleEl.textContent = '挑戰成功！';
                titleEl.className = 'text-2xl font-bold text-green-500 mb-3';
                messageEl.textContent = '🎉 恭喜！你成功存活了3分鐘！';
                break;
            case 'survival_failure':
                titleEl.textContent = '挑戰失敗';
                titleEl.className = 'text-2xl font-bold text-red-500 mb-3';
                messageEl.textContent = '時間到！再接再厲，挑戰更高分！';
                break;
            default:
                // Keep original text
                break;
        }

        const finalScore = document.getElementById('finalScore');
        if (finalScore) finalScore.textContent = score;

        const finalMaxCombo = document.getElementById('finalMaxCombo');
        if (finalMaxCombo) finalMaxCombo.textContent = maxCombo;

        const finalActionCount = document.getElementById('finalActionCount');
        if (finalActionCount) finalActionCount.textContent = actionCount;
    }

    static updateQuestModalButtons(result) {
        const modal = document.getElementById('gameOverModal');
        const buttonContainer = modal.querySelector('.flex.gap-2, .flex.gap-3');
        if (!buttonContainer) return;

        // 獲取當前關卡號碼
        const urlParams = new URLSearchParams(window.location.search);
        const currentLevel = parseInt(urlParams.get('level')) || 1;
        
        if (result === 'win') {
            // 勝利：[返回關卡][下一關]
            const nextLevel = currentLevel + 1;
            buttonContainer.innerHTML = `
                <button id="modalBackToQuestButton" class="flex-1 bg-blue-500 hover:bg-blue-600 text-white font-medium py-2 px-3 text-sm rounded action-button">返回關卡</button>
                <button id="modalNextLevelButton" class="flex-1 bg-green-500 hover:bg-green-600 text-white font-semibold py-2.5 px-4 rounded action-button">下一關</button>
            `;
            
            // 為新按鈕添加事件監聽器
            const backToQuestBtn = modal.querySelector('#modalBackToQuestButton');
            const nextLevelBtn = modal.querySelector('#modalNextLevelButton');
            
            if (backToQuestBtn) {
                backToQuestBtn.addEventListener('click', () => {
                    window.location.href = 'quest-mode.html';
                });
            }
            
            if (nextLevelBtn) {
                nextLevelBtn.addEventListener('click', () => {
                    window.location.href = `game.html?mode=quest&level=${nextLevel}`;
                });
            }
        } else if (result === 'loss') {
            // 失敗：[返回關卡][再次挑戰]
            buttonContainer.innerHTML = `
                <button id="modalBackToQuestButton" class="flex-1 bg-blue-500 hover:bg-blue-600 text-white font-medium py-2 px-3 text-sm rounded action-button">返回關卡</button>
                <button id="modalRestartButton" class="flex-1 bg-orange-500 hover:bg-orange-600 text-white font-semibold py-2.5 px-4 rounded action-button">再次挑戰</button>
            `;
            
            // 為新按鈕添加事件監聽器
            const backToQuestBtn = modal.querySelector('#modalBackToQuestButton');
            const restartBtn = modal.querySelector('#modalRestartButton');
            
            if (backToQuestBtn) {
                backToQuestBtn.addEventListener('click', () => {
                    window.location.href = 'quest-mode.html';
                });
            }
            
            if (restartBtn) {
                restartBtn.addEventListener('click', () => {
                    window.location.reload();
                });
            }
        }
    }

    // 新增：Toast 系統
    static showToast(message, type = 'info', duration = 2000) {
        // 移除現有的 toast
        const existingToast = document.getElementById('game-toast');
        if (existingToast) {
            existingToast.remove();
        }

        // 創建新的 toast
        const toast = document.createElement('div');
        toast.id = 'game-toast';
        toast.className = 'fixed top-4 left-1/2 transform -translate-x-1/2 z-50 px-4 py-2 rounded-lg shadow-lg text-white font-medium text-sm max-w-xs text-center transition-all duration-300';
        
        switch(type) {
            case 'success':
                toast.className += ' bg-green-500';
                break;
            case 'warning':
                toast.className += ' bg-orange-500';
                break;
            case 'error':
                toast.className += ' bg-red-600';
                break;
            case 'damage':
                toast.className += ' bg-red-500';
                break;
            case 'combo':
                toast.className += ' bg-purple-500';
                break;
            case 'blocked':
                toast.className += ' bg-gray-600';
                break;
            case 'milestone':
                toast.className += ' bg-yellow-500 text-black';
                break;
            default:
                toast.className += ' bg-blue-500';
        }

        toast.innerHTML = message;
        document.body.appendChild(toast);

        // 顯示動畫
        setTimeout(() => {
            toast.style.opacity = '1';
            toast.style.transform = 'translate(-50%, 0)';
        }, 10);

        // 自動隱藏
        setTimeout(() => {
            toast.style.opacity = '0';
            toast.style.transform = 'translate(-50%, -20px)';
            setTimeout(() => {
                if (toast.parentNode) {
                    toast.parentNode.removeChild(toast);
                }
            }, 300);
        }, duration);
    }

    // 新增：顯示動作結果的Toast
    static showActionResultToast(result) {
        let message = '';
        let type = 'info';

        if (result.isBlocked) {
            if (result.reason === 'minCombo') {
                message = `🚫 需要${result.required}連擊 (目前${result.current})`;
            } else if (result.reason === 'colorBlocked') {
                message = `🚫 ${result.blockedColors}方塊無效`;
            } else if (result.reason === 'colorOnly') {
                message = `🚫 僅${result.allowedColors}方塊有效`;
            } else {
                message = '🚫 攻擊被阻擋';
            }
            type = 'blocked';
        } else {
            if (result.damage > 0) {
                const comboText = result.combo > 1 ? ` (${result.combo}連擊)` : '';
                message = `⚔️ 造成 ${result.damage} 傷害${comboText}`;
                type = 'damage';
            } else if (result.score > 0) {
                const comboText = result.combo > 1 ? ` (${result.combo}連擊)` : '';
                message = `⭐ 獲得 ${result.score} 分${comboText}`;
                type = 'success';
            }
        }

        if (message) {
            this.showToast(message, type, 2500);
        }
    }

    // 新增：改進的限制顯示系統
    static createQuestRestrictionsDisplay(restrictions, currentCombo = 0) {
        if (!restrictions || Object.keys(restrictions).length === 0) {
            return '';
        }

        const colorMap = {
            red: { name: '紅', hex: '#EF4444' },
            blue: { name: '藍', hex: '#3B82F6' },
            green: { name: '綠', hex: '#10B981' },
            yellow: { name: '黃', hex: '#F59E0B' },
            purple: { name: '紫', hex: '#8B5CF6' }
        };

        let restrictionsHTML = '<div class="flex flex-wrap gap-2 items-center justify-center mt-2">';

        // 連擊限制
        if (restrictions.minComboForDamage) {
            const isComboMet = currentCombo >= restrictions.minComboForDamage;
            const statusClass = isComboMet ? 'bg-green-600' : 'bg-red-600';
            const statusText = isComboMet ? `✓ ${currentCombo}` : `${currentCombo}/${restrictions.minComboForDamage}`;
            
            restrictionsHTML += `
                <div class="flex items-center gap-1 px-2 py-1 rounded-md ${statusClass} text-white text-xs">
                    <span>連擊</span>
                    <span class="font-bold">${statusText}</span>
                </div>
            `;
        }

        // 無效顏色 (色塊 + 叉叉)
        if (restrictions.noDamageColors && restrictions.noDamageColors.length > 0) {
            restrictionsHTML += '<div class="flex items-center gap-1">';
            restrictions.noDamageColors.forEach(color => {
                const colorInfo = colorMap[color];
                if (colorInfo) {
                    restrictionsHTML += `
                        <div class="relative">
                            <div class="w-6 h-6 rounded-sm border border-gray-300" style="background-color: ${colorInfo.hex}"></div>
                            <div class="absolute inset-0 flex items-center justify-center text-white font-bold text-lg">✕</div>
                        </div>
                    `;
                }
            });
            restrictionsHTML += '</div>';
        }

        // 有效顏色 (色塊 + 圈圈)
        if (restrictions.damageOnlyColors && restrictions.damageOnlyColors.length > 0) {
            restrictionsHTML += '<div class="flex items-center gap-1">';
            restrictions.damageOnlyColors.forEach(color => {
                const colorInfo = colorMap[color];
                if (colorInfo) {
                    restrictionsHTML += `
                        <div class="relative">
                            <div class="w-6 h-6 rounded-sm border border-gray-300" style="background-color: ${colorInfo.hex}"></div>
                            <div class="absolute inset-0 flex items-center justify-center text-white font-bold text-lg">○</div>
                        </div>
                    `;
                }
            });
            restrictionsHTML += '</div>';
        }

        // 橫向消除限制
        if (restrictions.requireHorizontalMatch) {
            restrictionsHTML += `
                <div class="px-2 py-1 bg-yellow-600 text-white text-xs rounded-md">
                    僅橫向
                </div>
            `;
        }

        restrictionsHTML += '</div>';
        return restrictionsHTML;
    }

    // 新增：更新限制顯示的方法
    static updateQuestRestrictionsDisplay(restrictions, currentCombo) {
        const restrictionsContainer = document.getElementById('quest-restrictions-display');
        if (!restrictionsContainer) return;

        const newRestrictionsHTML = this.createQuestRestrictionsDisplay(restrictions, currentCombo);
        if (newRestrictionsHTML) {
            restrictionsContainer.innerHTML = `
                <div class="bg-slate-900/50 rounded-md px-2 py-1">
                    ${newRestrictionsHTML}
                </div>
            `;
        }
    }

    // ===== RPG系統UI方法 =====
    
    // 創建RPG狀態欄HTML
    static createRPGStatsHTML(gameState) {
        const { level, exp, expToNextLevel, gold } = gameState;
        const actionPoints = gameState.actionPoints !== undefined ? gameState.actionPoints : 5;
        const expPercent = expToNextLevel > 0 ? (exp / expToNextLevel) * 100 : 100;
        
        // 檢查是否為存活模式
        const isSurvivalMode = gameState.isSurvivalMode || (window.gameEngine?.config?.isSurvivalMode);
        
        // 檢查是否有計時器需求
        const hasTimer = gameState.hasTimer !== undefined ? gameState.hasTimer : true; // RPG模式預設有計時器
        let timerProgressHTML = '';
        
        if (hasTimer) {
            timerProgressHTML = `
                <!-- 底部細橫向進度條 -->
                <div class="absolute bottom-0 left-0 right-0 h-1">
                    <div id="timer-progress-bar" class="h-full bg-gradient-to-r from-emerald-400 via-cyan-400 to-blue-400 transition-all duration-200 ease-linear shadow-sm" style="width: 100%"></div>
                </div>`;
        }
        
        // 創建已獲技能HTML（整合模式）
        const acquiredSkillsHTML = this.createAcquiredSkillsHTML(gameState.playerSkills, true);
        
        // 存活時間和技能合併的HTML
        let survivalAndSkillsHTML = '';
        if (isSurvivalMode) {
            const survivalTime = gameState.survivalTime || 0;
            const targetTime = gameState.targetSurvivalTime || 180000; // 3分鐘
            const minutes = Math.floor(survivalTime / 60000);
            const seconds = Math.floor((survivalTime % 60000) / 1000);
            const targetMinutes = Math.floor(targetTime / 60000);
            const targetSeconds = Math.floor((targetTime % 60000) / 1000);
            
            survivalAndSkillsHTML = `
                <div class="flex items-center justify-between gap-2 mt-1">
                    <!-- 存活時間 -->
                    <div class="flex items-center gap-1 flex-shrink-0">
                        <span class="text-xs text-green-200">⏰</span>
                        <span id="survival-time" class="text-xs font-semibold text-green-300">${minutes}:${seconds.toString().padStart(2, '0')} / ${targetMinutes}:${targetSeconds.toString().padStart(2, '0')}</span>
                    </div>
                    
                    <!-- 已獲技能 -->
                    <div class="flex items-center gap-1 flex-1 min-w-0">
                        <span class="text-xs text-slate-200 whitespace-nowrap">技能:</span>
                        <div class="flex gap-1 overflow-x-auto">
                            ${this.createSkillIconsHTML(gameState.playerSkills)}
                        </div>
                    </div>
                </div>`;
        } else {
            // 非存活模式只顯示技能
            survivalAndSkillsHTML = acquiredSkillsHTML;
        }
        
        return `
        <div id="rpg-stats" class="relative flex-shrink-0 bg-gradient-to-br from-indigo-500/80 via-purple-500/80 to-pink-400/80 rounded-t-xl px-3 py-2 text-white backdrop-blur-sm">
            <div class="space-y-2">
                <!-- 第一排：緊湊的狀態顯示 -->
                <div class="flex items-center gap-3 text-xs">
                    <div class="flex items-center gap-1">
                        <span class="text-yellow-200">Lv</span>
                        <span id="player-level" class="font-bold text-yellow-300">${level}</span>
                    </div>
                    <div class="flex items-center gap-1">
                        <span class="text-yellow-200"></span>
                        <span id="player-gold" class="font-semibold text-yellow-300">${gold}</span>
                    </div>
                    <div class="flex items-center gap-1">
                        <span class="text-red-200">🩷</span>
                        <span id="action-points-display" class="font-semibold text-red-300">${actionPoints}</span>
                    </div>
                    ${hasTimer ? `
                    <div class="flex items-center gap-1">
                        <span class="text-orange-200">⏱️</span>
                        <span id="time-left" class="font-semibold text-orange-300">8s</span>
                    </div>` : ''}
                    <div class="flex items-center gap-1">
                        <span class="text-sky-200">📊</span>
                        <span id="score" class="font-semibold text-sky-300">0</span>
                    </div>
                    <div class="flex items-center gap-1">
                        <span class="text-emerald-200">🔗</span>
                        <span id="combo" class="font-semibold text-emerald-300">0</span>
                    </div>
                </div>
                
                <!-- 經驗條 -->
                <div class="relative w-full h-2.5 bg-white/20 rounded-full overflow-hidden backdrop-blur-sm">
                    <div id="exp-bar" class="h-full bg-gradient-to-r from-emerald-400 to-cyan-400 rounded-full transition-all duration-300 ease-out" style="width: ${expPercent}%"></div>
                    <span id="exp-text" class="absolute inset-0 flex items-center justify-center text-xs font-bold text-white drop-shadow-sm">EXP ${exp}/${expToNextLevel}</span>
                </div>
                
                <!-- 存活時間和已獲技能 -->
                ${survivalAndSkillsHTML}
            </div>
            
            ${timerProgressHTML}
        </div>`;
    }
    
    // 創建技能圖標HTML（用於整合顯示）
    static createSkillIconsHTML(playerSkills) {
        const hasSkills = playerSkills && Object.keys(playerSkills).length > 0;
        
        if (hasSkills) {
            let skillsHTML = '';
            Object.entries(playerSkills).forEach(([skillId, level]) => {
                const skillData = window.SkillSystem?.getSkillData(skillId, level);
                if (skillData) {
                    skillsHTML += `
                    <div class="skill-icon relative" title="${skillData.name} Lv.${level}&#10;${skillData.description}">
                        <div class="w-6 h-6 bg-gradient-to-br from-slate-500/80 to-slate-600/80 rounded-md flex items-center justify-center text-sm border border-slate-300/30 shadow-sm backdrop-blur-sm">
                            ${skillData.icon}
                        </div>
                        <span class="absolute -bottom-0.5 -right-0.5 bg-emerald-500 text-white text-xs font-bold rounded-full w-3 h-3 flex items-center justify-center border border-slate-300/50 text-[10px]">${level}</span>
                    </div>`;
                }
            });
            return skillsHTML;
        } else {
            // 提供骨架佔位符
            return `
            <div class="skill-icon-placeholder opacity-30">
                <div class="w-6 h-6 bg-slate-400/60 rounded-md flex items-center justify-center text-sm border border-slate-300/40 shadow-sm backdrop-blur-sm">
                    <span class="text-slate-100 text-xs">?</span>
                </div>
            </div>
            <div class="skill-icon-placeholder opacity-20">
                <div class="w-6 h-6 bg-slate-400/60 rounded-md flex items-center justify-center text-sm border border-slate-300/40 shadow-sm backdrop-blur-sm">
                    <span class="text-slate-100 text-xs">?</span>
                </div>
            </div>
            <div class="skill-icon-placeholder opacity-10">
                <div class="w-6 h-6 bg-slate-400/60 rounded-md flex items-center justify-center text-sm border border-slate-300/40 shadow-sm backdrop-blur-sm">
                    <span class="text-slate-100 text-xs">?</span>
                </div>
            </div>`;
        }
    }

    // 創建已獲技能欄HTML
    static createAcquiredSkillsHTML(playerSkills, isIntegrated = false) {
        // 優化：始終提供固定高度的容器，避免佈局變化
        const hasSkills = playerSkills && Object.keys(playerSkills).length > 0;
        
        let skillsHTML = '';
        if (hasSkills) {
            Object.entries(playerSkills).forEach(([skillId, level]) => {
                const skillData = window.SkillSystem?.getSkillData(skillId, level);
                if (skillData) {
                    skillsHTML += `
                    <div class="skill-icon relative" title="${skillData.name} Lv.${level}&#10;${skillData.description}">
                        <div class="w-8 h-8 bg-gradient-to-br from-slate-500/80 to-slate-600/80 rounded-lg flex items-center justify-center text-lg border-2 border-slate-300/30 shadow-md backdrop-blur-sm">
                            ${skillData.icon}
                        </div>
                        <span class="absolute -bottom-1 -right-1 bg-emerald-500 text-white text-xs font-bold rounded-full w-4 h-4 flex items-center justify-center border border-slate-300/50">${level}</span>
                    </div>`;
                }
            });
        } else {
            // 提供骨架佔位符 - 使用更柔和的配色
            skillsHTML = `
            <div class="skill-icon-placeholder opacity-30">
                <div class="w-8 h-8 bg-slate-400/60 rounded-lg flex items-center justify-center text-lg border-2 border-slate-300/40 shadow-md backdrop-blur-sm">
                    <span class="text-slate-100">?</span>
                </div>
            </div>
            <div class="skill-icon-placeholder opacity-20">
                <div class="w-8 h-8 bg-slate-400/60 rounded-lg flex items-center justify-center text-lg border-2 border-slate-300/40 shadow-md backdrop-blur-sm">
                    <span class="text-slate-100">?</span>
                </div>
            </div>
            <div class="skill-icon-placeholder opacity-10">
                <div class="w-8 h-8 bg-slate-400/60 rounded-lg flex items-center justify-center text-lg border-2 border-slate-300/40 shadow-md backdrop-blur-sm">
                    <span class="text-slate-100">?</span>
                </div>
            </div>`;
        }
        
        if (isIntegrated) {
            // 整合模式：直接返回技能內容，在狀態欄中顯示
            return `
                <div class="flex items-center gap-2 mt-1">
                    <span class="text-xs text-slate-200 whitespace-nowrap">已獲技能:</span>
                    <div class="flex gap-1 overflow-x-auto">
                        ${skillsHTML}
                    </div>
                </div>`;
        } else {
            // 獨立模式：完整的技能區域
            return `
            <div id="acquired-skills" class="px-3 py-2 bg-slate-100/20 border-b border-slate-200/30 min-h-[3.5rem] backdrop-blur-sm">
                <div class="flex items-center gap-2 overflow-x-auto h-10">
                    <span class="text-xs text-slate-100 whitespace-nowrap">已獲技能:</span>
                    <div class="flex gap-1">
                        ${skillsHTML}
                    </div>
                </div>
            </div>`;
        }
    }
    
    // 修改createStandardHeaderHTML以支持RPG模式
    static createRPGHeaderHTML(mode, config, gameState) {
        if (config.hasRPGSystem && gameState) {
            // RPG模式header - 技能已整合到狀態欄中，不需要單獨創建
            const rpgStatsHTML = this.createRPGStatsHTML(gameState);
            
            return rpgStatsHTML;
        } else {
            // 非RPG模式使用標準header
            return this.createStandardHeaderHTML(mode, config);
        }
    }
    
    // 顯示升級彈窗
    static showLevelUpModal(levelUpData) {
        const { level, skillOptions, playerGold, hasUsedFreeReroll, onSkillPurchase, onSkipUpgrade, onRerollOptions } = levelUpData;
        
        // 移除現有的升級彈窗
        const existingModal = document.getElementById('levelUpModal');
        if (existingModal) {
            existingModal.remove();
        }
        
        // 生成技能選項HTML
        let skillOptionsHTML = '';
        skillOptions.forEach(skillOption => {
            // 支持新的技能選項格式
            const skillId = skillOption.id || skillOption;
            const skillData = skillOption.id ? skillOption : window.SkillSystem?.getSkillData(skillId, 1);
            
            if (skillData) {
                const currentLevel = skillOption.currentPlayerLevel || 0;
                const nextLevel = skillData.currentLevel?.level || 1;
                const cost = skillData.currentLevel?.cost || 0;
                const isUpgrade = skillOption.isUpgrade || false;
                const canAfford = playerGold >= cost;
                const buttonClass = canAfford 
                    ? 'bg-green-500 hover:bg-green-600 cursor-pointer' 
                    : 'bg-gray-400 cursor-not-allowed';
                
                skillOptionsHTML += `
                                        <div class="skill-option bg-slate-50 rounded-lg p-4 border-2 border-transparent hover:border-purple-300 transition-colors">
                            <div class="flex items-start gap-3">
                                <div class="skill-icon-large w-12 h-12 bg-gradient-to-br from-slate-500/80 to-slate-600/80 rounded-lg flex items-center justify-center text-2xl border-2 border-slate-300/30 shadow-md backdrop-blur-sm">
                                    ${skillData.icon}
                                </div>
                        <div class="flex-1">
                            <h4 class="font-bold text-gray-800 mb-1">
                                ${skillData.name}
                                ${isUpgrade ? `<span class="text-orange-600 text-xs ml-1">升級</span>` : `<span class="text-green-600 text-xs ml-1">新技能</span>`}
                            </h4>
                            <p class="text-sm text-gray-600 mb-2">${skillData.description}</p>
                            <div class="flex items-center justify-between">
                                <span class="text-sm font-medium text-gray-700">
                                    ${isUpgrade ? `等級 ${currentLevel} → ${nextLevel}` : `獲得等級 ${nextLevel}`}
                                </span>
                                <span class="text-lg font-bold text-yellow-600">💰${cost}</span>
                            </div>
                        </div>
                    </div>
                    <button class="skill-purchase-btn w-full mt-3 ${buttonClass} text-white font-medium py-2 px-4 rounded-lg transition-colors" 
                            data-skill-id="${skillId}" 
                            ${!canAfford ? 'disabled' : ''}>
                        ${canAfford ? (isUpgrade ? '升級技能' : '獲得技能') : '金幣不足'}
                    </button>
                </div>`;
            }
        });
        
        // 重抽按鈕邏輯
        const rerollCost = 50;
        const canRerollFree = !hasUsedFreeReroll;
        const canRerollPaid = playerGold >= rerollCost;
        
        let rerollButtonsHTML = '';
        if (canRerollFree) {
            rerollButtonsHTML = `
                <button id="free-reroll-btn" class="flex-1 bg-blue-500 hover:bg-blue-600 text-white font-medium py-2 px-4 rounded-lg transition-colors">
                    🎲 免費重抽
                </button>`;
        } else if (canRerollPaid) {
            rerollButtonsHTML = `
                <button id="paid-reroll-btn" class="flex-1 bg-orange-500 hover:bg-orange-600 text-white font-medium py-2 px-4 rounded-lg transition-colors">
                    🎲 重抽 (💰${rerollCost})
                </button>`;
        }
        
        // 創建升級彈窗
        const modal = document.createElement('div');
        modal.id = 'levelUpModal';
        modal.className = 'fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-4';
        modal.innerHTML = `
            <div class="bg-white rounded-xl shadow-2xl w-full max-w-md max-h-[90vh] overflow-y-auto">
                <div class="bg-gradient-to-r from-purple-600 to-blue-600 text-white p-4 rounded-t-xl">
                    <h2 class="text-xl font-bold text-center">🎉 升級到 ${level} 級！</h2>
                    <p class="text-center text-purple-100 mt-1">選擇一個技能來強化自己</p>
                    <div class="text-center mt-2">
                        <span class="bg-white/20 rounded-full px-3 py-1 text-sm">目前金幣: 💰${playerGold}</span>
                    </div>
                </div>
                
                <div class="p-4">
                    <div id="skill-options-container" class="space-y-3 mb-4">
                        ${skillOptionsHTML}
                    </div>
                    
                    <div class="flex gap-2">
                        ${rerollButtonsHTML}
                        <button id="skip-upgrade-btn" class="flex-1 bg-gray-500 hover:bg-gray-600 text-white font-medium py-2 px-4 rounded-lg transition-colors">
                            跳過升級
                        </button>
                    </div>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
        
        // 綁定事件
        modal.querySelectorAll('.skill-purchase-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const skillId = e.target.dataset.skillId;
                if (skillId && !e.target.disabled) {
                    onSkillPurchase(skillId);
                }
            });
        });
        
        const skipBtn = modal.querySelector('#skip-upgrade-btn');
        skipBtn.addEventListener('click', () => {
            onSkipUpgrade();
        });
        
        // 重抽按鈕事件
        const freeRerollBtn = modal.querySelector('#free-reroll-btn');
        if (freeRerollBtn) {
            freeRerollBtn.addEventListener('click', () => {
                console.log('免費重抽按鈕點擊 (初次創建)');
                if (typeof onRerollOptions === 'function') {
                    onRerollOptions(true);
                } else {
                    console.error('onRerollOptions is not a function:', onRerollOptions);
                    // 備用方案：直接調用gameEngine
                    if (window.gameEngine && typeof window.gameEngine.handleRerollOptions === 'function') {
                        window.gameEngine.handleRerollOptions(true);
                    }
                }
            });
        }
        
        const paidRerollBtn = modal.querySelector('#paid-reroll-btn');
        if (paidRerollBtn) {
            paidRerollBtn.addEventListener('click', () => {
                console.log('付費重抽按鈕點擊 (初次創建)');
                if (typeof onRerollOptions === 'function') {
                    onRerollOptions(false);
                } else {
                    console.error('onRerollOptions is not a function:', onRerollOptions);
                    // 備用方案：直接調用gameEngine
                    if (window.gameEngine && typeof window.gameEngine.handleRerollOptions === 'function') {
                        window.gameEngine.handleRerollOptions(false);
                    }
                }
            });
        }
        
        // 顯示動畫
        setTimeout(() => {
            modal.style.opacity = '1';
        }, 10);
    }
    
    // 更新升級彈窗（用於重抽）
    static updateLevelUpModal(updateData) {
        const modal = document.getElementById('levelUpModal');
        if (!modal) return;
        
        const { skillOptions, playerGold, hasUsedFreeReroll } = updateData;
        
        // 更新技能選項
        const container = modal.querySelector('#skill-options-container');
        if (container && skillOptions) {
            let skillOptionsHTML = '';
            skillOptions.forEach(skillOption => {
                const skillId = skillOption.id || skillOption;
                const skillData = skillOption.id ? skillOption : window.SkillSystem?.getSkillData(skillId, 1);
                
                if (skillData) {
                    const currentLevel = skillOption.currentPlayerLevel || 0;
                    const nextLevel = skillData.currentLevel?.level || 1;
                    const cost = skillData.currentLevel?.cost || 0;
                    const isUpgrade = skillOption.isUpgrade || false;
                    const canAfford = playerGold >= cost;
                    const buttonClass = canAfford 
                        ? 'bg-green-500 hover:bg-green-600 cursor-pointer' 
                        : 'bg-gray-400 cursor-not-allowed';
                    
                    skillOptionsHTML += `
                    <div class="skill-option bg-slate-50 rounded-lg p-4 border-2 border-transparent hover:border-purple-300 transition-colors">
                        <div class="flex items-start gap-3">
                            <div class="skill-icon-large w-12 h-12 bg-gradient-to-br from-slate-500/80 to-slate-600/80 rounded-lg flex items-center justify-center text-2xl border-2 border-slate-300/30 shadow-md backdrop-blur-sm">
                                ${skillData.icon}
                            </div>
                            <div class="flex-1">
                                <h4 class="font-bold text-gray-800 mb-1">
                                    ${skillData.name}
                                    ${isUpgrade ? `<span class="text-orange-600 text-xs ml-1">升級</span>` : `<span class="text-green-600 text-xs ml-1">新技能</span>`}
                                </h4>
                                <p class="text-sm text-gray-600 mb-2">${skillData.description}</p>
                                <div class="flex items-center justify-between">
                                    <span class="text-sm font-medium text-gray-700">
                                        ${isUpgrade ? `等級 ${currentLevel} → ${nextLevel}` : `獲得等級 ${nextLevel}`}
                                    </span>
                                    <span class="text-lg font-bold text-yellow-600">💰${cost}</span>
                                </div>
                            </div>
                        </div>
                        <button class="skill-purchase-btn w-full mt-3 ${buttonClass} text-white font-medium py-2 px-4 rounded-lg transition-colors" 
                                data-skill-id="${skillId}" 
                                ${!canAfford ? 'disabled' : ''}>
                            ${canAfford ? (isUpgrade ? '升級技能' : '獲得技能') : '金幣不足'}
                        </button>
                    </div>`;
                }
            });
            
            container.innerHTML = skillOptionsHTML;
            
            // 重新綁定購買按鈕事件
            container.querySelectorAll('.skill-purchase-btn').forEach(btn => {
                btn.addEventListener('click', (e) => {
                    const skillId = e.target.dataset.skillId;
                    if (skillId && !e.target.disabled && window.gameEngine) {
                        window.gameEngine.purchaseSkill(skillId);
                    }
                });
            });
        }
        
        // 更新金幣顯示
        const goldDisplay = modal.querySelector('.bg-white\\/20');
        if (goldDisplay) {
            goldDisplay.textContent = `目前金幣: ${playerGold}`;
        }
        
        // 更新重抽按鈕
        const buttonContainer = modal.querySelector('.flex.gap-2');
        if (buttonContainer) {
            const rerollCost = 50;
            const canRerollFree = !hasUsedFreeReroll;
            const canRerollPaid = playerGold >= rerollCost;
            
            // 移除舊的重抽按鈕
            const oldRerollBtn = buttonContainer.querySelector('#free-reroll-btn, #paid-reroll-btn');
            if (oldRerollBtn) {
                oldRerollBtn.remove();
            }
            
                         // 添加新的重抽按鈕
            if (canRerollFree) {
                const freeRerollBtn = document.createElement('button');
                freeRerollBtn.id = 'free-reroll-btn';
                freeRerollBtn.className = 'flex-1 bg-blue-500 hover:bg-blue-600 text-white font-medium py-2 px-4 rounded-lg transition-colors';
                freeRerollBtn.textContent = '🎲 免費重抽';
                freeRerollBtn.addEventListener('click', () => {
                    console.log('免費重抽按鈕點擊');
                    if (window.gameEngine && typeof window.gameEngine.handleRerollOptions === 'function') {
                        window.gameEngine.handleRerollOptions(true);
                    } else {
                        console.error('gameEngine.handleRerollOptions 方法未找到');
                    }
                });
                buttonContainer.insertBefore(freeRerollBtn, buttonContainer.firstChild);
            } else if (canRerollPaid) {
                const paidRerollBtn = document.createElement('button');
                paidRerollBtn.id = 'paid-reroll-btn';
                paidRerollBtn.className = 'flex-1 bg-orange-500 hover:bg-orange-600 text-white font-medium py-2 px-4 rounded-lg transition-colors';
                paidRerollBtn.textContent = `🎲 重抽 (💰${rerollCost})`;
                paidRerollBtn.addEventListener('click', () => {
                    console.log('付費重抽按鈕點擊');
                    if (window.gameEngine && typeof window.gameEngine.handleRerollOptions === 'function') {
                        window.gameEngine.handleRerollOptions(false);
                    } else {
                        console.error('gameEngine.handleRerollOptions 方法未找到');
                    }
                });
                buttonContainer.insertBefore(paidRerollBtn, buttonContainer.firstChild);
            }
        }
    }
    
    // 關閉升級彈窗
    static closeLevelUpModal() {
        const modal = document.getElementById('levelUpModal');
        if (modal) {
            modal.style.opacity = '0';
            setTimeout(() => {
                if (modal.parentNode) {
                    modal.parentNode.removeChild(modal);
                }
            }, 300);
        }
    }
    
    // 更新RPG狀態UI
    static updateRPGStatsUI(gameState) {
        if (!gameState.level) return;
        
        // 更新等級
        const levelEl = document.getElementById('player-level');
        if (levelEl) levelEl.textContent = gameState.level;
        
        // 更新金幣
        const goldEl = document.getElementById('player-gold');
        if (goldEl) goldEl.textContent = `💰${gameState.gold}`;
        
        // 更新行動點
        const actionPointsEl = document.getElementById('action-points-display');
        if (actionPointsEl) actionPointsEl.textContent = gameState.actionPoints || 0;
        
        // 更新經驗條
        const expBar = document.getElementById('exp-bar');
        const expText = document.getElementById('exp-text');
        if (expBar && expText) {
            const expPercent = gameState.expToNextLevel > 0 ? (gameState.exp / gameState.expToNextLevel) * 100 : 100;
            expBar.style.width = `${expPercent}%`;
            expText.textContent = `EXP ${gameState.exp}/${gameState.expToNextLevel}`;
        }
        
        // 更新存活時間（如果是存活模式）
        const isSurvivalMode = gameState.isSurvivalMode || (window.gameEngine?.config?.isSurvivalMode);
        if (isSurvivalMode) {
            const survivalTimeEl = document.getElementById('survival-time');
            
            if (survivalTimeEl) {
                const survivalTime = gameState.survivalTime || 0;
                const targetTime = gameState.targetSurvivalTime || 180000; // 3分鐘
                const minutes = Math.floor(survivalTime / 60000);
                const seconds = Math.floor((survivalTime % 60000) / 1000);
                const targetMinutes = Math.floor(targetTime / 60000);
                const targetSeconds = Math.floor((targetTime % 60000) / 1000);
                
                // 效能優化：只在時間發生變化時才更新UI
                const timeText = `${minutes}:${seconds.toString().padStart(2, '0')} / ${targetMinutes}:${targetSeconds.toString().padStart(2, '0')}`;
                
                if (survivalTimeEl.textContent !== timeText) {
                    survivalTimeEl.textContent = timeText;
                }
            }
        }
        
        // 更新已獲技能 - 修正：針對新的整合布局
        this.updateSkillsDisplay(gameState.playerSkills);
    }
    
    // 新增：更新技能顯示的專用函數
    static updateSkillsDisplay(playerSkills) {
        // 查找技能顯示容器
        const skillsContainer = document.querySelector('#rpg-stats .flex.gap-1.overflow-x-auto');
        
        if (skillsContainer) {
            // 直接更新技能內容
            skillsContainer.innerHTML = this.createSkillIconsHTML(playerSkills);
            // console.log('✅ 技能顯示已更新:', playerSkills);
        } else {
            console.log('❌ 未找到技能顯示容器');
            
            // 備用方案：重新構建整個RPG狀態欄
            const rpgStatsContainer = document.getElementById('rpg-stats');
            if (rpgStatsContainer && window.gameEngine) {
                const gameState = {
                    level: window.gameEngine.level,
                    exp: window.gameEngine.exp,
                    expToNextLevel: window.gameEngine.expToNextLevel,
                    gold: window.gameEngine.gold,
                    actionPoints: window.gameEngine.actionPoints,
                    playerSkills: playerSkills,
                    hasTimer: window.gameEngine.config.hasTimer,
                    isSurvivalMode: window.gameEngine.config.isSurvivalMode,
                    survivalTime: window.gameEngine.survivalTime || 0,
                    targetSurvivalTime: window.gameEngine.config.survivalConfig?.targetSurvivalTime || 180000
                };
                
                rpgStatsContainer.outerHTML = this.createRPGStatsHTML(gameState);
                console.log('✅ RPG狀態欄已重新構建，技能已更新');
            }
        }
    }
}

// 導出類
if (typeof module !== 'undefined' && module.exports) {
    module.exports = UIManager;
}