window.GameModes = {
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
    },

    quest: {
        numCols: 3,
        numRows: 10,
        theme: 'quest',
        hasSkills: false,
        hasTimer: false,
        blockHeight: 40, // 為闖關模式設定合理的方塊高度
        enableHorizontalMatches: true,
        title: '闖關模式',
        description: '擊敗敵人以獲得勝利',
        // 在闖關模式中，分數也等同於對敵人的傷害
        scoring: {
            baseScore: 1, // 基礎傷害
            comboMultiplier: 0.2,
            chainMultiplier: 1.5,
            comboMilestones: {
                5: 10,
                10: 25,
                15: 50
            }
        },
        // 關卡特定數據（這些值將在遊戲初始化時被特定關卡覆寫）
        levelData: {
            moves: 15, // 預設步數
            enemy: {
                name: '史萊姆',
                maxHP: 100,
                asset: 'slime.png' // 預設敵人圖片
            }
        },
        levelDetails: {
            // 【第一階段：新手教學】- 無限制，學習基本操作
            1: {
                name: "森林史萊姆",
                description: "森林中最弱小的魔物，是學習戰鬥的最佳對象。",
                maxHP: 30,
                moves: 20
                // 無限制 - 讓新手熟悉基本玩法
            },
            2: {
                name: "小莫菇",
                description: "呆萌的小蘑菇，偶爾會釋放無害的孢子。",
                maxHP: 40,
                moves: 18
                // 無限制 - 繼續熟悉操作
            },
            3: {
                name: "林精靈",
                description: "友善的森林精靈，只是想和你玩耍一下。",
                maxHP: 50,
                moves: 16
                // 無限制 - 最後一關無限制練習
            },
            
            // 【第二階段：引入限制】- 單一簡單限制
            4: {
                name: "影蜥",
                description: "躲在陰影中的蜥蜴，害怕明亮的黃光。",
                maxHP: 60,
                moves: 16,
                restrictions: {
                    noDamageColors: ['yellow']  // 黃色無效 - 最簡單的限制
                }
            },
            5: {
                name: "森林護衛",
                description: "森林的守護者，只有連續攻擊才能突破防禦。",
                maxHP: 75,
                moves: 15,
                restrictions: {
                    minComboForDamage: 2  // 需要連擊2次以上
                }
            },
            6: {
                name: "水靈",
                description: "純淨的水元素，只對冰寒的藍色能量有反應。",
                maxHP: 85,
                moves: 15,
                restrictions: {
                    damageOnlyColors: ['blue']  // 僅藍色有效
                }
            },
            
            // 【第三階段：進階限制】- 更具挑戰性的單一限制
            7: {
                name: "風元素",
                description: "飄忽不定的風精靈，需要強力的連擊才能捕捉。",
                maxHP: 100,
                moves: 14,
                restrictions: {
                    minComboForDamage: 3  // 需要連擊3次以上
                }
            },
            8: {
                name: "火焰術士",
                description: "掌控火焰的法師，害怕水和大地的力量。",
                maxHP: 110,
                moves: 14,
                restrictions: {
                    noDamageColors: ['red', 'yellow']  // 紅色和黃色無效
                }
            },
            9: {
                name: "森林賢者",
                description: "古老的森林智者，只有自然的綠色能量能傷害它。",
                maxHP: 120,
                moves: 13,
                restrictions: {
                    damageOnlyColors: ['green'],  // 僅綠色有效
                    minComboForDamage: 2  // 需要連擊2次以上
                }
            },
            
            // 【第四階段：最終挑戰】- 複合限制
            10: {
                name: "森林之王尤羅德",
                description: "沉睡千年的森林古王，掌握所有自然力量，需要完美的戰鬥技巧才能擊敗。",
                maxHP: 150,
                moves: 12,
                restrictions: {
                    damageOnlyColors: ['blue', 'green'],  // 僅藍綠色有效
                    minComboForDamage: 3,  // 需要連擊3次以上
                    requireHorizontalMatch: true  // 僅橫向消除有效
                }
            }
        }
    }
};

// 導出模式配置
if (typeof module !== 'undefined' && module.exports) {
    module.exports = GameModes;
} 