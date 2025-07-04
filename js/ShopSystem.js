// 商城系統 - 處理道具購買和商城管理
const SHOP_CONFIG_VERSION = "shop_v1.0";
console.log("🔄 載入商城系統版本:", SHOP_CONFIG_VERSION);

window.ShopSystem = {
    // 商城配置
    config: {
        defaultCurrency: 1000,  // 預設貨幣（測試用）
        maxEquippedItems: 3,    // 最大裝備道具數
        currencyName: '金幣',
        currencyIcon: '💰'
    },

    // 初始化商城
    init() {
        console.log('🏪 初始化商城系統');
        this.initializeTestData();
    },

    // 初始化測試數據
    initializeTestData() {
        // 檢查是否已有數據
        const existingCurrency = this.getCurrency();
        if (existingCurrency === null) {
            console.log('🎯 設置測試數據');
            this.setCurrency(this.config.defaultCurrency);
        }
    },

    // 獲取貨幣
    getCurrency() {
        try {
            const currency = localStorage.getItem('player_currency');
            return currency ? parseInt(currency) : null;
        } catch (error) {
            console.error('獲取貨幣失敗:', error);
            return 0;
        }
    },

    // 設置貨幣
    setCurrency(amount) {
        try {
            localStorage.setItem('player_currency', amount.toString());
            console.log(`💰 設置貨幣: ${amount}`);
        } catch (error) {
            console.error('設置貨幣失敗:', error);
        }
    },

    // 增加貨幣
    addCurrency(amount) {
        const current = this.getCurrency() || 0;
        const newAmount = current + amount;
        this.setCurrency(newAmount);
        return newAmount;
    },

    // 減少貨幣
    subtractCurrency(amount) {
        const current = this.getCurrency() || 0;
        const newAmount = Math.max(0, current - amount);
        this.setCurrency(newAmount);
        return newAmount;
    },

    // 檢查是否有足夠貨幣
    canAfford(amount) {
        const current = this.getCurrency() || 0;
        return current >= amount;
    },

    // 購買道具
    purchaseItem(itemId, quantity = 1) {
        console.log(`🛒 嘗試購買道具: ${itemId}, 數量: ${quantity}`);
        
        // 獲取道具信息
        const item = ItemSystem.getItemData(itemId);
        if (!item) {
            console.error(`道具 ${itemId} 不存在`);
            return { success: false, message: '道具不存在' };
        }

        // 檢查數量是否有效
        if (quantity <= 0) {
            return { success: false, message: '購買數量必須大於0' };
        }

        // 計算總價
        const totalPrice = item.price * quantity;
        
        // 檢查是否有足夠貨幣
        if (!this.canAfford(totalPrice)) {
            const current = this.getCurrency() || 0;
            return { 
                success: false, 
                message: `金幣不足！需要 ${totalPrice}，目前擁有 ${current}` 
            };
        }

        // 檢查背包容量
        const inventory = InventorySystem.getInventory();
        const currentQuantity = inventory[itemId] || 0;
        
        if (currentQuantity + quantity > item.maxStack) {
            return { 
                success: false, 
                message: `背包已滿！${item.name} 最大持有量：${item.maxStack}` 
            };
        }

        // 執行購買
        this.subtractCurrency(totalPrice);
        InventorySystem.addItem(itemId, quantity);

        console.log(`✅ 購買成功: ${item.name} x${quantity}, 花費: ${totalPrice}`);
        
        return { 
            success: true, 
            message: `購買成功！獲得 ${item.name} x${quantity}`,
            item: item,
            quantity: quantity,
            totalPrice: totalPrice,
            remainingCurrency: this.getCurrency()
        };
    },

    // 獲取商城道具列表
    getShopItems() {
        return ItemSystem.getAllItems().map(item => {
            const inventory = InventorySystem.getInventory();
            const owned = inventory[item.id] || 0;
            
            return {
                ...item,
                owned: owned,
                canBuy: owned < item.maxStack,
                isMaxed: owned >= item.maxStack
            };
        });
    },

    // 檢查道具是否可購買
    canPurchaseItem(itemId, quantity = 1) {
        const item = ItemSystem.getItemData(itemId);
        if (!item) return false;

        const totalPrice = item.price * quantity;
        const inventory = InventorySystem.getInventory();
        const currentQuantity = inventory[itemId] || 0;

        return this.canAfford(totalPrice) && 
               (currentQuantity + quantity <= item.maxStack);
    },

    // 獲取推薦道具
    getRecommendedItems() {
        const allItems = this.getShopItems();
        const inventory = InventorySystem.getInventory();
        
        // 推薦邏輯：優先推薦持有量較少的道具
        return allItems
            .filter(item => item.canBuy)
            .sort((a, b) => {
                const aOwned = inventory[a.id] || 0;
                const bOwned = inventory[b.id] || 0;
                return aOwned - bOwned;
            })
            .slice(0, 3);
    },

    // 批量購買道具
    bulkPurchase(purchases) {
        console.log('🛒 批量購買:', purchases);
        
        const results = [];
        let totalCost = 0;

        // 先驗證所有購買是否可行
        for (const purchase of purchases) {
            const { itemId, quantity } = purchase;
            const item = ItemSystem.getItemData(itemId);
            
            if (!item) {
                return { success: false, message: `道具 ${itemId} 不存在` };
            }

            const cost = item.price * quantity;
            totalCost += cost;
            
            const inventory = InventorySystem.getInventory();
            const currentQuantity = inventory[itemId] || 0;
            
            if (currentQuantity + quantity > item.maxStack) {
                return { 
                    success: false, 
                    message: `${item.name} 超過最大持有量` 
                };
            }
        }

        // 檢查總金額
        if (!this.canAfford(totalCost)) {
            return { 
                success: false, 
                message: `金幣不足！需要 ${totalCost}，目前擁有 ${this.getCurrency()}` 
            };
        }

        // 執行批量購買
        this.subtractCurrency(totalCost);
        
        for (const purchase of purchases) {
            const { itemId, quantity } = purchase;
            const item = ItemSystem.getItemData(itemId);
            
            InventorySystem.addItem(itemId, quantity);
            results.push({
                itemId: itemId,
                name: item.name,
                quantity: quantity,
                cost: item.price * quantity
            });
        }

        return {
            success: true,
            message: `批量購買成功！`,
            results: results,
            totalCost: totalCost,
            remainingCurrency: this.getCurrency()
        };
    },

    // 獲取購買建議
    getPurchaseSuggestions() {
        const inventory = InventorySystem.getInventory();
        const equippedItems = InventorySystem.getEquippedItems();
        const suggestions = [];

        // 建議1：如果沒有裝備道具，建議購買基本道具
        if (equippedItems.length === 0) {
            suggestions.push({
                type: 'basic',
                message: '建議購買基本道具開始遊戲',
                items: ['CLEAR_ALL', 'CLEAR_ROW']
            });
        }

        // 建議2：如果某些道具用完了，建議補充
        for (const itemId of equippedItems) {
            const quantity = inventory[itemId] || 0;
            if (quantity === 0) {
                const item = ItemSystem.getItemData(itemId);
                if (item) {
                    suggestions.push({
                        type: 'refill',
                        message: `${item.name} 已用完，建議補充`,
                        items: [itemId]
                    });
                }
            }
        }

        // 建議3：如果背包空間充足，建議購買新道具
        const totalItems = Object.values(inventory).reduce((sum, qty) => sum + qty, 0);
        if (totalItems < 6) {
            const unownedItems = ItemSystem.getAllItems().filter(item => 
                !inventory[item.id] || inventory[item.id] === 0
            );
            
            if (unownedItems.length > 0) {
                suggestions.push({
                    type: 'expand',
                    message: '發現新道具，建議嘗試',
                    items: unownedItems.slice(0, 2).map(item => item.id)
                });
            }
        }

        return suggestions;
    },

    // 格式化貨幣顯示
    formatCurrency(amount) {
        return `${this.config.currencyIcon} ${amount.toLocaleString()}`;
    },

    // 測試功能：補充金錢到1000元
    fillMoneyTo1000() {
        console.log('🧪 測試功能：補充金錢到1000元');
        this.setCurrency(1000);
        
        // 返回更新後的金額
        return this.getCurrency();
    },

    // 重置商城數據（測試用）
    resetShopData() {
        console.log('🔄 重置商城數據');
        localStorage.removeItem('player_currency');
        InventorySystem.clearInventory();
        this.initializeTestData();
    }
};

// 導出商城系統
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ShopSystem;
} 