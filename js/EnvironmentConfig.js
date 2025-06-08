// 環境配置管理器
class EnvironmentConfig {
    constructor() {
        this.environment = this.detectEnvironment();
        this.config = this.getConfig();
    }
    
    // 檢測當前環境
    detectEnvironment() {
        const hostname = window.location.hostname;
        const href = window.location.href;
        
        // Production 環境 - 使用自定義域名
        if (hostname === 'your-custom-domain.com') {
            return 'production';
        }
        
        // Staging 環境 - 使用特定的 Vercel 域名
        if (hostname.includes('your-app-staging') && hostname.includes('vercel.app')) {
            return 'staging';
        }
        
        // 本地開發環境
        if (hostname === 'localhost' || hostname === '127.0.0.1') {
            return 'development';
        }
        
        // Vercel Preview 環境 - 所有其他 vercel.app 域名
        if (hostname.includes('vercel.app')) {
            return 'preview';
        }
        
        // 預設為開發環境
        return 'development';
    }
    
    // 獲取環境配置
    getConfig() {
        const configs = {
            // 生產環境配置
            production: {
                supabaseUrl: 'https://admkbelthyyqngsnsxmm.supabase.co',
                supabaseKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkbWtiZWx0aHl5cW5nc25zeG1tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzMDU4NjMsImV4cCI6MjA2NDg4MTg2M30.NdpkqWnSJsb9bHQn8H7_CgpIkwu9f5kSzLrWV39ta2w',
                redirectBaseUrl: 'https://your-custom-domain.com'
            },
            
            // 測試環境配置
            staging: {
                supabaseUrl: 'https://admkbelthyyqngsnsxmm.supabase.co',
                supabaseKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkbWtiZWx0aHl5cW5nc25zeG1tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzMDU4NjMsImV4cCI6MjA2NDg4MTg2M30.NdpkqWnSJsb9bHQn8H7_CgpIkwu9f5kSzLrWV39ta2w',
                redirectBaseUrl: window.location.origin // 使用當前域名
            },
            
            // 開發環境配置
            development: {
                supabaseUrl: 'https://admkbelthyyqngsnsxmm.supabase.co',
                supabaseKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkbWtiZWx0aHl5cW5nc25zeG1tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzMDU4NjMsImV4cCI6MjA2NDg4MTg2M30.NdpkqWnSJsb9bHQn8H7_CgpIkwu9f5kSzLrWV39ta2w',
                redirectBaseUrl: 'http://localhost:3000' // 固定本地端口
            },
            
            // Preview 環境配置 - 關鍵！
            preview: {
                supabaseUrl: 'https://admkbelthyyqngsnsxmm.supabase.co',
                supabaseKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkbWtiZWx0aHl5cW5nc25zeG1tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzMDU4NjMsImV4cCI6MjA2NDg4MTg2M30.NdpkqWnSJsb9bHQn8H7_CgpIkwu9f5kSzLrWV39ta2w',
                redirectBaseUrl: 'https://your-custom-domain.com', // 重定向到生產環境！
                useProductionRedirect: true // 特殊標記
            }
        };
        
        return configs[this.environment];
    }
    
    // 獲取重定向 URL
    getRedirectUrl(pathname = '/game.html', searchParams = '?mode=classic') {
        const config = this.config;
        
        console.log(`環境檢測: ${this.environment}`);
        console.log(`重定向基礎 URL: ${config.redirectBaseUrl}`);
        
        // Preview 環境特殊處理：重定向到生產環境
        if (this.environment === 'preview' && config.useProductionRedirect) {
            const redirectUrl = `${config.redirectBaseUrl}${pathname}${searchParams}`;
            console.log(`Preview 環境重定向到生產環境: ${redirectUrl}`);
            return redirectUrl;
        }
        
        // 其他環境使用相應的配置
        const redirectUrl = `${config.redirectBaseUrl}${pathname}${searchParams}`;
        console.log(`${this.environment} 環境重定向 URL: ${redirectUrl}`);
        return redirectUrl;
    }
    
    // 是否允許 OAuth 登入
    isOAuthEnabled() {
        // Preview 環境可以選擇禁用 OAuth 或重定向到生產環境
        if (this.environment === 'preview') {
            return true; // 允許但會重定向到生產環境
        }
        return true;
    }
    
    // 獲取環境資訊
    getEnvironmentInfo() {
        return {
            environment: this.environment,
            hostname: window.location.hostname,
            origin: window.location.origin,
            config: this.config,
            isProduction: this.environment === 'production',
            isDevelopment: this.environment === 'development',
            isPreview: this.environment === 'preview',
            isStaging: this.environment === 'staging'
        };
    }
    
    // 顯示環境警告（Preview 環境）
    showEnvironmentWarning() {
        if (this.environment === 'preview') {
            console.warn('⚠️ 您正在 Vercel Preview 環境中。OAuth 登入將重定向到生產環境。');
            
            // 可選：在頁面上顯示提示
            if (typeof document !== 'undefined') {
                this.createEnvironmentBanner();
            }
        }
    }
    
    // 創建環境提示横幅
    createEnvironmentBanner() {
        if (document.getElementById('envBanner')) return; // 避免重複創建
        
        const banner = document.createElement('div');
        banner.id = 'envBanner';
        banner.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            background: linear-gradient(90deg, #f59e0b, #d97706);
            color: white;
            text-align: center;
            padding: 8px;
            font-size: 14px;
            z-index: 9999;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        `;
        
        banner.innerHTML = `
            ⚠️ Preview 環境 - OAuth 登入將重定向到生產環境 
            <button onclick="this.parentElement.remove()" style="background:none;border:none;color:white;margin-left:10px;cursor:pointer;">✕</button>
        `;
        
        document.body.insertBefore(banner, document.body.firstChild);
        
        // 自動隱藏
        setTimeout(() => {
            if (document.getElementById('envBanner')) {
                banner.remove();
            }
        }, 10000);
    }
}

// 全域實例
window.environmentConfig = new EnvironmentConfig();

// 顯示環境資訊
console.log('🌍 環境配置:', window.environmentConfig.getEnvironmentInfo()); 