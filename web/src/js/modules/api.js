/**
 * API 客户端模块
 * 封装所有与后端 API 的通信
 */

const API_BASE = 'http://localhost:8080/api';

/**
 * 获取存储的 Token
 */
function getToken() {
    return localStorage.getItem('token');
}

/**
 * 设置 Token
 */
function setToken(token) {
    localStorage.setItem('token', token);
}

/**
 * 清除 Token
 */
function clearToken() {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
}

/**
 * 获取当前用户信息
 */
function getCurrentUser() {
    const user = localStorage.getItem('user');
    return user ? JSON.parse(user) : null;
}

/**
 * 保存用户信息
 */
function saveUser(user) {
    localStorage.setItem('user', JSON.stringify(user));
}

/**
 * 是否已登录
 */
function isLoggedIn() {
    return !!getToken();
}

/**
 * 通用请求方法
 */
async function request(method, path, data = null, options = {}) {
    const headers = {
        'Content-Type': 'application/json',
    };

    const token = getToken();
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }

    const config = {
        method,
        headers,
    };

    if (data && method !== 'GET') {
        config.body = JSON.stringify(data);
    }

    try {
        const response = await fetch(`${API_BASE}${path}`, config);
        const result = await response.json();

        if (!response.ok) {
            // Token 过期或无效
            if (response.status === 401) {
                clearToken();
                window.location.hash = '#/login';
            }
            throw new Error(result.message || '请求失败');
        }

        return result;
    } catch (error) {
        if (error.name === 'TypeError' && error.message.includes('fetch')) {
            throw new Error('网络连接失败，请检查后端服务是否启动');
        }
        throw error;
    }
}

// ===== 认证 API =====
export const auth = {
    /**
     * 发送验证码
     */
    sendCode(target, type) {
        return request('POST', '/auth/send-code', { target, type });
    },

    /**
     * 手机号注册
     */
    registerByPhone(phone, code, password, nickname = '') {
        return request('POST', '/auth/register/phone', {
            phone, code, password, nickname,
        });
    },

    /**
     * 邮箱注册
     */
    registerByEmail(email, code, password, nickname = '') {
        return request('POST', '/auth/register/email', {
            email, code, password, nickname,
        });
    },

    /**
     * 登录
     */
    login(account, password) {
        return request('POST', '/auth/login', { account, password });
    },

    /**
     * 重置密码
     */
    resetPassword(account, code, newPassword) {
        return request('POST', '/auth/reset-password', {
            account, code, new_password: newPassword,
        });
    },
};

// ===== 笔记 API =====
export const notes = {
    /**
     * 获取笔记列表
     */
    list(page = 1, pageSize = 20, folderId = null) {
        let path = `/notes?page=${page}&page_size=${pageSize}`;
        if (folderId) {
            path += `&folder_id=${folderId}`;
        }
        return request('GET', path);
    },

    /**
     * 获取笔记详情
     */
    get(id) {
        return request('GET', `/notes/${id}`);
    },

    /**
     * 创建笔记
     */
    create(title, content, folderId = null) {
        const data = { title, content };
        if (folderId) data.folder_id = folderId;
        return request('POST', '/notes', data);
    },

    /**
     * 更新笔记
     */
    update(id, data) {
        return request('PUT', `/notes/${id}`, data);
    },

    /**
     * 删除笔记
     */
    delete(id) {
        return request('DELETE', `/notes/${id}`);
    },
};

// ===== 文件夹 API =====
export const folders = {
    /**
     * 获取文件夹列表
     */
    list() {
        return request('GET', '/folders');
    },

    /**
     * 获取文件夹详情
     */
    get(id) {
        return request('GET', `/folders/${id}`);
    },

    /**
     * 创建文件夹
     */
    create(name) {
        return request('POST', '/folders', { name });
    },

    /**
     * 更新文件夹
     */
    update(id, name) {
        return request('PUT', `/folders/${id}`, { name });
    },

    /**
     * 删除文件夹
     */
    delete(id) {
        return request('DELETE', `/folders/${id}`);
    },
};

// ===== 个人信息 API =====
export const profile = {
    /**
     * 获取个人信息
     */
    get() {
        return request('GET', '/profile');
    },

    /**
     * 更新昵称
     */
    updateNickname(nickname) {
        return request('PUT', '/profile/nickname', { nickname });
    },

    /**
     * 更新生日
     */
    updateBirthday(birthday) {
        return request('PUT', '/profile/birthday', { birthday });
    },

    /**
     * 更新手机号
     */
    updatePhone(newPhone, code, password) {
        return request('PUT', '/profile/phone', {
            new_phone: newPhone, code, password,
        });
    },

    /**
     * 更新邮箱
     */
    updateEmail(newEmail, code, password) {
        return request('PUT', '/profile/email', {
            new_email: newEmail, code, password,
        });
    },

    /**
     * 修改密码
     */
    changePassword(oldPassword, newPassword) {
        return request('PUT', '/profile/password', {
            old_password: oldPassword,
            new_password: newPassword,
        });
    },

    /**
     * 上传头像
     */
    async uploadAvatar(file) {
        const formData = new FormData();
        formData.append('avatar', file);

        const headers = {};
        const token = getToken();
        if (token) {
            headers['Authorization'] = `Bearer ${token}`;
        }

        const response = await fetch(`${API_BASE}/profile/avatar`, {
            method: 'POST',
            headers,
            body: formData,
        });

        const result = await response.json();
        if (!response.ok) {
            throw new Error(result.message || '上传失败');
        }
        return result;
    },
};

// 导出工具函数
export { getToken, setToken, clearToken, getCurrentUser, saveUser, isLoggedIn };
