import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:bault/models/sync_status.dart';
import 'package:bault/services/sync_service.dart';
import 'package:bault/services/sync_service_factory.dart';
import 'package:bault/services/service_locator.dart';

/// 동기화 기능을 관리하는 Provider
class SyncProvider extends ChangeNotifier {
  final ServiceLocator _serviceLocator;

  bool _isSyncEnabled = false;
  bool _isAutoSyncEnabled = false;
  SyncType _currentSyncType = SyncType.local;
  SyncStatus _lastSyncStatus = SyncStatus.notStarted;
  DateTime? _lastSyncTime;
  List<BackupInfo> _backupList = [];
  bool _isLoadingBackups = false;

  /// 생성자
  SyncProvider({ServiceLocator? serviceLocator})
      : _serviceLocator = serviceLocator ?? ServiceLocator() {
    _initialize();
  }

  /// 초기화
  Future<void> _initialize() async {
    _currentSyncType = await SyncServiceFactory.getCurrentSyncType();
    _isSyncEnabled = await _serviceLocator.syncService.isSyncEnabled();
    _lastSyncStatus = await _serviceLocator.syncService.getLastSyncStatus();

    // 백업 목록 로드
    if (_isSyncEnabled) {
      await _loadBackupList();
    }

    notifyListeners();
  }

  /// 동기화 활성화 여부
  bool get isSyncEnabled => _isSyncEnabled;

  /// 자동 동기화 활성화 여부
  bool get isAutoSyncEnabled => _isAutoSyncEnabled;

  /// 현재 동기화 유형
  SyncType get currentSyncType => _currentSyncType;

  /// 마지막 동기화 상태
  SyncStatus get lastSyncStatus => _lastSyncStatus;

  /// 마지막 동기화 시간 (포맷팅된 문자열)
  String get lastSyncTimeFormatted {
    if (_lastSyncTime == null) {
      return '없음';
    }

    // 날짜 포맷팅
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    return formatter.format(_lastSyncTime!);
  }

  /// 백업 목록
  List<BackupInfo> get backupList => _backupList;

  /// 백업 목록 로딩 중 여부
  bool get isLoadingBackups => _isLoadingBackups;

  /// 동기화 유형 변경
  Future<void> changeSyncType(SyncType newType) async {
    _currentSyncType = newType;
    await _serviceLocator.changeSyncType(newType);

    // 상태 초기화
    _isSyncEnabled = await _serviceLocator.syncService.isSyncEnabled();
    _lastSyncStatus = await _serviceLocator.syncService.getLastSyncStatus();

    notifyListeners();
  }

  /// 동기화 활성화
  Future<bool> enableSync() async {
    final success = await _serviceLocator.syncService.enableSync();
    if (success) {
      _isSyncEnabled = true;
      notifyListeners();
    }
    return success;
  }

  /// 동기화 비활성화
  Future<void> disableSync() async {
    await _serviceLocator.syncService.disableSync();
    _isSyncEnabled = false;
    notifyListeners();
  }

  /// 수동 동기화 수행
  Future<SyncResult> syncNow() async {
    final result = await _serviceLocator.syncService.syncNow();
    _lastSyncStatus = result.status;
    _lastSyncTime = result.timestamp;
    notifyListeners();
    return result;
  }

  /// 자동 동기화 설정
  Future<void> setAutoSync(bool enabled, {Duration? interval}) async {
    await _serviceLocator.syncService.setAutoSync(enabled, interval: interval);
    _isAutoSyncEnabled = enabled;
    notifyListeners();
  }

  /// 백업 생성
  Future<String?> createBackup() async {
    final backupId = await _serviceLocator.syncService.createBackup();
    if (backupId != null) {
      await _loadBackupList(); // 백업 목록 갱신
    }
    return backupId;
  }

  /// 백업 목록 로드
  Future<void> _loadBackupList() async {
    _isLoadingBackups = true;
    notifyListeners();

    _backupList = await _serviceLocator.syncService.getBackupList();

    _isLoadingBackups = false;
    notifyListeners();
  }

  /// 백업 목록 새로고침
  Future<void> refreshBackupList() async {
    await _loadBackupList();
  }

  /// 백업 복원
  Future<SyncResult> restoreBackup(String backupId) async {
    final result = await _serviceLocator.syncService.restoreBackup(backupId);
    if (result.status == SyncStatus.success) {
      _lastSyncStatus = SyncStatus.success;
      _lastSyncTime = DateTime.now();
    }
    notifyListeners();
    return result;
  }
}
