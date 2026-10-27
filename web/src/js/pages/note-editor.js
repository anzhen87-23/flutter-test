/**
 * 笔记编辑页面（支持图片/视频上传、Markdown 实时预览、分享）
 */

import { notes, folders } from '../modules/api.js';
import { showToast, escapeHtml } from '../modules/ui.js';
import { navigate } from '../router.js';

export async function renderNoteEditor(container, params) {
    const noteId = params.id;
    const isNew = noteId === 'new';

    container.innerHTML = `
        <div class="editor-wrapper">
            <div class="editor-header">
                <button class="btn btn-sm" id="btn-back">← 返回</button>
                <div class="editor-mode-toggle">
                    <button class="mode-btn active" id="btn-edit-mode">编辑</button>
                    <button class="mode-btn" id="btn-preview-mode">预览</button>
                </div>
            </div>
            <div class="editor-body">
                <div class="form-group">
                    <input type="text" id="note-title" class="editor-title"
                        placeholder="输入标题..." maxlength="200">
                </div>
                <div class="form-group">
                    <select id="note-folder" class="folder-filter">
                        <option value="">未分类</option>
                    </select>
                </div>
                <!-- 编辑区 -->
                <div id="editor-edit-pane">
                    <textarea id="note-content" class="editor-content"
                        placeholder="写点什么..."></textarea>
                </div>
                <!-- 实时预览区 -->
                <div id="editor-preview-pane" class="editor-preview">
                </div>
            </div>
            <!-- 底部工具栏 -->
            <div class="editor-bottom-toolbar">
                <button type="button" class="toolbar-icon-btn" id="btn-upload-image" title="插入图片">
                    <span class="toolbar-icon">🖼️</span>
                    <span class="toolbar-label">图片</span>
                </button>
                <input type="file" id="image-input" accept="image/*" style="display: none;">
                <button type="button" class="toolbar-icon-btn" id="btn-upload-video" title="插入视频">
                    <span class="toolbar-icon"></span>
                    <span class="toolbar-label">视频</span>
                </button>
                <input type="file" id="video-input" accept="video/*" style="display: none;">
                <button type="button" class="toolbar-icon-btn" id="btn-share" title="分享">
                    <span class="toolbar-icon">🔗</span>
                    <span class="toolbar-label">分享</span>
                </button>
                <div class="toolbar-spacer"></div>
                <button class="btn btn-sm" id="btn-cancel">取消</button>
                <button class="btn btn-primary btn-sm" id="btn-save">保存</button>
            </div>
        </div>
    `;

    const titleInput = document.getElementById('note-title');
    const contentInput = document.getElementById('note-content');
    const folderSelect = document.getElementById('note-folder');
    const saveBtn = document.getElementById('btn-save');
    const cancelBtn = document.getElementById('btn-cancel');
    const backBtn = document.getElementById('btn-back');
    const uploadImageBtn = document.getElementById('btn-upload-image');
    const imageInput = document.getElementById('image-input');
    const uploadVideoBtn = document.getElementById('btn-upload-video');
    const videoInput = document.getElementById('video-input');
    const shareBtn = document.getElementById('btn-share');
    const editModeBtn = document.getElementById('btn-edit-mode');
    const previewModeBtn = document.getElementById('btn-preview-mode');
    const editPane = document.getElementById('editor-edit-pane');
    const previewPane = document.getElementById('editor-preview-pane');

    // 加载文件夹列表
    await loadFolderOptions(folderSelect);

    // 如果是编辑模式，加载笔记数据
    if (!isNew && noteId) {
        const editorWrapper = container.querySelector('.editor-wrapper');
        editorWrapper.style.opacity = '0.5';
        editorWrapper.style.pointerEvents = 'none';

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
            editorWrapper.style.opacity = '1';
            editorWrapper.style.pointerEvents = 'auto';
        }
    }

    // 返回
    const goBack = () => navigate('/notes');
    backBtn.addEventListener('click', goBack);
    cancelBtn.addEventListener('click', goBack);

    // === 实时预览更新 ===
    let previewTimer = null;
    const updatePreview = () => {
        clearTimeout(previewTimer);
        previewTimer = setTimeout(() => {
            previewPane.innerHTML = renderMarkdown(contentInput.value);
        }, 100);
    };

    // === 编辑/预览模式切换 ===
    editModeBtn.addEventListener('click', () => {
        editModeBtn.classList.add('active');
        previewModeBtn.classList.remove('active');
        editPane.style.display = '';
        previewPane.style.display = '';
        previewPane.classList.remove('editor-preview-full');
        updatePreview();
    });

    previewModeBtn.addEventListener('click', () => {
        previewModeBtn.classList.add('active');
        editModeBtn.classList.remove('active');
        editPane.style.display = 'none';
        previewPane.style.display = '';
        previewPane.classList.add('editor-preview-full');
        updatePreview();
    });

    // === 图片上传 ===
    uploadImageBtn.addEventListener('click', () => {
        imageInput.click();
    });

    imageInput.addEventListener('change', async (e) => {
        const file = e.target.files[0];
        if (!file) return;

        if (file.size > 10 * 1024 * 1024) {
            showToast('图片大小不能超过 10MB', 'error');
            imageInput.value = '';
            return;
        }

        uploadImageBtn.disabled = true;
        const originalHTML = uploadImageBtn.innerHTML;
        uploadImageBtn.innerHTML = '<span class="toolbar-icon">⏳</span><span class="toolbar-label">上传中</span>';

        try {
            const result = await notes.uploadImage(file);
            const { url } = result.data;
            const markdownImage = `![${file.name}](${url})\n`;
            insertAtCursor(contentInput, markdownImage);
            updatePreview();
            showToast('图片已插入', 'success');
        } catch (error) {
            showToast(error.message || '上传图片失败', 'error');
        } finally {
            uploadImageBtn.disabled = false;
            uploadImageBtn.innerHTML = originalHTML;
            imageInput.value = '';
        }
    });

    // === 视频上传 ===
    uploadVideoBtn.addEventListener('click', () => {
        videoInput.click();
    });

    videoInput.addEventListener('change', async (e) => {
        const file = e.target.files[0];
        if (!file) return;

        if (file.size > 50 * 1024 * 1024) {
            showToast('视频大小不能超过 50MB', 'error');
            videoInput.value = '';
            return;
        }

        uploadVideoBtn.disabled = true;
        const originalHTML = uploadVideoBtn.innerHTML;
        uploadVideoBtn.innerHTML = '<span class="toolbar-icon">⏳</span><span class="toolbar-label">上传中</span>';

        try {
            const result = await notes.uploadVideo(file);
            const { url } = result.data;
            const markdownVideo = `<video controls src="${url}" style="max-width:100%;border-radius:8px;margin:8px 0;">你的浏览器不支持视频播放</video>\n`;
            insertAtCursor(contentInput, markdownVideo);
            updatePreview();
            showToast('视频已插入', 'success');
        } catch (error) {
            showToast(error.message || '上传视频失败', 'error');
        } finally {
            uploadVideoBtn.disabled = false;
            uploadVideoBtn.innerHTML = originalHTML;
            videoInput.value = '';
        }
    });

    // === 分享 ===
    shareBtn.addEventListener('click', async () => {
        const title = titleInput.value.trim() || '我的笔记';
        const content = contentInput.value.trim();
        const shareText = `${title}\n\n${content}`;

        if (navigator.share) {
            try {
                await navigator.share({ title, text: shareText });
                showToast('分享成功', 'success');
            } catch (err) {
                if (err.name !== 'AbortError') {
                    copyToClipboard(shareText);
                }
            }
        } else {
            copyToClipboard(shareText);
        }
    });

    // === 保存 ===
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
            } catch (e) {}
        }, 2000);
    };

    titleInput.addEventListener('input', () => { autoSave(); updatePreview(); });
    contentInput.addEventListener('input', () => { autoSave(); updatePreview(); });
}

/**
 * Markdown 渲染（支持图片、视频、标题、粗体、斜体、链接、列表）
 */
function renderMarkdown(content) {
    if (!content) return '<p style="color: var(--text-secondary);">暂无内容</p>';

    let html = escapeHtml(content);

    // 还原 <video> 标签
    html = html.replace(/&lt;video(.*?)&gt;(.*?)&lt;\/video&gt;/g, '<video$1>$2</video>');

    // 图片: ![alt](url)
    html = html.replace(/!\[([^\]]*)\]\(([^)]+)\)/g,
        '<img src="$2" alt="$1" class="note-preview-img-full" loading="lazy">');

    // 链接: [text](url)
    html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g,
        '<a href="$2" target="_blank" rel="noopener">$1</a>');

    // 标题
    html = html.replace(/^######\s+(.+)$/gm, '<h6>$1</h6>');
    html = html.replace(/^#####\s+(.+)$/gm, '<h5>$1</h5>');
    html = html.replace(/^####\s+(.+)$/gm, '<h4>$1</h4>');
    html = html.replace(/^###\s+(.+)$/gm, '<h3>$1</h3>');
    html = html.replace(/^##\s+(.+)$/gm, '<h2>$1</h2>');
    html = html.replace(/^#\s+(.+)$/gm, '<h1>$1</h1>');

    // 粗体、斜体
    html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
    html = html.replace(/\*(.+?)\*/g, '<em>$1</em>');

    // 有序列表
    html = html.replace(/^\d+\.\s+(.+)$/gm, '<li>$1</li>');
    // 无序列表
    html = html.replace(/^[-*]\s+(.+)$/gm, '<li>$1</li>');

    // 换行
    html = html.replace(/\n/g, '<br>');

    return html;
}

/**
 * 复制文本到剪贴板
 */
function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        showToast('已复制到剪贴板', 'success');
    }).catch(() => {
        const textarea = document.createElement('textarea');
        textarea.value = text;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
        showToast('已复制到剪贴板', 'success');
    });
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

    const newCursorPos = start + text.length;
    textarea.setSelectionRange(newCursorPos, newCursorPos);
    textarea.focus();

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
