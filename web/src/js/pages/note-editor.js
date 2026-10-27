/**
 * 笔记编辑页面（支持图片上传）
 */

import { notes, folders } from '../modules/api.js';
import { showToast, escapeHtml } from '../modules/ui.js';
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
            <!-- 图片上传工具栏 -->
            <div class="editor-toolbar">
                <button type="button" class="toolbar-btn" id="btn-upload-image" title="插入图片">
                    🖼️ 图片
                </button>
                <input type="file" id="image-input" accept="image/*" style="display: none;">
                <span class="toolbar-hint">支持 JPG/PNG/GIF/WEBP，最大 10MB</span>
            </div>
            <textarea id="note-content" class="editor-content"
                placeholder="写点什么... 可以点击工具栏插入图片"></textarea>
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
    const uploadBtn = document.getElementById('btn-upload-image');
    const imageInput = document.getElementById('image-input');

    // 加载文件夹列表
    await loadFolderOptions(folderSelect);

    // 如果是编辑模式，加载笔记数据
    if (!isNew && noteId) {
        const editorContainer = container.querySelector('.editor-container');
        editorContainer.style.opacity = '0.5';
        editorContainer.style.pointerEvents = 'none';

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
        } finally {
            editorContainer.style.opacity = '1';
            editorContainer.style.pointerEvents = 'auto';
        }
    }

    // 返回
    const goBack = () => navigate('/notes');
    backBtn.addEventListener('click', goBack);
    cancelBtn.addEventListener('click', goBack);

    // 图片上传按钮
    uploadBtn.addEventListener('click', () => {
        imageInput.click();
    });

    // 图片选择后上传
    imageInput.addEventListener('change', async (e) => {
        const file = e.target.files[0];
        if (!file) return;

        console.log('[editor] 选择图片:', file.name, file.size, 'bytes');

        // 验证文件大小
        if (file.size > 10 * 1024 * 1024) {
            showToast('图片大小不能超过 10MB', 'error');
            imageInput.value = '';
            return;
        }

        uploadBtn.disabled = true;
        const originalText = uploadBtn.innerHTML;
        uploadBtn.innerHTML = '⏳ 上传中...';

        try {
            const result = await notes.uploadImage(file);
            const { url, filename } = result.data;

            // 在光标位置插入 Markdown 图片语法
            const markdownImage = `![${file.name}](${url})\n`;
            insertAtCursor(contentInput, markdownImage);

            console.log('[editor] 图片插入成功:', url);
            showToast('图片已插入', 'success');
        } catch (error) {
            console.error('[editor] 上传图片失败:', error);
            showToast(error.message || '上传图片失败', 'error');
        } finally {
            uploadBtn.disabled = false;
            uploadBtn.innerHTML = originalText;
            imageInput.value = '';
        }
    });

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
                    folder_id: folderId,
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
            if (isNew) return;
            const title = titleInput.value.trim();
            if (!title) return;

            try {
                await notes.update(noteId, {
                    title,
                    content: contentInput.value,
                    folder_id: folderSelect.value ? parseInt(folderSelect.value, 10) : null,
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
 * 在 textarea 光标位置插入文本
 */
function insertAtCursor(textarea, text) {
    const start = textarea.selectionStart;
    const end = textarea.selectionEnd;
    const before = textarea.value.substring(0, start);
    const after = textarea.value.substring(end);

    textarea.value = before + text + after;

    // 移动光标到插入文本之后
    const newCursorPos = start + text.length;
    textarea.setSelectionRange(newCursorPos, newCursorPos);
    textarea.focus();

    // 触发 input 事件以启动自动保存
    textarea.dispatchEvent(new Event('input', { bubbles: true }));
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
