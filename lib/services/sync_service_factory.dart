import 'package:bault/services/impl/google_drive_sync_service.dart';
import 'package:bault/services/impl/local_sync_service.dart';
import 'package:bault/services/sync_service.dart';
import 'package:bault/services/auth_service.dart';
import 'package:bault/services/password_service.dart';
import 'package:bault/services/encryption_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 동기화 서비스 유형
enum SyncType {
  /// 로컬 저장소 동기화
  local,

  /// 구글 드라이브 동기화
  googleDrive,
}

/// 동기화 서비스 팩토리
class SyncServiceFactory {
  static const String _syncTypeKey = 'sync_type';

  /// 동기화 유형에 따라 적절한 동기화 서비스 생성
  static Future<SyncService> createSyncService({
    required AuthService authService,
    required PasswordService passwordService,
    required EncryptionService encryptionService,
    SyncType? syncType,
  }) async {
    // 지정된 유형이 없으면 저장된 유형 사용
    SyncType type = syncType ?? await _getSavedSyncType();

    // 웹 플랫폼에서는 로컬 동기화 서비스 사용 불가
    if (kIsWeb && type == SyncType.local) {
      debugPrint('웹 플랫폼에서는 로컬 동기화를 지원하지 않습니다. 구글 드라이브 동기화로 전환합니다.');
      type = SyncType.googleDrive;
      await _saveSyncType(SyncType.googleDrive);
    }

    // 유형에 따라 서비스 생성
    switch (type) {
      case SyncType.googleDrive:
        await _saveSyncType(SyncType.googleDrive);
        return GoogleDriveSyncService(
          authService: authService,
          passwordService: passwordService,
          encryptionService: encryptionService,
        );

      case SyncType.local:
        if (kIsWeb) {
          // 웹에서는 예외 발생
          throw UnsupportedError('웹 플랫폼에서는 로컬 동기화를 지원하지 않습니다.');
        }
        await _saveSyncType(SyncType.local);
        return LocalSyncService(
          passwordService: passwordService,
          encryptionService: encryptionService,
        );
    }
  }

  /// 저장된 동기화 유형 가져오기
  static Future<SyncType> _getSavedSyncType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final typeIndex = prefs.getInt(_syncTypeKey);

      if (typeIndex != null && typeIndex < SyncType.values.length) {
        final savedType = SyncType.values[typeIndex];

        // 웹에서 로컬 동기화가 저장되어 있으면 구글 드라이브로 변경
        if (kIsWeb && savedType == SyncType.local) {
          return SyncType.googleDrive;
        }

        return savedType;
      }

      // 기본값: 웹에서는 구글 드라이브, 모바일에서는 로컬
      return kIsWeb ? SyncType.googleDrive : SyncType.local;
    } catch (e) {
      return kIsWeb ? SyncType.googleDrive : SyncType.local;
    }
  }

  /// 동기화 유형 저장
  static Future<void> _saveSyncType(SyncType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_syncTypeKey, type.index);
    } catch (e) {
      debugPrint('동기화 유형 저장 실패: $e');
    }
  }

  /// 현재 선택된 동기화 유형 가져오기
  static Future<SyncType> getCurrentSyncType() async {
    return _getSavedSyncType();
  }

  /// 동기화 유형 변경
  static Future<SyncService> changeSyncType({
    required SyncType newType,
    required AuthService authService,
    required PasswordService passwordService,
    required EncryptionService encryptionService,
  }) async {
    return createSyncService(
      authService: authService,
      passwordService: passwordService,
      encryptionService: encryptionService,
      syncType: newType,
    );
  }
}
