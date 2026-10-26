/**
 * 笔记列表页面
 */

import { notes, folders } from '../modules/api.js';
import { showToast, formatDate, showLoading, showEmpty, escapeHtml } from '../modules/ui.js';
import { navigate } from '../router.js';

let currentPage = 1;
let currentFolder = null;
let folderList = [];

export async function renderNotes(container, params) {
    container.innerHTML = `
        <div class="notes-header">
            <h2>我的笔记</h2>
            <button class="btn btn-primary" id="btn-new-note">+ 新建笔记</button>
        </div>
        <div class="notes-toolbar">
            <select class="folder-filter" id="folder-filter">
                <option value="">全部笔记</option>
            </select>
        </div>
        <div id="notes-list"></div>
        <div id="notes-pagination" class="pagination"></div>
    `;

    const notesList = document.getElementById('notes-list');
    const pagination = document.getElementById('notes-pagination');
    const folderFilter = document.getElementById('folder-filter');

    // 从查询参数读取 folder_id
    if (params && params.query && params.query.folder_id) {
        currentFolder = parseInt(params.query.folder_id, 10);
    } else {
        currentFolder = null;
    }

    // 加载文件夹列表
    await loadFolders(folderFilter);

    // 设置文件夹筛选器的值
    if (currentFolder) {
        folderFilter.value = currentFolder.toString();
    }

    // 加载笔记
    await loadNotes(notesList, pagination);

    // 新建笔记
    document.getElementById('btn-new-note').addEventListener('click', () => {
        navigate('/note/new');
    });

    // 文件夹筛选
    folderFilter.addEventListener('change', (e) => {
        currentFolder = e.target.value || null;
        currentPage = 1;
        loadNotes(notesList, pagination);
    });
}

/**
 * 加载文件夹列表
 */
async function loadFolders(selectEl) {
    try {
        const result = await folders.list();
        folderList = result.data || [];

        folderList.forEach(folder => {
            const option = document.createElement('option');
            option.value = folder.id;
            option.textContent = `${folder.name} (${folder.note_count})`;
            selectEl.appendChild(option);
        });
    } catch (error) {
        console.error('加载文件夹失败:', error);
    }
}

/**
 * 加载笔记列表
 */
async function loadNotes(container, paginationContainer) {
    showLoading(container);

    try {
        console.log('[notes] 开始加载笔记列表, page:', currentPage, 'folder:', currentFolder);
        const result = await notes.list(currentPage, 20, currentFolder);
        console.log('[notes] API 响应:', result);

        if (!result || !result.data) {
            throw new Error('API 响应格式错误: ' + JSON.stringify(result));
        }

        const { notes: noteList, total, page, page_size } = result.data;
        console.log('[notes] 解析结果: noteList=', noteList, 'total=', total);

        if (!noteList || noteList.length === 0) {
            showEmpty(container, '📝', '还没有笔记，点击右上角创建吧');
            paginationContainer.innerHTML = '';
            return;
        }

        container.innerHTML = noteList.map(note => {
            const folderName = getFolderName(note.folder_id);
            return `
                <div class="note-card" data-id="${note.id}">
                    <div class="note-card-header">
                        <span class="note-card-title">${escapeHtml(note.title)}</span>
                        <span class="note-card-time">${formatDate(note.updated_at)}</span>
                    </div>
                    ${note.content ? `
                        <div class="note-card-content">${escapeHtml(note.content)}</div>
                    ` : ''}
                    <div class="note-card-footer">
                        ${folderName ? `<span class="note-folder-tag">📁 ${escapeHtml(folderName)}</span>` : '<span></span>'}
                        <div>
                            <button class="btn btn-sm btn-edit" data-id="${note.id}">编辑</button>
                            <button class="btn btn-sm btn-danger btn-delete" data-id="${note.id}">删除</button>
                        </div>
                    </div>
                </div>
            `;
        }).join('');

        // 点击笔记卡片进入编辑
        container.querySelectorAll('.note-card').forEach(card => {
            card.addEventListener('click', (e) => {
                // 如果点击的是按钮，不触发卡片点击
                if (e.target.tagName === 'BUTTON') return;
                navigate(`/note/edit/${card.dataset.id}`);
            });
        });

        // 编辑按钮
        container.querySelectorAll('.btn-edit').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                navigate(`/note/edit/${btn.dataset.id}`);
            });
        });

        // 删除按钮
        container.querySelectorAll('.btn-delete').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                e.stopPropagation();
                if (confirm('确定要删除这条笔记吗？')) {
                    try {
                        await notes.delete(btn.dataset.id);
                        showToast('删除成功', 'success');
                        loadNotes(container, paginationContainer);
                    } catch (error) {
                        showToast(error.message, 'error');
                    }
                }
            });
        });

        // 渲染分页
        renderPagination(paginationContainer, total, page, page_size, () => {
            loadNotes(container, paginationContainer);
        });

    } catch (error) {
        console.error('[notes] 加载失败:', error);
        container.innerHTML = `<div class="empty-state"><p>加载失败: ${error.message}</p></div>`;
    }
}

/**
 * 获取文件夹名称
 */
function getFolderName(folderId) {
    if (!folderId) return null;
    const folder = folderList.find(f => f.id === folderId);
    return folder ? folder.name : null;
}

/**
 * 渲染分页
 */
function renderPagination(container, total, currentPage, pageSize, onPageChange) {
    const totalPages = Math.ceil(total / pageSize);

    if (totalPages <= 1) {
        container.innerHTML = '';
        return;
    }

    let html = '';

    // 上一页
    html += `<button class="page-btn" ${currentPage === 1 ? 'disabled' : ''} data-page="${currentPage - 1}">上一页</button>`;

    // 页码
    for (let i = 1; i <= totalPages; i++) {
        if (i === 1 || i === totalPages || Math.abs(i - currentPage) <= 2) {
            html += `<button class="page-btn ${i === currentPage ? 'active' : ''}" data-page="${i}">${i}</button>`;
        } else if (Math.abs(i - currentPage) === 3) {
            html += `<span>...</span>`;
        }
    }

    // 下一页
    html += `<button class="page-btn" ${currentPage === totalPages ? 'disabled' : ''} data-page="${currentPage + 1}">下一页</button>`;

    container.innerHTML = html;

    container.querySelectorAll('.page-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            if (btn.disabled) return;
            currentPage = parseInt(btn.dataset.page);
            onPageChange();
        });
    });
}
