import '../models/password_entry.dart';
import 'encryption_service.dart';
import 'password_repository.dart';

abstract class PasswordService {
  /// 모든 비밀번호 가져오기
  Future<List<PasswordEntry>> getAll();

  /// ID로 비밀번호 가져오기
  Future<PasswordEntry?> getById(String id);

  /// 검색어로 비밀번호 검색
  Future<List<PasswordEntry>> search(String query);

  /// 비밀번호 추가
  Future<void> add(PasswordEntry entry);

  /// 비밀번호 수정
  Future<void> update(PasswordEntry entry);

  /// 비밀번호 삭제
  Future<void> delete(String id);

  /// 모든 비밀번호 삭제
  Future<void> clear();

  /// 모든 비밀번호를 Map 형태로 가져오기 (동기화용)
  Future<Map<String, dynamic>> getAllPasswords();

  /// ID로 비밀번호 업데이트 (동기화용)
  Future<void> updatePassword(String id, dynamic data);

  /// 백업에서 비밀번호 복원 (동기화용)
  Future<void> restorePasswordsFromBackup(Map<String, dynamic> backup);
}
