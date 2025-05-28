import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'biometric_service.dart';
import 'clipboard_service.dart';
import 'encryption_service.dart';
import 'password_repository.dart';
import 'password_service.dart';
import 'sync_service.dart';
import 'sync_service_factory.dart';
import 'impl/aes_encryption_service.dart';
import 'impl/flutter_clipboard_service.dart' as impl;
import 'impl/google_auth_service.dart';
import 'impl/local_auth_service.dart';
import 'impl/local_biometric_service.dart';
import 'impl/local_password_repository.dart';
import 'impl/password_service_impl.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final SharedPreferences _prefs;
  EncryptionService? _encryptionService;
  PasswordRepository? _passwordRepository;
  PasswordService? _passwordService;
  late final ClipboardService _clipboardService;
  late final BiometricService _biometricService;
  AuthService? _authService;
  SyncService? _syncService;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _clipboardService = impl.FlutterClipboardService();
    _biometricService = LocalBiometricService(_prefs);

    final tempEncryptionService = AESEncryptionService('temp');
    final localAuthService = LocalAuthService(_prefs, tempEncryptionService);
    _authService = GoogleAuthService(_prefs, localAuthService);
  }

  /// 마스터 비밀번호로 암호화 서비스 초기화
  Future<void> initializeWithMasterPassword(String masterPassword) async {
    _encryptionService = AESEncryptionService(masterPassword);

    final localAuthService = LocalAuthService(_prefs, _encryptionService!);
    _authService = GoogleAuthService(_prefs, localAuthService);

    _passwordRepository = LocalPasswordRepository(_prefs);

    _passwordService = PasswordServiceImpl(
      repository: _passwordRepository!,
      encryptionService: _encryptionService!,
    );

    try {
      _syncService = await SyncServiceFactory.createSyncService(
        authService: _authService!,
        passwordService: _passwordService!,
        encryptionService: _encryptionService!,
      );
    } catch (e) {
      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint('웹 플랫폼에서는 일부 동기화 기능이 제한됩니다.');
        }
      }
      _syncService = null;
    }
  }

  PasswordService get passwordService {
    if (_passwordService == null) {
      throw StateError(
          '암호화 서비스가 초기화되지 않았습니다. initializeWithMasterPassword를 먼저 호출하세요.');
    }
    return _passwordService!;
  }

  ClipboardService get clipboardService => _clipboardService;
  BiometricService get biometricService => _biometricService;
  AuthService get authService => _authService!;
  SyncService? get syncService => _syncService;

  /// 동기화 서비스 유형 변경
  Future<void> changeSyncType(SyncType newType) async {
    if (_encryptionService == null || _passwordService == null) {
      throw StateError('암호화 서비스가 초기화되지 않았습니다.');
    }

    try {
      final currentType = await SyncServiceFactory.getCurrentSyncType();
      if (currentType == newType) {
        return;
      }

      final newService = await SyncServiceFactory.changeSyncType(
        newType: newType,
        authService: _authService!,
        passwordService: _passwordService!,
        encryptionService: _encryptionService!,
      );

      _syncService = newService;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('동기화 유형 변경 중 오류 발생: $e');
      }
      rethrow;
    }
  }
}
