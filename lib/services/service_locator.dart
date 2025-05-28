import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
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

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _clipboardService = impl.FlutterClipboardService();
    _biometricService = LocalBiometricService(_prefs);

    // 임시 암호화 서비스로 로컬 인증 서비스 생성
    final tempEncryptionService = AESEncryptionService('temp-key-for-init');
    final localAuthService = LocalAuthService(_prefs, tempEncryptionService);
    // 구글 인증 서비스 생성
    _authService = GoogleAuthService(_prefs, localAuthService);
  }

  /// 마스터 비밀번호로 암호화 서비스 초기화
  Future<void> initializeWithMasterPassword(String masterPassword) async {
    debugPrint('🔧 ServiceLocator.initializeWithMasterPassword 시작');

    // 암호화 서비스 생성
    debugPrint('🔧 암호화 서비스 생성 시작');
    _encryptionService = AESEncryptionService(masterPassword);
    debugPrint('🔧 암호화 서비스 생성 완료');

    // 로컬 인증 서비스를 실제 암호화 서비스로 재생성
    debugPrint('🔧 로컬 인증 서비스 재생성 시작');
    final localAuthService = LocalAuthService(_prefs, _encryptionService!);
    debugPrint('🔧 로컬 인증 서비스 재생성 완료');

    // 구글 인증 서비스 재생성
    debugPrint('🔧 구글 인증 서비스 재생성 시작');
    _authService = GoogleAuthService(_prefs, localAuthService);
    debugPrint('🔧 구글 인증 서비스 재생성 완료');

    // 저장소 선택 (로컬 또는 구글 드라이브)
    debugPrint('🔧 비밀번호 저장소 생성 시작');
    _passwordRepository = LocalPasswordRepository(_prefs);
    debugPrint('🔧 비밀번호 저장소 생성 완료');

    // 비밀번호 서비스 생성
    debugPrint('🔧 비밀번호 서비스 생성 시작');
    _passwordService = PasswordServiceImpl(
      repository: _passwordRepository!,
      encryptionService: _encryptionService!,
    );
    debugPrint('🔧 비밀번호 서비스 생성 완료');

    // 동기화 서비스 생성 (웹에서는 조건부 생성)
    try {
      debugPrint('🔧 동기화 서비스 생성 시작');
      _syncService = await SyncServiceFactory.createSyncService(
        authService: _authService!,
        passwordService: _passwordService!,
        encryptionService: _encryptionService!,
      );
      debugPrint('🔧 동기화 서비스 생성 완료');
    } catch (e) {
      debugPrint('🔧 동기화 서비스 초기화 실패: $e');
      if (kIsWeb) {
        debugPrint('🔧 웹 플랫폼에서는 일부 동기화 기능이 제한됩니다.');
      }
      // 웹에서는 동기화 서비스 없이 진행
      _syncService = null;
    }

    debugPrint('🔧 ServiceLocator.initializeWithMasterPassword 완료');
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
      // 이미 동일한 유형인 경우 변경하지 않음
      final currentType = await SyncServiceFactory.getCurrentSyncType();
      if (currentType == newType) {
        return;
      }

      // 새로운 동기화 서비스 생성
      final newService = await SyncServiceFactory.changeSyncType(
        newType: newType,
        authService: _authService!,
        passwordService: _passwordService!,
        encryptionService: _encryptionService!,
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
