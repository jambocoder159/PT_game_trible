# 部署設定指南

## 🌍 環境架構

我們的應用程式支援四個環境：

1. **Development** (`localhost`)：本地開發
2. **Preview** (`*.vercel.app`)：Vercel 預覽部署  
3. **Staging** (`*-staging*.vercel.app`)：測試環境
4. **Production** (`your-custom-domain.com`)：正式環境

## 🔧 設定步驟

### 1. 自定義域名設定

1. **購買域名**（推薦）
2. **在 Vercel 中設定自定義域名**：
   - 前往 Vercel Dashboard > 您的專案 > Settings > Domains
   - 添加您的自定義域名（例如：`yourgame.com`）
   - 設定 DNS 記錄

### 2. 更新環境配置

編輯 `js/EnvironmentConfig.js`：

```javascript
// 修改 production 配置中的域名
production: {
    supabaseUrl: 'https://admkbelthyyqngsnsxmm.supabase.co',
    supabaseKey: 'your-key',
    redirectBaseUrl: 'https://yourgame.com'  // 您的自定義域名
},

// 修改 preview 配置中的重定向
preview: {
    supabaseUrl: 'https://admkbelthyyqngsnsxmm.supabase.co',
    supabaseKey: 'your-key',
    redirectBaseUrl: 'https://yourgame.com', // 重定向到生產環境
    useProductionRedirect: true
}
```

### 3. Supabase 設定

**URL Configuration**：
- Site URL: `https://yourgame.com`
- Redirect URLs:
  ```
  https://yourgame.com/game.html
  https://yourgame.com/index.html
  http://localhost:3000/game.html  (開發用)
  http://localhost:3000/index.html (開發用)
  ```

### 4. Google OAuth 設定

在 Google Cloud Console 中：
- Authorized redirect URIs: `https://admkbelthyyqngsnsxmm.supabase.co/auth/v1/callback`

## 🚀 部署流程

### Preview 環境
```bash
git push origin feature-branch
# Vercel 自動創建 Preview 部署
# OAuth 登入會重定向到生產環境
```

### Production 環境
```bash
git push origin main
# 部署到自定義域名
# OAuth 登入在同域名內完成
```

## 🔍 環境識別邏輯

```javascript
// 環境檢測邏輯
detectEnvironment() {
    const hostname = window.location.hostname;
    
    if (hostname === 'yourgame.com') return 'production';
    if (hostname.includes('staging') && hostname.includes('vercel.app')) return 'staging';
    if (hostname === 'localhost') return 'development';
    if (hostname.includes('vercel.app')) return 'preview';
    return 'development';
}
```

## ⚠️ Preview 環境處理

**問題**：Vercel Preview 每次部署產生新 URL
**解決方案**：Preview 環境的 OAuth 重定向到生產環境

**用戶體驗流程**：
1. 用戶在 Preview 環境測試功能
2. 點擊登入 → 跳轉到 Google
3. 登入完成 → 重定向到生產環境
4. 用戶可以在生產環境中查看登入狀態

## 🛠️ 開發工作流程

### 本地開發
```bash
npm run dev
# 使用 localhost:3000
# OAuth 重定向回本地
```

### 功能測試
```bash
git push origin feature-branch
# 檢查 Preview 環境功能
# OAuth 測試會重定向到生產環境
```

### 正式發布
```bash
git push origin main
# 部署到生產環境
# 完整功能測試
```

## 📊 環境監控

每個環境會在 console 顯示：
- 當前環境類型
- 重定向 URL
- Supabase 配置
- 環境警告（Preview 環境）

## 🔄 緊急回退

如果 OAuth 出現問題：
1. 檢查 Supabase URL Configuration
2. 確認自定義域名 DNS 設定
3. 驗證 Google OAuth 設定
4. 清除瀏覽器快取重試

## 💡 最佳實踐

1. **自定義域名**：避免依賴 Vercel 隨機 URL
2. **環境隔離**：不同環境使用不同配置
3. **監控日誌**：檢查 console 中的環境資訊
4. **測試流程**：在 Preview 環境測試功能，在生產環境測試 OAuth 