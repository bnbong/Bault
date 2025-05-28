import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../models/auth_user.dart';
import '../auth_service.dart';
import '../../utils/debug_logger.dart';
import 'local_auth_service.dart';

class GoogleAuthService implements AuthService {
  final SharedPreferences _prefs;
  final LocalAuthService _localAuthService;
  late final GoogleSignIn _googleSignIn;

  static const String _googleTokenKey = 'google_token';
  static const List<String> _scopes = [
    'email',
    'profile',
    'https://www.googleapis.com/auth/drive.file',
  ];

  // dart-define으로 전달된 환경변수 사용
  static const String _webClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const String _iosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const String _iosClientIdReversed =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID_REVERSED');
  static const String _androidClientId =
      String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID');

  GoogleAuthService(this._prefs, this._localAuthService) {
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() {
    try {
      DebugLogger.config('GoogleAuthService 초기화 시작');

      // 플랫폼 정보 출력
      DebugLogger.logPlatformInfo();

      // 환경 변수 검증
      _validateEnvironmentVariables();

      final clientId = _getClientId();
      DebugLogger.config('사용할 클라이언트 ID: $clientId');

      _googleSignIn = GoogleSignIn(
        scopes: _scopes,
        clientId: clientId.isNotEmpty ? clientId : null,
        serverClientId: kIsWeb ? null : _webClientId,
        signInOption: SignInOption.standard,
      );

      DebugLogger.success('GoogleSignIn 객체 생성 완료');

      // iOS 설정 체크리스트 출력
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        DebugLogger.logIOSSetupChecklist();
      }
    } catch (e, stackTrace) {
      DebugLogger.error('GoogleAuthService 초기화 실패', e, stackTrace);
      rethrow;
    }
  }

  void _validateEnvironmentVariables() {
    DebugLogger.config('환경 변수 검증 시작');

    // 원시 값들 먼저 출력
    DebugLogger.config('원시 환경변수 값들:');
    DebugLogger.config('  - _webClientId: "$_webClientId"');
    DebugLogger.config('  - _iosClientId: "$_iosClientId"');
    DebugLogger.config('  - _iosClientIdReversed: "$_iosClientIdReversed"');
    DebugLogger.config('  - _androidClientId: "$_androidClientId"');

    final envVars = {
      'GOOGLE_WEB_CLIENT_ID': _webClientId,
      'GOOGLE_IOS_CLIENT_ID': _iosClientId,
      'GOOGLE_IOS_CLIENT_ID_REVERSED': _iosClientIdReversed,
      'GOOGLE_ANDROID_CLIENT_ID': _androidClientId,
    };

    DebugLogger.logEnvironmentVariables(envVars);

    // iOS 특별 검증
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (_iosClientId.isEmpty) {
        DebugLogger.error('iOS 클라이언트 ID가 설정되지 않았습니다!');
        throw Exception(
            'iOS 클라이언트 ID가 설정되지 않았습니다. GOOGLE_IOS_CLIENT_ID 환경 변수를 확인하세요.');
      }

      if (_iosClientIdReversed.isEmpty) {
        DebugLogger.warning(
            'iOS 클라이언트 ID Reversed가 설정되지 않았습니다. URL 스킴 처리에 문제가 있을 수 있습니다.');
      }

      // iOS 클라이언트 ID 형식 검증
      if (!_iosClientId.contains('.apps.googleusercontent.com')) {
        DebugLogger.warning('iOS 클라이언트 ID 형식이 올바르지 않을 수 있습니다: $_iosClientId');
      }
    }
  }

  // 플랫폼별 클라이언트 ID 결정 함수
  static String _getClientId() {
    if (kIsWeb) {
      DebugLogger.network('웹 플랫폼 - 웹 클라이언트 ID 사용');
      return _webClientId;
    } else {
      // 모바일 플랫폼에서 defaultTargetPlatform 사용
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          DebugLogger.ios('iOS 플랫폼 - iOS 클라이언트 ID 사용');
          return _iosClientId;
        case TargetPlatform.android:
          DebugLogger.android('Android 플랫폼 - Android 클라이언트 ID 사용');
          return _androidClientId;
        default:
          DebugLogger.warning('알 수 없는 플랫폼 - 웹 클라이언트 ID 사용');
          return _webClientId;
      }
    }
  }

  @override
  Future<bool> isMasterPasswordSet() async {
    return _localAuthService.isMasterPasswordSet();
  }

  @override
  Future<void> setMasterPassword(String password) async {
    await _localAuthService.setMasterPassword(password);
  }

  @override
  Future<void> changeMasterPassword(
      String currentPassword, String newPassword) async {
    await _localAuthService.changeMasterPassword(currentPassword, newPassword);
  }

  @override
  Future<bool> verifyMasterPassword(String password) async {
    return _localAuthService.verifyMasterPassword(password);
  }

  @override
  Future<int> incrementLoginAttempts() async {
    return _localAuthService.incrementLoginAttempts();
  }

  @override
  Future<void> resetLoginAttempts() async {
    await _localAuthService.resetLoginAttempts();
  }

  @override
  Future<int> getLoginAttempts() async {
    return _localAuthService.getLoginAttempts();
  }

  @override
  Future<void> setLoginLockoutUntil(DateTime time) async {
    await _localAuthService.setLoginLockoutUntil(time);
  }

  @override
  Future<DateTime?> getLoginLockoutUntil() async {
    return _localAuthService.getLoginLockoutUntil();
  }

  @override
  Future<bool> isLoginLocked() async {
    return _localAuthService.isLoginLocked();
  }

  @override
  Future<bool> signInWithGoogle() async {
    try {
      DebugLogger.progress('구글 로그인 시도 시작');
      DebugLogger.config('현재 플랫폼: ${defaultTargetPlatform.name}');
      DebugLogger.config('사용 중인 클라이언트 ID: ${_getClientId()}');
      DebugLogger.config('스코프: $_scopes');

      // 현재 로그인 상태 확인
      final isCurrentlySignedIn = await _googleSignIn.isSignedIn();
      DebugLogger.info('현재 로그인 상태: $isCurrentlySignedIn');

      if (isCurrentlySignedIn) {
        DebugLogger.info('이미 로그인된 상태입니다. 로그아웃 후 재로그인을 시도합니다.');
        await _googleSignIn.signOut();
      }

      DebugLogger.progress('구글 로그인 다이얼로그 표시 중...');
      final account = await _googleSignIn.signIn();

      if (account == null) {
        DebugLogger.warning('구글 로그인 취소됨 (사용자가 취소하거나 에러 발생)');
        return false;
      }

      DebugLogger.success('구글 계정 선택됨: ${account.email}');
      DebugLogger.info('계정 정보:');
      DebugLogger.info('  - ID: ${account.id}');
      DebugLogger.info('  - 이름: ${account.displayName}');
      DebugLogger.info('  - 사진 URL: ${account.photoUrl}');

      DebugLogger.progress('인증 토큰 가져오는 중...');
      final auth = await account.authentication;

      if (auth.accessToken == null) {
        DebugLogger.error('액세스 토큰을 가져올 수 없습니다');
        return false;
      }

      DebugLogger.success('액세스 토큰 획득 성공');
      DebugLogger.info('토큰 정보:');
      DebugLogger.info('  - 액세스 토큰 길이: ${auth.accessToken?.length ?? 0}');
      DebugLogger.info('  - ID 토큰 존재 여부: ${auth.idToken != null}');

      await _prefs.setString(_googleTokenKey, auth.accessToken ?? '');
      DebugLogger.success('토큰 저장 완료');

      // 사용자 정보 업데이트
      DebugLogger.progress('사용자 정보 업데이트 중...');
      final user = await getUser();
      await updateUser(
        user.copyWith(
          isGoogleAccountLinked: true,
          lastLoginAt: DateTime.now(),
        ),
      );

      DebugLogger.success('구글 로그인 성공!');
      return true;
    } on PlatformException catch (e) {
      DebugLogger.error('플랫폼 예외 발생: ${e.code} - ${e.message}');
      DebugLogger.info('상세 정보: ${e.details}');

      // iOS 특정 에러 처리
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        _handleiOSSpecificErrors(e);
      }

      return false;
    } catch (e, stackTrace) {
      DebugLogger.error('구글 로그인 실패', e, stackTrace);
      return false;
    }
  }

  void _handleiOSSpecificErrors(PlatformException e) {
    DebugLogger.ios('iOS 특정 에러 분석:');

    switch (e.code) {
      case 'sign_in_failed':
        DebugLogger.error('로그인 실패: 네트워크 연결이나 설정을 확인하세요');
        DebugLogger.ios('Info.plist에 URL 스킴이 올바르게 설정되어 있는지 확인하세요');
        DebugLogger.ios('예상 URL 스킴: $_iosClientIdReversed');
        break;
      case 'sign_in_canceled':
        DebugLogger.warning('사용자가 로그인을 취소했습니다');
        break;
      case 'sign_in_required':
        DebugLogger.warning('로그인이 필요합니다');
        break;
      case 'network_error':
        DebugLogger.network('네트워크 에러: 인터넷 연결을 확인하세요');
        break;
      default:
        DebugLogger.error('알 수 없는 에러 코드: ${e.code}');
        DebugLogger.error('메시지: ${e.message}');
        DebugLogger.error('상세: ${e.details}');
    }

    DebugLogger.ios('iOS 설정 체크리스트:');
    DebugLogger.ios('  1. Info.plist에 CFBundleURLSchemes 설정 확인');
    DebugLogger.ios('  2. GoogleService-Info.plist 파일 존재 확인');
    DebugLogger.ios('  3. 번들 ID와 구글 콘솔 설정 일치 확인');
    DebugLogger.ios('  4. iOS 클라이언트 ID 형식 확인: $_iosClientId');
  }

  @override
  Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
      await _prefs.remove(_googleTokenKey);

      // 사용자 정보 업데이트
      final user = await getUser();
      await updateUser(
        user.copyWith(
          isGoogleAccountLinked: false,
        ),
      );
    } catch (e) {
      throw Exception('구글 로그아웃 실패: $e');
    }
  }

  @override
  Future<AuthUser> getUser() async {
    return _localAuthService.getUser();
  }

  @override
  Future<void> updateUser(AuthUser user) async {
    await _localAuthService.updateUser(user);
  }

  /// Google Drive 클라이언트 가져오기
  Future<drive.DriveApi?> getDriveApi() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        return null;
      }

      final auth = await account.authentication;
      final client = GoogleHttpClient(auth);
      return drive.DriveApi(client);
    } catch (e) {
      return null;
    }
  }

  /// 구글 계정 연동 여부 확인
  Future<bool> isGoogleSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  @override
  Future<bool> isAuthenticated() async {
    // 구글 계정 로그인 상태 확인
    return await isGoogleSignedIn();
  }

  @override
  Future<bool> signIn() async {
    // 구글 계정으로 로그인 시도
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        // 자동 로그인 실패 시 수동 로그인 시도
        return await signInWithGoogle();
      }

      final auth = await account.authentication;
      await _prefs.setString(_googleTokenKey, auth.accessToken ?? '');

      // 사용자 정보 업데이트
      final user = await getUser();
      await updateUser(
        user.copyWith(
          isGoogleAccountLinked: true,
          lastLoginAt: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<http.Client?> getAuthClient() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        return null;
      }

      final auth = await account.authentication;
      return GoogleHttpClient(auth);
    } catch (e) {
      return null;
    }
  }
}

class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleHttpClient(GoogleSignInAuthentication auth)
      : _headers = {
          'Authorization': 'Bearer ${auth.accessToken}',
          'Content-Type': 'application/json',
        };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
