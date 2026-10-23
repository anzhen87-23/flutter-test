/**
 * 登录页面
 */

import { auth, setToken, saveUser } from '../modules/api.js';
import { showToast, validatePassword, escapeHtml } from '../modules/ui.js';
import { navigate } from '../router.js';

export function renderLogin(container) {
    container.innerHTML = `
        <div class="card auth-card">
            <h2>📝 登录</h2>
            <form id="login-form">
                <div class="form-group">
                    <label class="form-label">账号</label>
                    <input type="text" id="login-account" class="form-input"
                        placeholder="手机号/邮箱/用户名" autocomplete="username" required>
                </div>
                <div class="form-group">
                    <label class="form-label">密码</label>
                    <input type="password" id="login-password" class="form-input"
                        placeholder="6位数字密码" maxlength="6" autocomplete="current-password" required>
                    <p class="form-hint">密码为6位数字</p>
                </div>
                <button type="submit" class="btn btn-primary btn-block" id="login-btn">登录</button>
            </form>
            <div class="auth-links">
                <a href="#/register">没有账号？立即注册</a>
                <a href="#/reset-password">忘记密码？</a>
            </div>
        </div>
    `;

    // 添加样式
    const style = document.createElement('style');
    style.textContent = `
        .auth-links {
            margin-top: 20px;
            display: flex;
            justify-content: space-between;
            font-size: 14px;
        }
    `;
    document.head.appendChild(style);

    // 绑定事件
    const form = document.getElementById('login-form');
    const accountInput = document.getElementById('login-account');
    const passwordInput = document.getElementById('login-password');
    const loginBtn = document.getElementById('login-btn');

    // 密码只允许数字
    passwordInput.addEventListener('input', (e) => {
        e.target.value = e.target.value.replace(/\D/g, '').slice(0, 6);
    });

    form.addEventListener('submit', async (e) => {
        e.preventDefault();

        const account = accountInput.value.trim();
        const password = passwordInput.value;

        if (!account) {
            showToast('请输入账号', 'error');
            accountInput.focus();
            return;
        }

        if (!validatePassword(password)) {
            showToast('密码必须为6位数字', 'error');
            passwordInput.focus();
            return;
        }

        loginBtn.disabled = true;
        loginBtn.textContent = '登录中...';

        try {
            const result = await auth.login(account, password);
            const { token, user } = result.data;

            setToken(token);
            saveUser(user);

            showToast('登录成功', 'success');
            navigate('/notes');
        } catch (error) {
            showToast(error.message, 'error');
        } finally {
            loginBtn.disabled = false;
            loginBtn.textContent = '登录';
        }
    });
}
