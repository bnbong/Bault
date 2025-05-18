import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bault/models/sync_status.dart';
import 'package:bault/services/sync_service.dart';
import 'package:bault/services/password_service.dart';
import 'package:bault/services/encryption_service.dart';
import 'package:uuid/uuid.dart';

/// 로컬 저장소를 이용한 동기화 서비스 구현
class LocalSyncService implements SyncService {
  static const String _syncEnabledKey = 'local_sync_enabled';
  static const String _autoSyncEnabledKey = 'local_auto_sync_enabled';
  static const String _lastSyncTimeKey = 'local_last_sync_time';
  static const String _backupFolderName = 'bault_backups';
  static const String _backupPrefix = 'bault_backup_';

  final PasswordService _passwordService;
  final EncryptionService _encryptionService;
  final Uuid _uuid = const Uuid();

  // 동기화 상태
  SyncStatus _currentSyncStatus = SyncStatus.notStarted;
  DateTime? _lastSyncTime;

  LocalSyncService({
    required PasswordService passwordService,
    required EncryptionService encryptionService,
  })  : _passwordService = passwordService,
        _encryptionService = encryptionService {
    _initSync();
  }

  Future<void> _initSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncTimeString = prefs.getString(_lastSyncTimeKey);
    if (lastSyncTimeString != null) {
      _lastSyncTime = DateTime.parse(lastSyncTimeString);
    }
  }

  @override
  Future<bool> isSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncEnabledKey) ?? false;
  }

  @override
  Future<bool> enableSync() async {
    try {
      // 백업 디렉토리 생성
      await _getOrCreateBackupDirectory();

      // 설정 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_syncEnabledKey, true);

      // 초기 백업 생성
      await createBackup();

      return true;
    } catch (e) {
      debugPrint('로컬 동기화 활성화 실패: $e');
      return false;
    }
  }

  @override
  Future<bool> disableSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, false);
    await prefs.setBool(_autoSyncEnabledKey, false);

    return true;
  }

  @override
  Future<SyncResult> syncNow() async {
    if (!await isSyncEnabled()) {
      return SyncResult.failed('동기화가 활성화되지 않았습니다.');
    }

    if (_currentSyncStatus == SyncStatus.inProgress) {
      return SyncResult.inProgress();
    }

    _currentSyncStatus = SyncStatus.inProgress;

    try {
      // 로컬 백업 생성
      await createBackup();

      // 동기화 완료 정보 저장
      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncTimeKey, _lastSyncTime!.toIso8601String());

      _currentSyncStatus = SyncStatus.success;
      return SyncResult.success();
    } catch (e) {
      _currentSyncStatus = SyncStatus.failed;
      return SyncResult.failed('동기화 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<bool> setAutoSync(bool enabled, {Duration? interval}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncEnabledKey, enabled);

    // 로컬 동기화에서는 주기적인 동기화가 필요 없음
    // 데이터 변경 시 직접 백업 생성

    return true;
  }

  @override
  Future<SyncStatus> getLastSyncStatus() async {
    return _currentSyncStatus;
  }

  @override
  Future<String?> createBackup() async {
    if (!await isSyncEnabled()) {
      return null;
    }

    try {
      final backupDir = await _getOrCreateBackupDirectory();

      // 로컬 데이터 가져오기
      final localData = await _passwordService.getAllPasswords();

      // 백업 ID 생성
      final backupId = _uuid.v4();

      // 파일명 생성 (타임스탬프 포함)
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFileName = '$_backupPrefix${timestamp}_$backupId.json';

      // 데이터 암호화
      final jsonData = jsonEncode(localData);
      final encryptedData = _encryptionService.encrypt(jsonData);

      // 백업 파일 생성
      final backupFile = File('${backupDir.path}/$backupFileName');
      await backupFile.writeAsString(encryptedData);

      return backupId;
    } catch (e) {
      debugPrint('백업 생성 실패: $e');
      return null;
    }
  }

  @override
  Future<List<BackupInfo>> getBackupList() async {
    if (!await isSyncEnabled()) {
      return [];
    }

    try {
      final backupDir = await _getOrCreateBackupDirectory();

      final Directory directory = Directory(backupDir.path);
      final List<FileSystemEntity> files = directory.listSync();

      final backupFiles = files
          .whereType<File>()
          .where((file) => file.path.contains(_backupPrefix))
          .toList();

      // 생성일 기준 내림차순 정렬
      backupFiles.sort((a, b) => FileStat.statSync(b.path)
          .changed
          .compareTo(FileStat.statSync(a.path).changed));

      final backupList = <BackupInfo>[];

      for (final file in backupFiles) {
        final fileName = file.path.split('/').last;
        String description = '자동 백업';
        String id = '';

        // 파일명에서 ID와 타임스탬프 추출
        if (fileName.startsWith(_backupPrefix)) {
          final fileNameWithoutPrefix =
              fileName.substring(_backupPrefix.length);
          final parts = fileNameWithoutPrefix.split('_');
          if (parts.length >= 2) {
            final dateString = parts[0];
            id = parts[1].split('.').first;
            description = '백업 ($dateString)';
          }
        }

        final stat = FileStat.statSync(file.path);

        backupList.add(BackupInfo(
          id: id,
          createdAt: stat.changed,
          description: description,
          size: stat.size,
        ));
      }

      return backupList;
    } catch (e) {
      debugPrint('백업 목록 조회 실패: $e');
      return [];
    }
  }

  @override
  Future<SyncResult> restoreBackup(String backupId) async {
    if (!await isSyncEnabled()) {
      return SyncResult.failed('동기화가 활성화되지 않았습니다.');
    }

    try {
      final backupDir = await _getOrCreateBackupDirectory();

      // 백업 ID로 파일 찾기
      final Directory directory = Directory(backupDir.path);
      final List<FileSystemEntity> files = directory.listSync();

      final backupFile = files.whereType<File>().firstWhere(
            (file) => file.path.contains(backupId),
            orElse: () => throw Exception('백업 파일을 찾을 수 없습니다.'),
          );

      // 백업 파일 읽기
      final encryptedData = await backupFile.readAsString();
      final jsonData = _encryptionService.decrypt(encryptedData);
      final backupData = jsonDecode(jsonData) as Map<String, dynamic>;

      // 복원 전 현재 데이터 백업
      await createBackup();

      // 백업 데이터 복원
      await _passwordService.restorePasswordsFromBackup(backupData);

      return SyncResult.success('백업이 성공적으로 복원되었습니다.');
    } catch (e) {
      return SyncResult.failed('백업 복원 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<SyncResult> resolveConflict(
      List<ConflictResolution> resolutions) async {
    // 로컬 동기화에서는 충돌이 발생하지 않음
    return SyncResult.success('로컬 동기화에서는 충돌 해결이 필요하지 않습니다.');
  }

  /// 백업 디렉토리 가져오기 또는 생성
  Future<Directory> _getOrCreateBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/$_backupFolderName');

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir;
  }
}
