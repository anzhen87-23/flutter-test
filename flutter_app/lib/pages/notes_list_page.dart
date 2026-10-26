import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/folder.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import 'note_editor_page.dart';

class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key});

  @override
  NotesListPageState createState() => NotesListPageState();
}

class NotesListPageState extends State<NotesListPage> {
  List<Note> _notes = [];
  List<Folder> _folders = [];
  int _currentPage = 1;
  int _total = 0;
  int? _selectedFolderId;
  bool _loading = true;

  /// 外部可调用：刷新笔记列表
  void refresh() {
    _loadNotes();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadFolders();
    await _loadNotes();
  }

  Future<void> _loadFolders() async {
    try {
      final folders = await FoldersApi.list();
      if (mounted) {
        setState(() => _folders = folders);
      }
    } catch (e) {
      // 忽略错误
    }
  }

  Future<void> _loadNotes() async {
    setState(() => _loading = true);

    try {
      final response = await NotesApi.list(
        page: _currentPage,
        folderId: _selectedFolderId,
      );

      if (mounted) {
        setState(() {
          _notes = response.notes;
          _total = response.total;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  Future<void> _createNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteEditorPage()),
    );

    if (result == true) {
      _loadNotes();
    }
  }

  Future<void> _editNote(Note note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorPage(noteId: note.id),
      ),
    );

    if (result == true) {
      _loadNotes();
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除笔记'),
        content: const Text('确定要删除这条笔记吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await NotesApi.delete(note.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功')),
          );
          _loadNotes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的笔记'),
        actions: [
          if (_folders.isNotEmpty)
            PopupMenuButton<int?>(
              icon: const Icon(Icons.filter_list),
              onSelected: (folderId) {
                setState(() {
                  _selectedFolderId = folderId;
                  _currentPage = 1;
                });
                _loadNotes();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('全部笔记'),
                ),
                ..._folders.map((f) => PopupMenuItem(
                  value: f.id,
                  child: Text(f.name),
                )),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotes,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _notes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_add, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '还没有笔记',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '点击右上角 + 创建第一条笔记',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      final folder = _folders.where((f) => f.id == note.folderId).firstOrNull;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            note.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (note.content.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    note.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (folder != null) ...[
                                    Icon(Icons.folder, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(
                                      folder.name,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    Validators.formatDate(note.updatedAt),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('编辑')),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('删除', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editNote(note);
                              } else if (value == 'delete') {
                                _deleteNote(note);
                              }
                            },
                          ),
                          onTap: () => _editNote(note),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}
