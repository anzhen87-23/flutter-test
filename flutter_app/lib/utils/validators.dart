import 'dart:async';

/// 验证工具类
class Validators {
  /// 验证手机号（中国大陆11位）
  static bool isValidPhone(String phone) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
  }

  /// 验证邮箱
  static bool isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  /// 验证密码（6位数字）
  static bool isValidPassword(String password) {
    return RegExp(r'^\d{6}$').hasMatch(password);
  }

  /// 验证验证码（6位数字）
  static bool isValidCode(String code) {
    return RegExp(r'^\d{6}$').hasMatch(code);
  }

  /// 手机号脱敏 (138****8000)
  static String maskPhone(String phone) {
    if (phone.length != 11) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(7)}';
  }

  /// 格式化日期（友好显示）
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';

    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    if (year == now.year) {
      return '$month-$day';
    }
    return '$year-$month-$day';
  }
}

/// 防抖工具
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

typedef VoidCallback = void Function();
