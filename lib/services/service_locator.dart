import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'encryption_service.dart';
import 'password_repository.dart';
import 'password_service.dart';
import 'clipboard_service.dart';
import 'biometric_service.dart';
import 'auth_service.dart';
import 'sync_service.dart';
import 'sync_service_factory.dart';
import 'impl/aes_encryption_service.dart';
import 'impl/local_password_repository.dart';
import 'impl/google_drive_repository.dart';
import 'impl/flutter_clipboard_service.dart' as impl;
import 'impl/local_biometric_service.dart';
import 'impl/local_auth_service.dart';
import 'impl/google_auth_service.dart';
import 'impl/password_service_impl.dart';
import 'package:flutter/foundation.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final SharedPreferences _prefs;
  late final EncryptionService _encryptionService;
  late final PasswordRepository _passwordRepository;
  late final PasswordService _passwordService;
  late final ClipboardService _clipboardService;
  late final BiometricService _biometricService;
  late final AuthService _authService;
  late final SyncService _syncService;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _encryptionService =
        AESEncryptionService('bault-secret-key'); // TODO: 키 관리 필요
    _clipboardService = impl.FlutterClipboardService();
    _biometricService = LocalBiometricService(_prefs);

    // 로컬 인증 서비스 생성
    final localAuthService = LocalAuthService(_prefs, _encryptionService);
    // 구글 인증 서비스 생성
    _authService = GoogleAuthService(_prefs, localAuthService);
    // Default : 로컬 인증 사용
    // _authService = localAuthService;

    // 저장소 선택 (로컬 또는 구글 드라이브)
    _passwordRepository = LocalPasswordRepository(_prefs);
    // TODO: 구글 드라이브 연동 시 아래 코드로 교체
    // final client = await _getGoogleDriveClient();
    // _passwordRepository = GoogleDriveRepository(drive.DriveApi(client));

    // 비밀번호 서비스 생성
    _passwordService = PasswordServiceImpl(
      repository: _passwordRepository,
      encryptionService: _encryptionService,
    );

    // 동기화 서비스 생성
    _syncService = await SyncServiceFactory.createSyncService(
      authService: _authService,
      passwordService: _passwordService,
      encryptionService: _encryptionService,
    );
  }

  PasswordService get passwordService => _passwordService;
  ClipboardService get clipboardService => _clipboardService;
  BiometricService get biometricService => _biometricService;
  AuthService get authService => _authService;
  SyncService get syncService => _syncService;

  /// 동기화 서비스 유형 변경
  Future<void> changeSyncType(SyncType newType) async {
    try {
      // 이미 동일한 유형인 경우 변경하지 않음
      final currentType = await SyncServiceFactory.getCurrentSyncType();
      if (currentType == newType) {
        return;
      }

      // 새로운 동기화 서비스 생성
      final newService = await SyncServiceFactory.changeSyncType(
        newType: newType,
        authService: _authService,
        passwordService: _passwordService,
        encryptionService: _encryptionService,
      );

      // 새 서비스로 대체
      _syncService = newService;
    } catch (e) {
      debugPrint('동기화 유형 변경 중 오류 발생: $e');
      // 기존 서비스를 계속 사용
      rethrow;
    }
  }

  // TODO: 구글 드라이브 클라이언트 초기화 구현
  Future<AuthClient> _getGoogleDriveClient() async {
    throw UnimplementedError('구글 드라이브 클라이언트 초기화가 필요합니다.');
  }
}
