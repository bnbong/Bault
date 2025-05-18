import 'package:bault/models/sync_status.dart';

/// 데이터 동기화 관련 인터페이스
abstract class SyncService {
  /// 동기화 활성화 여부 확인
  Future<bool> isSyncEnabled();

  /// 동기화 설정 활성화
  Future<bool> enableSync();

  /// 동기화 설정 비활성화
  Future<bool> disableSync();

  /// 수동 동기화 수행
  Future<SyncResult> syncNow();

  /// 자동 동기화 설정
  Future<bool> setAutoSync(bool enabled, {Duration? interval});

  /// 마지막 동기화 정보 조회
  Future<SyncStatus> getLastSyncStatus();

  /// 백업 생성
  Future<String?> createBackup();

  /// 백업 목록 조회
  Future<List<BackupInfo>> getBackupList();

  /// 백업 복원
  Future<SyncResult> restoreBackup(String backupId);

  /// 동기화 충돌 해결
  Future<SyncResult> resolveConflict(List<ConflictResolution> resolutions);
}
