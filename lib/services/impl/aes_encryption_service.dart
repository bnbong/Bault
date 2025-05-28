import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import '../encryption_service.dart';

class AESEncryptionService implements EncryptionService {
  final enc.Encrypter _encrypter;
  final enc.IV _iv;

  AESEncryptionService(String masterPassword)
      : _encrypter = enc.Encrypter(enc.AES(_generateKey(masterPassword))),
        _iv = _generateIV(masterPassword);

  static enc.Key _generateKey(String masterPassword) {
    try {
      const salt = 'bault-encryption-salt-2024';
      final bytes = utf8.encode(masterPassword + salt);
      final digest = sha256.convert(bytes);

      final key = enc.Key(Uint8List.fromList(digest.bytes));
      return key;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('키 생성 실패: $e');
      }
      rethrow;
    }
  }

  static enc.IV _generateIV(String masterPassword) {
    try {
      const salt = 'bault-iv-salt-2024';
      final bytes = utf8.encode(masterPassword + salt);
      final digest = sha256.convert(bytes);

      final iv = enc.IV(Uint8List.fromList(digest.bytes.take(16).toList()));
      return iv;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('IV 생성 실패: $e');
      }
      rethrow;
    }
  }

  @override
  String encrypt(String data) {
    try {
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('암호화 실패: $e');
      }
      throw Exception('데이터 암호화에 실패했습니다.');
    }
  }

  @override
  String decrypt(String encryptedData) {
    try {
      final encrypted = enc.Encrypted.fromBase64(encryptedData);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('복호화 실패: $e');
      }
      throw Exception('데이터 복호화에 실패했습니다.');
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
