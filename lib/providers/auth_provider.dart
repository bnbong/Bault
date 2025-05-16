import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';
import '../services/service_locator.dart';

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
      await _authService.setMasterPassword(password);
      await _loadUser();
      return true;
    } catch (e) {
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
}
