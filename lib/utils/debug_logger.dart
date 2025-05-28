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
        debugPrint('$_prefix 🔍 Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('$_prefix 📋 StackTrace: $stackTrace');
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

  /// 환경 변수 검증 결과 출력
  static void logEnvironmentVariables(Map<String, String> envVars) {
    if (kDebugMode) {
      config('환경 변수 검증 결과:');
      for (final entry in envVars.entries) {
        if (entry.value.isEmpty) {
          warning('  ${entry.key}: 누락됨');
        } else {
          success('  ${entry.key}: ${_maskSensitiveData(entry.value)}');
        }
      }
    }
  }

  /// 민감한 데이터 마스킹
  static String _maskSensitiveData(String data) {
    if (data.length <= 8) {
      return '***';
    }
    return '${data.substring(0, 4)}...${data.substring(data.length - 4)}';
  }

  /// 플랫폼 정보 출력
  static void logPlatformInfo() {
    if (kDebugMode) {
      config('플랫폼 정보:');
      config('  - 현재 플랫폼: ${defaultTargetPlatform.name}');
      config('  - 웹 환경: $kIsWeb');
      config('  - 디버그 모드: $kDebugMode');
      config('  - 프로파일 모드: $kProfileMode');
      config('  - 릴리즈 모드: $kReleaseMode');
    }
  }

  /// 구글 로그인 설정 체크리스트 출력
  static void logIOSSetupChecklist() {
    if (kDebugMode) {
      ios('iOS 구글 로그인 설정 체크리스트:');
      ios('  1. ✓ Info.plist에 CFBundleURLSchemes 설정');
      ios('  2. ✓ Info.plist에 GIDClientID 설정');
      ios('  3. ? GoogleService-Info.plist 파일 존재 (선택사항)');
      ios('  4. ✓ AppDelegate에서 구글 로그인 초기화');
      ios('  5. ✓ URL 스킴 처리 구현');
      ios('  6. ? 번들 ID와 구글 콘솔 설정 일치 확인');
      ios('  7. ? 실제 기기에서 테스트 (시뮬레이터 제한 있음)');
    }
  }
}
