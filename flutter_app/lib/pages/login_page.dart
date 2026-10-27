import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import 'register_page.dart';
import 'reset_password_page.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _rememberMe = false;

  static const String _savedAccountKey = 'saved_account';
  static const String _savedPasswordKey = 'saved_password';
  static const String _rememberMeKey = 'remember_me';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAccount = prefs.getString(_savedAccountKey);
    final savedPassword = prefs.getString(_savedPasswordKey);
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

    if (rememberMe && savedAccount != null && savedPassword != null) {
      _accountController.text = savedAccount;
      _passwordController.text = savedPassword;
      setState(() {
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString(_savedAccountKey, _accountController.text.trim());
      await prefs.setString(_savedPasswordKey, _passwordController.text);
      await prefs.setBool(_rememberMeKey, true);
    } else {
      await prefs.remove(_savedAccountKey);
      await prefs.remove(_savedPasswordKey);
      await prefs.setBool(_rememberMeKey, false);
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final account = _accountController.text.trim();
    final password = _passwordController.text;

    debugPrint('════════════════════════════════════════════');
    debugPrint('🔐 Login Attempt');
    debugPrint('📱 Account: $account');
    debugPrint('🔑 Password: ${'*' * password.length}');

    try {
      final user = await AuthApi.login(account, password);

      debugPrint('✅ Login Success');
      debugPrint('👤 User: ${user.toJson()}');
      debugPrint('════════════════════════════════════════════');

      // 保存账号密码
      await _saveCredentials();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登录成功')),
        );
        widget.onLoginSuccess();
      }
    } catch (e) {
      debugPrint('❌ Login Failed: $e');
      debugPrint('════════════════════════════════════════════');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.note_add, size: 80, color: Colors.indigo),
                  const SizedBox(height: 16),
                  const Text(
                    '安振个人笔记',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '登录您的账户',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _accountController,
                    decoration: const InputDecoration(
                      labelText: '账号',
                      hintText: '手机号/邮箱/用户名',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入账号';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: '密码',
                      hintText: '6位数字密码',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }
                      if (!Validators.isValidPassword(value)) {
                        return '密码必须为6位数字';
                      }
                      return null;
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('记住账号和密码'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('登录', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: const Text('没有账号？立即注册'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
                      );
                    },
                    child: const Text('忘记密码？'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
