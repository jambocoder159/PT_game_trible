// 道具系統 - 區分於技能系統，專門管理可購買和使用的道具
const ITEMS_CONFIG_VERSION = "items_v1.0";
console.log("🔄 載入道具系統版本:", ITEMS_CONFIG_VERSION);

window.ItemSystem = {
    // 道具庫定義
    ItemLibrary: {
        // === 原始技能轉換為道具 ===
        'REMOVE_SINGLE': {
            id: 'REMOVE_SINGLE',
            name: '移除方塊',
            description: '點擊移除任意單個方塊',
            icon: '❌',
            type: 'target', // 需要選擇目標
            price: 25,
            maxStack: 3,
            rarity: 'common',
            category: 'basic'
        },
        'REROLL_NEXT': {
            id: 'REROLL_NEXT',
            name: '重骰方塊',
            description: '重新生成下個方塊顏色',
            icon: '🎲',
            type: 'instant', // 即時效果
            price: 20,
            maxStack: 3,
            rarity: 'common',
            category: 'basic'
        },
        'CHANGE_COLOR': {
            id: 'CHANGE_COLOR',
            name: '變色方塊',
            description: '點擊將方塊變為隨機顏色',
            icon: '🌈',
            type: 'target', // 需要選擇目標
            price: 30,
            maxStack: 3,
            rarity: 'common',
            category: 'basic'
        },
        
        // === 新增高級道具 ===
        'CLEAR_ALL': {
            id: 'CLEAR_ALL',
            name: '清空方塊',
            description: '清除場上所有方塊並重新填充',
            icon: '💥',
            type: 'instant', // 即時效果
            price: 50,
            maxStack: 3, // 最大持有量
            rarity: 'rare', // 稀有度
            category: 'board' // 分類
        },
        'CLEAR_ROW': {
            id: 'CLEAR_ROW',
            name: '橫向清除',
            description: '清除指定方塊的所有橫向方塊',
            icon: '➡️',
            type: 'target', // 需要選擇目標
            price: 35,
            maxStack: 3,
            rarity: 'uncommon',
            category: 'targeted'
        },
        'CLEAR_COLOR': {
            id: 'CLEAR_COLOR',
            name: '同色清除',
            description: '清除場上所有與指定方塊相同顏色的方塊',
            icon: '🎨',
            type: 'target', // 需要選擇目標
            price: 40,
            maxStack: 3,
            rarity: 'uncommon',
            category: 'targeted'
        },
        
        // === 進階道具 ===
        'UNDO_LAST_ACTION': {
            id: 'UNDO_LAST_ACTION',
            name: '返回上一步',
            description: '撤銷上一次操作，回到之前的遊戲狀態',
            icon: '↩️',
            type: 'instant', // 即時效果
            price: 60,
            maxStack: 2,
            rarity: 'rare',
            category: 'special'
        },
        'CLEAR_CROSS': {
            id: 'CLEAR_CROSS',
            name: '十字爆破',
            description: '以選中方塊為中心，十字形消除周圍方塊',
            icon: '✚',
            type: 'target', // 需要選擇目標
            price: 55,
            maxStack: 3,
            rarity: 'rare',
            category: 'area'
        },
        'CLEAR_SQUARE': {
            id: 'CLEAR_SQUARE',
            name: '九宮格爆破',
            description: '以選中方塊為中心，九宮格範圍消除周圍方塊',
            icon: '⬛',
            type: 'target', // 需要選擇目標
            price: 70,
            maxStack: 3,
            rarity: 'epic',
            category: 'area'
        }
    },

    // 道具類型定義
    ItemTypes: {
        INSTANT: 'instant',    // 即時效果，不需要選擇目標
        TARGET: 'target',      // 需要選擇目標的道具
        PASSIVE: 'passive'     // 被動效果（未來擴展用）
    },

    // 道具稀有度定義
    ItemRarity: {
        COMMON: 'common',
        UNCOMMON: 'uncommon',
        RARE: 'rare',
        EPIC: 'epic',
        LEGENDARY: 'legendary'
    },

    // 稀有度顏色映射
    RarityColors: {
        common: '#6B7280',     // 灰色
        uncommon: '#10B981',   // 綠色
        rare: '#3B82F6',       // 藍色
        epic: '#8B5CF6',       // 紫色
        legendary: '#F59E0B'   // 金色
    },

    // 獲取道具數據
    getItemData(itemId) {
        const item = this.ItemLibrary[itemId];
        if (!item) {
            console.error(`道具 ${itemId} 不存在`);
            return null;
        }
        return { ...item };
    },

    // 獲取所有道具
    getAllItems() {
        return Object.values(this.ItemLibrary);
    },

    // 根據類型獲取道具
    getItemsByType(type) {
        return Object.values(this.ItemLibrary).filter(item => item.type === type);
    },

    // 根據分類獲取道具
    getItemsByCategory(category) {
        return Object.values(this.ItemLibrary).filter(item => item.category === category);
    },

    // 根據稀有度獲取道具
    getItemsByRarity(rarity) {
        return Object.values(this.ItemLibrary).filter(item => item.rarity === rarity);
    },

    // 計算道具總價值
    calculateItemValue(itemId, quantity) {
        const item = this.getItemData(itemId);
        if (!item) return 0;
        return item.price * quantity;
    },

    // 驗證道具是否可以使用
    canUseItem(itemId, gameEngine) {
        const item = this.getItemData(itemId);
        if (!item) return false;

        // 檢查遊戲狀態
        if (gameEngine.isAnimating || gameEngine.gameOver) {
            return false;
        }

        // 所有模式都可以使用道具系統
        return true;
    },

    // 使用道具效果
    async useItem(itemId, gameEngine, targetPosition = null) {
        const item = this.getItemData(itemId);
        if (!item) {
            console.log('❌ 道具不存在:', itemId);
            return false;
        }
        
        if (!this.canUseItem(itemId, gameEngine)) {
            console.log('❌ 無法使用道具');
            return false;
        }

        try {
            let result = false;
            
            switch (itemId) {
                // === 原始技能道具 ===
                case 'REMOVE_SINGLE':
                    console.log('🔧 處理 REMOVE_SINGLE，targetPosition:', targetPosition);
                    if (targetPosition) {
                        result = await this.applyRemoveSingleEffect(gameEngine, targetPosition);
                    } else {
                        console.log('❌ REMOVE_SINGLE 沒有提供 targetPosition');
                    }
                    break;
                case 'REROLL_NEXT':
                    console.log('🔧 處理 REROLL_NEXT');
                    result = await this.applyRerollNextEffect(gameEngine);
                    break;
                case 'CHANGE_COLOR':
                    console.log('🔧 處理 CHANGE_COLOR，targetPosition:', targetPosition);
                    if (targetPosition) {
                        result = await this.applyChangeColorEffect(gameEngine, targetPosition);
                    } else {
                        console.log('❌ CHANGE_COLOR 沒有提供 targetPosition');
                    }
                    break;
                    
                // === 高級道具 ===
                case 'CLEAR_ALL':
                    result = await this.applyClearAllEffect(gameEngine);
                    break;
                case 'CLEAR_ROW':
                    if (targetPosition) {
                        result = await this.applyClearRowEffect(gameEngine, targetPosition);
                    }
                    break;
                case 'CLEAR_COLOR':
                    if (targetPosition) {
                        result = await this.applyClearColorEffect(gameEngine, targetPosition);
                    }
                    break;
                    
                // === 進階道具 ===
                case 'UNDO_LAST_ACTION':
                    result = await this.applyUndoLastActionEffect(gameEngine);
                    break;
                case 'CLEAR_CROSS':
                    if (targetPosition) {
                        result = await this.applyClearCrossEffect(gameEngine, targetPosition);
                    } else {
                        console.log('❌ CLEAR_CROSS 沒有提供 targetPosition');
                    }
                    break;
                case 'CLEAR_SQUARE':
                    if (targetPosition) {
                        result = await this.applyClearSquareEffect(gameEngine, targetPosition);
                    } else {
                        console.log('❌ CLEAR_SQUARE 沒有提供 targetPosition');
                    }
                    break;
                default:
                    console.error(`未知道具效果: ${itemId}`);
                    return false;
            }

            if (result) {
                // 觸發UI更新
                gameEngine.updateUI();
                
                // 成功提示將在 GameEngine.processActiveItemOnBlock 中顯示
                // 避免重複提示
            }

            return result;
        } catch (error) {
            console.error(`使用道具 ${item.name} 時發生錯誤:`, error);
            return false;
        }
    },

    // === 原始技能道具效果實現 ===
    
    // 移除單個方塊效果
    async applyRemoveSingleEffect(gameEngine, targetPosition) {
        console.log('執行移除單個方塊效果', targetPosition);
        console.log('遊戲配置:', { numCols: gameEngine.config.numCols, numRows: gameEngine.config.numRows });
        console.log('網格狀態:', gameEngine.grid);
        
        const { colIndex, rowIndex } = targetPosition;
        
        // 檢查目標位置是否有效
        const targetGrid = gameEngine.config.numCols === 1 ? gameEngine.grid[0] : gameEngine.grid[colIndex];
        console.log('目標網格:', targetGrid);
        console.log('目標位置:', { colIndex, rowIndex });
        
        if (!targetGrid) {
            console.log('目標網格不存在');
            return false;
        }
        
        if (!targetGrid[rowIndex]) {
            console.log('目標行索引無效，網格長度:', targetGrid.length);
            return false;
        }

        const block = targetGrid[rowIndex];
        
        // 創建爆炸特效
        gameEngine.createParticleExplosion(block.x, block.drawY, block.width, block.height, block.colorHex);
        
        // 標記方塊為爆炸狀態並等待
        block.isExploding = true;
        await new Promise(resolve => setTimeout(resolve, 100));
        
        // 移除方塊
        targetGrid.splice(rowIndex, 1);
        
        console.log('成功移除單個方塊');
        return true;
    },

    // 重骰下個方塊效果
    async applyRerollNextEffect(gameEngine) {
        console.log('執行重骰下個方塊效果');
        
        if (typeof gameEngine.generateNextBlockColorWithDifferentColors === 'function') {
            // 使用現有的重骰邏輯，確保新顏色與原顏色不同
            gameEngine.generateNextBlockColorWithDifferentColors();
        } else {
            // 備用方法：直接重新生成
            for (let col = 0; col < gameEngine.config.numCols; col++) {
                let newColor;
                do {
                    newColor = gameEngine.getRandomColorName();
                } while (newColor === gameEngine.nextBlockColors[col] && gameEngine.colorNames.length > 1);
                gameEngine.nextBlockColors[col] = newColor;
            }
        }
        
        // 更新下個方塊預覽UI
        if (typeof gameEngine.updateNextBlockPreviewUI === 'function') {
            gameEngine.updateNextBlockPreviewUI();
        }
        
        console.log('下個方塊顏色已重新生成:', gameEngine.nextBlockColors);
        return true;
    },

    // 變色方塊效果
    async applyChangeColorEffect(gameEngine, targetPosition) {
        console.log('執行變色方塊效果', targetPosition);
        console.log('遊戲配置:', { numCols: gameEngine.config.numCols, numRows: gameEngine.config.numRows });
        console.log('網格狀態:', gameEngine.grid);
        
        const { colIndex, rowIndex } = targetPosition;
        
        // 檢查目標位置是否有效
        const targetGrid = gameEngine.config.numCols === 1 ? gameEngine.grid[0] : gameEngine.grid[colIndex];
        console.log('目標網格:', targetGrid);
        console.log('目標位置:', { colIndex, rowIndex });
        
        if (!targetGrid) {
            console.log('目標網格不存在');
            return false;
        }
        
        if (!targetGrid[rowIndex]) {
            console.log('目標行索引無效，網格長度:', targetGrid.length);
            return false;
        }

        const block = targetGrid[rowIndex];
        
        // 支援兩種屬性名稱：colorName (正常遊戲) 和 color (教學模式)
        const oldColor = block.colorName || block.color;
        
        // 生成不同的顏色
        let newColorName;
        do {
            newColorName = gameEngine.getRandomColorName();
        } while (newColorName === oldColor && gameEngine.colorNames.length > 1);
        
        // 更新方塊顏色（同時更新兩種屬性以確保兼容性）
        if (block.colorName !== undefined) {
            block.colorName = newColorName;
        }
        if (block.color !== undefined) {
            block.color = newColorName;
        }
        block.colorHex = gameEngine.config.colors[newColorName].hex;
        
        console.log(`方塊顏色從 ${oldColor} 變為 ${newColorName}`);
        return true;
    },

    // === 高級道具效果實現 ===

    // 清空方塊效果
    async applyClearAllEffect(gameEngine) {
        console.log('執行清空方塊效果');
        
        // 單排模式或多排模式的處理
        if (gameEngine.config.numCols === 1) {
            // 單排模式：清空grid[0]數組
            gameEngine.grid[0] = [];
        } else {
            // 多排模式：清空所有列
            for (let col = 0; col < gameEngine.config.numCols; col++) {
                if (gameEngine.grid[col]) {
                    gameEngine.grid[col] = [];
                }
            }
        }

        // 重新填充方塊
        gameEngine.refillGrid();
        gameEngine.updateBlockPositions();

        // 添加特效
        if (gameEngine.addScreenShakeEffect) {
            gameEngine.addScreenShakeEffect();
        }

        return true;
    },

    // 橫向清除效果
    async applyClearRowEffect(gameEngine, targetPosition) {
        console.log('執行橫向清除效果', targetPosition);
        console.log('遊戲配置:', { numCols: gameEngine.config.numCols, numRows: gameEngine.config.numRows });
        console.log('網格狀態:', gameEngine.grid);
        
        const { colIndex, rowIndex } = targetPosition;
        
        // 檢查目標位置是否有效
        const targetGrid = gameEngine.config.numCols === 1 ? gameEngine.grid[0] : gameEngine.grid[colIndex];
        console.log('目標網格:', targetGrid);
        console.log('目標位置:', { colIndex, rowIndex });
        
        if (!targetGrid) {
            console.log('目標網格不存在');
            return false;
        }
        
        if (!targetGrid[rowIndex]) {
            console.log('目標行索引無效，網格長度:', targetGrid.length);
            return false;
        }

        const targetRow = rowIndex;
        
        // 多排模式：清除所有列的同一行
        if (gameEngine.config.numCols > 1) {
            for (let col = 0; col < gameEngine.config.numCols; col++) {
                if (gameEngine.grid[col] && gameEngine.grid[col][targetRow]) {
                    // 創建爆炸特效
                    const block = gameEngine.grid[col][targetRow];
                    gameEngine.createParticleExplosion(block.x, block.drawY, block.width, block.height, block.colorHex);
                    // 移除方塊
                    gameEngine.grid[col].splice(targetRow, 1);
                }
            }
        } else {
            // 單排模式：在多個高度的方塊中選擇一定數量進行清除
            const gridArray = gameEngine.grid[0];
            const clearCount = Math.min(3, gridArray.length); // 最多清除3個
            const startIndex = Math.max(0, targetRow - Math.floor(clearCount / 2));
            
            for (let i = 0; i < clearCount && startIndex + i < gridArray.length; i++) {
                const blockIndex = startIndex + i;
                if (gridArray[blockIndex]) {
                    const block = gridArray[blockIndex];
                    gameEngine.createParticleExplosion(block.x, block.drawY, block.width, block.height, block.colorHex);
                    gridArray.splice(blockIndex, 1);
                    i--; // 因為數組長度改變，需要調整索引
                }
            }
        }

        // 等待一下讓特效顯示
        await new Promise(resolve => setTimeout(resolve, 200));

        return true;
    },

    // 同色清除效果
    async applyClearColorEffect(gameEngine, targetPosition) {
        console.log('執行同色清除效果', targetPosition);
        console.log('遊戲配置:', { numCols: gameEngine.config.numCols, numRows: gameEngine.config.numRows });
        console.log('網格狀態:', gameEngine.grid);
        
        const { colIndex, rowIndex } = targetPosition;
        
        // 檢查目標位置是否有效
        const targetGrid = gameEngine.config.numCols === 1 ? gameEngine.grid[0] : gameEngine.grid[colIndex];
        console.log('目標網格:', targetGrid);
        console.log('目標位置:', { colIndex, rowIndex });
        
        if (!targetGrid) {
            console.log('目標網格不存在');
            return false;
        }
        
        if (!targetGrid[rowIndex]) {
            console.log('目標行索引無效，網格長度:', targetGrid.length);
            return false;
        }

        const targetBlock = targetGrid[rowIndex];
        // 支援兩種屬性名稱：colorName (正常遊戲) 和 color (教學模式)
        const targetColor = targetBlock.colorName || targetBlock.color;
        console.log(`清除顏色: ${targetColor}`);

        // 清除所有相同顏色的方塊
        let clearedCount = 0;
        
        if (gameEngine.config.numCols === 1) {
            // 單排模式
            const gridArray = gameEngine.grid[0];
            for (let i = gridArray.length - 1; i >= 0; i--) {
                if (gridArray[i]) {
                    const blockColor = gridArray[i].colorName || gridArray[i].color;
                    if (blockColor === targetColor) {
                        // 創建爆炸特效
                        gameEngine.createParticleExplosion(
                            gridArray[i].x, 
                            gridArray[i].drawY, 
                            gridArray[i].width, 
                            gridArray[i].height, 
                            gridArray[i].colorHex
                        );
                        // 移除方塊
                        gridArray.splice(i, 1);
                        clearedCount++;
                    }
                }
            }
        } else {
            // 多排模式
            for (let col = 0; col < gameEngine.config.numCols; col++) {
                if (gameEngine.grid[col]) {
                    for (let row = gameEngine.grid[col].length - 1; row >= 0; row--) {
                        if (gameEngine.grid[col][row]) {
                            const blockColor = gameEngine.grid[col][row].colorName || gameEngine.grid[col][row].color;
                            if (blockColor === targetColor) {
                                // 創建爆炸特效
                                const block = gameEngine.grid[col][row];
                                gameEngine.createParticleExplosion(block.x, block.drawY, block.width, block.height, block.colorHex);
                                // 移除方塊
                                gameEngine.grid[col].splice(row, 1);
                                clearedCount++;
                            }
                        }
                    }
                }
            }
        }

        console.log(`清除了 ${clearedCount} 個 ${targetColor} 方塊`);

        // 等待一下讓特效顯示
        await new Promise(resolve => setTimeout(resolve, 200));

        return true;
    },

    // === 進階道具效果實現 ===
    
    // 返回上一步效果
    async applyUndoLastActionEffect(gameEngine) {
        console.log('執行返回上一步效果');
        
        // 檢查是否有保存的遊戲狀態
        if (!gameEngine.gameStateHistory || gameEngine.gameStateHistory.length === 0) {
            console.log('沒有可撤銷的操作');
            if (typeof UIManager !== 'undefined' && UIManager.showToast) {
                UIManager.showToast('沒有可撤銷的操作', 'warning', 2000);
            }
            return false;
        }
        
        try {
            // 獲取上一個遊戲狀態
            const previousState = gameEngine.gameStateHistory.pop();
            console.log('恢復到上一個狀態:', previousState);
            
            // 恢復網格狀態
            gameEngine.grid = JSON.parse(JSON.stringify(previousState.grid));
            
            // 恢復分數（如果有的話）
            if (previousState.score !== undefined) {
                gameEngine.score = previousState.score;
            }
            
            // 恢復行動點（如果有的話）
            if (previousState.actionPoints !== undefined) {
                gameEngine.actionPoints = previousState.actionPoints;
            }
            
            // 恢復連擊數（如果有的話）
            if (previousState.consecutiveSuccessfulActions !== undefined) {
                gameEngine.consecutiveSuccessfulActions = previousState.consecutiveSuccessfulActions;
            }
            
            // 更新方塊位置
            gameEngine.updateBlockPositions();
            
            console.log('成功撤銷上一步操作');
            return true;
        } catch (error) {
            console.error('撤銷操作失敗:', error);
            return false;
        }
    },
    
    // 十字爆破效果
    async applyClearCrossEffect(gameEngine, targetPosition) {
        console.log('執行十字爆破效果', targetPosition);
        
        const { colIndex, rowIndex } = targetPosition;
        
        // 檢查目標位置是否有效
        const targetGrid = gameEngine.config.numCols === 1 ? gameEngine.grid[0] : gameEngine.grid[colIndex];
        
        if (!targetGrid) {
            console.log('目標網格不存在');
            return false;
        }
        
        if (!targetGrid[rowIndex]) {
            console.log('目標行索引無效');
            return false;
        }
        
        let clearedCount = 0;
        
        if (gameEngine.config.numCols === 1) {
            // 單排模式：清除目標方塊及其上下相鄰的方塊
            const gridArray = gameEngine.grid[0];
            const targetIndexes = [rowIndex - 1, rowIndex, rowIndex + 1].filter(idx => idx >= 0 && idx < gridArray.length);
            
            // 從高索引開始清除（避免索引偏移）
            for (let i = targetIndexes.length - 1; i >= 0; i--) {
                const idx = targetIndexes[i];
                if (gridArray[idx]) {
                    const block = gridArray[idx];
                    gameEngine.createParticleExplosion(block.x, block.drawY, block.width, block.height, block.colorHex);
                    gridArray.splice(idx, 1);
                    clearedCount++;
                }
            }
        } else {
            // 多排模式：清除十字形區域
            const positions = [
                { col: colIndex, row: rowIndex },       // 中心
                { col: colIndex - 1, row: rowIndex },   // 左
                { col: colIndex + 1, row: rowIndex },   // 右
                { col: colIndex, row: rowIndex - 1 },   // 上
                { col: colIndex, row: rowIndex + 1 }    // 下
            ];
            
            // 收集所有要刪除的方塊（按列分組）
            const toDelete = {};
            
            for (const pos of positions) {
                if (pos.col >= 0 && pos.col < gameEngine.config.numCols &&
                    gameEngine.grid[pos.col] && 
                    pos.row >= 0 && pos.row < gameEngine.grid[pos.col].length &&
                    gameEngine.grid[pos.col][pos.row]) {
                    
                    if (!toDelete[pos.col]) {
                        toDelete[pos.col] = [];
                    }
                    toDelete[pos.col].push(pos.row);
                }
            }
            
            // 按列刪除方塊（從高索引開始）
            for (const col in toDelete) {
                const rows = toDelete[col].sort((a, b) => b - a); // 降序排列
                for (const row of rows) {
                    if (gameEngine.grid[col] && gameEngine.grid[col][row]) {
                        const block = gameEngine.grid[col][row];
                        gameEngine.createParticleExplosion(block.x, block.drawY, block.width, block.height, block.colorHex);
                        gameEngine.grid[col].splice(row, 1);
                        clearedCount++;
                    }
                }
            }
        }
        
        console.log(`十字爆破清除了 ${clearedCount} 個方塊`);
        
        // 等待一下讓特效顯示
        await new Promise(resolve => setTimeout(resolve, 200));
        
        return true;
    },
    
    // 九宮格爆破效果
    async applyClearSquareEffect(gameEngine, targetPosition) {
        console.log('執行九宮格爆破效果', targetPosition);
        
        const { colIndex, rowIndex } = targetPosition;
        
        // 檢查目標位置是否有效
        const targetGrid = gameEngine.config.numCols === 1 ? gameEngine.grid[0] : gameEngine.grid[colIndex];
        
        if (!targetGrid) {
            console.log('目標網格不存在');
            return false;
        }
        
        if (!targetGrid[rowIndex]) {
            console.log('目標行索引無效');
            return false;
        }
        
        let clearedCount = 0;
        
        if (gameEngine.config.numCols === 1) {
            // 單排模式：清除目標方塊及其上下兩個相鄰的方塊（共5個）
            const gridArray = gameEngine.grid[0];
            const targetIndexes = [rowIndex - 2, rowIndex - 1, rowIndex, rowIndex + 1, rowIndex + 2]
                .filter(idx => idx >= 0 && idx < gridArray.length);
            
            // 從高索引開始清除（避免索引偏移）
            for (let i = targetIndexes.length - 1; i >= 0; i--) {
                const idx = targetIndexes[i];
                if (gridArray[idx]) {
                    const block = gridArray[idx];
                    gameEngine.createParticleExplosion(block.x, block.drawY, block.width, block.height, block.colorHex);
                    gridArray.splice(idx, 1);
                    clearedCount++;
                }
            }
        } else {
            // 多排模式：清除九宮格區域
            const positions = [];
            
            for (let deltaCol = -1; deltaCol <= 1; deltaCol++) {
                for (let deltaRow = -1; deltaRow <= 1; deltaRow++) {
                    positions.push({
                        col: colIndex + deltaCol,
                        row: rowIndex + deltaRow
                    });
                }
            }
            
            // 收集所有要刪除的方塊（按列分組）
            const toDelete = {};
            
            for (const pos of positions) {
                if (pos.col >= 0 && pos.col < gameEngine.config.numCols &&
                    gameEngine.grid[pos.col] && 
                    pos.row >= 0 && pos.row < gameEngine.grid[pos.col].length &&
                    gameEngine.grid[pos.col][pos.row]) {
                    
                    if (!toDelete[pos.col]) {
                        toDelete[pos.col] = [];
                    }
                    toDelete[pos.col].push(pos.row);
                }
            }
            
            // 按列刪除方塊（從高索引開始）
            for (const col in toDelete) {
                const rows = toDelete[col].sort((a, b) => b - a); // 降序排列
                for (const row of rows) {
                    if (gameEngine.grid[col] && gameEngine.grid[col][row]) {
                        const block = gameEngine.grid[col][row];
                        gameEngine.createParticleExplosion(block.x, block.drawY, block.width, block.height, block.colorHex);
                        gameEngine.grid[col].splice(row, 1);
                        clearedCount++;
                    }
                }
            }
        }
        
        console.log(`九宮格爆破清除了 ${clearedCount} 個方塊`);
        
        // 等待一下讓特效顯示
        await new Promise(resolve => setTimeout(resolve, 200));
        
        return true;
    },

    // 獲取道具稀有度顏色
    getRarityColor(rarity) {
        return this.RarityColors[rarity] || this.RarityColors.common;
    },

    // 格式化道具描述
    formatItemDescription(item) {
        return item.description;
    }
};

// 導出道具系統
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ItemSystem;
} 