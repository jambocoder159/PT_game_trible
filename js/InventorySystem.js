// 背包系統 - 管理玩家道具持有量和裝備配置
const INVENTORY_CONFIG_VERSION = "inventory_v1.0";
console.log("🔄 載入背包系統版本:", INVENTORY_CONFIG_VERSION);

window.InventorySystem = {
    // 背包配置
    config: {
        maxEquippedItems: 3,    // 最大裝備道具數
        storageKey: 'player_inventory',
        equippedKey: 'equipped_items'
    },

    // 初始化背包系統
    init() {
        console.log('🎒 初始化背包系統');
        this.validateInventory();
        this.validateEquippedItems();
    },

    // 驗證背包數據
    validateInventory() {
        const inventory = this.getInventory();
        let hasChanged = false;
        
        // 檢查每個道具是否存在並驗證數量
        for (const [itemId, quantity] of Object.entries(inventory)) {
            const item = ItemSystem.getItemData(itemId);
            
            if (!item) {
                // 移除不存在的道具
                delete inventory[itemId];
                hasChanged = true;
                console.log(`移除無效道具: ${itemId}`);
            } else if (quantity > item.maxStack) {
                // 修正超過最大持有量的道具
                inventory[itemId] = item.maxStack;
                hasChanged = true;
                console.log(`修正道具數量: ${itemId} -> ${item.maxStack}`);
            } else if (quantity <= 0) {
                // 移除數量為0或負數的道具
                delete inventory[itemId];
                hasChanged = true;
                console.log(`移除無效數量道具: ${itemId}`);
            }
        }

        if (hasChanged) {
            this.saveInventory(inventory);
        }
    },

    // 驗證裝備道具
    validateEquippedItems() {
        const equippedItems = this.getEquippedItems();
        const inventory = this.getInventory();
        let hasChanged = false;
        
        const validEquippedItems = equippedItems.filter(itemId => {
            const item = ItemSystem.getItemData(itemId);
            const hasInInventory = inventory[itemId] && inventory[itemId] > 0;
            
            if (!item || !hasInInventory) {
                console.log(`移除無效的裝備道具: ${itemId}`);
                hasChanged = true;
                return false;
            }
            return true;
        });

        // 限制裝備數量
        if (validEquippedItems.length > this.config.maxEquippedItems) {
            validEquippedItems.splice(this.config.maxEquippedItems);
            hasChanged = true;
        }

        if (hasChanged) {
            this.saveEquippedItems(validEquippedItems);
        }
    },

    // 獲取背包數據
    getInventory() {
        try {
            const inventoryData = localStorage.getItem(this.config.storageKey);
            return inventoryData ? JSON.parse(inventoryData) : {};
        } catch (error) {
            console.error('獲取背包數據失敗:', error);
            return {};
        }
    },

    // 保存背包數據
    saveInventory(inventory) {
        try {
            localStorage.setItem(this.config.storageKey, JSON.stringify(inventory));
        } catch (error) {
            console.error('保存背包數據失敗:', error);
        }
    },

    // 獲取裝備道具列表
    getEquippedItems() {
        try {
            const equippedData = localStorage.getItem(this.config.equippedKey);
            return equippedData ? JSON.parse(equippedData) : [];
        } catch (error) {
            console.error('獲取裝備道具失敗:', error);
            return [];
        }
    },

    // 保存裝備道具列表
    saveEquippedItems(equippedItems) {
        try {
            localStorage.setItem(this.config.equippedKey, JSON.stringify(equippedItems));
            // 只在裝備發生變化時才輸出日誌
            if (JSON.stringify(this.getEquippedItems()) !== JSON.stringify(equippedItems)) {
                console.log('💼 裝備道具已更新:', equippedItems);
            }
        } catch (error) {
            console.error('保存裝備道具失敗:', error);
        }
    },

    // 添加道具
    addItem(itemId, quantity = 1) {
        const item = ItemSystem.getItemData(itemId);
        if (!item) {
            console.error(`道具 ${itemId} 不存在`);
            return false;
        }

        const inventory = this.getInventory();
        const currentQuantity = inventory[itemId] || 0;
        const newQuantity = Math.min(currentQuantity + quantity, item.maxStack);
        
        if (newQuantity > currentQuantity) {
            inventory[itemId] = newQuantity;
            this.saveInventory(inventory);
            console.log(`📦 添加道具: ${item.name} x${newQuantity - currentQuantity}`);
            return true;
        }
        
        return false;
    },

    // 移除道具
    removeItem(itemId, quantity = 1) {
        const inventory = this.getInventory();
        const currentQuantity = inventory[itemId] || 0;
        
        if (currentQuantity < quantity) {
            console.log(`道具數量不足: ${itemId}, 需要: ${quantity}, 擁有: ${currentQuantity}`);
            return false;
        }

        const newQuantity = currentQuantity - quantity;
        
        if (newQuantity <= 0) {
            delete inventory[itemId];
            // 如果道具用完了，也要從裝備中移除
            this.unequipItem(itemId);
        } else {
            inventory[itemId] = newQuantity;
        }
        
        this.saveInventory(inventory);
        
        const item = ItemSystem.getItemData(itemId);
        console.log(`📦 移除道具: ${item?.name || itemId} x${quantity}`);
        return true;
    },

    // 獲取道具數量
    getItemQuantity(itemId) {
        const inventory = this.getInventory();
        return inventory[itemId] || 0;
    },

    // 檢查是否有道具
    hasItem(itemId, quantity = 1) {
        return this.getItemQuantity(itemId) >= quantity;
    },

    // 裝備道具
    equipItem(itemId) {
        const item = ItemSystem.getItemData(itemId);
        if (!item) {
            console.error(`道具 ${itemId} 不存在`);
            return false;
        }

        // 檢查是否擁有該道具
        if (!this.hasItem(itemId)) {
            console.log(`無法裝備道具 ${item.name}：背包中沒有此道具`);
            return false;
        }

        const equippedItems = this.getEquippedItems();
        
        // 檢查是否已經裝備
        if (equippedItems.includes(itemId)) {
            console.log(`道具 ${item.name} 已經裝備`);
            return false;
        }

        // 檢查裝備槽位
        if (equippedItems.length >= this.config.maxEquippedItems) {
            console.log(`裝備槽位已滿 (${this.config.maxEquippedItems}/${this.config.maxEquippedItems})`);
            return false;
        }

        // 裝備道具
        equippedItems.push(itemId);
        this.saveEquippedItems(equippedItems);
        
        console.log(`⚔️ 裝備道具: ${item.name}`);
        return true;
    },

    // 卸下道具
    unequipItem(itemId) {
        const equippedItems = this.getEquippedItems();
        const index = equippedItems.indexOf(itemId);
        
        if (index === -1) {
            console.log(`道具 ${itemId} 未裝備`);
            return false;
        }

        equippedItems.splice(index, 1);
        this.saveEquippedItems(equippedItems);
        
        const item = ItemSystem.getItemData(itemId);
        console.log(`🔽 卸下道具: ${item?.name || itemId}`);
        return true;
    },

    // 檢查道具是否已裝備
    isEquipped(itemId) {
        return this.getEquippedItems().includes(itemId);
    },

    // 使用道具
    useItem(itemId, gameEngine, targetPosition = null) {
        // 檢查是否裝備了該道具
        if (!this.isEquipped(itemId)) {
            console.log(`無法使用道具 ${itemId}：未裝備`);
            return false;
        }

        // 檢查道具數量
        if (!this.hasItem(itemId)) {
            console.log(`無法使用道具 ${itemId}：數量不足`);
            return false;
        }

        // 使用道具效果
        const success = ItemSystem.useItem(itemId, gameEngine, targetPosition);
        
        if (success) {
            // 消耗道具
            this.removeItem(itemId, 1);
            
            const item = ItemSystem.getItemData(itemId);
            console.log(`✨ 使用道具成功: ${item?.name || itemId}`);
        }
        
        return success;
    },

    // 獲取可用道具列表（已裝備且有數量的道具）
    getAvailableItems() {
        const equippedItems = this.getEquippedItems();
        const inventory = this.getInventory();
        
        return equippedItems
            .filter(itemId => inventory[itemId] && inventory[itemId] > 0)
            .map(itemId => {
                const item = ItemSystem.getItemData(itemId);
                return {
                    ...item,
                    quantity: inventory[itemId]
                };
            });
    },

    // 獲取背包統計
    getInventoryStats() {
        const inventory = this.getInventory();
        const equippedItems = this.getEquippedItems();
        
        const totalItems = Object.values(inventory).reduce((sum, qty) => sum + qty, 0);
        const uniqueItems = Object.keys(inventory).length;
        const totalValue = Object.entries(inventory).reduce((sum, [itemId, qty]) => {
            const item = ItemSystem.getItemData(itemId);
            return sum + (item ? item.price * qty : 0);
        }, 0);

        return {
            totalItems,
            uniqueItems,
            totalValue,
            equippedCount: equippedItems.length,
            maxEquipped: this.config.maxEquippedItems,
            equippedItems: equippedItems.map(itemId => {
                const item = ItemSystem.getItemData(itemId);
                return {
                    id: itemId,
                    name: item?.name || itemId,
                    quantity: inventory[itemId] || 0
                };
            })
        };
    },

    // 獲取道具詳細信息
    getItemDetails(itemId) {
        const item = ItemSystem.getItemData(itemId);
        if (!item) return null;

        const inventory = this.getInventory();
        const quantity = inventory[itemId] || 0;
        const isEquipped = this.isEquipped(itemId);

        return {
            ...item,
            quantity,
            isEquipped,
            canEquip: quantity > 0 && !isEquipped,
            canUnequip: isEquipped,
            totalValue: item.price * quantity
        };
    },

    // 清空背包
    clearInventory() {
        try {
            localStorage.removeItem(this.config.storageKey);
            localStorage.removeItem(this.config.equippedKey);
            console.log('🗑️ 背包已清空');
        } catch (error) {
            console.error('清空背包失敗:', error);
        }
    },

    // 導出背包數據
    exportInventory() {
        return {
            inventory: this.getInventory(),
            equippedItems: this.getEquippedItems(),
            stats: this.getInventoryStats()
        };
    },

    // 導入背包數據
    importInventory(data) {
        try {
            if (data.inventory) {
                this.saveInventory(data.inventory);
            }
            if (data.equippedItems) {
                this.saveEquippedItems(data.equippedItems);
            }
            this.validateInventory();
            this.validateEquippedItems();
            console.log('📥 背包數據導入成功');
            return true;
        } catch (error) {
            console.error('導入背包數據失敗:', error);
            return false;
        }
    }
};

// 導出背包系統
if (typeof module !== 'undefined' && module.exports) {
    module.exports = InventorySystem;
} 