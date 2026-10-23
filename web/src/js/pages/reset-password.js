/**
 * 重置密码页面
 */

import { auth } from '../modules/api.js';
import {
    showToast, validatePhone, validateEmail,
    validatePassword, validateCode
} from '../modules/ui.js';
import { navigate } from '../router.js';

export function renderResetPassword(container) {
    container.innerHTML = `
        <div class="card auth-card">
            <h2>🔑 重置密码</h2>
            <form id="reset-form">
                <div class="form-group">
                    <label class="form-label">账号</label>
                    <input type="text" id="reset-account" class="form-input"
                        placeholder="手机号或邮箱" required>
                </div>
                <div class="form-group">
                    <label class="form-label">验证码</label>
                    <div class="input-with-code">
                        <input type="text" id="reset-code" class="form-input"
                            placeholder="6位验证码" maxlength="6" required>
                        <button type="button" class="btn" id="send-reset-code">发送验证码</button>
                    </div>
                </div>
                <div class="form-group">
                    <label class="form-label">新密码</label>
                    <input type="password" id="reset-password" class="form-input"
                        placeholder="6位数字密码" maxlength="6" required>
                    <p class="form-hint">密码为6位数字</p>
                </div>
                <div class="form-group">
                    <label class="form-label">确认新密码</label>
                    <input type="password" id="reset-password-confirm" class="form-input"
                        placeholder="再次输入新密码" maxlength="6" required>
                </div>
                <button type="submit" class="btn btn-primary btn-block">重置密码</button>
            </form>
            <div class="auth-links">
                <a href="#/login">返回登录</a>
            </div>
        </div>
    `;

    // 添加样式
    const style = document.createElement('style');
    style.textContent = `
        .auth-links {
            margin-top: 20px;
            text-align: center;
            font-size: 14px;
        }
    `;
    document.head.appendChild(style);

    const accountInput = document.getElementById('reset-account');
    const codeInput = document.getElementById('reset-code');
    const passwordInput = document.getElementById('reset-password');
    const confirmInput = document.getElementById('reset-password-confirm');
    const sendBtn = document.getElementById('send-reset-code');
    const form = document.getElementById('reset-form');

    // 密码只允许数字
    [passwordInput, confirmInput, codeInput].forEach(input => {
        input.addEventListener('input', (e) => {
            e.target.value = e.target.value.replace(/\D/g, '').slice(0, 6);
        });
    });

    // 发送验证码
    let countdown = 0;
    let timer = null;

    sendBtn.addEventListener('click', async () => {
        const account = accountInput.value.trim();
        if (!account) {
            showToast('请输入账号', 'error');
            return;
        }

        const isPhone = validatePhone(account);
        const isEmail = validateEmail(account);
        if (!isPhone && !isEmail) {
            showToast('请输入正确的手机号或邮箱', 'error');
            return;
        }

        if (countdown > 0) return;

        sendBtn.disabled = true;
        try {
            await auth.sendCode(account, 'reset_password');
            showToast('验证码已发送', 'success');

            countdown = 60;
            sendBtn.textContent = `${countdown}s`;
            timer = setInterval(() => {
                countdown--;
                if (countdown <= 0) {
                    clearInterval(timer);
                    sendBtn.disabled = false;
                    sendBtn.textContent = '发送验证码';
                } else {
                    sendBtn.textContent = `${countdown}s`;
                }
            }, 1000);
        } catch (error) {
            showToast(error.message, 'error');
            sendBtn.disabled = false;
        }
    });

    // 提交
    form.addEventListener('submit', async (e) => {
        e.preventDefault();

        const account = accountInput.value.trim();
        const code = codeInput.value.trim();
        const password = passwordInput.value;
        const confirm = confirmInput.value;

        if (!validateCode(code)) {
            showToast('请输入6位验证码', 'error');
            return;
        }
        if (!validatePassword(password)) {
            showToast('密码必须为6位数字', 'error');
            return;
        }
        if (password !== confirm) {
            showToast('两次输入的密码不一致', 'error');
            return;
        }

        const submitBtn = form.querySelector('button[type="submit"]');
        submitBtn.disabled = true;
        submitBtn.textContent = '重置中...';

        try {
            await auth.resetPassword(account, code, password);
            showToast('密码重置成功，请重新登录', 'success');
            navigate('/login');
        } catch (error) {
            showToast(error.message, 'error');
        } finally {
            submitBtn.disabled = false;
            submitBtn.textContent = '重置密码';
        }
    });
}
