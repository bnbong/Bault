import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/password_entry.dart';
import '../password_repository.dart';

class LocalPasswordRepository implements PasswordRepository {
  static const String _storageKey = 'passwords';
  final SharedPreferences _prefs;

  LocalPasswordRepository(this._prefs);

  @override
  Future<List<PasswordEntry>> getAll() async {
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => PasswordEntry.fromJson(json)).toList();
  }

  @override
  Future<PasswordEntry?> getById(String id) async {
    final passwords = await getAll();
    return passwords.firstWhere(
      (entry) => entry.id == id,
      orElse: () => throw Exception('비밀번호를 찾을 수 없습니다.'),
    );
  }

  @override
  Future<List<PasswordEntry>> search(String query) async {
    final passwords = await getAll();
    if (query.isEmpty) return passwords;

    return passwords.where((entry) {
      final serviceName = entry.serviceName.toLowerCase();
      final searchQuery = query.toLowerCase();
      return serviceName.contains(searchQuery);
    }).toList();
  }

  @override
  Future<void> add(PasswordEntry entry) async {
    final passwords = await getAll();
    passwords.add(entry);
    await _savePasswords(passwords);
  }

  @override
  Future<void> update(PasswordEntry entry) async {
    final passwords = await getAll();
    final index = passwords.indexWhere((e) => e.id == entry.id);
    if (index == -1) throw Exception('비밀번호를 찾을 수 없습니다.');

    passwords[index] = entry;
    await _savePasswords(passwords);
  }

  @override
  Future<void> delete(String id) async {
    final passwords = await getAll();
    passwords.removeWhere((entry) => entry.id == id);
    await _savePasswords(passwords);
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_storageKey);
  }

  Future<void> _savePasswords(List<PasswordEntry> passwords) async {
    final jsonList = passwords.map((entry) => entry.toJson()).toList();
    await _prefs.setString(_storageKey, jsonEncode(jsonList));
  }
}
