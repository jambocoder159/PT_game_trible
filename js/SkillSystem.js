// 技能系統 - 統一管理所有技能定義
window.SkillSystem = {
    // 技能庫定義
    SkillLibrary: {
        'ADD_COMBO': {
            name: '連擊爆發',
            description: '立即增加 {value} 連擊數',
            icon: '💥',
            levels: [
                { level: 1, value: 5, cost: 80 },
                { level: 2, value: 10, cost: 200 },
                { level: 3, value: 15, cost: 350 },
                { level: 4, value: 20, cost: 550 },
                { level: 5, value: 25, cost: 800 }
            ]
        },
        'ADD_AP': {
            name: '行動增幅',
            description: '獲得額外 {value} 點行動點',
            icon: '⚡',
            levels: [
                { level: 1, value: 1, cost: 120 },
                { level: 2, value: 3, cost: 300 },
                { level: 3, value: 5, cost: 550 },
                { level: 4, value: 7, cost: 900 }
            ]
        },
        'COLOR_BONUS_RED': {
            name: '紅方塊強化',
            description: '所有紅方塊消除分數增加 {value}%',
            icon: '🔴',
            color: 'red',
            levels: [
                { level: 1, value: 10, cost: 100 },
                { level: 2, value: 20, cost: 250 },
                { level: 3, value: 30, cost: 450 },
                { level: 4, value: 40, cost: 700 }
            ]
        },
        'COLOR_BONUS_BLUE': {
            name: '藍方塊強化',
            description: '所有藍方塊消除分數增加 {value}%',
            icon: '🔵',
            color: 'blue',
            levels: [
                { level: 1, value: 10, cost: 100 },
                { level: 2, value: 20, cost: 250 },
                { level: 3, value: 30, cost: 450 },
                { level: 4, value: 40, cost: 700 }
            ]
        },
        'COLOR_BONUS_GREEN': {
            name: '綠方塊強化',
            description: '所有綠方塊消除分數增加 {value}%',
            icon: '🟢',
            color: 'green',
            levels: [
                { level: 1, value: 10, cost: 100 },
                { level: 2, value: 20, cost: 250 },
                { level: 3, value: 30, cost: 450 },
                { level: 4, value: 40, cost: 700 }
            ]
        },
        'COLOR_BONUS_YELLOW': {
            name: '黃方塊強化',
            description: '所有黃方塊消除分數增加 {value}%',
            icon: '🟡',
            color: 'yellow',
            levels: [
                { level: 1, value: 10, cost: 100 },
                { level: 2, value: 20, cost: 250 },
                { level: 3, value: 30, cost: 450 },
                { level: 4, value: 40, cost: 700 }
            ]
        },
        'COLOR_BONUS_PURPLE': {
            name: '紫方塊強化',
            description: '所有紫方塊消除分數增加 {value}%',
            icon: '🟣',
            color: 'purple',
            levels: [
                { level: 1, value: 10, cost: 100 },
                { level: 2, value: 20, cost: 250 },
                { level: 3, value: 30, cost: 450 },
                { level: 4, value: 40, cost: 700 }
            ]
        },
        'COMBO_MULTIPLIER_BONUS': {
            name: '連擊倍率強化',
            description: 'Combo 倍率增加 {value}%',
            icon: '📈',
            levels: [
                { level: 1, value: 10, cost: 150 },
                { level: 2, value: 20, cost: 350 },
                { level: 3, value: 30, cost: 600 },
                { level: 4, value: 40, cost: 950 }
            ]
        }
    },

    // 獲取技能的當前等級數據
    getSkillData(skillId, level = 1) {
        const skill = this.SkillLibrary[skillId];
        if (!skill) return null;
        
        const levelData = skill.levels.find(l => l.level === level);
        if (!levelData) return null;
        
        return {
            ...skill,
            currentLevel: levelData,
            description: skill.description.replace('{value}', levelData.value)
                .replace('{color}', skill.name.includes('方塊') ? '' : skill.color || '')
        };
    },

    // 獲取隨機技能選項（用於升級時選擇）
    getRandomSkillOptions(playerSkills = {}, count = 2) {
        const skillOptions = [];
        const skillIds = Object.keys(this.SkillLibrary);
        
        // 為每個技能ID創建選項
        for (const skillId of skillIds) {
            const currentLevel = playerSkills[skillId] || 0;
            const maxLevel = this.SkillLibrary[skillId].levels.length;
            
            // 如果技能還能升級，加入選項
            if (currentLevel < maxLevel) {
                const nextLevel = currentLevel + 1;
                const skillData = this.getSkillData(skillId, nextLevel);
                if (skillData) {
                    skillOptions.push({
                        id: skillId,
                        ...skillData,
                        isUpgrade: currentLevel > 0,
                        currentPlayerLevel: currentLevel
                    });
                }
            }
        }
        
        // 隨機選擇指定數量的技能
        const shuffled = skillOptions.sort(() => 0.5 - Math.random());
        return shuffled.slice(0, count);
    },

    // 檢查技能是否可以升級
    canUpgradeSkill(skillId, currentLevel) {
        const skill = this.SkillLibrary[skillId];
        if (!skill) return false;
        
        return currentLevel < skill.levels.length;
    },

    // 獲取技能下一等級的數據
    getNextLevelData(skillId, currentLevel) {
        if (!this.canUpgradeSkill(skillId, currentLevel)) return null;
        
        return this.getSkillData(skillId, currentLevel + 1);
    },

    // 重新生成技能選項（重抽功能）
    rerollSkillOptions(playerSkills = {}, count = 2, excludeOptions = []) {
        const excludeIds = excludeOptions.map(option => option.id);
        const skillOptions = [];
        const skillIds = Object.keys(this.SkillLibrary).filter(id => !excludeIds.includes(id));
        
        for (const skillId of skillIds) {
            const currentLevel = playerSkills[skillId] || 0;
            const maxLevel = this.SkillLibrary[skillId].levels.length;
            
            if (currentLevel < maxLevel) {
                const nextLevel = currentLevel + 1;
                const skillData = this.getSkillData(skillId, nextLevel);
                if (skillData) {
                    skillOptions.push({
                        id: skillId,
                        ...skillData,
                        isUpgrade: currentLevel > 0,
                        currentPlayerLevel: currentLevel
                    });
                }
            }
        }
        
        const shuffled = skillOptions.sort(() => 0.5 - Math.random());
        return shuffled.slice(0, count);
    },

    // 計算經驗值需求 - 進一步放慢升級節奏
    calculateExpRequired(level) {
        // 更慢的升級：更大的基數和指數
        return Math.floor(300 * Math.pow(2.0, level - 1));
    },

    // 計算獲得經驗值 - 進一步降低經驗獲得
    calculateExpGained(baseScore, playerLevel) {
        // 更少的基礎經驗，讓玩家有充足時間累積金幣
        return Math.floor(baseScore * 0.2 * (1 + 0.03 * playerLevel));
    },

    // 計算獲得金幣 - 稍微增加金幣獲得
    calculateGoldGained(baseScore) {
        return Math.floor(baseScore / 4);
    },

    // 應用被動技能效果到分數計算（僅處理顏色加成）
    applyPassiveSkillEffects(baseScore, matchedColors, playerSkills) {
        let modifiedScore = baseScore;
        
        // 顏色加成技能
        for (const color of matchedColors) {
            const colorSkillId = `COLOR_BONUS_${color.toUpperCase()}`;
            if (playerSkills[colorSkillId]) {
                const skillData = this.getSkillData(colorSkillId, playerSkills[colorSkillId]);
                if (skillData) {
                    const bonus = skillData.currentLevel.value / 100;
                    modifiedScore *= (1 + bonus);
                }
            }
        }
        
        return Math.floor(modifiedScore);
    },

    // 應用即時技能效果
    applyInstantSkillEffect(skillId, level, gameEngine) {
        const skillData = this.getSkillData(skillId, level);
        if (!skillData) return false;
        
        switch (skillId) {
            case 'ADD_COMBO':
                gameEngine.consecutiveSuccessfulActions += skillData.currentLevel.value;
                return true;
                
            case 'ADD_AP':
                gameEngine.actionPoints += skillData.currentLevel.value;
                return true;
                
            default:
                return false;
        }
    }
}; 