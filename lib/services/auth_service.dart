import '../models/auth_user.dart';
import 'package:http/http.dart' as http;

abstract class AuthService {
  /// 마스터 비밀번호 설정 여부 확인
  Future<bool> isMasterPasswordSet();

  /// 마스터 비밀번호 설정
  Future<void> setMasterPassword(String password);

  /// 마스터 비밀번호 변경
  Future<void> changeMasterPassword(String currentPassword, String newPassword);

  /// 마스터 비밀번호 인증
  Future<bool> verifyMasterPassword(String password);

  /// 로그인 시도 횟수 증가
  Future<int> incrementLoginAttempts();

  /// 로그인 시도 횟수 초기화
  Future<void> resetLoginAttempts();

  /// 로그인 시도 횟수 가져오기
  Future<int> getLoginAttempts();

  /// 로그인 제한 시간 설정
  Future<void> setLoginLockoutUntil(DateTime time);

  /// 로그인 제한 시간 가져오기
  Future<DateTime?> getLoginLockoutUntil();

  /// 로그인 제한 여부 확인
  Future<bool> isLoginLocked();

  /// 구글 계정 연동
  Future<bool> signInWithGoogle();

  /// 구글 계정 연동 해제
  Future<void> signOutFromGoogle();

  /// 사용자 정보 가져오기
  Future<AuthUser> getUser();

  /// 사용자 정보 업데이트
  Future<void> updateUser(AuthUser user);

  /// 구글 계정 로그인 여부 확인
  Future<bool> isAuthenticated();

  /// 구글 계정 로그인
  Future<bool> signIn();

  /// 구글 드라이브 API 사용을 위한 인증 클라이언트 가져오기
  Future<http.Client?> getAuthClient();
}
