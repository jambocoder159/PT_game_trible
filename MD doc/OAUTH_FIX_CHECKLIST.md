# 🚨 OAuth 400 錯誤緊急修復清單

## 問題描述
`錯誤 400：redirect_uri_mismatch` - Google OAuth 配置缺少 Supabase 回調 URL

## 🔥 立即修復步驟

### 1. 前往 Google Cloud Console
1. 打開 [Google Cloud Console](https://console.cloud.google.com)
2. 前往 **APIs & Services** > **Credentials**
3. 找到你的 OAuth 2.0 Client ID：
   ```
   345527889051-r7biqbai0q6ps6q400rajivcmhp7rptd.apps.googleusercontent.com
   ```

### 2. 編輯 OAuth 配置
1. 點擊上面的 Client ID 進行編輯
2. 在 **Authorized redirect URIs** 部分
3. **立即添加這個必需的 URL**：
   ```
   https://admkbelthyyqngsnsxmm.supabase.co/auth/v1/callback
   ```

### 3. 添加完整的重定向 URL 列表

**複製貼上以下所有 URL 到 Authorized redirect URIs：**

```
https://admkbelthyyqngsnsxmm.supabase.co/auth/v1/callback
http://localhost:3000/main-menu.html
http://localhost:5173/main-menu.html
http://localhost:8080/main-menu.html
http://127.0.0.1:3000/main-menu.html
https://pt-game-trible.vercel.app/main-menu.html
```

### 4. 保存配置
1. 點擊 **Save** 按鈕
2. 等待配置生效（通常幾分鐘內）

### 5. 測試修復
1. 回到你的應用
2. 嘗試 Google 登入
3. 應該會成功重定向到 `main-menu.html`

---

## 📋 驗證清單

- [ ] ✅ 已添加 Supabase 回調 URL：`https://admkbelthyyqngsnsxmm.supabase.co/auth/v1/callback`
- [ ] ✅ 已添加本地開發 URL：`http://localhost:3000/main-menu.html`
- [ ] ✅ 已添加其他端口 URL：`http://localhost:5173/main-menu.html`、`http://localhost:8080/main-menu.html`
- [ ] ✅ 已添加正式環境 URL：`https://pt-game-trible.vercel.app/main-menu.html`
- [ ] ✅ 已保存 Google OAuth 配置
- [ ] ✅ 已測試本地 OAuth 登入
- [ ] ✅ 登入後重定向到 `main-menu.html` 而非 `game.html`

---

## 🔍 故障排除

### 如果還是有錯誤：

1. **清除瀏覽器緩存**
2. **等待 5-10 分鐘**讓 Google 配置生效
3. **檢查 Supabase 配置**：
   - 前往 Supabase Dashboard
   - Authentication > URL Configuration
   - 確認 Redirect URLs 包含：
     ```
     http://localhost:3000/main-menu.html
     http://localhost:5173/main-menu.html
     http://localhost:8080/main-menu.html
     https://pt-game-trible.vercel.app/main-menu.html
     ```

### 如果重定向到錯誤頁面：

檢查 `js/SupabaseAuth.js` 中的 `getRedirectUrl()` 方法是否已更新為使用 `main-menu.html`。

---

## 🎯 技術細節

### OAuth 流程：
1. **用戶點擊 Google 登入** → 重定向到 Google
2. **Google 驗證** → 重定向到 Supabase 回調 URL
3. **Supabase 處理認證** → 重定向到你的應用
4. **最終到達** → `main-menu.html`

### 關鍵 URL：
- **Supabase 回調**：`https://admkbelthyyqngsnsxmm.supabase.co/auth/v1/callback`
- **最終重定向**：`http://localhost:3000/main-menu.html`（或其他環境的對應 URL）

---

## ✅ 修復完成確認

當看到以下情況時，表示修復成功：
1. Google 登入不再顯示 400 錯誤
2. 登入成功後重定向到 `main-menu.html`
3. 可以看到用戶登入狀態和個人資訊

**🎉 修復完成！你現在可以在本地環境正常測試 OAuth 功能了。** 