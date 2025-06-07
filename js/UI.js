class UIManager {
    static createGameHTML(mode, config) {
        const skillsSection = config.hasSkills ? this.createSkillsSection() : '';
        const timeDisplay = config.hasTimer ? 
            `<p class="text-xs">剩餘時間</p>
             <p id="time-left" class="text-lg text-rose-600">45</p>` :
            `<p class="text-xs">行動點</p>
             <p id="action-points" class="text-lg text-rose-600">5</p>`;
        
        const nextBlockLabel = config.numCols === 1 ? '下一個方塊' : '下個方塊';
        const nextBlockContainer = config.numCols === 1 ? 
            `<div id="nextBlockPreviewContainer" class="w-14 h-6 mx-auto border-2 border-slate-300/70"></div>` :
            `<div id="nextBlockPreviewContainer" class="flex justify-center items-center gap-2 h-6"></div>`;

        const backButton = mode !== 'timeLimit' ? 
            `<button id="backToIntroButton" class="flex-1 bg-gradient-to-r from-gray-500 to-slate-500 hover:from-gray-600 hover:to-slate-600 text-white font-semibold py-2 px-3 text-sm shadow-lg action-button">
                返回介紹
             </button>` : '';

        const modalBackButton = mode !== 'timeLimit' ?
            `<button id="modalBackToIntroButton" class="flex-1 bg-gradient-to-r from-gray-500 to-slate-500 hover:from-gray-600 hover:to-slate-600 text-white font-semibold py-2 px-3 text-sm shadow-md action-button">
                返回介紹
             </button>` : '';

        const buttonLayout = backButton ? 
            `<div class="flex gap-2 mt-3">
                ${backButton}
                <button id="restartButton" class="flex-1 bg-gradient-to-r from-blue-500 to-sky-500 hover:from-blue-600 hover:to-sky-600 text-white font-semibold py-2 px-3 text-sm shadow-lg action-button">
                    重新開始
                </button>
             </div>` :
            `<button id="restartButton" class="w-full mt-3 bg-gradient-to-r from-blue-500 to-sky-500 hover:from-blue-600 hover:to-sky-600 text-white font-semibold py-2 px-3 text-sm shadow-lg action-button">
                重新開始
             </button>`;

        const modalButtonLayout = modalBackButton ?
            `<div class="flex gap-3">
                ${modalBackButton}
                <button id="modalRestartButton" class="flex-1 bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600 text-white font-semibold py-2.5 px-4 shadow-md action-button">
                    再玩一次
                </button>
             </div>` :
            `<button id="modalRestartButton" class="bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600 text-white font-semibold py-2.5 px-8 shadow-md action-button">
                再玩一次
             </button>`;

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

        return `
        <div class="game-container bg-white/80 backdrop-blur-md rounded-2xl shadow-xl">
            <h1 class="text-xl font-bold text-center text-slate-800 mb-2 tracking-tight">${config.title}</h1>

            <div class="grid grid-cols-3 gap-2 mb-2 text-center">
                <div class="stat-item bg-slate-100/70 p-1.5 rounded-lg shadow">
                    <p class="text-xs">分數</p>
                    <p id="score" class="text-lg text-sky-600">0</p>
                </div>
                <div class="stat-item bg-slate-100/70 p-1.5 rounded-lg shadow">
                    <p class="text-xs">連擊</p>
                    <p id="combo" class="text-lg text-emerald-600">0</p>
                </div>
                <div class="stat-item bg-slate-100/70 p-1.5 rounded-lg shadow">
                    ${timeDisplay}
                </div>
            </div>

            <!-- 連擊分數詳情 -->
            <div id="comboScoreDetails" class="mb-2 bg-gradient-to-r from-amber-50 to-orange-50 rounded-lg p-1.5 shadow-sm border border-amber-200 opacity-0 transition-all duration-300 overflow-hidden max-h-0">
                <div class="grid grid-cols-2 gap-2 text-center text-xs">
                    <div>
                        <p class="text-amber-700">上次得分</p>
                        <p id="lastComboScore" class="text-sm font-bold text-amber-600">0</p>
                    </div>
                    <div>
                        <p class="text-amber-700">連擊獎勵</p>
                        <p id="totalComboBonus" class="text-sm font-bold text-orange-600">0</p>
                    </div>
                </div>
            </div>

            <div class="mb-2 text-center">
                <p class="text-xs text-slate-700 font-medium mb-1">${nextBlockLabel}</p>
                ${nextBlockContainer}
            </div>
            
            <canvas id="gameCanvas" class="rounded-xl"></canvas>

            ${skillsSection}

            ${buttonLayout}
        </div>

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
        <div class="mt-2 pt-2 border-t border-slate-300/50">
            <h2 class="text-sm font-semibold text-center text-slate-700 mb-2">道具技能</h2>
            <div class="grid grid-cols-3 gap-2">
                <button id="skillRemoveSingle" class="skill-button bg-red-500 hover:bg-red-600 text-white text-xs py-1.5 px-1 font-medium">
                    移除 <span id="skillRemoveSingleUses" class="skill-uses-badge">3</span>
                </button>
                <button id="skillRerollNext" class="skill-button bg-amber-500 hover:bg-amber-600 text-white text-xs py-1.5 px-1 font-medium">
                    重骰 <span id="skillRerollNextUses" class="skill-uses-badge">3</span>
                </button>
                <button id="skillRerollBoard" class="skill-button bg-purple-500 hover:bg-purple-600 text-white text-xs py-1.5 px-1 font-medium">
                    變色 <span id="skillRerollBoardUses" class="skill-uses-badge">3</span>
                </button>
            </div>
        </div>`;
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