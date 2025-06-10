// 環境配置管理器
class EnvironmentConfig {
    constructor() {
        this.environment = this.detectEnvironment();
        this.config = this.getConfig();
        this.showEnvironmentInfo();
    }
    
    // 檢測當前環境
    detectEnvironment() {
        const hostname = window.location.hostname;
        const href = window.location.href;
        
        // Production 環境 - 使用自定義域名或主要 Vercel 域名
        if (hostname === 'your-custom-domain.com' || 
            hostname === 'pt-game-trible.vercel.app') {
            return 'production';
        }
        
        // 本地開發環境
        if (hostname === 'localhost' || hostname === '127.0.0.1' || hostname.includes('localhost')) {
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
                redirectBaseUrl: window.location.origin, // 使用當前域名
                oauthEnabled: true
            },
            
            // 開發環境配置 - 修復！
            development: {
                supabaseUrl: 'https://admkbelthyyqngsnsxmm.supabase.co',
                supabaseKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkbWtiZWx0aHl5cW5nc25zeG1tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzMDU4NjMsImV4cCI6MjA2NDg4MTg2M30.NdpkqWnSJsb9bHQn8H7_CgpIkwu9f5kSzLrWV39ta2w',
                redirectBaseUrl: window.location.origin, // 動態獲取本地端口
                oauthEnabled: true
            },
            
            // Preview 環境配置 - 修復！
            preview: {
                supabaseUrl: 'https://admkbelthyyqngsnsxmm.supabase.co',
                supabaseKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkbWtiZWx0aHl5cW5nc25zeG1tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzMDU4NjMsImV4cCI6MjA2NDg4MTg2M30.NdpkqWnSJsb9bHQn8H7_CgpIkwu9f5kSzLrWV39ta2w',
                redirectBaseUrl: window.location.origin, // 使用當前 Preview URL
                oauthEnabled: true
            }
        };
        
        return configs[this.environment];
    }
    
    // 獲取重定向 URL
    getRedirectUrl(pathname = '/main-menu.html', searchParams = '') {
        const config = this.config;
        
        console.log(`🌍 環境: ${this.environment}`);
        console.log(`🔗 重定向基礎 URL: ${config.redirectBaseUrl}`);
        
        // 統一使用當前環境的 URL
        const redirectUrl = `${config.redirectBaseUrl}${pathname}${searchParams}`;
        console.log(`➡️ 最終重定向 URL: ${redirectUrl}`);
        return redirectUrl;
    }
    
    // 是否允許 OAuth 登入
    isOAuthEnabled() {
        return this.config.oauthEnabled;
    }
    
    // 獲取環境資訊
    getEnvironmentInfo() {
        return {
            environment: this.environment,
            hostname: window.location.hostname,
            origin: window.location.origin,
            port: window.location.port,
            config: this.config,
            isProduction: this.environment === 'production',
            isDevelopment: this.environment === 'development',
            isPreview: this.environment === 'preview'
        };
    }
    
    // 顯示環境資訊
    showEnvironmentInfo() {
        const info = this.getEnvironmentInfo();
        console.log('🌍 環境配置詳情:', info);
        
        if (this.environment === 'development') {
            console.log('🔧 本地開發模式 - OAuth 將重定向回本地環境');
        } else if (this.environment === 'preview') {
            console.log('👀 Preview 模式 - OAuth 將重定向回當前 Preview URL');
        } else if (this.environment === 'production') {
            console.log('🚀 生產模式');
        }
    }
    
    // 創建環境提示横幅
    createEnvironmentBanner() {
        if (document.getElementById('envBanner')) return;
        
        const banner = document.createElement('div');
        banner.id = 'envBanner';
        banner.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            background: ${this.environment === 'development' ? '#10b981' : 
                         this.environment === 'preview' ? '#f59e0b' : '#3b82f6'};
            color: white;
            text-align: center;
            padding: 8px;
            font-size: 14px;
            z-index: 9999;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        `;
        
        const messages = {
            development: '🔧 本地開發模式',
            preview: '👀 Preview 環境',
            production: '🚀 生產環境'
        };
        
        banner.innerHTML = `
            ${messages[this.environment]} - ${window.location.origin}
            <button onclick="this.parentElement.remove()" style="background:none;border:none;color:white;margin-left:10px;cursor:pointer;">✕</button>
        `;
        
        document.body.insertBefore(banner, document.body.firstChild);
        
        // 5秒後自動隱藏
        setTimeout(() => {
            if (document.getElementById('envBanner')) {
                banner.remove();
            }
        }, 5000);
    }
    
    // 獲取 OAuth 配置建議
    getOAuthConfigSuggestion() {
        const suggestions = {
            development: [
                'http://localhost:3000/main-menu.html',
                'http://localhost:5173/main-menu.html', // Vite
                'http://localhost:8080/main-menu.html',  // 常見端口
                'http://127.0.0.1:3000/main-menu.html'
            ],
            preview: [
                `${window.location.origin}/main-menu.html`
            ],
            production: [
                'https://your-custom-domain.com/main-menu.html',
                'https://pt-game-trible.vercel.app/main-menu.html'
            ]
        };
        
        return suggestions;
    }
}

// 全域實例
if (typeof window !== 'undefined') {
    window.EnvironmentConfig = EnvironmentConfig;
    window.environmentConfig = new EnvironmentConfig();
    
    // 當 DOM 載入後顯示環境横幅
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            window.environmentConfig.createEnvironmentBanner();
        });
    } else {
        window.environmentConfig.createEnvironmentBanner();
    }
} 