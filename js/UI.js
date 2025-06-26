class UIManager {
    static createGameHTML(mode, config) {
        const skillsSection = config.hasSkills ? this.createSkillsSection() : '';
        const timeDisplay = config.hasTimer ? 
            `${config.gameDuration / 1000}s` :
            `5`;
        
        const modalStats = mode !== 'timeLimit' ?
            `<div class="bg-slate-50 rounded-lg p-3 mb-4">
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
             </div>` :
            `<p class="text-slate-700 text-lg mb-2">最終分數: <span id="finalScore" class="font-bold text-sky-600">0</span></p>`;

        const modalBackButton = mode !== 'timeLimit' ?
            `<button id="modalBackToIntroButton" class="flex-1 bg-gray-500 hover:bg-gray-600 text-white font-medium py-2 px-3 text-sm rounded action-button">
                返回主選單
             </button>` : '';

        const modalButtonLayout = modalBackButton ?
            `<div class="flex gap-3">
                ${modalBackButton}
                <button id="modalRestartButton" class="flex-1 bg-green-500 hover:bg-green-600 text-white font-semibold py-2.5 px-4 rounded action-button">
                    再玩一次
                </button>
             </div>` :
            `<button id="modalRestartButton" class="bg-green-500 hover:bg-green-600 text-white font-semibold py-2.5 px-8 rounded action-button">
                再玩一次
             </button>`;

        return `
        <div class="game-container bg-white/80 backdrop-blur-md rounded-xl shadow-xl">
            <!-- 遊戲控制欄 - 簡化版本 -->
            <div class="flex-shrink-0 bg-slate-100/50 rounded-t-xl px-3 py-2">
                <!-- 控制項：技能、統計資訊、主選單 -->
                <div class="flex items-center justify-between">
                    <!-- 技能區域 -->
                    ${skillsSection}
                    
                    <!-- 統計資訊 - 置中對齊 -->
                    <div class="flex-1 flex justify-center">
                        <div class="flex gap-6 text-center text-xs">
                            <div>
                                <p class="text-slate-600">分數</p>
                                <p id="score" class="text-sm font-bold text-sky-600">0</p>
                            </div>
                            <div>
                                <p class="text-slate-600">連擊</p>
                                <p id="combo" class="text-sm font-bold text-emerald-600">0</p>
                            </div>
                            ${(config.actionPointsStart !== undefined && config.actionPointsStart > 0) ? `
                            <div>
                                <p class="text-slate-600">行動</p>
                                <p id="action-points" class="text-sm font-bold text-purple-600">${config.actionPointsStart}</p>
                            </div>
                            ` : ''}
                        </div>
                    </div>
                    
                    <!-- 主選單按鈕 - 對所有模式都顯示 -->
                    <button id="backToIntroButton" class="bg-gray-500 hover:bg-gray-600 text-white p-2 rounded-full action-button w-8 h-8 flex items-center justify-center" title="主選單">
                        <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                            <path d="M10.707 2.293a1 1 0 00-1.414 0l-7 7a1 1 0 001.414 1.414L4 10.414V17a1 1 0 001 1h2a1 1 0 001-1v-2a1 1 0 011-1h2a1 1 0 011 1v2a1 1 0 001 1h2a1 1 0 001-1v-6.586l.293.293a1 1 0 001.414-1.414l-7-7z"/>
                        </svg>
                    </button>
                </div>
            </div>
            
            <!-- 時間顯示區 -->
            ${config.hasTimer ? `
            <div class="timer-display-area p-2 bg-slate-100/30">
                <div class="relative w-full h-5 bg-slate-300/50 rounded-full overflow-hidden shadow-inner">
                    <div id="time-progress-bar" class="h-full bg-gradient-to-r from-sky-400 to-cyan-400 rounded-full transition-all duration-200 ease-linear" style="width: 100%;"></div>
                    <p id="time-left" class="absolute inset-0 flex items-center justify-center text-xs font-bold text-white text-shadow">${(config.gameDuration / 1000).toFixed(0)}s</p>
                </div>
            </div>
            ` : ''}

            <!-- 遊戲畫布區域 - 最大化空間，下個方塊預覽將在Canvas內顯示 -->
            <div class="flex-grow flex items-center justify-center game-canvas-area">
                <canvas id="gameCanvas" class="rounded-lg max-w-full max-h-full"></canvas>
                <!-- 隱藏的下個方塊預覽容器，供遊戲引擎使用 -->
                <div id="nextBlockPreviewContainer" class="hidden"></div>
            </div>
        </div>

        <!-- 遊戲結束彈窗 -->
        <div id="gameOverModal" class="modal">
            <div class="modal-content">
                <h2 class="text-2xl font-bold text-rose-500 mb-3">${config.hasTimer ? '時間到！' : '遊戲結束！'}</h2>
                
                ${modalStats}
                
                <p class="text-slate-500 mb-4">再接再厲，挑戰更高分！</p>
                
                ${modalButtonLayout}
            </div>
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
}

// 導出類
if (typeof module !== 'undefined' && module.exports) {
    module.exports = UIManager;
} 