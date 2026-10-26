/**
 * 笔记编辑页面
 */

import { notes, folders } from '../modules/api.js';
import { showToast, showLoading, escapeHtml } from '../modules/ui.js';
import { navigate } from '../router.js';

export async function renderNoteEditor(container, params) {
    const noteId = params.id;
    const isNew = noteId === 'new';

    container.innerHTML = `
        <div class="editor-container">
            <div style="margin-bottom: 16px;">
                <button class="btn btn-sm" id="btn-back">← 返回</button>
            </div>
            <div class="form-group">
                <input type="text" id="note-title" class="editor-title"
                    placeholder="输入标题..." maxlength="200">
            </div>
            <div class="form-group">
                <select id="note-folder" class="folder-filter">
                    <option value="">未分类</option>
                </select>
            </div>
            <textarea id="note-content" class="editor-content"
                placeholder="写点什么..."></textarea>
            <div class="editor-actions">
                <button class="btn" id="btn-cancel">取消</button>
                <button class="btn btn-primary" id="btn-save">保存</button>
            </div>
        </div>
    `;

    const titleInput = document.getElementById('note-title');
    const contentInput = document.getElementById('note-content');
    const folderSelect = document.getElementById('note-folder');
    const saveBtn = document.getElementById('btn-save');
    const cancelBtn = document.getElementById('btn-cancel');
    const backBtn = document.getElementById('btn-back');

    // 加载文件夹列表
    await loadFolderOptions(folderSelect);

    // 如果是编辑模式，加载笔记数据
    if (!isNew && noteId) {
        showLoading(container.querySelector('.editor-container'));
        try {
            const result = await notes.get(noteId);
            const note = result.data;
            titleInput.value = note.title;
            contentInput.value = note.content || '';
            folderSelect.value = note.folder_id || '';
        } catch (error) {
            showToast(error.message || '加载笔记失败', 'error');
            navigate('/notes');
            return;
        }
    }

    // 返回
    const goBack = () => navigate('/notes');
    backBtn.addEventListener('click', goBack);
    cancelBtn.addEventListener('click', goBack);

    // 保存
    saveBtn.addEventListener('click', async () => {
        const title = titleInput.value.trim();
        const content = contentInput.value.trim();
        const folderId = folderSelect.value ? parseInt(folderSelect.value, 10) : null;

        if (!title) {
            showToast('请输入标题', 'error');
            titleInput.focus();
            return;
        }

        saveBtn.disabled = true;
        saveBtn.textContent = '保存中...';

        try {
            if (isNew) {
                await notes.create(title, content, folderId);
                showToast('创建成功', 'success');
            } else {
                await notes.update(noteId, {
                    title,
                    content: contentInput.value,
                    folder_id: folderId ? parseInt(folderId) : null,
                });
                showToast('保存成功', 'success');
            }
            navigate('/notes');
        } catch (error) {
            showToast(error.message, 'error');
        } finally {
            saveBtn.disabled = false;
            saveBtn.textContent = '保存';
        }
    });

    // 自动保存（防抖）
    let autoSaveTimer = null;
    const autoSave = () => {
        clearTimeout(autoSaveTimer);
        autoSaveTimer = setTimeout(async () => {
            if (isNew) return; // 新建不自动保存
            const title = titleInput.value.trim();
            if (!title) return;

            try {
                await notes.update(noteId, {
                    title,
                    content: contentInput.value,
                    folder_id: folderSelect.value ? parseInt(folderSelect.value) : null,
                });
            } catch (e) {
                // 静默失败
            }
        }, 2000);
    };

    titleInput.addEventListener('input', autoSave);
    contentInput.addEventListener('input', autoSave);
}

/**
 * 加载文件夹选项
 */
async function loadFolderOptions(selectEl) {
    try {
        const result = await folders.list();
        const folderList = result.data || [];

        folderList.forEach(folder => {
            const option = document.createElement('option');
            option.value = folder.id;
            option.textContent = folder.name;
            selectEl.appendChild(option);
        });
    } catch (error) {
        console.error('加载文件夹失败:', error);
    }
}
