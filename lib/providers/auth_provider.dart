import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';
import '../services/service_locator.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthUser?>((ref) {
  return AuthNotifier();
});

// 로그인 상태 프로바이더
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState?.isMasterPasswordSet ?? false;
});

class AuthNotifier extends StateNotifier<AuthUser?> {
  AuthNotifier() : super(null);

  AuthService get _authService => ServiceLocator().authService;

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getUser();
      state = user;
    } catch (e) {
      state = null;
    }
  }

  Future<bool> isMasterPasswordSet() async {
    try {
      return await _authService.isMasterPasswordSet();
    } catch (e) {
      return false;
    }
  }

  Future<bool> setMasterPassword(String password) async {
    try {
      await _authService.setMasterPassword(password);
      await ServiceLocator().initializeWithMasterPassword(password);
      await _loadUser();
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('마스터 비밀번호 설정 실패: $e');
        debugPrint('스택 트레이스: $stackTrace');
      }
      return false;
    }
  }

  Future<bool> verifyMasterPassword(String password) async {
    try {
      final isLocked = await _authService.isLoginLocked();
      if (isLocked) {
        return false;
      }

      final isValid = await _authService.verifyMasterPassword(password);
      if (isValid) {
        await _authService.resetLoginAttempts();
        await ServiceLocator().initializeWithMasterPassword(password);
        return true;
      } else {
        final attempts = await _authService.incrementLoginAttempts();
        if (attempts >= 5) {
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
      await ServiceLocator().initializeWithMasterPassword(newPassword);
      await _loadUser();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int> getLoginAttempts() async {
    try {
      return await _authService.getLoginAttempts();
    } catch (e) {
      return 0;
    }
  }

  Future<DateTime?> getLoginLockoutUntil() async {
    try {
      return await _authService.getLoginLockoutUntil();
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLoginLocked() async {
    try {
      return await _authService.isLoginLocked();
    } catch (e) {
      return false;
    }
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

  Future<void> signOutFromGoogle() async {
    try {
      await _authService.signOutFromGoogle();
      await _loadUser();
    } catch (e) {
      // 오류 무시
    }
  }

  Future<bool> isGoogleAuthAvailable() async {
    try {
      return true;
    } catch (e) {
      return false;
    }
  }
}
