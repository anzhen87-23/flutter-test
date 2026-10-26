import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'notes_list_page.dart';
import 'folders_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onLogout;

  const HomePage({super.key, required this.onLogout});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final GlobalKey<NotesListPageState> _notesKey = GlobalKey();
  final GlobalKey<FoldersPageState> _foldersKey = GlobalKey();

  List<Widget> get _pages => [
    NotesListPage(key: _notesKey),
    FoldersPage(key: _foldersKey),
    ProfilePage(onLogout: widget.onLogout),
  ];

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.clearToken();
      widget.onLogout();
    }
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
    // 切换到笔记或文件夹 Tab 时自动刷新
    if (index == 0) {
      _notesKey.currentState?.refresh();
    } else if (index == 1) {
      _foldersKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: '笔记',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: '文件夹',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
