import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personal_notes/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('完整用户流程', () {
    testWidgets('启动应用', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 验证显示登录页
      expect(find.text('个人笔记'), findsOneWidget);
    });

    testWidgets('登录页元素完整', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 验证所有输入框
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('账号'), findsOneWidget);
      expect(find.text('密码'), findsOneWidget);

      // 验证按钮
      expect(find.text('登录'), findsWidgets);
      expect(find.text('没有账号？立即注册'), findsOneWidget);
      expect(find.text('忘记密码？'), findsOneWidget);
    });

    testWidgets('跳转到注册页', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 点击注册
      await tester.tap(find.text('没有账号？立即注册'));
      await tester.pumpAndSettle();

      // 验证注册页
      expect(find.text('手机号注册'), findsOneWidget);
      expect(find.text('邮箱注册'), findsOneWidget);
    });

    testWidgets('跳转到重置密码页', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 点击忘记密码
      await tester.tap(find.text('忘记密码？'));
      await tester.pumpAndSettle();

      // 验证重置密码页
      expect(find.text('重置密码'), findsOneWidget);
      expect(find.text('账号'), findsOneWidget);
    });
  });
}
