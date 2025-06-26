const GameModes = {
    tutorial: {
        numCols: 1,
        numRows: 10,
        theme: 'classic',
        hasSkills: true,
        hasTimer: false,
        enableHorizontalMatches: false,
        blockWidthPercent: 0.65,
        title: '三消挑戰 - 教學模式',
        description: '學習遊戲操作的教學模式',
        // 教學模式的分數系統（簡化版）
        scoring: {
            baseScore: 10,
            comboMultiplier: 0.5,
            chainMultiplier: 2,
            comboMilestones: {
                3: 50,
                5: 100,
                10: 200
            }
        }
    },
    
    classic: {
        numCols: 1,
        numRows: 10,
        theme: 'classic',
        hasSkills: true,
        hasTimer: false,
        actionPointsStart: 5,
        enableHorizontalMatches: false,
        blockWidthPercent: 0.65,
        title: '三消挑戰',
        description: '經典單排模式',
        // 連擊分數系統
        scoring: {
            baseScore: 10,              // 基礎分數（每個消除方塊）
            comboMultiplier: 0.5,       // 連擊倍數（每次連擊增加 50%）
            chainMultiplier: 2,         // 連鎖倍數（同一回合內的連鎖反應）
            comboMilestones: {          // 連擊里程碑獎勵
                5: 100,    // 5連擊獎勵 100 分
                10: 300,   // 10連擊獎勵 300 分
                15: 500,   // 15連擊獎勵 500 分
                20: 1000,  // 20連擊獎勵 1000 分
                30: 2000   // 30連擊獎勵 2000 分
            }
        }
    },
    
    double: {
        numCols: 2,
        numRows: 10,
        theme: 'double',
        hasSkills: true,
        hasTimer: false,
        actionPointsStart: 5,
        enableHorizontalMatches: false,
        title: '雙排挑戰',
        description: '快速雙排模式',
        // 連擊分數系統
        scoring: {
            baseScore: 15,              // 雙排模式基礎分數較高
            comboMultiplier: 0.6,       // 連擊倍數稍高
            chainMultiplier: 2.5,       // 連鎖倍數較高
            comboMilestones: {          
                5: 150,    
                10: 400,   
                15: 750,   
                20: 1500,  
                30: 3000   
            }
        }
    },
    
    triple: {
        numCols: 3,
        numRows: 10,
        theme: 'triple',
        hasSkills: true,
        hasTimer: false,
        actionPointsStart: 5,
        enableHorizontalMatches: true,
        title: '三排挑戰',
        description: '進階三排模式',
        // 連擊分數系統
        scoring: {
            baseScore: 20,              // 三排模式基礎分數最高
            comboMultiplier: 0.7,       // 連擊倍數最高
            chainMultiplier: 3,         // 連鎖倍數最高
            comboMilestones: {          
                5: 200,    
                10: 500,   
                15: 1000,   
                20: 2000,  
                30: 4000   
            }
        }
    },
    
    tripleTimeAttack: {
        numCols: 3,
        numRows: 10,
        theme: 'triple',
        hasSkills: true,
        hasTimer: true,
        gameDuration: 120000, // 180 秒
        actionPointsStart: 3,
        enableHorizontalMatches: true,
        title: '三排限時強攻',
        description: '120秒內挑戰三排模式，只有3次失誤機會。',
        // 連擊分數系統
        scoring: {
            baseScore: 20,              // 三排模式基礎分數最高
            comboMultiplier: 0.7,       // 連擊倍數最高
            chainMultiplier: 3,         // 連鎖倍數最高
            comboMilestones: {          
                5: 200,    
                10: 500,   
                15: 1000,   
                20: 2000,  
                30: 4000   
            }
        }
    },
    
    timeLimit: {
        numCols: 3,
        numRows: 10,
        theme: 'time',
        hasSkills: false,
        hasTimer: true,
        gameDuration: 45000,
        actionPointsStart: 0, // 覆蓋 GameEngine 的預設值，表示沒有行動點限制
        enableHorizontalMatches: true,
        title: '45秒限時挑戰',
        description: '限時挑戰模式',
        // 連擊分數系統（限時模式分數更豐厚）
        scoring: {
            baseScore: 25,              // 限時模式基礎分數最高
            comboMultiplier: 1.0,       // 連擊倍數翻倍
            chainMultiplier: 4,         // 連鎖倍數最高
            comboMilestones: {          
                3: 200,    // 限時模式門檻較低
                5: 500,    
                10: 1000,   
                15: 2500,   
                20: 5000   
            }
        }
    }
};

// 導出模式配置
if (typeof module !== 'undefined' && module.exports) {
    module.exports = GameModes;
} 