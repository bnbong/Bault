import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/auth_user.dart';
import '../auth_service.dart';
import '../encryption_service.dart';
import 'aes_encryption_service.dart';

class LocalAuthService implements AuthService {
  final SharedPreferences _prefs;
  final EncryptionService _encryptionService;

  static const String _userKey = 'auth_user';
  static const String _passwordKey = 'master_password';
  static const String _attemptsKey = 'login_attempts';
  static const String _lockoutKey = 'login_lockout_until';

  LocalAuthService(this._prefs, this._encryptionService);

  @override
  Future<bool> isMasterPasswordSet() async {
    return _prefs.containsKey(_passwordKey);
  }

  @override
  Future<void> setMasterPassword(String password) async {
    try {
      final tempEncryptionService = AESEncryptionService(password);
      final encryptedPassword = tempEncryptionService.encrypt(password);
      await _prefs.setString(_passwordKey, encryptedPassword);

      final user = await getUser();
      await updateUser(
        user.copyWith(
          isMasterPasswordSet: true,
          lastLoginAt: DateTime.now(),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('마스터 비밀번호 설정 실패: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> changeMasterPassword(
      String currentPassword, String newPassword) async {
    final isValid = await verifyMasterPassword(currentPassword);
    if (!isValid) {
      throw Exception('현재 비밀번호가 올바르지 않습니다.');
    }

    final newEncryptionService = AESEncryptionService(newPassword);
    final encryptedPassword = newEncryptionService.encrypt(newPassword);
    await _prefs.setString(_passwordKey, encryptedPassword);

    final user = await getUser();
    await updateUser(
      user.copyWith(
        lastLoginAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<bool> verifyMasterPassword(String password) async {
    try {
      final storedPassword = _prefs.getString(_passwordKey);
      if (storedPassword == null) return false;

      final tempEncryptionService = AESEncryptionService(password);
      final decryptedPassword = tempEncryptionService.decrypt(storedPassword);
      return decryptedPassword == password;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('비밀번호 검증 중 오류 발생: $e');
      }
      return false;
    }
  }

  @override
  Future<int> incrementLoginAttempts() async {
    final attempts = await getLoginAttempts();
    final newAttempts = attempts + 1;
    await _prefs.setInt(_attemptsKey, newAttempts);
    return newAttempts;
  }

  @override
  Future<void> resetLoginAttempts() async {
    await _prefs.setInt(_attemptsKey, 0);
  }

  @override
  Future<int> getLoginAttempts() async {
    return _prefs.getInt(_attemptsKey) ?? 0;
  }

  @override
  Future<void> setLoginLockoutUntil(DateTime time) async {
    await _prefs.setString(_lockoutKey, time.toIso8601String());
  }

  @override
  Future<DateTime?> getLoginLockoutUntil() async {
    final lockoutTime = _prefs.getString(_lockoutKey);
    if (lockoutTime == null) {
      return null;
    }

    return DateTime.parse(lockoutTime);
  }

  @override
  Future<bool> isLoginLocked() async {
    final lockoutUntil = await getLoginLockoutUntil();
    if (lockoutUntil == null) {
      return false;
    }

    return DateTime.now().isBefore(lockoutUntil);
  }

  @override
  Future<bool> signInWithGoogle() async {
    throw UnimplementedError('구글 로그인은 로컬 인증 서비스에서 지원하지 않습니다.');
  }

  @override
  Future<void> signOutFromGoogle() async {
    throw UnimplementedError('구글 로그아웃은 로컬 인증 서비스에서 지원하지 않습니다.');
  }

  @override
  Future<AuthUser> getUser() async {
    final userJson = _prefs.getString(_userKey);

    if (userJson == null) {
      final initialUser = AuthUser.initial();
      await updateUser(initialUser);
      return initialUser;
    }

    return AuthUser.fromJson(jsonDecode(userJson));
  }

  @override
  Future<void> updateUser(AuthUser user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  @override
  Future<bool> isAuthenticated() async {
    return await isMasterPasswordSet();
  }

  @override
  Future<bool> signIn() async {
    final user = await getUser();
    await updateUser(
      user.copyWith(
        lastLoginAt: DateTime.now(),
      ),
    );
    return true;
  }

  @override
  Future<http.Client?> getAuthClient() async {
    return null;
  }
}
