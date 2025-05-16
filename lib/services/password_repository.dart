import '../models/password_entry.dart';

abstract class PasswordRepository {
  Future<List<PasswordEntry>> getAll();
  Future<PasswordEntry?> getById(String id);
  Future<List<PasswordEntry>> search(String query);
  Future<void> add(PasswordEntry entry);
  Future<void> update(PasswordEntry entry);
  Future<void> delete(String id);
  Future<void> clear();
}
