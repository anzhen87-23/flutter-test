/**
 * 路由模块
 * 基于 hash 的简单 SPA 路由
 */

import { isLoggedIn } from './modules/api.js';

// 路由表
const routes = {};

// 需要认证的路由
const authRoutes = ['/notes', '/folders', '/profile', '/note/edit', '/note/new'];

// 公开路由
const publicRoutes = ['/login', '/register', '/reset-password'];

/**
 * 注册路由
 */
export function registerRoute(path, handler) {
    routes[path] = handler;
}

/**
 * 获取当前路由路径
 */
export function getCurrentPath() {
    const hash = window.location.hash.slice(1) || '/login';
    // 去掉查询参数
    return hash.split('?')[0];
}

/**
 * 导航到指定路径
 */
export function navigate(path) {
    window.location.hash = '#' + path;
}

/**
 * 检查路由是否需要认证
 */
function needsAuth(path) {
    return authRoutes.some(route => path.startsWith(route));
}

/**
 * 路由匹配
 */
function matchRoute(path) {
    // 精确匹配
    if (routes[path]) {
        return { handler: routes[path], params: {} };
    }

    // 参数匹配 (例如 /note/edit/:id)
    for (const routePath of Object.keys(routes)) {
        const routeParts = routePath.split('/');
        const pathParts = path.split('/');

        if (routeParts.length !== pathParts.length) continue;

        const params = {};
        let match = true;

        for (let i = 0; i < routeParts.length; i++) {
            if (routeParts[i].startsWith(':')) {
                params[routeParts[i].slice(1)] = pathParts[i];
            } else if (routeParts[i] !== pathParts[i]) {
                match = false;
                break;
            }
        }

        if (match) {
            return { handler: routes[routePath], params };
        }
    }

    return null;
}

/**
 * 处理路由变化
 */
export function handleRoute() {
    const path = getCurrentPath();
    const mainContent = document.getElementById('main-content');
    const header = document.getElementById('header');

    // 认证检查
    if (needsAuth(path) && !isLoggedIn()) {
        navigate('/login');
        return;
    }

    // 已登录用户访问登录页，跳转到笔记页
    if (publicRoutes.includes(path) && isLoggedIn()) {
        navigate('/notes');
        return;
    }

    // 更新导航高亮
    updateNavActive(path);

    // 显示/隐藏头部
    if (needsAuth(path)) {
        header.classList.remove('hidden');
    } else {
        header.classList.add('hidden');
    }

    // 匹配并执行路由处理器
    const matched = matchRoute(path);
    if (matched) {
        matched.handler(mainContent, matched.params);
    } else {
        // 404
        mainContent.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">🔍</div>
                <p class="empty-state-text">页面不存在</p>
                <button class="btn btn-primary" onclick="location.hash='#/notes'">返回首页</button>
            </div>
        `;
    }
}

/**
 * 更新导航栏高亮
 */
function updateNavActive(path) {
    const navLinks = document.querySelectorAll('.nav-link');
    navLinks.forEach(link => {
        const page = link.getAttribute('data-page');
        if (path.startsWith('/' + page)) {
            link.classList.add('active');
        } else {
            link.classList.remove('active');
        }
    });
}

/**
 * 初始化路由
 */
export function initRouter() {
    window.addEventListener('hashchange', handleRoute);

    // 初始路由
    if (!window.location.hash) {
        window.location.hash = isLoggedIn() ? '#/notes' : '#/login';
    } else {
        handleRoute();
    }
}
