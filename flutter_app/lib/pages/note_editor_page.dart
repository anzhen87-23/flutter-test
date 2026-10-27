import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/folder.dart';
import '../services/api_service.dart';

class NoteEditorPage extends StatefulWidget {
  final int? noteId;
  final int? initialFolderId;

  const NoteEditorPage({super.key, this.noteId, this.initialFolderId});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();
  List<Folder> _folders = [];
  int? _selectedFolderId;
  bool _loading = false;
  bool _saving = false;
  bool _uploading = false;
  bool _isPreviewMode = false;

  bool get _isNew => widget.noteId == null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final folders = await FoldersApi.list();
      if (mounted) {
        setState(() => _folders = folders);
      }

      if (!_isNew) {
        final note = await NotesApi.get(widget.noteId!);
        if (mounted) {
          _titleController.text = note.title;
          _contentController.text = note.content;
          _selectedFolderId = note.folderId;
        }
      } else {
        if (mounted) {
          _selectedFolderId = widget.initialFolderId;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (_isNew) {
        await NotesApi.create(
          title: title,
          content: content,
          folderId: _selectedFolderId,
        );
      } else {
        await NotesApi.update(
          widget.noteId!,
          title: title,
          content: content,
          folderId: _selectedFolderId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isNew ? '创建成功' : '保存成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  /// 选择并上传图片
  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _uploading = true);

      final result = await NotesApi.uploadImage(image.path);
      final url = result['url'] as String;

      _insertAtCursor('![图片]($url)\n');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('图片已插入'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传图片失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  /// 选择并上传视频
  Future<void> _pickAndUploadVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video == null) return;

      // 检查文件大小（50MB）
      final fileSize = await video.length();
      if (fileSize > 50 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('视频大小不能超过 50MB'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      setState(() => _uploading = true);

      final result = await NotesApi.uploadVideo(video.path);
      final url = result['url'] as String;

      // 插入视频 HTML 标签（Markdown 渲染器会处理）
      _insertAtCursor('<video controls src="$url"></video>\n');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('视频已插入'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传视频失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  /// 分享笔记
  void _shareNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final shareText = '$title\n\n$content';

    Share.share(shareText, subject: title);
  }

  /// 在光标位置插入文本
  void _insertAtCursor(String text) {
    final controller = _contentController;
    final selection = controller.selection;
    final currentText = controller.text;

    final start = selection.start >= 0 ? selection.start : currentText.length;
    final end = selection.end >= 0 ? selection.end : currentText.length;

    final before = currentText.substring(0, start);
    final after = currentText.substring(end);

    controller.text = before + text + after;

    final newCursorPos = start + text.length;
    controller.selection = TextSelection.collapsed(offset: newCursorPos);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '新建笔记' : '编辑笔记'),
        actions: [
          // 编辑/预览切换
          IconButton(
            icon: Icon(_isPreviewMode ? Icons.edit : Icons.visibility),
            tooltip: _isPreviewMode ? '编辑' : '预览',
            onPressed: () {
              setState(() => _isPreviewMode = !_isPreviewMode);
            },
          ),
          // 保存按钮
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 标题和文件夹
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_folders.isNotEmpty)
                        DropdownButtonFormField<int?>(
                          value: _selectedFolderId,
                          decoration: const InputDecoration(
                            labelText: '文件夹',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('未分类')),
                            ..._folders.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))),
                          ],
                          onChanged: (value) => setState(() => _selectedFolderId = value),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleController,
                        maxLength: 200,
                        decoration: const InputDecoration(
                          labelText: '标题',
                          hintText: '输入笔记标题',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                // 内容区（编辑或预览）
                Expanded(
                  child: _isPreviewMode
                      ? _buildPreviewPane()
                      : _buildEditPane(),
                ),
              ],
            ),
      // 底部工具栏
      bottomNavigationBar: _buildBottomToolbar(),
    );
  }

  Widget _buildEditPane() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _StackedEditor(
        controller: _contentController,
        decoration: const InputDecoration(
          labelText: '内容',
          hintText: '写点什么...',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  /// 从内容中删除指定图片
  void _removeImage(String fullUrl) async {
    String relativePath = fullUrl;
    if (fullUrl.contains('/uploads/notes/')) {
      relativePath = '/uploads/notes/${fullUrl.split('/uploads/notes/').last}';
    }

    final content = _contentController.text;
    final updatedContent = content.replaceAll(
      RegExp(r'!\[([^\]]*)\]\([^)]*' + RegExp.escape(relativePath) + r'\)\n?'),
      '',
    );

    if (updatedContent != content) {
      _contentController.text = updatedContent;
      _contentController.selection = TextSelection.collapsed(offset: updatedContent.length);
    }

    try {
      final filename = relativePath.split('/uploads/notes/').last;
      await NotesApi.deleteImage(filename);
    } catch (e) {
      // 静默失败
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('图片已删除'), backgroundColor: Colors.orange),
      );
    }
  }

  Widget _buildPreviewPane() {
    final content = _contentController.text;
    if (content.isEmpty) {
      return const Center(
        child: Text('暂无内容', style: TextStyle(color: Colors.grey)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Markdown(
        data: content,
        selectable: true,
        imageBuilder: (uri, title, alt) {
          return CachedNetworkImage(
            imageUrl: uri.toString(),
            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
            fit: BoxFit.contain,
          );
        },
        builders: {
          'video': _VideoElementBuilder(),
        },
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(fontSize: 15, height: 1.8),
          h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            // 图片上传
            _ToolbarButton(
              icon: _uploading ? Icons.hourglass_empty : Icons.image,
              label: '图片',
              onTap: _uploading ? null : _pickAndUploadImage,
            ),
            const SizedBox(width: 8),
            // 视频上传
            _ToolbarButton(
              icon: _uploading ? Icons.hourglass_empty : Icons.videocam,
              label: '视频',
              onTap: _uploading ? null : _pickAndUploadVideo,
            ),
            const SizedBox(width: 8),
            // 分享
            _ToolbarButton(
              icon: Icons.share,
              label: '分享',
              onTap: _shareNote,
            ),
            const Spacer(),
            // 格式化按钮
            _ToolbarButton(
              icon: Icons.format_bold,
              label: '粗体',
              onTap: () => _insertAtCursor('****'),
              compact: true,
            ),
            _ToolbarButton(
              icon: Icons.format_italic,
              label: '斜体',
              onTap: () => _insertAtCursor('**'),
              compact: true,
            ),
            _ToolbarButton(
              icon: Icons.title,
              label: '标题',
              onTap: () => _insertAtCursor('## '),
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// 底部工具栏按钮
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool compact;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: 6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 18 : 22, color: onTap != null ? null : Colors.grey),
            if (!compact)
              Text(
                label,
                style: TextStyle(fontSize: 10, color: onTap != null ? null : Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

/// 视频元素构建器（Markdown 中的 <video> 标签）
class _VideoElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(covariant dynamic element, TextStyle? preferredStyle) {
    final src = element.attributes['src'] ?? '';
    if (src.isEmpty) return null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text('视频文件', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            SelectableText(
              src.toString(),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// 堆叠编辑器：将渲染后的内容（含图片）作为背景，透明 TextField 覆盖在上面
/// 这样编辑时也能看到图片
class _StackedEditor extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;

  const _StackedEditor({
    required this.controller,
    required this.decoration,
  });

  @override
  State<_StackedEditor> createState() => _StackedEditorState();
}

class _StackedEditorState extends State<_StackedEditor> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 底层：渲染后的内容（含图片）
        _buildRenderedContent(),
        // 上层：透明的 TextField 用于编辑
        Positioned.fill(
          child: TextField(
            controller: widget.controller,
            scrollController: _scrollController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(
              fontSize: 15,
              height: 1.8,
              color: Colors.transparent, // 透明文字
            ),
            cursorColor: Colors.black,
            decoration: widget.decoration.copyWith(
              border: widget.decoration.border,
              enabledBorder: widget.decoration.enabledBorder,
              focusedBorder: widget.decoration.focusedBorder,
            ),
          ),
        ),
      ],
    );
  }

  /// 渲染内容（文本 + 图片）
  Widget _buildRenderedContent() {
    final content = widget.controller.text;

    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildContentWidgets(content),
      ),
    );
  }

  /// 构建内容组件列表
  Widget _buildContentWidgets(String content) {
    if (content.isEmpty) {
      return const SizedBox(height: 200);
    }

    final widgets = <Widget>[];
    final imageRegex = RegExp(r'!\[([^\]]*)\]\(([^)]+)\)');

    int lastEnd = 0;

    for (final match in imageRegex.allMatches(content)) {
      // 图片前的文本
      if (match.start > lastEnd) {
        final text = content.substring(lastEnd, match.start);
        if (text.isNotEmpty) {
          widgets.add(_buildTextWidget(text));
        }
      }

      // 图片
      final url = match.group(2);
      if (url != null && url.isNotEmpty) {
        final fullUrl = url.startsWith('http')
            ? url
            : '${ApiService.serverUrl}$url';

        widgets.add(_buildImageWidget(fullUrl));
      }

      lastEnd = match.end;
    }

    // 最后的文本
    if (lastEnd < content.length) {
      final text = content.substring(lastEnd);
      if (text.isNotEmpty) {
        widgets.add(_buildTextWidget(text));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// 构建文本组件
  Widget _buildTextWidget(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.8,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }

  /// 构建图片组件
  Widget _buildImageWidget(String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (context, url) => Container(
              height: 100,
              color: Colors.grey[200],
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 100,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}
