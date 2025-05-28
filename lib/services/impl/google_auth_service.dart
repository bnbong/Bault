import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

import '../../models/auth_user.dart';
import '../auth_service.dart';
import 'local_auth_service.dart';

class GoogleAuthService implements AuthService {
  final SharedPreferences _prefs;
  final LocalAuthService _localAuthService;
  late final GoogleSignIn _googleSignIn;

  static const String _googleTokenKey = 'google_access_token';
  static const List<String> _scopes = [
    'email',
    'profile',
    'https://www.googleapis.com/auth/drive.file',
  ];

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
      _validateEnvironmentVariables();

      final clientId = _getClientId();

      _googleSignIn = GoogleSignIn(
        scopes: _scopes,
        clientId: clientId.isNotEmpty ? clientId : null,
        serverClientId: kIsWeb ? null : _webClientId,
        signInOption: SignInOption.standard,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('GoogleAuthService 초기화 실패: $e');
      }
      rethrow;
    }
  }

  void _validateEnvironmentVariables() {
    if (kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        if (_iosClientId.isEmpty) {
          throw Exception('iOS 클라이언트 ID가 설정되지 않았습니다.');
        }

        if (!_iosClientId.contains('.apps.googleusercontent.com')) {
          debugPrint('iOS 클라이언트 ID 형식이 올바르지 않을 수 있습니다: $_iosClientId');
        }
      }
    }
  }

  static String _getClientId() {
    if (kIsWeb) {
      return _webClientId;
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          return _iosClientId;
        case TargetPlatform.android:
          return _androidClientId;
        default:
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
      final isCurrentlySignedIn = await _googleSignIn.isSignedIn();

      if (isCurrentlySignedIn) {
        await _googleSignIn.signOut();
      }

      final account = await _googleSignIn.signIn();

      if (account == null) {
        return false;
      }

      final auth = await account.authentication;

      if (auth.accessToken == null) {
        return false;
      }

      await _prefs.setString(_googleTokenKey, auth.accessToken ?? '');

      final user = await getUser();
      await updateUser(
        user.copyWith(
          isGoogleAccountLinked: true,
          lastLoginAt: DateTime.now(),
        ),
      );

      return true;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('구글 로그인 플랫폼 예외: ${e.code} - ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('구글 로그인 실패: $e');
      }
      return false;
    }
  }

  @override
  Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
      await _prefs.remove(_googleTokenKey);

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

  Future<bool> isGoogleSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  @override
  Future<bool> isAuthenticated() async {
    return await isGoogleSignedIn();
  }

  @override
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        return await signInWithGoogle();
      }

      final auth = await account.authentication;
      await _prefs.setString(_googleTokenKey, auth.accessToken ?? '');

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
