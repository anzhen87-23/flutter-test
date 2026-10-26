/**
 * 个人中心页面
 */

import {
    profile as profileApi, auth,
    clearToken, getCurrentUser, saveUser, getToken
} from '../modules/api.js';
import {
    showToast, validatePhone, validateEmail,
    validatePassword, validateCode, formatDate, escapeHtml
} from '../modules/ui.js';
import { navigate } from '../router.js';

export async function renderProfile(container) {
    container.innerHTML = `
        <div class="profile-section">
            <div class="card">
                <div class="profile-header">
                    <img id="profile-avatar" class="profile-avatar"
                        src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='80' height='80'%3E%3Crect width='80' height='80' fill='%23e5e7eb'/%3E%3Ctext x='50%25' y='50%25' text-anchor='middle' dy='.3em' font-size='32' fill='%239ca3af'%3E👤%3C/text%3E%3C/svg%3E"
                        alt="头像">
                    <div class="profile-info">
                        <h2 id="profile-nickname">加载中...</h2>
                        <p id="profile-account"></p>
                    </div>
                </div>

                <ul class="profile-menu">
                    <li class="profile-menu-item" data-action="nickname">
                        <span>修改昵称</span>
                        <span>›</span>
                    </li>
                    <li class="profile-menu-item" data-action="birthday">
                        <span>修改生日</span>
                        <span id="birthday-display">›</span>
                    </li>
                    <li class="profile-menu-item" data-action="phone">
                        <span>修改手机号</span>
                        <span>›</span>
                    </li>
                    <li class="profile-menu-item" data-action="email">
                        <span>修改邮箱</span>
                        <span>›</span>
                    </li>
                    <li class="profile-menu-item" data-action="password">
                        <span>修改密码</span>
                        <span>›</span>
                    </li>
                    <li class="profile-menu-item" data-action="avatar">
                        <span>更换头像</span>
                        <span>›</span>
                    </li>
                </ul>

                <div style="margin-top: 24px; text-align: center;">
                    <button class="btn btn-danger" id="btn-logout-profile">退出登录</button>
                </div>
            </div>
        </div>
    `;

    // 加载个人信息
    await loadProfile();

    // 菜单事件
    document.querySelectorAll('.profile-menu-item').forEach(item => {
        item.addEventListener('click', () => {
            handleAction(item.dataset.action);
        });
    });

    // 头像点击
    document.getElementById('profile-avatar').addEventListener('click', () => {
        handleAction('avatar');
    });

    // 退出登录
    document.getElementById('btn-logout-profile').addEventListener('click', () => {
        if (confirm('确定要退出登录吗？')) {
            clearToken();
            showToast('已退出', 'success');
            navigate('/login');
        }
    });
}

/**
 * 加载个人信息
 */
async function loadProfile() {
    try {
        const result = await profileApi.get();
        const user = result.data;

        saveUser(user);

        document.getElementById('profile-nickname').textContent = user.nickname || user.username || '未设置昵称';
        document.getElementById('profile-account').textContent = user.phone || user.email || user.username;

        if (user.avatar_url) {
            const avatarBase = window.location.hostname === 'localhost'
                ? 'http://localhost:8080'
                : '';  // 线上通过 Nginx 代理，同源访问
            document.getElementById('profile-avatar').src = avatarBase + user.avatar_url;
        }

        if (user.birthday) {
            const date = new Date(user.birthday);
            document.getElementById('birthday-display').textContent =
                `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')} ›`;
        }
    } catch (error) {
        showToast('加载个人信息失败', 'error');
    }
}

/**
 * 处理菜单操作
 */
async function handleAction(action) {
    switch (action) {
        case 'nickname':
            await editNickname();
            break;
        case 'birthday':
            await editBirthday();
            break;
        case 'phone':
            await editPhone();
            break;
        case 'email':
            await editEmail();
            break;
        case 'password':
            await editPassword();
            break;
        case 'avatar':
            await editAvatar();
            break;
    }
}

/**
 * 修改昵称
 */
async function editNickname() {
    const nickname = prompt('请输入新昵称：');
    if (!nickname || !nickname.trim()) return;

    try {
        await profileApi.updateNickname(nickname.trim());
        showToast('昵称已更新', 'success');
        loadProfile();
    } catch (error) {
        showToast(error.message, 'error');
    }
}

/**
 * 修改生日
 */
async function editBirthday() {
    const birthday = prompt('请输入生日（格式：YYYY-MM-DD）：');
    if (!birthday) return;

    const date = new Date(birthday);
    if (isNaN(date.getTime())) {
        showToast('日期格式错误', 'error');
        return;
    }

    try {
        await profileApi.updateBirthday(date.toISOString());
        showToast('生日已更新', 'success');
        loadProfile();
    } catch (error) {
        showToast(error.message, 'error');
    }
}

/**
 * 修改手机号
 */
async function editPhone() {
    const password = prompt('请输入当前密码：');
    if (!password) return;

    if (!validatePassword(password)) {
        showToast('密码必须为6位数字', 'error');
        return;
    }

    const phone = prompt('请输入新手机号：');
    if (!phone) return;

    if (!validatePhone(phone)) {
        showToast('手机号格式错误', 'error');
        return;
    }

    const code = prompt('请输入验证码（请先在后端查看控制台输出的验证码）：');
    if (!code) return;

    if (!validateCode(code)) {
        showToast('验证码必须为6位数字', 'error');
        return;
    }

    try {
        await profileApi.updatePhone(phone, code, password);
        showToast('手机号已更新', 'success');
        loadProfile();
    } catch (error) {
        showToast(error.message, 'error');
    }
}

/**
 * 修改邮箱
 */
async function editEmail() {
    const password = prompt('请输入当前密码：');
    if (!password) return;

    if (!validatePassword(password)) {
        showToast('密码必须为6位数字', 'error');
        return;
    }

    const email = prompt('请输入新邮箱：');
    if (!email) return;

    if (!validateEmail(email)) {
        showToast('邮箱格式错误', 'error');
        return;
    }

    const code = prompt('请输入验证码（请先在后端查看控制台输出的验证码）：');
    if (!code) return;

    if (!validateCode(code)) {
        showToast('验证码必须为6位数字', 'error');
        return;
    }

    try {
        await profileApi.updateEmail(email, code, password);
        showToast('邮箱已更新', 'success');
        loadProfile();
    } catch (error) {
        showToast(error.message, 'error');
    }
}

/**
 * 修改密码
 */
async function editPassword() {
    const oldPassword = prompt('请输入旧密码：');
    if (!oldPassword) return;

    if (!validatePassword(oldPassword)) {
        showToast('密码必须为6位数字', 'error');
        return;
    }

    const newPassword = prompt('请输入新密码（6位数字）：');
    if (!newPassword) return;

    if (!validatePassword(newPassword)) {
        showToast('密码必须为6位数字', 'error');
        return;
    }

    if (oldPassword === newPassword) {
        showToast('新密码不能与旧密码相同', 'error');
        return;
    }

    const confirmPwd = prompt('请再次输入新密码确认：');
    if (confirmPwd !== newPassword) {
        showToast('两次输入的密码不一致', 'error');
        return;
    }

    try {
        await profileApi.changePassword(oldPassword, newPassword);
        showToast('密码已修改', 'success');
    } catch (error) {
        showToast(error.message, 'error');
    }
}

/**
 * 更换头像
 */
async function editAvatar() {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/jpeg,image/png,image/gif';

    input.onchange = async (e) => {
        const file = e.target.files[0];
        if (!file) return;

        if (file.size > 5 * 1024 * 1024) {
            showToast('头像大小不能超过5MB', 'error');
            return;
        }

        try {
            const result = await profileApi.uploadAvatar(file);
            showToast('头像已更新', 'success');
            loadProfile();
        } catch (error) {
            showToast(error.message, 'error');
        }
    };

    input.click();
}
