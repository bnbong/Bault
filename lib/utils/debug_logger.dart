import 'package:flutter/foundation.dart';

/// 구글 로그인 디버깅을 위한 전용 로거
class DebugLogger {
  static const String _prefix = '[GoogleAuth]';

  /// 일반 정보 로그
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix ℹ️ $message');
    }
  }

  /// 성공 로그
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix ✅ $message');
    }
  }

  /// 경고 로그
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix ⚠️ $message');
    }
  }

  /// 에러 로그
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('$_prefix ❌ $message');
      if (error != null) {
        debugPrint('$_prefix Error: $error');
      }
    }
  }

  /// 진행 상황 로그
  static void progress(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix 🔄 $message');
    }
  }

  /// 설정 관련 로그
  static void config(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix 🔧 $message');
    }
  }

  /// 네트워크 관련 로그
  static void network(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix 🌐 $message');
    }
  }

  /// iOS 특정 로그
  static void ios(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix 🍎 $message');
    }
  }

  /// Android 특정 로그
  static void android(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix 🤖 $message');
    }
  }
}
