# 開發藍圖：三排快節奏RPG模式

## 核心理念

將即時的三消操作與輕度的RPG成長元素結合。玩家在單局遊戲內成長，每次遊玩都有不同的技能組合，創造獨特的體驗。

---

## 階段一：數據結構與核心邏輯（建立基石）

**目標：** 建立後端邏輯和數據模型，為功能實現打下基礎。此階段不包含UI開發。

1.  **建立技能系統 ≈(`js/SkillSystem.js`)**
    -   建立新的 `js/SkillSystem.js` 檔案，用於統一定義所有技能，實現高度模組化以便未來擴充。
    -   **技能數據結構範例：**
        ```javascript
        const SkillLibrary = {
            'ADD_COMBO': {
                name: '連擊爆發',
                description: '立即增加 {value} 連擊數',
                icon: '💥',
                levels: [
                    { level: 1, value: 5, cost: 100 },
                    { level: 2, value: 10, cost: 250 },
                    { level: 3, value: 15, cost: 450 },
                    { level: 4, value: 20, cost: 700 },
                    { level: 5, value: 25, cost: 1000 }
                ]
            },
            'ADD_AP': {
                name: '行動增幅',
                description: '獲得額外 {value} 點行動點',
                icon: '⚡',
                levels: [
                    { level: 1, value: 1, cost: 150 },
                    { level: 2, value: 3, cost: 400 },
                    { level: 3, value: 5, cost: 750 },
                    { level: 4, value: 7, cost: 1200 }
                ]
            },
            'COLOR_BONUS': {
                name: '{color}方塊強化',
                description: '所有{color}方塊消除分數增加 {value}%',
                icon: '🎨',
                levels: [
                    { level: 1, value: 10, cost: 120 },
                    { level: 2, value: 20, cost: 300 },
                    { level: 3, value: 30, cost: 550 },
                    { level: 4, value: 40, cost: 850 }
                ]
            },
            'COMBO_MULTIPLIER_BONUS': {
                name: '連擊倍率強化',
                description: 'Combo 倍率增加 {value}%',
                icon: '📈',
                levels: [
                    { level: 1, value: 10, cost: 200 },
                    { level: 2, value: 20, cost: 450 },
                    { level: 3, value: 30, cost: 800 },
                    { level: 4, value: 40, cost: 1300 }
                ]
            }
        };
        ```

2.  **更新遊戲模式配置 (`js/GameModes.js`)**
    -   在 `tripleActionTimer` 模式配置中，新增 `hasRPGSystem: true` 標誌。
    -   定義RPG相關的基礎數值，如經驗值曲線公式。

3.  **擴充遊戲引擎狀態 (`js/GameEngine.js`)**
    -   在 `setupGameState()` 方法中，為RPG系統初始化新的屬性：
        -   `level`: 玩家等級
        -   `exp`: 當前經驗值
        -   `expToNextLevel`: 升級所需經驗
        -   `gold`: 金幣數量
        -   `playerSkills`: 玩家已獲取的技能及等級

4.  **設計經驗與金幣系統**
    -   **經驗值公式**：`所需經驗 = 100 * (1.5 ^ (目前等級 - 1))`
    -   **獲得經驗**：`獲得經驗 = 基礎分數 * (1 + 0.1 * 等級)`
    -   **獲得金幣**：`獲得金幣 = Math.floor(基礎分數 / 5)`

5.  **在 `GameEngine.js` 中實現核心RPG邏輯**
    -   `addExp(amount)`: 處理經驗值增加及升級判斷。
    -   `levelUp()`: 執行升級邏輯，包括提升等級、更新經驗需求、減少計時器時間、暫停遊戲並觸發技能選擇。
    -   修改 `calculateComboScore()`: 在計分時，根據 `playerSkills` 應用被動技能加成。

---

## 階段二：UI/UX 設計與實現（讓玩家看得到）

**目標：** 將後端數據可視化，打造直觀的遊戲界面。

1.  **設計新的遊戲界面 (`js/UI.js`)**
    -   **RPG狀態欄**: 顯示等級、經驗條和金幣。
    -   **已獲技能欄**: 以圖標形式顯示玩家當前擁有的技能和等級。
    -   **升級彈窗**: 設計一個模式彈窗，展示兩個隨機技能選項，包括名稱、描述、價格，以及購買/放棄按鈕。

2.  **在 `UI.js` 中建立新的HTML生成器**
    -   `createRPGStatsHTML()`: 生成RPG狀態欄的HTML。
    -   `createAcquiredSkillsHTML()`: 生成已獲技能圖標的HTML。
    -   `showLevelUpModal(skillOptions)`: 動態生成並顯示升級彈窗。

3.  **整合到遊戲主循環**
    -   修改 `GameEngine.js` 的 `updateUI()` 方法，以定期更新RPG相關的UI元素。

---

## 階段三：技能效果實現与整合（讓技能動起來）

**目標：** 將數據和UI結合，讓技能產生實際效果。

1.  **在 `GameEngine.js` 中實現技能購買邏輯**
    -   建立 `purchaseSkill(skillId)` 方法，處理金幣檢查、扣除、更新玩家技能狀態，並在完成後恢復遊戲。

2.  **在 `GameEngine.js` 中實現各類技能效果**
    -   **即時生效類** (`ADD_COMBO`, `ADD_AP`): 購買後立即觸發一次性效果。
    -   **被動加成類** (`COLOR_BONUS`, `COMBO_MULTIPLIER_BONUS`): 修改核心計分邏輯，使其在計算時應用這些被動加成。

---

## 遊戲流程

1.  **玩家消除方塊** -> 計算分數。
2.  根據分數**獲得經驗值和金幣**。
3.  **檢查經驗值**是否達到升級門檻。
    -   **否**: 更新UI，等待下一次操作。
    -   **是**: 觸發**升級**流程。
4.  **升級流程**:
    -   遊戲暫停，行動計時器上限永久 **-0.5秒**。
    -   系統隨機抽取兩種技能，**顯示技能購買彈窗**。
    -   玩家選擇**購買**或**放棄**。
    -   關閉彈窗，**遊戲恢復**。
5.  循環等待玩家下一次操作。 