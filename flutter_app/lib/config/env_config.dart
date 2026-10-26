// API 环境配置
// 使用方法: import 'package:personal_notes/config/env_config.dart';

enum AppEnvironment {
  development,
  production,
}

class EnvConfig {
  static AppEnvironment _currentEnv = AppEnvironment.development;

  static void setEnvironment(AppEnvironment env) {
    _currentEnv = env;
  }

  static AppEnvironment get currentEnvironment => _currentEnv;

  // API 基础地址
  static String get apiBaseUrl {
    switch (_currentEnv) {
      case AppEnvironment.development:
        return 'http://39.106.88.210:8080/api'; // 开发环境（与生产相同）
      case AppEnvironment.production:
        return 'http://39.106.88.210:8080/api'; // 生产环境
    }
  }

  // 是否启用日志
  static bool get enableLogging {
    switch (_currentEnv) {
      case AppEnvironment.development:
        return true;
      case AppEnvironment.production:
        return false;
    }
  }

  // 请求超时时间（毫秒）
  static int get requestTimeout {
    switch (_currentEnv) {
      case AppEnvironment.development:
        return 30000;
      case AppEnvironment.production:
        return 15000;
    }
  }

  // 是否显示调试信息
  static bool get showDebugInfo => _currentEnv == AppEnvironment.development;
}
