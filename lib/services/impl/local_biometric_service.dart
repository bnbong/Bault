import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../biometric_service.dart';

class LocalBiometricService implements BiometricService {
  final SharedPreferences _prefs;
  static const String _biometricsKey = 'biometrics_enabled';
  late final LocalAuthentication? _localAuth;

  LocalBiometricService(this._prefs) {
    // 웹 환경에서는 생체인식 서비스를 초기화하지 않음
    if (!kIsWeb) {
      try {
        _localAuth = LocalAuthentication();
      } catch (e) {
        debugPrint('생체인식 서비스 초기화 실패: $e');
        _localAuth = null;
      }
    } else {
      _localAuth = null;
    }
  }

  @override
  Future<bool> isBiometricsAvailable() async {
    // 웹 환경이거나 생체인식 서비스가 초기화되지 않았으면 항상 false 반환
    if (kIsWeb || _localAuth == null) {
      return false;
    }

    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      debugPrint('생체인식 가능 여부 확인 실패: $e');
      return false;
    } catch (e) {
      debugPrint('생체인식 가능 여부 확인 중 예상치 못한 오류: $e');
      return false;
    }
  }

  @override
  Future<bool> isBiometricsEnrolled() async {
    // 웹 환경이거나 생체인식 서비스가 초기화되지 않았으면 항상 false 반환
    if (kIsWeb || _localAuth == null) {
      return false;
    }

    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException catch (e) {
      debugPrint('생체인식 등록 여부 확인 실패: $e');
      return false;
    } catch (e) {
      debugPrint('생체인식 등록 여부 확인 중 예상치 못한 오류: $e');
      return false;
    }
  }

  @override
  Future<bool> authenticate(String localizedReason) async {
    // 웹 환경이거나 생체인식 서비스가 초기화되지 않았으면 항상 false 반환
    if (kIsWeb || _localAuth == null) {
      debugPrint('생체인식 인증 불가: 웹 환경이거나 생체인식 서비스 미초기화');
      return false;
    }

    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        debugPrint('생체인식 인증 불가: 기기가 생체인식을 지원하지 않음');
        return false;
      }

      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        debugPrint('생체인식 인증 불가: 생체인식 검사 기능 사용 불가');
        return false;
      }

      // 사용 가능한 생체인식 유형 확인
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      debugPrint('사용 가능한 생체인식: $availableBiometrics');

      if (availableBiometrics.isEmpty) {
        debugPrint('사용 가능한 생체인식 없음');
        return false;
      }

      final hasFaceID = availableBiometrics.contains(BiometricType.face);
      final hasFingerprint =
          availableBiometrics.contains(BiometricType.fingerprint);

      debugPrint('Face ID 사용 가능: $hasFaceID, 지문 사용 가능: $hasFingerprint');

      // 인증 시도
      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      debugPrint('생체인식 인증 결과: $authenticated');
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint(
          '생체인식 인증 PlatformException: ${e.message}, code: ${e.code}, details: ${e.details}');
      return false;
    } catch (e) {
      debugPrint('생체인식 인증 중 예상치 못한 오류: $e');
      return false;
    }
  }

  @override
  Future<void> enrollBiometrics() async {
    // 웹 환경이거나 생체인식을 사용할 수 없는 경우 예외 발생
    if (kIsWeb || _localAuth == null) {
      throw Exception('현재 환경에서는 생체인식을 사용할 수 없습니다.');
    }

    final isAvailable = await isBiometricsAvailable();
    if (!isAvailable) {
      throw Exception('생체인식을 사용할 수 없습니다.');
    }

    final isEnrolled = await isBiometricsEnrolled();
    if (!isEnrolled) {
      throw Exception('생체인식이 등록되어 있지 않습니다.');
    }

    await _prefs.setBool(_biometricsKey, true);
  }

  @override
  Future<void> removeBiometrics() async {
    await _prefs.setBool(_biometricsKey, false);
  }

  bool isBiometricsEnabled() {
    return _prefs.getBool(_biometricsKey) ?? false;
  }
}
