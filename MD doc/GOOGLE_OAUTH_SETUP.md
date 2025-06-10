# Google OAuth 多環境配置指南

## 🎯 問題說明

在開發三消遊戲時，你需要在不同環境（本地、預覽、正式）中測試 OAuth 登入功能，但每個環境的域名不同，需要相應的重定向 URL 配置。

## 🚨 關鍵修復：Supabase 回調 URL

**重要：你遇到的 400 錯誤是因為缺少 Supabase 的回調 URL！**

立即在 Google Cloud Console 中添加：
```
https://admkbelthyyqngsnsxmm.supabase.co/auth/v1/callback
```

## 🚀 解決方案

### 方案一：單一 OAuth 應用 + 多重定向 URL（推薦）

#### 1. 進入 Google Cloud Console
1. 前往 [Google Cloud Console](https://console.cloud.google.com)
2. 選擇你的項目或創建新項目
3. 啟用 Google+ API 或 Google Identity Services

#### 2. 配置 OAuth 2.0 用戶端
1. 前往 **APIs & Services** > **Credentials**
2. 找到你的現有 OAuth Client ID：`345527889051-r7biqbai0q6ps6q400rajivcmhp7rptd.apps.googleusercontent.com`
3. 點擊編輯

#### 3. 添加重定向 URI（關鍵步驟）

在 **Authorized redirect URIs** 中添加以下 URL：

```
# 🚨 必需：Supabase 回調 URL
https://admkbelthyyqngsnsxmm.supabase.co/auth/v1/callback

# 本地開發環境
http://localhost:3000/main-menu.html
http://localhost:5173/main-menu.html
http://localhost:8080/main-menu.html
http://127.0.0.1:3000/main-menu.html

# Vercel Preview 環境（動態）
https://pt-game-trible-{hash}.vercel.app/main-menu.html

# 正式環境
https://pt-game-trible.vercel.app/main-menu.html
https://your-custom-domain.com/main-menu.html
```

#### 4. Supabase 配置

在 Supabase Dashboard 中：

1. 前往 **Authentication** > **URL Configuration**
2. 設定 **Site URL**：`https://pt-game-trible.vercel.app`
3. 添加 **Redirect URLs**：
   ```
   http://localhost:3000/main-menu.html
   http://localhost:5173/main-menu.html
   http://localhost:8080/main-menu.html
   https://pt-game-trible.vercel.app/main-menu.html
   https://your-custom-domain.com/main-menu.html
   ```

#### 5. Google Provider 設定
1. 前往 **Authentication** > **Providers**
2. 啟用 **Google**
3. 輸入 Google OAuth 的 **Client ID** 和 **Client Secret**

---

### 方案二：多個 OAuth 應用（完全隔離）

如果你希望完全隔離不同環境，可以創建多個 OAuth 應用：

#### 開發環境 OAuth
- **名稱**：`三消挑戰 - 開發`
- **重定向 URI**：
  ```
  https://admkbelthyyqngsnsxmm.supabase.co/auth/v1/callback
  http://localhost:3000/main-menu.html
  http://localhost:5173/main-menu.html
  http://localhost:8080/main-menu.html
  ```

#### 預覽環境 OAuth
- **名稱**：`三消挑戰 - 預覽`
- **重定向 URI**：
  ```
  https://admkbelthyyqngsnsxmm.supabase.co/auth/v1/callback
  https://*.vercel.app/main-menu.html
  ```

#### 正式環境 OAuth
- **名稱**：`三消挑戰 - 正式`
- **重定向 URI**：
  ```
  https://admkbelthyyqngsnsxmm.supabase.co/auth/v1/callback
  https://pt-game-trible.vercel.app/main-menu.html
  https://your-custom-domain.com/main-menu.html
  ```

然後在不同環境使用不同的 Client ID。

---

## 🔧 現在的代碼修復

我已經修復了 `EnvironmentConfig.js`，現在：

### ✅ 修復內容
1. **本地開發**：使用 `window.location.origin`，自動適配任何端口
2. **Preview 環境**：使用當前 Preview URL，不再重定向到正式環境
3. **生產環境**：使用正式域名

### 🎯 環境檢測邏輯
```javascript
// 本地：localhost:任何端口 → development
// 正式：pt-game-trible.vercel.app → production  
// 預覽：任何其他 .vercel.app → preview
```

### 📋 重定向 URL 模式
```javascript
// 所有環境都重定向到 main-menu.html
${當前環境域名}/main-menu.html
```

---

## 🧪 測試步驟

### 1. 本地測試
```bash
# 啟動本地服務器（任何端口都行）
npx serve . -p 3000
# 或
npx serve . -p 5173
# 或
python -m http.server 8080
```

打開 `http://localhost:{端口}/main-menu.html`，測試 Google 登入。

### 2. Preview 測試
1. 推送代碼到 GitHub
2. Vercel 自動創建 Preview 部署
3. 訪問 Preview URL，測試登入

### 3. 正式環境測試
訪問正式域名，測試登入功能。

---

## 🛠️ 快速配置工具

我已經在 `EnvironmentConfig.js` 中添加了配置建議工具：

```javascript
// 在瀏覽器控制台中運行
console.log(window.environmentConfig.getOAuthConfigSuggestion());
```

這會顯示當前環境建議的重定向 URL 列表。

---

## 📋 檢查清單

### Google Cloud Console（🚨 立即執行）
- [ ] 找到現有的 OAuth Client ID：`345527889051-r7biqbai0q6ps6q400rajivcmhp7rptd.apps.googleusercontent.com`
- [ ] **添加 Supabase 回調 URL**：`https://admkbelthyyqngsnsxmm.supabase.co/auth/v1/callback`
- [ ] 添加所有環境的最終重定向 URI
- [ ] 保存配置

### Supabase Dashboard
- [ ] 設定 Site URL
- [ ] 添加所有 Redirect URLs
- [ ] 配置 Google Provider
- [ ] 輸入 Google OAuth 憑證

### 代碼配置
- [ ] 更新 `EnvironmentConfig.js`（已完成）
- [ ] 測試本地環境登入
- [ ] 測試 Preview 環境登入
- [ ] 測試正式環境登入

---

## 🔍 常見問題

### Q: 為什麼需要 Supabase 回調 URL？
**A**: OAuth 流程是：你的網站 → Google 登入 → Supabase 回調 → 你的網站。Supabase 回調 URL 必須在 Google OAuth 配置中。

### Q: 本地登入後還是跳到正式環境？
**A**: 檢查 Google OAuth 和 Supabase 是否都添加了本地重定向 URL。

### Q: Preview 環境 URL 會變化怎麼辦？
**A**: 使用通配符模式或在每次 Preview 時手動添加 URL。推薦使用方案一的多 URL 配置。

### Q: 可以用一個配置支援所有環境嗎？
**A**: 可以！使用方案一，在 Google OAuth 中添加所有可能的重定向 URL。

---

## 🚨 緊急修復步驟

1. **立即前往 Google Cloud Console**
2. **找到你的 OAuth Client ID**：`345527889051-r7biqbai0q6ps6q400rajivcmhp7rptd.apps.googleusercontent.com`
3. **點擊編輯**
4. **在 Authorized redirect URIs 中添加**：`https://admkbelthyyqngsnsxmm.supabase.co/auth/v1/callback`
5. **保存**
6. **重新測試 OAuth 登入**

現在你的本地開發環境應該能正確重定向了！🎉 