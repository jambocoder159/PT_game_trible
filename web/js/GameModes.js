// 版本控制 - 防止瀏覽器緩存舊版本
const CONFIG_VERSION = "element_system_v1.0";
console.log("🔄 載入遊戲模式配置版本:", CONFIG_VERSION);

// 元素系統定義 - 五色對應五元素
window.ELEMENTS = {
    red:    { name: '火焰', icon: '🔥', type: 'fire',    color: '#F87171' },
    blue:   { name: '寒冰', icon: '💧', type: 'water',   color: '#60A5FA' },
    green:  { name: '自然', icon: '🌿', type: 'nature',  color: '#4ADE80' },
    yellow: { name: '雷電', icon: '⚡', type: 'thunder', color: '#FACC15' },
    purple: { name: '魔法', icon: '✨', type: 'magic',   color: '#A78BFA' }
};

// 元素相剋關係（用於提示，不影響數值）
window.ELEMENT_WEAKNESS = {
    fire:    'water',   // 火怕水
    water:   'thunder', // 水怕雷
    nature:  'fire',    // 自然怕火
    thunder: 'nature',  // 雷怕自然
    magic:   null       // 魔法無弱點
};

// 將限制條件轉為元素世界觀語言
window.getElementRestrictionText = function(restrictions) {
    if (!restrictions || Object.keys(restrictions).length === 0) return [];
    const texts = [];

    if (restrictions.damageOnlyColors) {
        const elements = restrictions.damageOnlyColors.map(c => ELEMENTS[c]);
        const names = elements.map(e => `${e.icon} ${e.name}`).join(' ');
        texts.push({ type: 'weakness', text: `弱點：${names}` });
    }
    if (restrictions.noDamageColors) {
        const elements = restrictions.noDamageColors.map(c => ELEMENTS[c]);
        const names = elements.map(e => `${e.icon} ${e.name}`).join(' ');
        texts.push({ type: 'resist', text: `抗性：${names}免疫` });
    }
    if (restrictions.minComboForDamage) {
        texts.push({ type: 'shield', text: `🛡️ 護盾：需${restrictions.minComboForDamage}連擊破防` });
    }
    if (restrictions.minChainForDamage) {
        texts.push({ type: 'shield', text: `🔗 連鎖護盾：需${restrictions.minChainForDamage}連鎖破防` });
    }
    return texts;
};

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
    
    tripleActionTimer: {
        numCols: 3,
        numRows: 10,
        theme: 'rpg',
        hasSkills: true,
        hasTimer: true,
        hasRPGSystem: true,
        isSurvivalMode: true, // 新增：存活模式標誌
        gameDuration: 8000, // 基礎13秒，每次操作後重置
        actionPointsStart: 5, // RPG模式也有行動點，計時結束時扣除
        enableHorizontalMatches: true,
        title: '三排生存RPG',
        description: '存活3分鐘！在階段性挑戰中生存並成長，獲得更強大的技能！（最大上限：3分鐘）',
        // RPG模式分數系統
        scoring: {
            baseScore: 15,              // 中等基礎分數
            comboMultiplier: 0.6,       // 中等連擊倍數
            chainMultiplier: 2.5,       // 中等連鎖倍數
            comboMilestones: {          
                5: 150,    
                10: 400,   
                15: 800,   
                20: 1600,  
                30: 3200   
            }
        },
        // RPG系統配置
        rpgConfig: {
            initialLevel: 1,
            maxLevel: 20, // 擴增到二十級
            baseTimer: 8, // 基礎計時器時間（秒）
            timerReductionPerLevel: 0.2, // 降低每升級的減少量
            minTimer: 5 // 提高最低計時器時間
        },
        // 存活模式配置
        survivalConfig: {
            targetSurvivalTime: 180000, // 3分鐘 = 180,000毫秒 = 180秒
            challengeMilestones: [60000, 120000, 150000], // 1分鐘、2分鐘、2.5分鐘
            challengeTypes: [
                {
                    type: 'blackenBlocks',
                    name: '黑色方塊',
                    description: '2顆方塊變成黑色，等3次消除自然解除',
                    difficulty: 1,
                    blocksCount: 2,
                    clearancesRequired: 3
                },
                {
                    type: 'blackenBlocks',
                    name: '黑色方塊',
                    description: '3顆方塊變成黑色，等4次消除自然解除',
                    difficulty: 2,
                    blocksCount: 3,
                    clearancesRequired: 4
                },
                {
                    type: 'blackenBlocks',
                    name: '黑色方塊',
                    description: '5顆方塊變成黑色，等5次消除自然解除',
                    difficulty: 3,
                    blocksCount: 5,
                    clearancesRequired: 5
                }
            ]
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
                description: "森林中最弱小的魔物，全身由自然元素凝聚而成。",
                element: 'nature',
                maxHP: 30,
                moves: 20
                // 無限制 - 讓新手熟悉基本玩法
            },
            2: {
                name: "小莫菇",
                description: "呆萌的小蘑菇，體內蘊含微弱的自然之力。",
                element: 'nature',
                maxHP: 40,
                moves: 18
                // 無限制 - 繼續熟悉操作
            },
            3: {
                name: "林精靈",
                description: "友善的森林精靈，操控著輕柔的自然元素。",
                element: 'nature',
                maxHP: 50,
                moves: 16
                // 無限制 - 最後一關無限制練習
            },
            
            // 【第二階段：引入限制】- 單一簡單限制
            4: {
                name: "影蜥",
                description: "潛伏暗影的蜥蜴，身披雷電鱗甲，雷系攻擊對其無效。",
                element: 'thunder',
                maxHP: 60,
                moves: 16,
                restrictions: {
                    noDamageColors: ['yellow']  // 黃色（雷電）無效
                }
            },
            5: {
                name: "森林護衛",
                description: "森林的守護者，堅硬的樹皮護盾需要連續攻擊才能擊破。",
                element: 'nature',
                maxHP: 75,
                moves: 15,
                restrictions: {
                    minComboForDamage: 2  // 需要連擊2次以上
                }
            },
            6: {
                name: "水靈",
                description: "純淨的水元素精靈，唯有同屬寒冰之力才能引起共鳴造成傷害。",
                element: 'water',
                maxHP: 85,
                moves: 15,
                restrictions: {
                    damageOnlyColors: ['blue']  // 僅寒冰有效
                }
            },
            
            // 【第三階段：進階限制】- 更具挑戰性的單一限制
            7: {
                name: "風元素",
                description: "飄忽不定的雷風精靈，需要強力的連續攻擊才能擊中其虛幻的身軀。",
                element: 'thunder',
                maxHP: 100,
                moves: 14,
                restrictions: {
                    minComboForDamage: 3  // 需要連擊3次以上
                }
            },
            8: {
                name: "火焰術士",
                description: "操控烈焰的法師，火焰與雷電的攻擊會被其吸收轉化。",
                element: 'fire',
                maxHP: 110,
                moves: 14,
                restrictions: {
                    noDamageColors: ['red', 'yellow']  // 火焰和雷電無效
                }
            },
            9: {
                name: "森林賢者",
                description: "古老的森林智者，與大地共鳴，唯有自然之力能觸及其本質。",
                element: 'nature',
                maxHP: 120,
                moves: 13,
                restrictions: {
                    damageOnlyColors: ['green'],  // 僅自然有效
                    minComboForDamage: 2  // 需要連擊2次以上
                }
            },
            
            // 【第四階段：最終挑戰】- 複合限制
            10: {
                name: "森林之王尤羅德",
                description: "沉睡千年的森林古王，融合了寒冰與自然之力，唯有同屬元素才能撼動其根基。",
                element: 'nature',
                maxHP: 150,
                moves: 12,
                restrictions: {
                    damageOnlyColors: ['blue', 'green'],  // 僅寒冰和自然有效
                    minComboForDamage: 3  // 需要連擊3次以上
                }
            },
            
            // 【第二章：熔岩洞窟】(11-20關)
            11: {
                name: "火焰蜥蜴",
                description: "身披烈焰鱗甲的洞窟守衛，火系攻擊會被其鱗片吸收。",
                element: 'fire',
                maxHP: 180,
                moves: 15,
                restrictions: {
                    noDamageColors: ['red']  // 火焰免疫
                }
            },
            12: {
                name: "熔岩史萊姆",
                description: "由滾燙熔岩凝聚的史萊姆，高溫護盾需要連續攻擊才能擊破。",
                element: 'fire',
                maxHP: 200,
                moves: 14,
                restrictions: {
                    minComboForDamage: 2  // 需要連擊2次以上
                }
            },
            13: {
                name: "岩漿元素",
                description: "純粹的岩漿生命體，唯有寒冰之力能凝固其灼熱的核心。",
                element: 'fire',
                maxHP: 220,
                moves: 14,
                restrictions: {
                    damageOnlyColors: ['blue']  // 僅寒冰有效
                }
            },
            14: {
                name: "火山蠑螈",
                description: "棲息於岩漿河的古老爬蟲，火焰與雷電皆為其養分。",
                element: 'fire',
                maxHP: 240,
                moves: 13,
                restrictions: {
                    noDamageColors: ['red', 'yellow']  // 火焰和雷電免疫
                }
            },
            15: {
                name: "烈焰戰士",
                description: "手持火焰之劍的精銳戰士，強韌的戰意需要猛烈的連擊才能壓制。",
                element: 'fire',
                maxHP: 260,
                moves: 13,
                restrictions: {
                    minComboForDamage: 3  // 需要連擊3次以上
                }
            },
            16: {
                name: "炎魔術師",
                description: "將烈焰化為魔法的術師，唯有自然的生命力能淨化其黑炎。",
                element: 'fire',
                maxHP: 280,
                moves: 12,
                restrictions: {
                    damageOnlyColors: ['green'],  // 僅自然有效
                    minComboForDamage: 2  // 需要連擊2次以上
                }
            },
            17: {
                name: "熔岩巨人",
                description: "巨大的岩石生物，熔岩構成的身軀堅不可摧，需要不斷的猛攻。",
                element: 'fire',
                maxHP: 300,
                moves: 12,
                restrictions: {
                    minComboForDamage: 2  // 需要連擊2次以上
                }
            },
            18: {
                name: "火焰獨眼巨人",
                description: "獨眼噴射灼熱光束的火焰巨獸，唯有寒冰之力能封印其烈焰之瞳。",
                element: 'fire',
                maxHP: 320,
                moves: 11,
                restrictions: {
                    damageOnlyColors: ['blue'],  // 僅寒冰有效
                    minComboForDamage: 3  // 需要連擊3次以上
                }
            },
            19: {
                name: "地獄看門犬",
                description: "三頭地獄犬，融合了火焰與暗影之力，唯有寒冰與自然能壓制其凶焰。",
                element: 'fire',
                maxHP: 350,
                moves: 11,
                restrictions: {
                    damageOnlyColors: ['blue', 'green'],  // 僅寒冰和自然有效
                    minComboForDamage: 4  // 需要連擊4次以上
                }
            },
            20: {
                name: "熔岩龍王炎帝",
                description: "洞窟深處的炎龍至尊，烈焰王座的主人，唯有最純粹的寒冰之力才能觸及其逆鱗。",
                element: 'fire',
                maxHP: 400,
                moves: 10,
                restrictions: {
                    damageOnlyColors: ['blue'],  // 僅寒冰有效
                    minComboForDamage: 4  // 需要連擊4次以上
                }
            },
            
            // 【第三章：天空之城】(21-30關)
            21: {
                name: "風元素精靈",
                description: "飄渺的雷風精靈，身軀由風暴凝聚，雷電攻擊只會穿透其虛幻之身。",
                element: 'thunder',
                maxHP: 450,
                moves: 12,
                restrictions: {
                    noDamageColors: ['yellow']  // 雷電免疫
                }
            },
            22: {
                name: "雷電鳥",
                description: "翱翔雲端的雷霆神禽，高速飛行的身影需要連續猛攻才能命中。",
                element: 'thunder',
                maxHP: 480,
                moves: 12,
                restrictions: {
                    minComboForDamage: 3  // 需要連擊3次以上
                }
            },
            23: {
                name: "雲中仙鶴",
                description: "棲息於雲海的神聖仙鶴，唯有自然之力能觸及其靈魂。",
                element: 'nature',
                maxHP: 500,
                moves: 11,
                restrictions: {
                    damageOnlyColors: ['green']  // 僅自然有效
                }
            },
            24: {
                name: "天空守護者",
                description: "天空之城的忠誠守衛，吸收火焰與雷電化為自身力量。",
                element: 'thunder',
                maxHP: 520,
                moves: 11,
                restrictions: {
                    noDamageColors: ['red', 'yellow']  // 火焰和雷電免疫
                }
            },
            25: {
                name: "雷神之鷹",
                description: "承載雷神之力的神鷹，狂暴的雷霆護體需要極致的連擊才能貫穿。",
                element: 'thunder',
                maxHP: 550,
                moves: 10,
                restrictions: {
                    minComboForDamage: 4  // 需要連擊4次以上
                }
            },
            26: {
                name: "風暴法師",
                description: "操控風暴的至高法師，唯有寒冰之力能凍結其風暴核心。",
                element: 'thunder',
                maxHP: 580,
                moves: 10,
                restrictions: {
                    damageOnlyColors: ['blue'],  // 僅寒冰有效
                    minComboForDamage: 3  // 需要連擊3次以上
                }
            },
            27: {
                name: "天空巨龍",
                description: "翱翔天際的遠古巨龍，堅韌的龍鱗需要不懈的連續攻擊才能擊穿。",
                element: 'thunder',
                maxHP: 600,
                moves: 9,
                restrictions: {
                    minComboForDamage: 3  // 需要連擊3次以上
                }
            },
            28: {
                name: "雲中幻獸",
                description: "神秘的幻影生物，唯有寒冰與自然的雙重力量能令其現出真身。",
                element: 'magic',
                maxHP: 650,
                moves: 9,
                restrictions: {
                    damageOnlyColors: ['blue', 'green'],  // 僅寒冰和自然有效
                    minComboForDamage: 4  // 需要連擊4次以上
                }
            },
            29: {
                name: "天界守門神",
                description: "天空之城的最終守護者，唯有自然的生命力能撼動其神聖的意志。",
                element: 'magic',
                maxHP: 700,
                moves: 8,
                restrictions: {
                    damageOnlyColors: ['green'],  // 僅自然有效
                    minComboForDamage: 5  // 需要連擊5次以上
                }
            },
            30: {
                name: "天空霸主蒼龍帝",
                description: "統御蒼穹的龍族至尊，萬物之力皆為其所用，唯有最純粹的寒冰能觸及其驕傲的龍心。",
                element: 'magic',
                maxHP: 800,
                moves: 8,
                restrictions: {
                    damageOnlyColors: ['blue'],  // 僅寒冰有效
                    minComboForDamage: 5  // 需要連擊5次以上
                }
            }
        }
    }
};

// 導出模式配置
if (typeof module !== 'undefined' && module.exports) {
    module.exports = GameModes;
} 