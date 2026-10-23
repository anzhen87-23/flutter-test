/**
 * 文件夹管理页面
 */

import { folders, notes } from '../modules/api.js';
import { showToast, showLoading, showEmpty, escapeHtml } from '../modules/ui.js';
import { navigate } from '../router.js';

export async function renderFolders(container) {
    container.innerHTML = `
        <div class="notes-header">
            <h2>文件夹</h2>
            <button class="btn btn-primary" id="btn-new-folder">+ 新建文件夹</button>
        </div>
        <div id="folders-list" class="folder-grid"></div>
    `;

    const foldersList = document.getElementById('folders-list');

    await loadFolders(foldersList);

    // 新建文件夹
    document.getElementById('btn-new-folder').addEventListener('click', async () => {
        const name = prompt('请输入文件夹名称：');
        if (!name || !name.trim()) return;

        try {
            await folders.create(name.trim());
            showToast('创建成功', 'success');
            loadFolders(foldersList);
        } catch (error) {
            showToast(error.message, 'error');
        }
    });
}

/**
 * 加载文件夹列表
 */
async function loadFolders(container) {
    showLoading(container);

    try {
        const result = await folders.list();
        const folderList = result.data || [];

        if (folderList.length === 0) {
            showEmpty(container, '📁', '还没有文件夹');
            return;
        }

        container.innerHTML = folderList.map(folder => `
            <div class="folder-card" data-id="${folder.id}">
                <div class="folder-card-icon">📁</div>
                <div class="folder-card-name">${escapeHtml(folder.name)}</div>
                <div class="folder-card-count">${folder.note_count} 条笔记</div>
                <div style="margin-top: 12px; display: flex; gap: 8px;">
                    <button class="btn btn-sm btn-rename" data-id="${folder.id}" data-name="${escapeHtml(folder.name)}">重命名</button>
                    <button class="btn btn-sm btn-danger btn-delete-folder" data-id="${folder.id}">删除</button>
                </div>
            </div>
        `).join('');

        // 点击文件夹查看笔记
        container.querySelectorAll('.folder-card').forEach(card => {
            card.addEventListener('click', (e) => {
                if (e.target.tagName === 'BUTTON') return;
                navigate(`/notes?folder_id=${card.dataset.id}`);
            });
        });

        // 重命名
        container.querySelectorAll('.btn-rename').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                e.stopPropagation();
                const newName = prompt('请输入新名称：', btn.dataset.name);
                if (!newName || !newName.trim()) return;
                if (newName.trim() === btn.dataset.name) return;

                try {
                    await folders.update(btn.dataset.id, newName.trim());
                    showToast('重命名成功', 'success');
                    loadFolders(container);
                } catch (error) {
                    showToast(error.message, 'error');
                }
            });
        });

        // 删除
        container.querySelectorAll('.btn-delete-folder').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                e.stopPropagation();
                if (!confirm('删除文件夹后，其中的笔记将移至未分类。确定删除吗？')) return;

                try {
                    await folders.delete(btn.dataset.id);
                    showToast('删除成功', 'success');
                    loadFolders(container);
                } catch (error) {
                    showToast(error.message, 'error');
                }
            });
        });

    } catch (error) {
        container.innerHTML = `<div class="empty-state"><p>${error.message}</p></div>`;
    }
}
