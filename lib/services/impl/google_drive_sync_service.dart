import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:bault/models/sync_status.dart';
import 'package:bault/services/sync_service.dart';
import 'package:bault/services/auth_service.dart';
import 'package:bault/services/password_service.dart';
import 'package:bault/services/encryption_service.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:shared_preferences/shared_preferences.dart';

/// 구글 드라이브를 이용한 동기화 서비스 구현
class GoogleDriveSyncService implements SyncService {
  static const String _appFolderName = 'Bault';
  static const String _backupPrefix = 'bault_backup_';
  static const String _dataFileName = 'bault_data.json';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _syncEnabledKey = 'google_drive_sync_enabled';
  static const String _autoSyncEnabledKey = 'auto_sync_enabled';
  static const String _autoSyncIntervalKey = 'auto_sync_interval_minutes';

  final AuthService _authService;
  final PasswordService _passwordService;
  final EncryptionService _encryptionService;

  // 동기화 상태를 저장할 변수
  SyncStatus _currentSyncStatus = SyncStatus.notStarted;
  DateTime? _lastSyncTime;

  // 타이머 관련 변수
  Timer? _autoSyncTimer;

  GoogleDriveSyncService({
    required AuthService authService,
    required PasswordService passwordService,
    required EncryptionService encryptionService,
  })  : _authService = authService,
        _passwordService = passwordService,
        _encryptionService = encryptionService {
    _initSync();
  }

  /// 초기화 함수
  Future<void> _initSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncTimeString = prefs.getString(_lastSyncTimeKey);
    if (lastSyncTimeString != null) {
      _lastSyncTime = DateTime.parse(lastSyncTimeString);
    }

    // 자동 동기화 설정이 있으면 타이머 시작
    final autoSyncEnabled = prefs.getBool(_autoSyncEnabledKey) ?? false;
    if (autoSyncEnabled) {
      final interval = prefs.getInt(_autoSyncIntervalKey) ?? 60; // 기본값 60분
      _startAutoSync(Duration(minutes: interval));
    }
  }

  @override
  Future<bool> isSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncEnabledKey) ?? false;
  }

  @override
  Future<bool> enableSync() async {
    // 구글 계정 로그인 확인
    final isLoggedIn = await _authService.isAuthenticated();
    if (!isLoggedIn) {
      try {
        final success = await _authService.signIn();
        if (!success) {
          return false;
        }
      } catch (e) {
        debugPrint('구글 로그인 실패: $e');
        return false;
      }
    }

    try {
      // 앱 폴더 생성 (없는 경우)
      await _getOrCreateAppFolder();

      // 설정 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_syncEnabledKey, true);

      // 초기 동기화 수행
      await syncNow();

      return true;
    } catch (e) {
      debugPrint('구글 드라이브 동기화 활성화 실패: $e');
      return false;
    }
  }

  @override
  Future<bool> disableSync() async {
    // 자동 동기화 중지
    _stopAutoSync();

    // 설정 저장
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
      // 구글 드라이브 클라이언트 초기화
      final client = await _getDriveClient();
      if (client == null) {
        _currentSyncStatus = SyncStatus.failed;
        return SyncResult.failed('구글 드라이브 클라이언트 초기화 실패');
      }

      // 앱 폴더 가져오기 or 생성
      final appFolder = await _getOrCreateAppFolder();

      // 원격 데이터 파일 검색
      final fileList = await client.files.list(
        q: "'${appFolder.id}' in parents and name = '$_dataFileName'",
        $fields: 'files(id, name, modifiedTime)',
      );

      String? remoteFileId;
      DateTime? remoteModifiedTime;
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final remoteFile = fileList.files!.first;
        remoteFileId = remoteFile.id;
        remoteModifiedTime = remoteFile.modifiedTime;
      }

      // 로컬 데이터 가져오기
      final localData = await _passwordService.getAllPasswords();

      // 원격 파일이 있으면 다운로드
      if (remoteFileId != null) {
        final remoteContent = await _downloadFile(client, remoteFileId);
        final remoteData = jsonDecode(remoteContent) as Map<String, dynamic>;

        // 충돌 검사
        if (_lastSyncTime != null && remoteModifiedTime != null) {
          if (remoteModifiedTime.isAfter(_lastSyncTime!)) {
            // 양쪽 모두 변경된 경우 충돌 처리
            final conflicts = _detectConflicts(localData, remoteData);
            if (conflicts.isNotEmpty) {
              _currentSyncStatus = SyncStatus.conflict;
              return SyncResult.conflict(conflicts);
            }
          }
        }

        // 로컬이 더 최신이거나 충돌이 없으면 업로드
        await _uploadData(client, remoteFileId, localData);
      } else {
        // 원격 파일이 없으면 새로 생성
        await _createDataFile(client, appFolder.id!, localData);
      }

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

    if (enabled) {
      final minutes = interval?.inMinutes ?? 60; // 기본값 60분
      await prefs.setInt(_autoSyncIntervalKey, minutes);
      _startAutoSync(interval ?? Duration(minutes: minutes));
    } else {
      _stopAutoSync();
    }

    return true;
  }

  void _startAutoSync(Duration interval) {
    _stopAutoSync(); // 기존 타이머 중지

    _autoSyncTimer = Timer.periodic(interval, (_) async {
      if (await isSyncEnabled() &&
          _currentSyncStatus != SyncStatus.inProgress) {
        await syncNow();
      }
    });
  }

  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
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
      final client = await _getDriveClient();
      if (client == null) {
        return null;
      }

      final appFolder = await _getOrCreateAppFolder();

      // 로컬 데이터 가져오기
      final localData = await _passwordService.getAllPasswords();

      // 백업 파일명 생성 (날짜 포함)
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFileName = '$_backupPrefix$timestamp.json';

      // 백업 파일 생성
      final backupFile = await _createFile(
        client,
        appFolder.id!,
        backupFileName,
        jsonEncode(localData),
      );

      return backupFile.id;
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
      final client = await _getDriveClient();
      if (client == null) {
        return [];
      }

      final appFolder = await _getOrCreateAppFolder();

      final backupFiles = await client.files.list(
        q: "'${appFolder.id}' in parents and name contains '$_backupPrefix'",
        $fields: 'files(id, name, createdTime, size)',
        orderBy: 'createdTime desc',
      );

      if (backupFiles.files == null || backupFiles.files!.isEmpty) {
        return [];
      }

      final backupList = backupFiles.files!.map((file) {
        // 파일명에서 타임스탬프 추출
        final fileName = file.name ?? '';
        String description = '자동 백업';

        if (fileName.startsWith(_backupPrefix)) {
          final dateString = fileName.substring(
              _backupPrefix.length, fileName.lastIndexOf('.'));
          description = '백업 ($dateString)';
        }

        return BackupInfo(
          id: file.id!,
          createdAt: file.createdTime ?? DateTime.now(),
          description: description,
          size: int.tryParse(file.size ?? '0') ?? 0,
        );
      }).toList();

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
      final client = await _getDriveClient();
      if (client == null) {
        return SyncResult.failed('구글 드라이브 클라이언트 초기화 실패');
      }

      // 백업 파일 다운로드
      final backupContent = await _downloadFile(client, backupId);
      final backupData = jsonDecode(backupContent) as Map<String, dynamic>;

      // 현재 데이터를 먼저 백업
      await createBackup();

      // 백업 데이터 복원
      await _passwordService.restorePasswordsFromBackup(backupData);

      // 동기화 갱신
      await syncNow();

      return SyncResult.success('백업이 성공적으로 복원되었습니다.');
    } catch (e) {
      return SyncResult.failed('백업 복원 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<SyncResult> resolveConflict(
      List<ConflictResolution> resolutions) async {
    if (!await isSyncEnabled()) {
      return SyncResult.failed('동기화가 활성화되지 않았습니다.');
    }

    if (_currentSyncStatus != SyncStatus.conflict) {
      return SyncResult.failed('충돌 상태가 아닙니다.');
    }

    try {
      // 충돌 해결에 따라 데이터 업데이트
      for (final resolution in resolutions) {
        switch (resolution.resolutionType) {
          case ConflictResolutionType.keepLocal:
            // 로컬 데이터 유지 (아무 작업 안함)
            break;

          case ConflictResolutionType.useRemote:
            // 원격 데이터로 업데이트
            final client = await _getDriveClient();
            if (client == null) {
              continue;
            }

            // 데이터 파일 검색
            final appFolder = await _getOrCreateAppFolder();
            final fileList = await client.files.list(
              q: "'${appFolder.id}' in parents and name = '$_dataFileName'",
              $fields: 'files(id)',
            );

            if (fileList.files != null && fileList.files!.isNotEmpty) {
              final remoteFileId = fileList.files!.first.id!;
              final remoteContent = await _downloadFile(client, remoteFileId);
              final remoteData =
                  jsonDecode(remoteContent) as Map<String, dynamic>;

              // 원격 데이터에서 해당 항목 찾아 로컬에 적용
              if (remoteData.containsKey(resolution.itemId)) {
                await _passwordService.updatePassword(
                  resolution.itemId,
                  remoteData[resolution.itemId],
                );
              }
            }
            break;

          case ConflictResolutionType.manual:
            // 수동 병합된 데이터 적용
            if (resolution.mergedData != null) {
              await _passwordService.updatePassword(
                resolution.itemId,
                resolution.mergedData,
              );
            }
            break;
        }
      }

      // 충돌 해결 후 동기화
      _currentSyncStatus = SyncStatus.notStarted;
      return await syncNow();
    } catch (e) {
      return SyncResult.failed('충돌 해결 중 오류가 발생했습니다: $e');
    }
  }

  /// 구글 드라이브 클라이언트 가져오기
  Future<drive.DriveApi?> _getDriveClient() async {
    try {
      final authClient = await _authService.getAuthClient();
      if (authClient == null) {
        return null;
      }

      return drive.DriveApi(authClient);
    } catch (e) {
      debugPrint('구글 드라이브 클라이언트 가져오기 실패: $e');
      return null;
    }
  }

  /// 앱 폴더 가져오기 또는 생성
  Future<drive.File> _getOrCreateAppFolder() async {
    final client = await _getDriveClient();
    if (client == null) {
      throw Exception('구글 드라이브 클라이언트 초기화 실패');
    }

    // 기존 폴더 검색
    final folderList = await client.files.list(
      q: "name = '$_appFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      $fields: 'files(id, name)',
    );

    // 폴더가 있으면 반환
    if (folderList.files != null && folderList.files!.isNotEmpty) {
      return folderList.files!.first;
    }

    // 폴더가 없으면 생성
    final folder = drive.File()
      ..name = _appFolderName
      ..mimeType = 'application/vnd.google-apps.folder';

    return await client.files.create(folder);
  }

  /// 데이터 파일 생성
  Future<drive.File> _createDataFile(
      drive.DriveApi client, String folderId, Map<String, dynamic> data) async {
    return _createFile(client, folderId, _dataFileName, jsonEncode(data));
  }

  /// 파일 생성 (일반)
  Future<drive.File> _createFile(drive.DriveApi client, String folderId,
      String fileName, String content) async {
    final file = drive.File()
      ..name = fileName
      ..parents = [folderId];

    final mediaContent = drive.Media(
      Stream.value(utf8.encode(content)),
      content.length,
      contentType: 'application/json',
    );

    return await client.files.create(file, uploadMedia: mediaContent);
  }

  /// 데이터 업로드
  Future<drive.File> _uploadData(
      drive.DriveApi client, String fileId, Map<String, dynamic> data) async {
    final content = jsonEncode(data);

    final mediaContent = drive.Media(
      Stream.value(utf8.encode(content)),
      content.length,
      contentType: 'application/json',
    );

    return await client.files.update(
      drive.File(),
      fileId,
      uploadMedia: mediaContent,
    );
  }

  /// 파일 다운로드
  Future<String> _downloadFile(drive.DriveApi client, String fileId) async {
    final response = await client.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = await _readByteStream(response.stream);
    return utf8.decode(bytes);
  }

  /// 스트림에서 바이트 읽기
  Future<List<int>> _readByteStream(Stream<List<int>> stream) async {
    final List<int> result = [];
    await for (var bytes in stream) {
      result.addAll(bytes);
    }
    return result;
  }

  /// 충돌 감지 함수
  List<SyncConflict> _detectConflicts(
      Map<String, dynamic> localData, Map<String, dynamic> remoteData) {
    final conflicts = <SyncConflict>[];

    // 두 데이터 모두에 있는 항목에 대해 충돌 확인
    for (final key in localData.keys) {
      if (remoteData.containsKey(key)) {
        final localItem = localData[key];
        final remoteItem = remoteData[key];

        // 항목 비교 로직 (간소화된 예시)
        if (localItem != remoteItem) {
          conflicts.add(SyncConflict(
            itemId: key,
            localVersion: localItem,
            remoteVersion: remoteItem,
            localModifiedAt: DateTime.now(), // 실제로는 로컬 데이터의 수정 시간 필요
            remoteModifiedAt: DateTime.now(), // 실제로는 원격 데이터의 수정 시간 필요
          ));
        }
      }
    }

    return conflicts;
  }

  /// 서비스 종료 시 정리
  void dispose() {
    _stopAutoSync();
  }
}
