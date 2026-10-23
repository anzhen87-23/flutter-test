/**
 * 应用入口
 * 初始化路由和全局事件
 */

import { initRouter, registerRoute } from './router.js';
import { clearToken } from './modules/api.js';

// 导入页面
import { renderLogin } from './pages/login.js';
import { renderRegister } from './pages/register.js';
import { renderResetPassword } from './pages/reset-password.js';
import { renderNotes } from './pages/notes.js';
import { renderNoteEditor } from './pages/note-editor.js';
import { renderFolders } from './pages/folders.js';
import { renderProfile } from './pages/profile.js';

// 注册路由
registerRoute('/login', renderLogin);
registerRoute('/register', renderRegister);
registerRoute('/reset-password', renderResetPassword);
registerRoute('/notes', renderNotes);
registerRoute('/note/new', (container) => renderNoteEditor(container, { id: 'new' }));
registerRoute('/note/edit/:id', renderNoteEditor);
registerRoute('/folders', renderFolders);
registerRoute('/profile', renderProfile);

// 全局退出登录
document.getElementById('btn-logout').addEventListener('click', () => {
    if (confirm('确定要退出登录吗？')) {
        clearToken();
        window.location.hash = '#/login';
        window.location.reload();
    }
});

// 初始化路由
initRouter();

console.log('📝 个人笔记应用已启动');
