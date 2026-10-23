import 'package:flutter_test/flutter_test.dart';
import 'package:personal_notes/utils/validators.dart';

void main() {
  group('Validators.isValidPhone', () {
    test('有效手机号', () {
      expect(Validators.isValidPhone('13800008000'), true);
      expect(Validators.isValidPhone('13912345678'), true);
      expect(Validators.isValidPhone('15800000000'), true);
      expect(Validators.isValidPhone('18612345678'), true);
    });

    test('无效手机号', () {
      expect(Validators.isValidPhone(''), false);
      expect(Validators.isValidPhone('12345678901'), false); // 不是1开头
      expect(Validators.isValidPhone('1380000800'), false); // 10位
      expect(Validators.isValidPhone('138000080001'), false); // 12位
      expect(Validators.isValidPhone('12800008000'), false); // 第二位不是3-9
      expect(Validators.isValidPhone('abcdefghijk'), false);
    });
  });

  group('Validators.isValidEmail', () {
    test('有效邮箱', () {
      expect(Validators.isValidEmail('test@example.com'), true);
      expect(Validators.isValidEmail('user.name@domain.co'), true);
      expect(Validators.isValidEmail('user+tag@gmail.com'), true);
    });

    test('无效邮箱', () {
      expect(Validators.isValidEmail(''), false);
      expect(Validators.isValidEmail('notemail'), false);
      expect(Validators.isValidEmail('@example.com'), false);
      expect(Validators.isValidEmail('user@'), false);
    });
  });

  group('Validators.isValidPassword', () {
    test('有效密码（6位数字）', () {
      expect(Validators.isValidPassword('123456'), true);
      expect(Validators.isValidPassword('000000'), true);
      expect(Validators.isValidPassword('999999'), true);
    });

    test('无效密码', () {
      expect(Validators.isValidPassword(''), false);
      expect(Validators.isValidPassword('12345'), false); // 5位
      expect(Validators.isValidPassword('1234567'), false); // 7位
      expect(Validators.isValidPassword('abcdef'), false); // 字母
      expect(Validators.isValidPassword('12345a'), false); // 包含字母
    });
  });

  group('Validators.isValidCode', () {
    test('有效验证码', () {
      expect(Validators.isValidCode('123456'), true);
      expect(Validators.isValidCode('000000'), true);
    });

    test('无效验证码', () {
      expect(Validators.isValidCode(''), false);
      expect(Validators.isValidCode('12345'), false);
      expect(Validators.isValidCode('abcdef'), false);
    });
  });

  group('Validators.maskPhone', () {
    test('手机号脱敏', () {
      expect(Validators.maskPhone('13800008000'), '138****8000');
      expect(Validators.maskPhone('13912345678'), '139****5678');
    });

    test('非标准长度直接返回', () {
      expect(Validators.maskPhone('1234'), '1234');
    });
  });

  group('Validators.formatDate', () {
    test('刚刚', () {
      final now = DateTime.now();
      expect(Validators.formatDate(now), '刚刚');
    });

    test('几分钟前', () {
      final date = DateTime.now().subtract(const Duration(minutes: 5));
      expect(Validators.formatDate(date), '5分钟前');
    });

    test('几小时前', () {
      final date = DateTime.now().subtract(const Duration(hours: 3));
      expect(Validators.formatDate(date), '3小时前');
    });

    test('几天前', () {
      final date = DateTime.now().subtract(const Duration(days: 2));
      expect(Validators.formatDate(date), '2天前');
    });
  });
}
