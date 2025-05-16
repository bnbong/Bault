import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../services/biometric_service.dart';
import '../services/service_locator.dart';

final biometricProvider =
    StateNotifierProvider<BiometricStateNotifier, AsyncValue<bool>>((ref) {
  return BiometricStateNotifier(ServiceLocator().biometricService);
});

// 생체인식 사용 가능 여부 확인 프로바이더
final isBiometricsAvailableProvider = Provider<bool>((ref) {
  final biometricState = ref.watch(biometricProvider);
  // 웹 환경에서는 항상 false 반환
  if (kIsWeb) return false;

  return biometricState.maybeWhen(
    data: (isEnabled) => isEnabled,
    orElse: () => false,
  );
});

class BiometricStateNotifier extends StateNotifier<AsyncValue<bool>> {
  final BiometricService _biometricService;

  BiometricStateNotifier(this._biometricService)
      : super(const AsyncValue.loading()) {
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    try {
      // 웹 환경에서는 생체인식을 사용할 수 없음
      if (kIsWeb) {
        state = const AsyncValue.data(false);
        return;
      }

      final isAvailable = await _biometricService.isBiometricsAvailable();
      final isEnrolled = await _biometricService.isBiometricsEnrolled();
      state = AsyncValue.data(isAvailable && isEnrolled);
    } catch (e, stack) {
      debugPrint('생체인식 상태 확인 실패: $e');
      state = const AsyncValue.data(false); // 오류 발생 시 생체인식을 비활성화
    }
  }

  Future<void> enrollBiometrics() async {
    try {
      // 웹 환경에서는 생체인식을 등록할 수 없음
      if (kIsWeb) {
        throw Exception('현재 환경에서는 생체인식을 사용할 수 없습니다.');
      }

      await _biometricService.enrollBiometrics();
      state = const AsyncValue.data(true);
    } catch (e, stack) {
      debugPrint('생체인식 등록 실패: $e');
      state = const AsyncValue.data(false); // 오류 발생 시 생체인식을 비활성화
    }
  }

  Future<void> removeBiometrics() async {
    try {
      await _biometricService.removeBiometrics();
      state = const AsyncValue.data(false);
    } catch (e, stack) {
      debugPrint('생체인식 제거 실패: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> authenticate(String localizedReason) async {
    try {
      // 웹 환경에서는 생체인식을 사용할 수 없음
      if (kIsWeb) {
        return false;
      }

      return await _biometricService.authenticate(localizedReason);
    } catch (e) {
      debugPrint('생체인식 인증 실패: $e');
      return false;
    }
  }

  // 현재 환경에서 생체인식 사용 가능 여부 확인
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;

    try {
      return await _biometricService.isBiometricsAvailable();
    } catch (e) {
      debugPrint('생체인식 가능 여부 확인 실패: $e');
      return false;
    }
  }
}
