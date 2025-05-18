import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../../models/auth_user.dart';
import '../auth_service.dart';
import 'local_auth_service.dart';

class GoogleAuthService implements AuthService {
  final GoogleSignIn _googleSignIn;
  final LocalAuthService _localAuthService;
  final SharedPreferences _prefs;

  static const String _googleTokenKey = 'google_auth_token';
  static const List<String> _scopes = [
    'email',
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  GoogleAuthService(this._prefs, this._localAuthService)
      : _googleSignIn = GoogleSignIn(scopes: _scopes);

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
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return false;
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
