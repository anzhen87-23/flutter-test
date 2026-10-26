import 'package:flutter/material.dart';
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
  List<Folder> _folders = [];
  int? _selectedFolderId;
  bool _loading = false;
  bool _saving = false;

  bool get _isNew => widget.noteId == null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      // 加载文件夹列表
      final folders = await FoldersApi.list();
      if (mounted) {
        setState(() => _folders = folders);
      }

      // 如果是编辑模式，加载笔记数据
      if (!_isNew) {
        final note = await NotesApi.get(widget.noteId!);
        if (mounted) {
          _titleController.text = note.title;
          _contentController.text = note.content;
          _selectedFolderId = note.folderId;
        }
      } else {
        // 新建模式：使用传入的初始文件夹
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

    debugPrint('════════════════════════════════════════════');
    debugPrint('📝 [Note Save] 开始保存');
    debugPrint('📝 [Note Save] 是否新建: $_isNew');
    debugPrint('📝 [Note Save] title: $title');
    debugPrint('📝 [Note Save] content: $content');
    debugPrint('📝 [Note Save] _selectedFolderId: $_selectedFolderId (runtimeType: ${_selectedFolderId.runtimeType})');
    debugPrint('📝 [Note Save] initialFolderId: ${widget.initialFolderId}');

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
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 文件夹选择
                  if (_folders.isNotEmpty)
                    DropdownButtonFormField<int?>(
                      initialValue: _selectedFolderId,
                      decoration: const InputDecoration(
                        labelText: '文件夹',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('未分类'),
                        ),
                        ..._folders.map((f) => DropdownMenuItem(
                          value: f.id,
                          child: Text(f.name),
                        )),
                      ],
                      onChanged: (value) {
                        debugPrint('🔽 [Dropdown] onChanged: value=$value, runtimeType=${value.runtimeType}');
                        setState(() => _selectedFolderId = value);
                      },
                    ),
                  const SizedBox(height: 16),

                  // 标题
                  TextField(
                    controller: _titleController,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: '标题',
                      hintText: '输入笔记标题',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 内容
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        labelText: '内容',
                        hintText: '写点什么...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
