import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../models/user.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfilePage({super.key, this.onLogout});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await ProfileApi.get();
      if (mounted) {
        setState(() {
          _user = user;
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

  Future<void> _editNickname() async {
    final controller = TextEditingController(text: _user?.nickname ?? '');
    final nickname = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '昵称',
            hintText: '请输入昵称',
          ),
          maxLength: 50,
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

    if (nickname != null && nickname.isNotEmpty) {
      try {
        await ProfileApi.updateNickname(nickname);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('昵称已更新')),
          );
          _loadProfile();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更新失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _changePassword() async {
    final oldPwdController = TextEditingController();
    final newPwdController = TextEditingController();
    final confirmPwdController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('修改密码'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPwdController,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: '旧密码',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: newPwdController,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: '新密码',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: confirmPwdController,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: '确认新密码',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
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
      ),
    );

    if (result == true) {
      final oldPwd = oldPwdController.text;
      final newPwd = newPwdController.text;
      final confirmPwd = confirmPwdController.text;

      if (!Validators.isValidPassword(oldPwd)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('旧密码必须为6位数字')),
        );
        return;
      }
      if (!Validators.isValidPassword(newPwd)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('新密码必须为6位数字')),
        );
        return;
      }
      if (newPwd != confirmPwd) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('两次输入的密码不一致')),
        );
        return;
      }
      if (oldPwd == newPwd) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('新密码不能与旧密码相同')),
        );
        return;
      }

      try {
        await ProfileApi.changePassword(
          oldPassword: oldPwd,
          newPassword: newPwd,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('密码已修改')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('修改失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _editBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _user?.birthday ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: '选择生日',
      cancelText: '取消',
      confirmText: '确定',
    );

    if (picked != null) {
      try {
        await ProfileApi.updateBirthday(picked);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('生日已更新')),
          );
          _loadProfile();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更新失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _changePhone() async {
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final codeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('修改手机号'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: '当前密码',
                  hintText: '6位数字密码',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: phoneController,
                maxLength: 11,
                decoration: const InputDecoration(
                  labelText: '新手机号',
                  hintText: '11位手机号',
                ),
                keyboardType: TextInputType.phone,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeController,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: '验证码',
                        hintText: '6位验证码',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final phone = phoneController.text.trim();
                      if (!Validators.isValidPhone(phone)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请输入正确的手机号')),
                        );
                        return;
                      }
                      try {
                        await AuthApi.sendCode(phone, 'phone');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('验证码已发送')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('发送失败: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('发送验证码'),
                  ),
                ],
              ),
            ],
          ),
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
      ),
    );

    if (result == true) {
      final password = passwordController.text;
      final newPhone = phoneController.text.trim();
      final code = codeController.text;

      if (!Validators.isValidPassword(password)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('密码必须为6位数字')),
        );
        return;
      }
      if (!Validators.isValidPhone(newPhone)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('手机号格式不正确')),
        );
        return;
      }
      if (!Validators.isValidCode(code)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证码必须为6位数字')),
        );
        return;
      }

      try {
        await ProfileApi.updatePhone(
          newPhone: newPhone,
          code: code,
          password: password,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('手机号已更新')),
          );
          _loadProfile();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更新失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _changeEmail() async {
    final passwordController = TextEditingController();
    final emailController = TextEditingController();
    final codeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('修改邮箱'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: '当前密码',
                  hintText: '6位数字密码',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: '新邮箱',
                  hintText: 'example@email.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeController,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: '验证码',
                        hintText: '6位验证码',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final email = emailController.text.trim();
                      if (!Validators.isValidEmail(email)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请输入正确的邮箱')),
                        );
                        return;
                      }
                      try {
                        await AuthApi.sendCode(email, 'email');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('验证码已发送')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('发送失败: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('发送验证码'),
                  ),
                ],
              ),
            ],
          ),
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
      ),
    );

    if (result == true) {
      final password = passwordController.text;
      final newEmail = emailController.text.trim();
      final code = codeController.text;

      if (!Validators.isValidPassword(password)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('密码必须为6位数字')),
        );
        return;
      }
      if (!Validators.isValidEmail(newEmail)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('邮箱格式不正确')),
        );
        return;
      }
      if (!Validators.isValidCode(code)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证码必须为6位数字')),
        );
        return;
      }

      try {
        await ProfileApi.updateEmail(
          newEmail: newEmail,
          code: code,
          password: password,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('邮箱已更新')),
          );
          _loadProfile();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更新失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileSize = await file.length();

      if (fileSize > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('图片大小不能超过5MB')),
        );
        return;
      }

      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        await ProfileApi.uploadAvatar(pickedFile.path);

        if (mounted) {
          Navigator.pop(context); // 关闭加载对话框
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('头像已更新')),
          );
          _loadProfile();
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // 关闭加载对话框
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('上传失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('加载失败'))
              : ListView(
                  children: [
                    // 头像和用户信息（头像可点击）
                    GestureDetector(
                      onTap: _changeAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: _user!.avatarUrl.isNotEmpty
                                      ? NetworkImage('http://39.106.88.210:8080${_user!.avatarUrl}')
                                      : null,
                                  child: _user!.avatarUrl.isEmpty
                                      ? const Icon(Icons.person, size: 40)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _user!.displayName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _user!.account,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),

                    // 菜单项
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('修改昵称'),
                      subtitle: Text(_user!.nickname),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _editNickname,
                    ),
                    ListTile(
                      leading: const Icon(Icons.cake),
                      title: const Text('修改生日'),
                      subtitle: Text(_user!.birthday != null
                          ? '${_user!.birthday!.year}-${_user!.birthday!.month.toString().padLeft(2, '0')}-${_user!.birthday!.day.toString().padLeft(2, '0')}'
                          : '未设置'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _editBirthday,
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('修改手机号'),
                      subtitle: Text(_user!.phone ?? '未绑定'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _changePhone,
                    ),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('修改邮箱'),
                      subtitle: Text(_user!.email ?? '未绑定'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _changeEmail,
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('修改密码'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _changePassword,
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo),
                      title: const Text('更换头像'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _changeAvatar,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('退出登录', style: TextStyle(color: Colors.red)),
                      onTap: () async {
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
                          if (mounted) {
                            if (widget.onLogout != null) {
                              widget.onLogout!();
                            } else {
                              // Fallback: navigate to login page if onLogout is not provided
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/',
                                (route) => false,
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
    );
  }
}
