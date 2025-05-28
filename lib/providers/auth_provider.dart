import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';
import '../services/service_locator.dart';
import 'package:flutter/foundation.dart';

final authProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<AuthUser>>((ref) {
  return AuthStateNotifier(ServiceLocator().authService);
});

// 로그인 상태 프로바이더
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(
    data: (user) => user.isMasterPasswordSet,
    orElse: () => false,
  );
});

class AuthStateNotifier extends StateNotifier<AsyncValue<AuthUser>> {
  final AuthService _authService;

  AuthStateNotifier(this._authService) : super(const AsyncValue.loading()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> hasMasterPassword() async {
    try {
      return await _authService.isMasterPasswordSet();
    } catch (e) {
      return false;
    }
  }

  Future<bool> setMasterPassword(String password) async {
    try {
      debugPrint('🔐 마스터 비밀번호 설정 시작');
      debugPrint('🔐 비밀번호 길이: ${password.length}');

      debugPrint('🔐 AuthService.setMasterPassword 호출 시작');
      await _authService.setMasterPassword(password);
      debugPrint('🔐 AuthService.setMasterPassword 완료');

      debugPrint('🔐 ServiceLocator.initializeWithMasterPassword 호출 시작');
      await ServiceLocator().initializeWithMasterPassword(password);
      debugPrint('🔐 ServiceLocator.initializeWithMasterPassword 완료');

      debugPrint('🔐 사용자 정보 로드 시작');
      await _loadUser();
      debugPrint('🔐 사용자 정보 로드 완료');

      debugPrint('🔐 마스터 비밀번호 설정 성공');
      return true;
    } catch (e, stackTrace) {
      debugPrint('🔐 마스터 비밀번호 설정 실패: $e');
      debugPrint('🔐 스택 트레이스: $stackTrace');
      return false;
    }
  }

  Future<bool> verifyMasterPassword(String password) async {
    try {
      // 로그인 제한 확인
      final isLocked = await _authService.isLoginLocked();
      if (isLocked) {
        return false;
      }

      final isValid = await _authService.verifyMasterPassword(password);
      if (isValid) {
        await _authService.resetLoginAttempts();
        // 마스터 비밀번호로 ServiceLocator의 암호화 서비스 초기화
        await ServiceLocator().initializeWithMasterPassword(password);
        return true;
      } else {
        final attempts = await _authService.incrementLoginAttempts();
        if (attempts >= 5) {
          // 5번 이상 실패 시 로그인 제한 (30분)
          final lockoutTime = DateTime.now().add(const Duration(minutes: 30));
          await _authService.setLoginLockoutUntil(lockoutTime);
        }
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> changeMasterPassword(
      String currentPassword, String newPassword) async {
    try {
      await _authService.changeMasterPassword(currentPassword, newPassword);
      // 새로운 마스터 비밀번호로 ServiceLocator의 암호화 서비스 재초기화
      await ServiceLocator().initializeWithMasterPassword(newPassword);
      await _loadUser();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int> getLoginAttempts() async {
    return _authService.getLoginAttempts();
  }

  Future<DateTime?> getLoginLockoutUntil() async {
    return _authService.getLoginLockoutUntil();
  }

  Future<bool> isLoginLocked() async {
    return _authService.isLoginLocked();
  }

  Future<bool> signInWithGoogle() async {
    try {
      final success = await _authService.signInWithGoogle();
      if (success) {
        await _loadUser();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signOutFromGoogle() async {
    try {
      await _authService.signOutFromGoogle();
      await _loadUser();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 구글 인증 사용 가능 여부 확인
  Future<bool> canUseGoogleAuth() async {
    try {
      // 시뮬레이터나 웹 환경에서는 구글 인증이 제한될 수 있음
      // 실제 기기일 경우 true 반환
      final isAuthenticated = await _authService.isAuthenticated();
      return true;
    } catch (e) {
      // 오류 발생 시 인증 불가능으로 처리
      return false;
    }
  }
}
