import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../encryption_service.dart';

class AESEncryptionService implements EncryptionService {
  final enc.Encrypter _encrypter;
  final enc.IV _iv;

  AESEncryptionService(String masterPassword)
      : _encrypter = enc.Encrypter(enc.AES(_generateKey(masterPassword))),
        _iv = _generateIV(masterPassword) {
    debugPrint(
        '🔒 AESEncryptionService 생성됨 (비밀번호 길이: ${masterPassword.length})');
  }

  /// 마스터 비밀번호로부터 일관된 AES 키 생성
  static enc.Key _generateKey(String masterPassword) {
    try {
      debugPrint('🔒 AES 키 생성 시작');
      // 마스터 비밀번호와 고정 솔트를 사용하여 일관된 키 생성
      const salt = 'bault-encryption-salt-2024';
      final combined = masterPassword + salt;
      final bytes = utf8.encode(combined);
      final digest = sha256.convert(bytes);

      // SHA-256 해시의 첫 32바이트를 AES-256 키로 사용
      final key = enc.Key(Uint8List.fromList(digest.bytes));
      debugPrint('🔒 AES 키 생성 완료');
      return key;
    } catch (e, stackTrace) {
      debugPrint('🔒 AES 키 생성 실패: $e');
      debugPrint('🔒 스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 마스터 비밀번호로부터 일관된 IV 생성
  static enc.IV _generateIV(String masterPassword) {
    try {
      debugPrint('🔒 IV 생성 시작');
      // 마스터 비밀번호와 다른 솔트를 사용하여 일관된 IV 생성
      const salt = 'bault-iv-salt-2024';
      final combined = masterPassword + salt;
      final bytes = utf8.encode(combined);
      final digest = sha256.convert(bytes);

      // SHA-256 해시의 첫 16바이트를 IV로 사용
      final iv = enc.IV(Uint8List.fromList(digest.bytes.take(16).toList()));
      debugPrint('🔒 IV 생성 완료');
      return iv;
    } catch (e, stackTrace) {
      debugPrint('🔒 IV 생성 실패: $e');
      debugPrint('🔒 스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  @override
  String encrypt(String data) {
    try {
      debugPrint('🔒 데이터 암호화 시작 (데이터 길이: ${data.length})');
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      final result = encrypted.base64;
      debugPrint('🔒 데이터 암호화 완료 (암호화된 길이: ${result.length})');
      return result;
    } catch (e, stackTrace) {
      debugPrint('🔒 데이터 암호화 실패: $e');
      debugPrint('🔒 스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  @override
  String decrypt(String encryptedData) {
    try {
      final encrypted = enc.Encrypted.fromBase64(encryptedData);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      throw Exception('복호화 실패: $e');
    }
  }

  @override
  bool isEncrypted(String data) {
    try {
      enc.Encrypted.fromBase64(data);
      return true;
    } catch (e) {
      return false;
    }
  }
}
