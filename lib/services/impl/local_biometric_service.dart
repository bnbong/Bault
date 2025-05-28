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
    if (!kIsWeb) {
      try {
        _localAuth = LocalAuthentication();
      } catch (e) {
        _localAuth = null;
      }
    } else {
      _localAuth = null;
    }
  }

  @override
  Future<bool> isBiometricsAvailable() async {
    if (kIsWeb || _localAuth == null) {
      return false;
    }

    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> isBiometricsEnrolled() async {
    if (kIsWeb || _localAuth == null) {
      return false;
    }

    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String localizedReason) async {
    if (kIsWeb || _localAuth == null) {
      return false;
    }

    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        return false;
      }

      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        return false;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      return authenticated;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> enrollBiometrics() async {
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
