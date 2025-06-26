# 技能系統技術架構文件

## 系統架構概覽

技能系統採用模組化設計，各系統相對獨立但緊密配合，確保可維護性和擴展性。

## 核心模組設計

### 1. ProgressionSystem.js - 進度系統核心
```javascript
class ProgressionSystem {
    constructor(supabaseAuth) {
        this.supabaseAuth = supabaseAuth;
        this.playerData = null;
        this.eventListeners = new Map();
    }

    // 核心功能
    async loadPlayerData()           // 載入玩家資料
    async savePlayerData()           // 保存玩家資料
    addExperience(amount, source)    // 添加經驗值
    levelUp()                        // 等級提升處理
    checkLevelRequirements()         // 檢查等級需求
    
    // 事件系統
    on(event, callback)              // 註冊事件監聽
    emit(event, data)                // 觸發事件
}
```

### 2. CurrencyManager.js - 貨幣系統管理
```javascript
class CurrencyManager {
    constructor(progressionSystem) {
        this.progressionSystem = progressionSystem;
        this.dailyLimits = new Map();
    }

    // 星幣操作
    async addStarCoins(amount, source)
    async spendStarCoins(amount, reason)
    getStarCoins()

    // 寶石操作
    async addGems(amount, source)
    async spendGems(amount, reason)
    getGems()

    // 限制檢查
    checkDailyLimit(type)
    resetDailyLimits()
}
```

### 3. SkillManager.js - 技能系統核心
```javascript
class SkillManager {
    constructor(progressionSystem, currencyManager) {
        this.progressionSystem = progressionSystem;
        this.currencyManager = currencyManager;
        this.skillDefinitions = this.loadSkillDefinitions();
        this.activeSkills = [];
    }

    // 技能管理
    unlockSkill(skillId, paymentMethod)
    upgradeSkill(skillId)
    getSkillLevel(skillId)
    isSkillUnlocked(skillId)
    
    // 技能配置
    equipSkill(skillId, slotIndex)
    unequipSkill(slotIndex)
    getEquippedSkills()
    
    // 技能使用
    canUseSkill(skillId)
    useSkill(skillId, gameContext)
    resetSkillUses()
}
```

### 4. SkillEffects.js - 技能效果實現
```javascript
class SkillEffects {
    constructor(gameEngine) {
        this.gameEngine = gameEngine;
        this.effects = this.initializeEffects();
    }

    // 原有技能效果
    precisionRemove(level, target)
    colorReforge(level, options)
    blockRecolor(level, target)
    
    // 新增技能效果
    timeRewind(level, steps)
    colorPurify(level, amount)
    futureVision(level, count)
    
    // 進階技能效果
    chainExplosion(level, area)
    perfectBalance(level, bonus)
    timeControl(level, duration)
}
```

### 5. AchievementSystem.js - 成就系統
```javascript
class AchievementSystem {
    constructor(progressionSystem, currencyManager) {
        this.progressionSystem = progressionSystem;
        this.currencyManager = currencyManager;
        this.achievements = this.loadAchievements();
        this.progress = new Map();
    }

    // 成就檢查
    checkAchievements(action, data)
    unlockAchievement(achievementId)
    getProgress(achievementId)
    
    // 獎勵發放
    grantReward(reward)
    displayAchievementNotification(achievement)
}
```

## 資料流架構

### 1. 玩家資料結構
```javascript
const PlayerDataSchema = {
    // 基本資料
    playerId: String,
    username: String,
    level: Number,
    experience: Number,
    
    // 貨幣
    starCoins: Number,
    gems: Number,
    vipLevel: Number,
    
    // 技能資料
    skills: {
        [skillId]: {
            level: Number,
            unlocked: Boolean,
            usesLeft: Number
        }
    },
    
    // 技能配置
    equippedSkills: [String],
    skillSlots: Number,
    
    // 統計資料
    stats: {
        totalGames: Number,
        totalScore: Number,
        totalExperience: Number,
        maxCombo: Number
    },
    
    // 成就
    achievements: [String],
    
    // 時間記錄
    lastLogin: Date,
    consecutiveLogins: Number,
    createdAt: Date,
    updatedAt: Date
};
```

### 2. 技能定義結構
```javascript
const SkillDefinition = {
    id: String,
    name: String,
    description: String,
    category: String, // 'basic', 'advanced', 'master'
    
    // 解鎖條件
    unlockRequirements: {
        level: Number,
        cost: {
            starCoins: Number,
            gems: Number
        },
        prerequisites: [String] // 前置技能
    },
    
    // 等級配置
    levels: [
        {
            level: Number,
            maxUses: Number,
            effect: Object,
            upgradeCost: {
                starCoins: Number,
                gems: Number
            }
        }
    ],
    
    // UI 資料
    icon: String,
    color: String,
    animation: String
};
```

## 系統互動流程

### 1. 遊戲開始流程
```
GameStart → ProgressionSystem.loadPlayerData()
         → SkillManager.loadEquippedSkills()
         → GameEngine.initializeSkills()
         → UI.displaySkillButtons()
```

### 2. 技能使用流程
```
PlayerAction → SkillManager.canUseSkill()
           → SkillEffects.executeSkill()
           → GameEngine.applySkillEffect()
           → SkillManager.updateUsageCount()
           → UI.updateSkillDisplay()
```

### 3. 遊戲結算流程
```
GameEnd → GameEngine.calculateRewards()
        → ProgressionSystem.addExperience()
        → CurrencyManager.addCurrency()
        → AchievementSystem.checkAchievements()
        → ProgressionSystem.savePlayerData()
        → UI.displayResults()
```

### 4. 技能升級流程
```
UpgradeRequest → SkillManager.checkRequirements()
              → CurrencyManager.checkBalance()
              → CurrencyManager.spendCurrency()
              → SkillManager.upgradeSkill()
              → AchievementSystem.checkAchievements()
              → ProgressionSystem.savePlayerData()
              → UI.displayUpgradeResult()
```

## 資料庫架構

### 1. 玩家資料表 (players)
```sql
CREATE TABLE players (
    id UUID PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    level INTEGER DEFAULT 1,
    experience INTEGER DEFAULT 0,
    star_coins INTEGER DEFAULT 0,
    gems INTEGER DEFAULT 0,
    vip_level INTEGER DEFAULT 0,
    last_login TIMESTAMP,
    consecutive_logins INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### 2. 技能資料表 (player_skills)
```sql
CREATE TABLE player_skills (
    id UUID PRIMARY KEY,
    player_id UUID REFERENCES players(id),
    skill_id VARCHAR(50) NOT NULL,
    level INTEGER DEFAULT 0,
    unlocked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(player_id, skill_id)
);
```

### 3. 技能配置表 (player_skill_loadouts)
```sql
CREATE TABLE player_skill_loadouts (
    id UUID PRIMARY KEY,
    player_id UUID REFERENCES players(id),
    loadout_name VARCHAR(50) DEFAULT 'Default',
    slot_1 VARCHAR(50),
    slot_2 VARCHAR(50),
    slot_3 VARCHAR(50),
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### 4. 成就資料表 (player_achievements)
```sql
CREATE TABLE player_achievements (
    id UUID PRIMARY KEY,
    player_id UUID REFERENCES players(id),
    achievement_id VARCHAR(50) NOT NULL,
    unlocked_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(player_id, achievement_id)
);
```

## 事件系統設計

### 1. 事件類型定義
```javascript
const EventTypes = {
    // 等級相關
    LEVEL_UP: 'level_up',
    EXPERIENCE_GAINED: 'experience_gained',
    
    // 貨幣相關
    CURRENCY_EARNED: 'currency_earned',
    CURRENCY_SPENT: 'currency_spent',
    
    // 技能相關
    SKILL_UNLOCKED: 'skill_unlocked',
    SKILL_UPGRADED: 'skill_upgraded',
    SKILL_USED: 'skill_used',
    
    // 成就相關
    ACHIEVEMENT_UNLOCKED: 'achievement_unlocked',
    ACHIEVEMENT_PROGRESS: 'achievement_progress',
    
    // 遊戲相關
    GAME_COMPLETED: 'game_completed',
    HIGH_SCORE: 'high_score'
};
```

### 2. 事件監聽範例
```javascript
// 在遊戲引擎中監聽等級提升事件
progressionSystem.on(EventTypes.LEVEL_UP, (data) => {
    ui.showLevelUpAnimation(data.newLevel);
    ui.displayLevelRewards(data.rewards);
    achievementSystem.checkAchievements('level_up', data);
});

// 監聽技能解鎖事件
skillManager.on(EventTypes.SKILL_UNLOCKED, (data) => {
    ui.showSkillUnlockedNotification(data.skillId);
    achievementSystem.checkAchievements('skill_unlock', data);
});
```

## 效能最佳化考量

### 1. 資料快取策略
- **玩家資料：** 登入時載入，遊戲期間保持在記憶體
- **技能定義：** 應用啟動時載入，靜態快取
- **成就進度：** 延遲載入，按需更新

### 2. 資料庫最佳化
- 為常用查詢建立索引
- 使用資料庫觸發器自動更新 updated_at
- 定期清理過期的臨時資料

### 3. 前端效能
- 技能圖示和動畫預載入
- 使用虛擬滾動處理長列表
- 動畫效果的 CSS GPU 加速

## 安全性考量

### 1. 資料驗證
```javascript
// 服務端驗證範例
function validateSkillUpgrade(playerId, skillId) {
    // 檢查玩家等級
    // 檢查貨幣餘額
    // 檢查技能前置條件
    // 防止重複請求
}
```

### 2. 防作弊機制
- 所有貨幣操作在服務端驗證
- 技能使用次數服務端追蹤
- 經驗值獲取根據遊戲表現計算

### 3. 資料一致性
- 使用資料庫事務確保操作原子性
- 定期同步本地和服務端資料
- 異常情況的回滾機制

## 測試策略

### 1. 單元測試
- 各模組的獨立功能測試
- 邊界條件和異常情況測試
- 數值計算的準確性測試

### 2. 整合測試
- 模組間互動測試
- 資料流完整性測試
- 使用者操作流程測試

### 3. 效能測試
- 大量資料處理效能
- 並發使用者負載測試
- 記憶體使用量監控

---

此架構設計確保系統的可擴展性、可維護性和效能，為後續的功能擴展和最佳化奠定堅實基礎。 