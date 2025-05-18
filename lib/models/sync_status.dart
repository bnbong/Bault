/// 동기화 결과 상태
enum SyncStatus {
  /// 동기화 성공
  success,

  /// 동기화 실패
  failed,

  /// 동기화 진행 중
  inProgress,

  /// 동기화 충돌 발생
  conflict,

  /// 동기화 대기 중
  waiting,

  /// 동기화 시작 안됨
  notStarted,
}

/// 동기화 결과 정보
class SyncResult {
  /// 동기화 상태
  final SyncStatus status;

  /// 동기화 메시지
  final String message;

  /// 충돌 항목 목록
  final List<SyncConflict>? conflicts;

  /// 동기화 시간
  final DateTime timestamp;

  SyncResult({
    required this.status,
    required this.message,
    this.conflicts,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 성공 결과 생성
  factory SyncResult.success([String message = '동기화가 완료되었습니다.']) {
    return SyncResult(
      status: SyncStatus.success,
      message: message,
    );
  }

  /// 실패 결과 생성
  factory SyncResult.failed(String message) {
    return SyncResult(
      status: SyncStatus.failed,
      message: message,
    );
  }

  /// 충돌 결과 생성
  factory SyncResult.conflict(List<SyncConflict> conflicts) {
    return SyncResult(
      status: SyncStatus.conflict,
      message: '${conflicts.length}개의 항목에서 충돌이 발생했습니다.',
      conflicts: conflicts,
    );
  }

  /// 진행 중 결과 생성
  factory SyncResult.inProgress() {
    return SyncResult(
      status: SyncStatus.inProgress,
      message: '동기화가 진행 중입니다.',
    );
  }
}

/// 동기화 충돌 정보
class SyncConflict {
  /// 충돌 항목 ID
  final String itemId;

  /// 로컬 버전
  final dynamic localVersion;

  /// 원격 버전
  final dynamic remoteVersion;

  /// 마지막 수정 시간 (로컬)
  final DateTime localModifiedAt;

  /// 마지막 수정 시간 (원격)
  final DateTime remoteModifiedAt;

  SyncConflict({
    required this.itemId,
    required this.localVersion,
    required this.remoteVersion,
    required this.localModifiedAt,
    required this.remoteModifiedAt,
  });
}

/// 충돌 해결 방법
enum ConflictResolutionType {
  /// 로컬 버전 유지
  keepLocal,

  /// 원격 버전 사용
  useRemote,

  /// 수동 병합
  manual,
}

/// 충돌 해결 정보
class ConflictResolution {
  /// 충돌 항목 ID
  final String itemId;

  /// 해결 방법
  final ConflictResolutionType resolutionType;

  /// 수동 병합인 경우 병합된 데이터
  final dynamic mergedData;

  ConflictResolution({
    required this.itemId,
    required this.resolutionType,
    this.mergedData,
  });
}

/// 백업 정보
class BackupInfo {
  /// 백업 ID
  final String id;

  /// 백업 생성 시간
  final DateTime createdAt;

  /// 백업 설명
  final String description;

  /// 백업 크기 (바이트)
  final int size;

  BackupInfo({
    required this.id,
    required this.createdAt,
    required this.description,
    required this.size,
  });
}
