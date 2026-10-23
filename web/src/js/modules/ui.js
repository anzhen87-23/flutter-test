/**
 * UI 工具模块
 * Toast提示、确认对话框等通用UI组件
 */

/**
 * 显示 Toast 提示
 */
export function showToast(message, type = 'success', duration = 3000) {
    const container = document.getElementById('toast-container');
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    container.appendChild(toast);

    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(100%)';
        toast.style.transition = 'all 0.3s ease';
        setTimeout(() => toast.remove(), 300);
    }, duration);
}

/**
 * 显示确认对话框
 */
export function showConfirm(message) {
    return new Promise((resolve) => {
        const dialog = document.getElementById('confirm-dialog');
        const messageEl = document.getElementById('confirm-message');
        const okBtn = document.getElementById('confirm-ok');
        const cancelBtn = document.getElementById('confirm-cancel');

        messageEl.textContent = message;
        dialog.classList.remove('hidden');

        const cleanup = () => {
            dialog.classList.add('hidden');
            okBtn.onclick = null;
            cancelBtn.onclick = null;
        };

        okBtn.onclick = () => {
            cleanup();
            resolve(true);
        };

        cancelBtn.onclick = () => {
            cleanup();
            resolve(false);
        };
    });
}

/**
 * 格式化日期
 */
export function formatDate(dateStr) {
    if (!dateStr) return '';
    const date = new Date(dateStr);
    const now = new Date();
    const diff = now - date;

    // 1分钟内
    if (diff < 60 * 1000) return '刚刚';
    // 1小时内
    if (diff < 60 * 60 * 1000) return `${Math.floor(diff / 60000)}分钟前`;
    // 24小时内
    if (diff < 24 * 60 * 60 * 1000) return `${Math.floor(diff / 3600000)}小时前`;
    // 7天内
    if (diff < 7 * 24 * 60 * 60 * 1000) return `${Math.floor(diff / 86400000)}天前`;

    // 更早：显示具体日期
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');

    // 同年不显示年份
    if (year === now.getFullYear()) {
        return `${month}-${day}`;
    }
    return `${year}-${month}-${day}`;
}

/**
 * 验证手机号格式
 */
export function validatePhone(phone) {
    return /^1[3-9]\d{9}$/.test(phone);
}

/**
 * 验证邮箱格式
 */
export function validateEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

/**
 * 验证密码格式（6位数字）
 */
export function validatePassword(password) {
    return /^\d{6}$/.test(password);
}

/**
 * 验证验证码格式（6位数字）
 */
export function validateCode(code) {
    return /^\d{6}$/.test(code);
}

/**
 * 显示 Loading 状态
 */
export function showLoading(container, text = '加载中...') {
    container.innerHTML = `
        <div class="loading">
            <div class="spinner"></div>
            <p>${text}</p>
        </div>
    `;
}

/**
 * 显示空状态
 */
export function showEmpty(container, icon = '📭', text = '暂无数据') {
    container.innerHTML = `
        <div class="empty-state">
            <div class="empty-state-icon">${icon}</div>
            <p class="empty-state-text">${text}</p>
        </div>
    `;
}

/**
 * 防抖函数
 */
export function debounce(fn, delay = 300) {
    let timer = null;
    return function (...args) {
        clearTimeout(timer);
        timer = setTimeout(() => fn.apply(this, args), delay);
    };
}

/**
 * 转义 HTML（防止XSS）
 */
export function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
