import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_notes/main.dart';

void main() {
  testWidgets('应用启动显示登录页', (WidgetTester tester) async {
    await tester.pumpWidget(const PersonalNotesApp());

    // 等待加载完成
    await tester.pumpAndSettle();

    // 验证登录页元素
    expect(find.text('个人笔记'), findsOneWidget);
    expect(find.text('登录您的账户'), findsOneWidget);
    expect(find.text('登录'), findsWidgets);
    expect(find.text('没有账号？立即注册'), findsOneWidget);
    expect(find.text('忘记密码？'), findsOneWidget);
  });

  testWidgets('登录表单验证 - 空账号', (WidgetTester tester) async {
    await tester.pumpWidget(const PersonalNotesApp());
    await tester.pumpAndSettle();

    // 点击登录按钮
    await tester.tap(find.text('登录').last);
    await tester.pumpAndSettle();

    // 验证错误提示
    expect(find.text('请输入账号'), findsOneWidget);
  });

  testWidgets('登录表单验证 - 密码格式', (WidgetTester tester) async {
    await tester.pumpWidget(const PersonalNotesApp());
    await tester.pumpAndSettle();

    // 输入账号
    await tester.enterText(find.byType(TextFormField).first, '13800008000');

    // 输入无效密码
    await tester.enterText(find.byType(TextFormField).last, 'abc');

    // 点击登录
    await tester.tap(find.text('登录').last);
    await tester.pumpAndSettle();

    // 验证错误提示
    expect(find.text('密码必须为6位数字'), findsOneWidget);
  });

  testWidgets('注册页面切换', (WidgetTester tester) async {
    await tester.pumpWidget(const PersonalNotesApp());
    await tester.pumpAndSettle();

    // 点击注册链接
    await tester.tap(find.text('没有账号？立即注册'));
    await tester.pumpAndSettle();

    // 验证注册页元素
    expect(find.text('注册'), findsWidgets);
    expect(find.text('手机号注册'), findsOneWidget);
    expect(find.text('邮箱注册'), findsOneWidget);
  });
}
