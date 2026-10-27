/**
 * 笔记编辑页面 - 所见即所得编辑器（WYSIWYG）
 * 使用 contenteditable div，直接编辑渲染后的内容
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
                <!-- 所见即所得编辑区 -->
                <div id="note-editor" class="wysiwyg-editor" contenteditable="true"
                     data-placeholder="写点什么..."></div>
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
    const editor = document.getElementById('note-editor');
    const folderSelect = document.getElementById('note-folder');
    const saveBtn = document.getElementById('btn-save');
    const cancelBtn = document.getElementById('btn-cancel');
    const backBtn = document.getElementById('btn-back');
    const uploadImageBtn = document.getElementById('btn-upload-image');
    const imageInput = document.getElementById('image-input');
    const uploadVideoBtn = document.getElementById('btn-upload-video');
    const videoInput = document.getElementById('video-input');
    const shareBtn = document.getElementById('btn-share');

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
            folderSelect.value = note.folder_id || '';
            // Markdown → HTML 渲染到编辑器
            editor.innerHTML = markdownToHtml(note.content || '');
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

    // === 图片上传 ===
    uploadImageBtn.addEventListener('click', () => {
        editor.focus();
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
        uploadImageBtn.innerHTML = '<span class="toolbar-icon"></span><span class="toolbar-label">上传中</span>';

        try {
            const result = await notes.uploadImage(file);
            const { url } = result.data;

            // 插入图片到编辑器
            editor.focus();
            insertImageAtCursor(editor, url, file.name);

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
        editor.focus();
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

            editor.focus();
            insertVideoAtCursor(editor, url);

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
        const content = htmlToMarkdown(editor.innerHTML);
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
        const content = htmlToMarkdown(editor.innerHTML).trim();
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
                    content,
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
                    content: htmlToMarkdown(editor.innerHTML),
                    folder_id: folderSelect.value ? parseInt(folderSelect.value, 10) : null,
                });
            } catch (e) {}
        }, 2000);
    };

    titleInput.addEventListener('input', autoSave);
    editor.addEventListener('input', autoSave);
}

/**
 * 在编辑器光标位置插入图片
 */
function insertImageAtCursor(editor, url, alt) {
    const img = document.createElement('img');
    img.src = url;
    img.alt = alt;
    img.className = 'editor-inline-img';
    img.draggable = true;

    insertNodeAtCursor(editor, img);

    // 插入换行
    const br = document.createElement('br');
    insertNodeAtCursor(editor, br);
}

/**
 * 在编辑器光标位置插入视频
 */
function insertVideoAtCursor(editor, url) {
    const video = document.createElement('video');
    video.src = url;
    video.controls = true;
    video.className = 'editor-inline-video';
    video.style.cssText = 'max-width:100%;border-radius:8px;margin:8px 0;';

    insertNodeAtCursor(editor, video);

    const br = document.createElement('br');
    insertNodeAtCursor(editor, br);
}

/**
 * 在光标位置插入 DOM 节点
 */
function insertNodeAtCursor(editor, node) {
    const sel = window.getSelection();
    if (sel.rangeCount > 0) {
        const range = sel.getRangeAt(0);
        // 确保 range 在编辑器内
        if (editor.contains(range.commonAncestorContainer)) {
            range.deleteContents();
            range.insertNode(node);
            // 移动光标到插入节点之后
            range.setStartAfter(node);
            range.collapse(true);
            sel.removeAllRanges();
            sel.addRange(range);
        } else {
            editor.appendChild(node);
        }
    } else {
        editor.appendChild(node);
    }
}

/**
 * Markdown → HTML（用于加载时渲染）
 */
function markdownToHtml(markdown) {
    if (!markdown) return '';

    let html = escapeHtml(markdown);

    // 还原 <video> 标签
    html = html.replace(/&lt;video(.*?)&gt;(.*?)&lt;\/video&gt;/g, '<video$1 controls style="max-width:100%;border-radius:8px;margin:8px 0;">$2</video>');

    // 图片
    html = html.replace(/!\[([^\]]*)\]\(([^)]+)\)/g,
        '<img src="$2" alt="$1" class="editor-inline-img">');

    // 链接
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

    // 有序/无序列表
    html = html.replace(/^\d+\.\s+(.+)$/gm, '<li>$1</li>');
    html = html.replace(/^[-*]\s+(.+)$/gm, '<li>$1</li>');

    // 换行
    html = html.replace(/\n/g, '<br>');

    return html;
}

/**
 * HTML → Markdown（用于保存时转换）
 */
function htmlToMarkdown(html) {
    if (!html) return '';

    // 使用临时 DOM 解析
    const tmp = document.createElement('div');
    tmp.innerHTML = html;

    let markdown = '';

    function processNode(node) {
        if (node.nodeType === Node.TEXT_NODE) {
            markdown += node.textContent;
            return;
        }

        if (node.nodeType !== Node.ELEMENT_NODE) return;

        const tag = node.tagName.toLowerCase();

        switch (tag) {
            case 'img':
                markdown += `![${node.alt || '图片'}](${node.src})\n`;
                break;
            case 'video':
                markdown += `<video controls src="${node.src}"></video>\n`;
                break;
            case 'br':
                markdown += '\n';
                break;
            case 'p':
                markdown += processChildren(node) + '\n\n';
                break;
            case 'div':
                // div 通常作为段落分隔
                markdown += processChildren(node) + '\n';
                break;
            case 'strong':
            case 'b':
                markdown += `**${processChildren(node)}**`;
                break;
            case 'em':
            case 'i':
                markdown += `*${processChildren(node)}*`;
                break;
            case 'h1':
                markdown += `# ${processChildren(node)}\n\n`;
                break;
            case 'h2':
                markdown += `## ${processChildren(node)}\n\n`;
                break;
            case 'h3':
                markdown += `### ${processChildren(node)}\n\n`;
                break;
            case 'h4':
                markdown += `#### ${processChildren(node)}\n\n`;
                break;
            case 'a':
                markdown += `[${processChildren(node)}](${node.href})`;
                break;
            case 'li':
                markdown += `- ${processChildren(node)}\n`;
                break;
            case 'ul':
            case 'ol':
                markdown += processChildren(node);
                break;
            default:
                markdown += processChildren(node);
        }
    }

    function processChildren(node) {
        let text = '';
        node.childNodes.forEach(child => {
            const before = markdown;
            markdown = '';
            processNode(child);
            text += markdown;
            markdown = '';
        });
        return text;
    }

    tmp.childNodes.forEach(child => processNode(child));

    // 清理多余空行
    return markdown.replace(/\n{3,}/g, '\n\n').trim();
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
