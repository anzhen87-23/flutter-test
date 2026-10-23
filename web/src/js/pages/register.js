/**
 * 注册页面
 */

import { auth, setToken, saveUser } from '../modules/api.js';
import {
    showToast, validatePhone, validateEmail,
    validatePassword, validateCode, escapeHtml
} from '../modules/ui.js';
import { navigate } from '../router.js';

export function renderRegister(container) {
    container.innerHTML = `
        <div class="card auth-card">
            <h2>📝 注册</h2>

            <!-- 注册方式选择 -->
            <div class="register-tabs">
                <button class="tab-btn active" data-tab="phone">手机号注册</button>
                <button class="tab-btn" data-tab="email">邮箱注册</button>
            </div>

            <!-- 手机号注册表单 -->
            <form id="register-phone-form" class="register-form">
                <div class="form-group">
                    <label class="form-label">手机号</label>
                    <input type="tel" id="reg-phone" class="form-input"
                        placeholder="请输入手机号" maxlength="11" required>
                </div>
                <div class="form-group">
                    <label class="form-label">验证码</label>
                    <div class="input-with-code">
                        <input type="text" id="reg-phone-code" class="form-input"
                            placeholder="6位验证码" maxlength="6" required>
                        <button type="button" class="btn" id="send-phone-code">发送验证码</button>
                    </div>
                </div>
                <div class="form-group">
                    <label class="form-label">密码</label>
                    <input type="password" id="reg-phone-password" class="form-input"
                        placeholder="6位数字密码" maxlength="6" required>
                    <p class="form-hint">密码为6位数字</p>
                </div>
                <div class="form-group">
                    <label class="form-label">昵称（选填）</label>
                    <input type="text" id="reg-phone-nickname" class="form-input"
                        placeholder="给自己取个名字" maxlength="50">
                </div>
                <button type="submit" class="btn btn-primary btn-block">注册</button>
            </form>

            <!-- 邮箱注册表单 -->
            <form id="register-email-form" class="register-form hidden">
                <div class="form-group">
                    <label class="form-label">邮箱</label>
                    <input type="email" id="reg-email" class="form-input"
                        placeholder="请输入邮箱" required>
                </div>
                <div class="form-group">
                    <label class="form-label">验证码</label>
                    <div class="input-with-code">
                        <input type="text" id="reg-email-code" class="form-input"
                            placeholder="6位验证码" maxlength="6" required>
                        <button type="button" class="btn" id="send-email-code">发送验证码</button>
                    </div>
                </div>
                <div class="form-group">
                    <label class="form-label">密码</label>
                    <input type="password" id="reg-email-password" class="form-input"
                        placeholder="6位数字密码" maxlength="6" required>
                    <p class="form-hint">密码为6位数字</p>
                </div>
                <div class="form-group">
                    <label class="form-label">昵称（选填）</label>
                    <input type="text" id="reg-email-nickname" class="form-input"
                        placeholder="给自己取个名字" maxlength="50">
                </div>
                <button type="submit" class="btn btn-primary btn-block">注册</button>
            </form>

            <div class="auth-links">
                <a href="#/login">已有账号？立即登录</a>
            </div>
        </div>
    `;

    // 添加样式
    const style = document.createElement('style');
    style.textContent = `
        .register-tabs {
            display: flex;
            margin-bottom: 24px;
            border-bottom: 2px solid var(--border);
        }
        .tab-btn {
            flex: 1;
            padding: 12px;
            border: none;
            background: none;
            cursor: pointer;
            font-size: 14px;
            color: var(--text-secondary);
            border-bottom: 2px solid transparent;
            margin-bottom: -2px;
            transition: all 0.2s;
        }
        .tab-btn.active {
            color: var(--primary);
            border-bottom-color: var(--primary);
            font-weight: 600;
        }
        .auth-links {
            margin-top: 20px;
            text-align: center;
            font-size: 14px;
        }
        .hidden { display: none !important; }
    `;
    document.head.appendChild(style);

    // Tab 切换
    const tabBtns = document.querySelectorAll('.tab-btn');
    const phoneForm = document.getElementById('register-phone-form');
    const emailForm = document.getElementById('register-email-form');

    tabBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            tabBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');

            if (btn.dataset.tab === 'phone') {
                phoneForm.classList.remove('hidden');
                emailForm.classList.add('hidden');
            } else {
                phoneForm.classList.add('hidden');
                emailForm.classList.remove('hidden');
            }
        });
    });

    // 密码只允许数字
    document.querySelectorAll('input[type="password"]').forEach(input => {
        input.addEventListener('input', (e) => {
            e.target.value = e.target.value.replace(/\D/g, '').slice(0, 6);
        });
    });

    // 验证码只允许数字
    document.querySelectorAll('#reg-phone-code, #reg-email-code').forEach(input => {
        input.addEventListener('input', (e) => {
            e.target.value = e.target.value.replace(/\D/g, '').slice(0, 6);
        });
    });

    // 手机号只允许数字
    document.getElementById('reg-phone').addEventListener('input', (e) => {
        e.target.value = e.target.value.replace(/\D/g, '').slice(0, 11);
    });

    // 发送验证码（手机）
    setupSendCode('send-phone-code', 'reg-phone', 'register', validatePhone);

    // 发送验证码（邮箱）
    setupSendCode('send-email-code', 'reg-email', 'register', validateEmail);

    // 手机号注册
    document.getElementById('register-phone-form').addEventListener('submit', async (e) => {
        e.preventDefault();

        const phone = document.getElementById('reg-phone').value.trim();
        const code = document.getElementById('reg-phone-code').value.trim();
        const password = document.getElementById('reg-phone-password').value;
        const nickname = document.getElementById('reg-phone-nickname').value.trim();

        if (!validatePhone(phone)) {
            showToast('请输入正确的手机号', 'error');
            return;
        }
        if (!validateCode(code)) {
            showToast('请输入6位验证码', 'error');
            return;
        }
        if (!validatePassword(password)) {
            showToast('密码必须为6位数字', 'error');
            return;
        }

        await doRegister(container, () =>
            auth.registerByPhone(phone, code, password, nickname)
        );
    });

    // 邮箱注册
    document.getElementById('register-email-form').addEventListener('submit', async (e) => {
        e.preventDefault();

        const email = document.getElementById('reg-email').value.trim();
        const code = document.getElementById('reg-email-code').value.trim();
        const password = document.getElementById('reg-email-password').value;
        const nickname = document.getElementById('reg-email-nickname').value.trim();

        if (!validateEmail(email)) {
            showToast('请输入正确的邮箱', 'error');
            return;
        }
        if (!validateCode(code)) {
            showToast('请输入6位验证码', 'error');
            return;
        }
        if (!validatePassword(password)) {
            showToast('密码必须为6位数字', 'error');
            return;
        }

        await doRegister(container, () =>
            auth.registerByEmail(email, code, password, nickname)
        );
    });
}

/**
 * 设置发送验证码按钮
 */
function setupSendCode(btnId, inputId, type, validator) {
    const btn = document.getElementById(btnId);
    let countdown = 0;
    let timer = null;

    btn.addEventListener('click', async () => {
        const target = document.getElementById(inputId).value.trim();

        if (!validator(target)) {
            showToast(type === 'register' ? '请输入正确的手机号或邮箱' : '格式错误', 'error');
            return;
        }

        if (countdown > 0) return;

        btn.disabled = true;
        try {
            await auth.sendCode(target, type);
            showToast('验证码已发送', 'success');

            countdown = 60;
            btn.textContent = `${countdown}s`;
            timer = setInterval(() => {
                countdown--;
                if (countdown <= 0) {
                    clearInterval(timer);
                    btn.disabled = false;
                    btn.textContent = '发送验证码';
                } else {
                    btn.textContent = `${countdown}s`;
                }
            }, 1000);
        } catch (error) {
            showToast(error.message, 'error');
            btn.disabled = false;
        }
    });
}

/**
 * 执行注册
 */
async function doRegister(container, registerFn) {
    const submitBtn = container.querySelector('button[type="submit"]:not(.hidden)');
    submitBtn.disabled = true;
    submitBtn.textContent = '注册中...';

    try {
        const result = await registerFn();
        const { token, user } = result.data;

        setToken(token);
        saveUser(user);

        showToast('注册成功', 'success');
        navigate('/notes');
    } catch (error) {
        showToast(error.message, 'error');
    } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = '注册';
    }
}
