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
        gameDuration: 120000, // 120 秒
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
        hasSkills: true,
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
                    minComboForDamage: 3  // 需要連擊3次以上
                    // requireHorizontalMatch: true  // 僅橫向消除有效 (功能未實現)
                }
            },
            
            // 【第二章：熔岩洞窟】(11-20關)
            11: {
                name: "火焰蜥蜴",
                description: "洞窟中的火焰守衛，身體散發灼熱的溫度。",
                maxHP: 180,
                moves: 15,
                restrictions: {
                    noDamageColors: ['red']  // 紅色無效
                }
            },
            12: {
                name: "熔岩史萊姆",
                description: "由熔岩形成的史萊姆，需要強力的連擊才能擊破。",
                maxHP: 200,
                moves: 14,
                restrictions: {
                    minComboForDamage: 2  // 需要連擊2次以上
                }
            },
            13: {
                name: "岩漿元素",
                description: "純粹的岩漿生物，只對冰寒的藍色能量脆弱。",
                maxHP: 220,
                moves: 14,
                restrictions: {
                    damageOnlyColors: ['blue']  // 僅藍色有效
                }
            },
            14: {
                name: "火山蠑螈",
                description: "棲息在高溫環境的爬蟲，害怕水和自然的力量。",
                maxHP: 240,
                moves: 13,
                restrictions: {
                    noDamageColors: ['red', 'yellow']  // 紅色和黃色無效
                }
            },
            15: {
                name: "烈焰戰士",
                description: "手持火焰之劍的戰士，需要完美的連擊組合才能擊敗。",
                maxHP: 260,
                moves: 13,
                restrictions: {
                    minComboForDamage: 3  // 需要連擊3次以上
                }
            },
            16: {
                name: "炎魔術師",
                description: "掌控烈焰的法師，只有純淨的綠色自然力量能傷害它。",
                maxHP: 280,
                moves: 12,
                restrictions: {
                    damageOnlyColors: ['green'],  // 僅綠色有效
                    minComboForDamage: 2  // 需要連擊2次以上
                }
            },
            17: {
                name: "熔岩巨人",
                description: "巨大的岩石生物，身體堅硬如鐵，需要強力的攻擊。",
                maxHP: 300,
                moves: 12,
                restrictions: {
                    // requireHorizontalMatch: true,  // 僅橫向消除有效 (功能未實現)
                    minComboForDamage: 2  // 需要連擊2次以上
                }
            },
            18: {
                name: "火焰獨眼巨人",
                description: "單眼的火焰巨獸，害怕藍色的冰寒力量和連續攻擊。",
                maxHP: 320,
                moves: 11,
                restrictions: {
                    damageOnlyColors: ['blue'],  // 僅藍色有效
                    minComboForDamage: 3,  // 需要連擊3次以上
                    //requireHorizontalMatch: true  // 僅橫向消除有效
                }
            },
            19: {
                name: "地獄看門犬",
                description: "三頭地獄犬，需要同時滿足多種條件才能傷害。",
                maxHP: 350,
                moves: 11,
                restrictions: {
                    damageOnlyColors: ['blue', 'green'],  // 僅藍綠色有效
                    minComboForDamage: 4,  // 需要連擊4次以上
                }
            },
            20: {
                name: "熔岩龍王炎帝",
                description: "洞窟深處的炎龍之王，掌握最強的火焰力量，需要極致的戰鬥技巧。",
                maxHP: 400,
                moves: 10,
                restrictions: {
                    damageOnlyColors: ['blue'],  // 僅藍色有效
                    minComboForDamage: 4,  // 需要連擊4次以上
                    // requireHorizontalMatch: true  // 僅橫向消除有效
                }
            },
            
            // 【第三章：天空之城】(21-30關)
            21: {
                name: "風元素精靈",
                description: "飄渺的風之精靈，身形輕盈難以捕捉。",
                maxHP: 450,
                moves: 12,
                restrictions: {
                    noDamageColors: ['yellow']  // 黃色無效
                }
            },
            22: {
                name: "雷電鳥",
                description: "掌控雷電的神鳥，需要強力連擊才能擊中。",
                maxHP: 480,
                moves: 12,
                restrictions: {
                    minComboForDamage: 3  // 需要連擊3次以上
                }
            },
            23: {
                name: "雲中仙鶴",
                description: "生活在雲端的仙鶴，只對綠色的自然力量有反應。",
                maxHP: 500,
                moves: 11,
                restrictions: {
                    damageOnlyColors: ['green']  // 僅綠色有效
                }
            },
            24: {
                name: "天空守護者",
                description: "天空之城的守衛，害怕特定的能量組合。",
                maxHP: 520,
                moves: 11,
                restrictions: {
                    noDamageColors: ['red', 'yellow']  // 紅色和黃色無效
                }
            },
            25: {
                name: "雷神之鷹",
                description: "帶有神力的巨鷹，需要完美的連擊技巧。",
                maxHP: 550,
                moves: 10,
                restrictions: {
                    minComboForDamage: 4  // 需要連擊4次以上
                }
            },
            26: {
                name: "風暴法師",
                description: "操控風暴的強大法師，只對純淨的藍色力量脆弱。",
                maxHP: 580,
                moves: 10,
                restrictions: {
                    damageOnlyColors: ['blue'],  // 僅藍色有效
                    minComboForDamage: 3  // 需要連擊3次以上
                }
            },
            27: {
                name: "天空巨龍",
                description: "翱翔天際的巨龍，需要橫向的強力攻擊才能擊中。",
                maxHP: 600,
                moves: 9,
                restrictions: {
                    // requireHorizontalMatch: true,  // 僅橫向消除有效
                    minComboForDamage: 3  // 需要連擊3次以上
                }
            },
            28: {
                name: "雲中幻獸",
                description: "神秘的幻想生物，需要同時滾足多種嚴格條件。",
                maxHP: 650,
                moves: 9,
                restrictions: {
                    damageOnlyColors: ['blue', 'green'],  // 僅藍綠色有效
                    minComboForDamage: 4,  // 需要連擊4次以上
                    // requireHorizontalMatch: true  // 僅橫向消除有效
                }
            },
            29: {
                name: "天界守門神",
                description: "天空之城的最後守護者，力量接近神明。",
                maxHP: 700,
                moves: 8,
                restrictions: {
                    damageOnlyColors: ['green'],  // 僅綠色有效
                    minComboForDamage: 5,  // 需要連擊5次以上
                    // requireHorizontalMatch: true  // 僅橫向消除有效
                }
            },
            30: {
                name: "天空霸主蒼龍帝",
                description: "統治天空的蒼龍皇帝，傳說中最強的存在，需要超越極限的戰鬥技巧。",
                maxHP: 800,
                moves: 8,
                restrictions: {
                    damageOnlyColors: ['blue'],  // 僅藍色有效
                    minComboForDamage: 5,  // 需要連擊5次以上
                    // requireHorizontalMatch: true  // 僅橫向消除有效
                }
            }
        }
    }
};

// 導出模式配置
if (typeof module !== 'undefined' && module.exports) {
    module.exports = GameModes;
} 