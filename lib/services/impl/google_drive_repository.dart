import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import '../../models/password_entry.dart';
import '../password_repository.dart';

class GoogleDriveRepository implements PasswordRepository {
  static const String _fileName = 'bault_passwords.json';
  final drive.DriveApi _driveApi;

  GoogleDriveRepository(this._driveApi);

  @override
  Future<List<PasswordEntry>> getAll() async {
    try {
      final file = await _getOrCreateFile();
      final response = await _driveApi.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = await response.stream.toList();
      final content = utf8.decode(bytes.expand((x) => x).toList());
      final List<dynamic> jsonList = json.decode(content);
      return jsonList.map((json) => PasswordEntry.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
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
    final file = await _getOrCreateFile();
    await _driveApi.files.update(
      drive.File()..trashed = true,
      file.id!,
    );
  }

  Future<drive.File> _getOrCreateFile() async {
    try {
      final files = await _driveApi.files.list(
        q: "name = '$_fileName' and trashed = false",
        spaces: 'appDataFolder',
      );

      if (files.files!.isNotEmpty) {
        return files.files!.first;
      }

      final file = drive.File()
        ..name = _fileName
        ..parents = ['appDataFolder']
        ..mimeType = 'application/json';

      final createdFile = await _driveApi.files.create(
        file,
        uploadMedia: drive.Media(
          Stream.value(utf8.encode('[]')),
          0,
        ),
      );

      return createdFile;
    } catch (e) {
      throw Exception('Failed to get or create file: $e');
    }
  }

  Future<void> _savePasswords(List<PasswordEntry> passwords) async {
    final file = await _getOrCreateFile();
    final jsonList = passwords.map((entry) => entry.toJson()).toList();
    final content = jsonEncode(jsonList);

    await _saveFile(content, file.id!);
  }

  Future<void> _saveFile(String content, String fileId) async {
    try {
      await _driveApi.files.update(
        drive.File(),
        fileId,
        uploadMedia: drive.Media(
          Stream.value(utf8.encode(content)),
          content.length,
        ),
      );
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }
}
