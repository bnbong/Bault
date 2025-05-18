import 'dart:convert';
import 'package:bault/models/password_entry.dart';
import 'package:bault/services/encryption_service.dart';
import 'package:bault/services/password_repository.dart';
import 'package:bault/services/password_service.dart';

/// 비밀번호 관리 서비스 구현
class PasswordServiceImpl implements PasswordService {
  final PasswordRepository _repository;
  final EncryptionService _encryptionService;

  PasswordServiceImpl({
    required PasswordRepository repository,
    required EncryptionService encryptionService,
  })  : _repository = repository,
        _encryptionService = encryptionService;

  @override
  Future<List<PasswordEntry>> getAll() async {
    final entries = await _repository.getAll();
    return entries.map((entry) => _decryptEntry(entry)).toList();
  }

  @override
  Future<PasswordEntry?> getById(String id) async {
    final entry = await _repository.getById(id);
    if (entry == null) return null;
    return _decryptEntry(entry);
  }

  @override
  Future<List<PasswordEntry>> search(String query) async {
    final entries = await _repository.search(query);
    return entries.map((entry) => _decryptEntry(entry)).toList();
  }

  @override
  Future<void> add(PasswordEntry entry) async {
    final encryptedEntry = _encryptEntry(entry);
    await _repository.add(encryptedEntry);
  }

  @override
  Future<void> update(PasswordEntry entry) async {
    final encryptedEntry = _encryptEntry(entry);
    await _repository.update(encryptedEntry);
  }

  @override
  Future<void> delete(String id) async {
    await _repository.delete(id);
  }

  @override
  Future<void> clear() async {
    await _repository.clear();
  }

  @override
  Future<Map<String, dynamic>> getAllPasswords() async {
    final entries = await getAll();
    Map<String, dynamic> result = {};

    for (var entry in entries) {
      result[entry.id] = {
        'serviceName': entry.serviceName,
        'password': entry.password,
        'createdAt': entry.createdAt.toIso8601String(),
        'updatedAt': entry.updatedAt.toIso8601String(),
      };
    }

    return result;
  }

  @override
  Future<void> updatePassword(String id, dynamic data) async {
    if (data is! Map<String, dynamic>) {
      throw ArgumentError('데이터 형식이 잘못되었습니다.');
    }

    PasswordEntry entry = PasswordEntry(
      id: id,
      serviceName: data['serviceName'],
      password: data['password'],
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: DateTime.parse(data['updatedAt']),
    );

    await update(entry);
  }

  @override
  Future<void> restorePasswordsFromBackup(Map<String, dynamic> backup) async {
    // 기존 데이터 모두 삭제
    await clear();

    // 백업 데이터 복원
    for (var id in backup.keys) {
      final data = backup[id];
      if (data is Map<String, dynamic>) {
        PasswordEntry entry = PasswordEntry(
          id: id,
          serviceName: data['serviceName'],
          password: data['password'],
          createdAt: DateTime.parse(data['createdAt']),
          updatedAt: DateTime.parse(data['updatedAt']),
        );

        await add(entry);
      }
    }
  }

  PasswordEntry _encryptEntry(PasswordEntry entry) {
    return PasswordEntry(
      id: entry.id,
      serviceName: entry.serviceName,
      password: _encryptionService.encrypt(entry.password),
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  PasswordEntry _decryptEntry(PasswordEntry entry) {
    return PasswordEntry(
      id: entry.id,
      serviceName: entry.serviceName,
      password: _encryptionService.decrypt(entry.password),
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }
}
