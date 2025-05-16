abstract class BiometricService {
  /// 생체인식 사용 가능 여부 확인
  Future<bool> isBiometricsAvailable();

  /// 생체인식 등록 여부 확인
  Future<bool> isBiometricsEnrolled();

  /// 생체인식 인증
  Future<bool> authenticate(String localizedReason);

  /// 생체인식 등록
  Future<void> enrollBiometrics();

  /// 생체인식 해제
  Future<void> removeBiometrics();
}
