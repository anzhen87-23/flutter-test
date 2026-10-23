import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../services/api_service.dart';

class FoldersPage extends StatefulWidget {
  const FoldersPage({super.key});

  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  List<Folder> _folders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() => _loading = true);

    try {
      final folders = await FoldersApi.list();
      if (mounted) {
        setState(() {
          _folders = folders;
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

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '文件夹名称',
            hintText: '请输入文件夹名称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      try {
        await FoldersApi.create(name);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('创建成功')),
          );
          _loadFolders();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _renameFolder(Folder folder) async {
    final controller = TextEditingController(text: folder.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名文件夹'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '新名称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != folder.name) {
      try {
        await FoldersApi.update(folder.id, newName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('重命名成功')),
          );
          _loadFolders();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('重命名失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteFolder(Folder folder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除文件夹'),
        content: Text('确定要删除文件夹"${folder.name}"吗？\n其中的笔记将移至未分类。'),
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
        await FoldersApi.delete(folder.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功')),
          );
          _loadFolders();
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
        title: const Text('文件夹'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFolders,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _folders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '还没有文件夹',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '点击右上角 + 创建文件夹',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: _folders.length,
                    itemBuilder: (context, index) {
                      final folder = _folders[index];
                      return Card(
                        child: InkWell(
                          onTap: () {
                            // 可以跳转到该文件夹的笔记列表
                          },
                          onLongPress: () => _showFolderOptions(folder),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.folder, size: 32, color: Colors.amber),
                                const Spacer(),
                                Text(
                                  folder.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${folder.noteCount} 条笔记',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createFolder,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFolderOptions(Folder folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('重命名'),
              onTap: () {
                Navigator.pop(context);
                _renameFolder(folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteFolder(folder);
              },
            ),
          ],
        ),
      ),
    );
  }
}
