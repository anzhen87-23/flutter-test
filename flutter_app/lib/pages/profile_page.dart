import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../models/user.dart';

class ProfilePage extends StatefulWidget {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('加载失败'))
              : ListView(
                  children: [
                    // 头像和用户信息
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[300],
                            child: _user!.avatarUrl.isNotEmpty
                                ? null
                                : const Icon(Icons.person, size: 40),
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
                      title: const Text('生日'),
                      subtitle: Text(_user!.birthday != null
                          ? '${_user!.birthday!.year}-${_user!.birthday!.month.toString().padLeft(2, '0')}-${_user!.birthday!.day.toString().padLeft(2, '0')}'
                          : '未设置'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: 实现生日编辑
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('手机号'),
                      subtitle: Text(_user!.phone ?? '未绑定'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: 实现手机号修改
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('邮箱'),
                      subtitle: Text(_user!.email ?? '未绑定'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: 实现邮箱修改
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('修改密码'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _changePassword,
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
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
    );
  }
}
