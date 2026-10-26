import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _phoneFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();

  // 手机号注册
  final _phoneController = TextEditingController();
  final _phoneCodeController = TextEditingController();
  final _phonePwdController = TextEditingController();
  final _phoneNicknameController = TextEditingController();

  // 邮箱注册
  final _emailController = TextEditingController();
  final _emailCodeController = TextEditingController();
  final _emailPwdController = TextEditingController();
  final _emailNicknameController = TextEditingController();

  bool _loading = false;
  int _phoneCountdown = 0;
  int _emailCountdown = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _phoneCodeController.dispose();
    _phonePwdController.dispose();
    _phoneNicknameController.dispose();
    _emailController.dispose();
    _emailCodeController.dispose();
    _emailPwdController.dispose();
    _emailNicknameController.dispose();
    super.dispose();
  }

  Future<void> _sendCode(String target, String type, bool isPhone) async {
    if (isPhone) {
      if (!Validators.isValidPhone(target)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入正确的手机号')),
        );
        return;
      }
    } else {
      if (!Validators.isValidEmail(target)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入正确的邮箱')),
        );
        return;
      }
    }

    try {
      await AuthApi.sendCode(target, type);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('验证码已发送')),
      );

      setState(() {
        if (isPhone) {
          _phoneCountdown = 60;
        } else {
          _emailCountdown = 60;
        }
      });

      _startCountdown(isPhone);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _startCountdown(bool isPhone) {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          if (isPhone) {
            if (_phoneCountdown > 0) _phoneCountdown--;
          } else {
            if (_emailCountdown > 0) _emailCountdown--;
          }
        });
      }
      return (isPhone ? _phoneCountdown : _emailCountdown) > 0;
    });
  }

  Future<void> _registerByPhone() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await AuthApi.registerByPhone(
        phone: _phoneController.text.trim(),
        code: _phoneCodeController.text.trim(),
        password: _phonePwdController.text,
        nickname: _phoneNicknameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('注册成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
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

  Future<void> _registerByEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await AuthApi.registerByEmail(
        email: _emailController.text.trim(),
        code: _emailCodeController.text.trim(),
        password: _emailPwdController.text,
        nickname: _emailNicknameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('注册成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
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
      appBar: AppBar(
        title: const Text('注册'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '手机号注册'),
                Tab(text: '邮箱注册'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 400,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 手机号注册表单
                  _buildPhoneForm(),
                  // 邮箱注册表单
                  _buildEmailForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneForm() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _phoneController,
            maxLength: 11,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '手机号',
              border: OutlineInputBorder(),
            ),
            validator: (v) => Validators.isValidPhone(v ?? '') ? null : '请输入正确的手机号',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _phoneCodeController,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: '验证码',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => Validators.isValidCode(v ?? '') ? null : '请输入6位验证码',
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _phoneCountdown > 0
                    ? null
                    : () => _sendCode(_phoneController.text, 'register', true),
                child: Text(_phoneCountdown > 0 ? '$_phoneCountdown' : '发送验证码'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phonePwdController,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '密码',
              border: OutlineInputBorder(),
            ),
            validator: (v) => Validators.isValidPassword(v ?? '') ? null : '密码必须为6位数字',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneNicknameController,
            maxLength: 50,
            decoration: const InputDecoration(
              labelText: '昵称（选填）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _registerByPhone,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('注册'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _emailFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: '邮箱',
              border: OutlineInputBorder(),
            ),
            validator: (v) => Validators.isValidEmail(v ?? '') ? null : '请输入正确的邮箱',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _emailCodeController,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: '验证码',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => Validators.isValidCode(v ?? '') ? null : '请输入6位验证码',
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _emailCountdown > 0
                    ? null
                    : () => _sendCode(_emailController.text, 'register', false),
                child: Text(_emailCountdown > 0 ? '$_emailCountdown' : '发送验证码'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailPwdController,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '密码',
              border: OutlineInputBorder(),
            ),
            validator: (v) => Validators.isValidPassword(v ?? '') ? null : '密码必须为6位数字',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailNicknameController,
            maxLength: 50,
            decoration: const InputDecoration(
              labelText: '昵称（选填）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _registerByEmail,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('注册'),
          ),
        ],
      ),
    );
  }
}
