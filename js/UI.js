class UIManager {
    static createGameHTML(mode, config) {
        const headerHTML = (mode === 'quest') 
            ? this.createQuestHeaderHTML(config)
            : this.createStandardHeaderHTML(mode, config);

        const skillsSection = config.hasSkills ? this.createSkillsSection() : '';
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
                    ${skillsSection}
                    <button id="backToIntroButton" class="bg-gray-500 hover:bg-gray-600 text-white p-2 rounded-full action-button w-8 h-8 flex items-center justify-center" title="主選單">
                        <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path d="M10.707 2.293a1 1 0 00-1.414 0l-7 7a1 1 0 001.414 1.414L4 10.414V17a1 1 0 001 1h2a1 1 0 001-1v-2a1 1 0 011-1h2a1 1 0 011 1v2a1 1 0 001 1h2a1 1 0 001-1v-6.586l.293.293a1 1 0 001.414-1.414l-7-7z"/></svg>
                    </button>
                </div>
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
            
            <!-- 中間部：敵人圖片和血條 -->
            <div class="px-3 pb-2">
                <div class="flex items-center gap-3">
                    <div class="w-16 h-16 flex-shrink-0">
                        <img id="enemy-image" src="${enemyImageSrc}" alt="${enemy.name}" class="w-full h-full object-contain transition-transform duration-100">
                    </div>
                    <div class="flex-1">
                        <div class="w-full bg-gray-600 rounded-full h-4 border border-gray-500 shadow-inner">
                            <div id="enemy-hp-bar" class="bg-gradient-to-r from-red-500 to-red-700 h-full rounded-full transition-all duration-300 ease-out flex items-center justify-end pr-1">
                                <span id="enemy-hp-text" class="text-xs font-bold text-white text-shadow">${enemy.maxHP}/${enemy.maxHP}</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- 下半部：限制條件顯示 -->
            ${restrictionsDisplay ? `
            <div id="quest-restrictions-display" class="px-3 pb-2">
                <div class="bg-slate-900/50 rounded-md px-2 py-1">
                    ${restrictionsDisplay}
                </div>
            </div>
            ` : ''}
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
        return `
        <div class="flex gap-1">
            <div class="relative">
                <button id="skillRemoveSingle" class="skill-button bg-red-500 hover:bg-red-600 text-white p-2 rounded-full w-8 h-8 flex items-center justify-center" title="移除單個方塊">
                    <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
                    </svg>
                </button>
                <span id="skillRemoveSingleUses" class="skill-badge">3</span>
            </div>
            <div class="relative">
                <button id="skillRerollNext" class="skill-button bg-amber-500 hover:bg-amber-600 text-white p-2 rounded-full w-8 h-8 flex items-center justify-center" title="重骰下個方塊">
                    <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1 0 01-1-1V3a1 1 0 011-1zm.008 9.057a1 1 0 011.276.61A5.002 5.002 0 0014.001 13H11a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0v-2.101a7.002 7.002 0 01-11.601-2.566 1 1 0 01.61-1.276z" clip-rule="evenodd"/>
                    </svg>
                </button>
                <span id="skillRerollNextUses" class="skill-badge">3</span>
            </div>
            <div class="relative">
                <button id="skillRerollBoard" class="skill-button bg-purple-500 hover:bg-purple-600 text-white p-2 rounded-full w-8 h-8 flex items-center justify-center" title="變色板面">
                    <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M4 3a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V5a2 2 0 00-2-2H4zm12 12H4l4-8 3 6 2-4 3 6z" clip-rule="evenodd"/>
                    </svg>
                </button>
                <span id="skillRerollBoardUses" class="skill-badge">3</span>
            </div>
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
                break;
            case 'quest_loss':
                titleEl.textContent = '失敗';
                titleEl.className = 'text-2xl font-bold text-red-500 mb-3';
                messageEl.textContent = '步數用盡，再試一次吧！';
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
}

// 導出類
if (typeof module !== 'undefined' && module.exports) {
    module.exports = UIManager;
} 