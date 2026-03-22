/**
 * CatDisplay - 闖關模式貓咪角色顯示系統
 * 管理左側面板的 5 隻貓咪角色顯示與動畫
 */
class CatDisplay {
    constructor(containerEl) {
        this.container = containerEl;
        this.cats = [
            { id: 'blaze', name: '火焰貓', color: 'red', hex: '#EF4444', status: 'normal', emoji: '🔥' },
            { id: 'tide', name: '海潮貓', color: 'blue', hex: '#3B82F6', status: 'normal', emoji: '🌊' },
            { id: 'forest', name: '森林貓', color: 'green', hex: '#10B981', status: 'normal', emoji: '🌿' },
            { id: 'flash', name: '閃電貓', color: 'yellow', hex: '#F59E0B', status: 'normal', emoji: '⚡' },
            { id: 'shadow', name: '暗影貓', color: 'purple', hex: '#8B5CF6', status: 'normal', emoji: '🌙' }
        ];
        this.catElements = {};
        this.render();
    }

    render() {
        this.container.innerHTML = '';

        // 場景背景已由 CSS 處理
        const catsWrapper = document.createElement('div');
        catsWrapper.className = 'cats-wrapper';

        this.cats.forEach(cat => {
            const catEl = this.createCatElement(cat);
            this.catElements[cat.color] = catEl;
            catsWrapper.appendChild(catEl);
        });

        this.container.appendChild(catsWrapper);
    }

    createCatElement(cat) {
        const wrapper = document.createElement('div');
        wrapper.className = 'cat-character';
        wrapper.id = `cat-${cat.id}`;
        wrapper.dataset.color = cat.color;

        // 狀態環圈
        const statusRing = document.createElement('div');
        statusRing.className = 'cat-status-ring status-normal';

        // 貓咪佔位符 SVG
        const catSvg = document.createElement('div');
        catSvg.className = 'cat-placeholder';
        catSvg.innerHTML = this.createCatSVG(cat);

        // 貓咪名稱
        const nameTag = document.createElement('div');
        nameTag.className = 'cat-name-tag';
        nameTag.innerHTML = `<span class="cat-emoji">${cat.emoji}</span> ${cat.name}`;

        statusRing.appendChild(catSvg);
        wrapper.appendChild(statusRing);
        wrapper.appendChild(nameTag);

        return wrapper;
    }

    createCatSVG(cat) {
        const bodyColor = cat.hex;
        const darkerColor = this.darkenColor(cat.hex, 0.2);

        return `
        <svg viewBox="0 0 80 80" class="cat-svg" xmlns="http://www.w3.org/2000/svg">
            <!-- 耳朵 -->
            <polygon points="18,28 25,8 35,25" fill="${bodyColor}" stroke="${darkerColor}" stroke-width="1.5"/>
            <polygon points="62,28 55,8 45,25" fill="${bodyColor}" stroke="${darkerColor}" stroke-width="1.5"/>
            <polygon points="21,26 26,12 33,24" fill="#FFB6C1" opacity="0.6"/>
            <polygon points="59,26 54,12 47,24" fill="#FFB6C1" opacity="0.6"/>

            <!-- 頭部 -->
            <ellipse cx="40" cy="34" rx="22" ry="18" fill="${bodyColor}" stroke="${darkerColor}" stroke-width="1.5"/>

            <!-- 眼睛 -->
            <ellipse cx="32" cy="32" rx="4" ry="5" fill="white"/>
            <ellipse cx="48" cy="32" rx="4" ry="5" fill="white"/>
            <ellipse cx="33" cy="33" rx="2.5" ry="3" fill="#333"/>
            <ellipse cx="49" cy="33" rx="2.5" ry="3" fill="#333"/>
            <circle cx="34" cy="31" r="1" fill="white"/>
            <circle cx="50" cy="31" r="1" fill="white"/>

            <!-- 鼻子 -->
            <ellipse cx="40" cy="38" rx="2" ry="1.5" fill="#FF9999"/>

            <!-- 嘴巴 -->
            <path d="M37,40 Q40,43 43,40" fill="none" stroke="#666" stroke-width="1" stroke-linecap="round"/>

            <!-- 鬍鬚 -->
            <line x1="18" y1="35" x2="30" y2="37" stroke="#999" stroke-width="0.8"/>
            <line x1="18" y1="38" x2="30" y2="38" stroke="#999" stroke-width="0.8"/>
            <line x1="50" y1="37" x2="62" y2="35" stroke="#999" stroke-width="0.8"/>
            <line x1="50" y1="38" x2="62" y2="38" stroke="#999" stroke-width="0.8"/>

            <!-- 身體 -->
            <ellipse cx="40" cy="60" rx="18" ry="14" fill="${bodyColor}" stroke="${darkerColor}" stroke-width="1.5"/>

            <!-- 前腳 -->
            <ellipse cx="28" cy="70" rx="5" ry="4" fill="${bodyColor}" stroke="${darkerColor}" stroke-width="1"/>
            <ellipse cx="52" cy="70" rx="5" ry="4" fill="${bodyColor}" stroke="${darkerColor}" stroke-width="1"/>

            <!-- 尾巴 -->
            <path d="M58,55 Q72,45 68,35" fill="none" stroke="${bodyColor}" stroke-width="5" stroke-linecap="round"/>
            <path d="M58,55 Q72,45 68,35" fill="none" stroke="${darkerColor}" stroke-width="5.5" stroke-linecap="round" opacity="0.2"/>
        </svg>`;
    }

    darkenColor(hex, amount) {
        const num = parseInt(hex.replace('#', ''), 16);
        const r = Math.max(0, (num >> 16) - Math.round(255 * amount));
        const g = Math.max(0, ((num >> 8) & 0x00FF) - Math.round(255 * amount));
        const b = Math.max(0, (num & 0x0000FF) - Math.round(255 * amount));
        return `#${(r << 16 | g << 8 | b).toString(16).padStart(6, '0')}`;
    }

    /**
     * 當方塊消除時觸發對應貓咪動畫
     * @param {string[]} colors - 被消除的顏色名稱陣列
     */
    onBlocksEliminated(colors) {
        const uniqueColors = [...new Set(colors)];
        uniqueColors.forEach(color => {
            const catEl = this.catElements[color];
            if (catEl) {
                catEl.classList.add('cat-cheer');
                setTimeout(() => catEl.classList.remove('cat-cheer'), 600);
            }
        });
    }

    /**
     * 連擊時所有貓咪動畫
     * @param {number} comboCount - 連擊數
     */
    onCombo(comboCount) {
        if (comboCount >= 3) {
            Object.values(this.catElements).forEach(catEl => {
                catEl.classList.add('cat-combo-cheer');
                setTimeout(() => catEl.classList.remove('cat-combo-cheer'), 800);
            });
        }
    }

    /**
     * 更新貓咪狀態環顏色
     * @param {string} colorName - 貓咪對應的顏色
     * @param {'normal'|'warning'|'danger'} status - 狀態
     */
    updateCatStatus(colorName, status) {
        const catEl = this.catElements[colorName];
        if (!catEl) return;

        const ring = catEl.querySelector('.cat-status-ring');
        if (!ring) return;

        ring.classList.remove('status-normal', 'status-warning', 'status-danger');
        ring.classList.add(`status-${status}`);
    }

    /**
     * 根據闖關限制更新貓咪狀態
     * @param {object} restrictions - 關卡限制
     */
    updateFromRestrictions(restrictions) {
        if (!restrictions) return;

        // 重置所有貓咪狀態
        this.cats.forEach(cat => this.updateCatStatus(cat.color, 'normal'));

        // 無效顏色的貓咪顯示紅色
        if (restrictions.noDamageColors) {
            restrictions.noDamageColors.forEach(color => {
                this.updateCatStatus(color, 'danger');
            });
        }

        // 有效顏色的貓咪保持綠色，其他變黃色
        if (restrictions.damageOnlyColors) {
            this.cats.forEach(cat => {
                if (!restrictions.damageOnlyColors.includes(cat.color)) {
                    this.updateCatStatus(cat.color, 'danger');
                }
            });
        }
    }
}
