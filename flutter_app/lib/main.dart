import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const PersonalNotesApp());
}

class PersonalNotesApp extends StatelessWidget {
  const PersonalNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '个人笔记',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AppEntry(),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _isLoggedIn = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 这里简化处理，实际应该检查 SharedPreferences
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _loading = false;
      _isLoggedIn = false; // 默认未登录
    });
  }

  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _onLogout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isLoggedIn) {
      return HomePage(onLogout: _onLogout);
    } else {
      return LoginPage(onLoginSuccess: _onLoginSuccess);
    }
  }
}
