import '../models/password_entry.dart';
import 'encryption_service.dart';
import 'password_repository.dart';

class PasswordService {
  final PasswordRepository _repository;
  final EncryptionService _encryptionService;

  PasswordService({
    required PasswordRepository repository,
    required EncryptionService encryptionService,
  })  : _repository = repository,
        _encryptionService = encryptionService;

  Future<List<PasswordEntry>> getAll() async {
    final entries = await _repository.getAll();
    return entries.map((entry) => _decryptEntry(entry)).toList();
  }

  Future<PasswordEntry?> getById(String id) async {
    final entry = await _repository.getById(id);
    if (entry == null) return null;
    return _decryptEntry(entry);
  }

  Future<List<PasswordEntry>> search(String query) async {
    final entries = await _repository.search(query);
    return entries.map((entry) => _decryptEntry(entry)).toList();
  }

  Future<void> add(PasswordEntry entry) async {
    final encryptedEntry = _encryptEntry(entry);
    await _repository.add(encryptedEntry);
  }

  Future<void> update(PasswordEntry entry) async {
    final encryptedEntry = _encryptEntry(entry);
    await _repository.update(encryptedEntry);
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
  }

  Future<void> clear() async {
    await _repository.clear();
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
