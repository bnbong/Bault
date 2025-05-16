import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import '../encryption_service.dart';

class AESEncryptionService implements EncryptionService {
  final Encrypter _encrypter;
  final IV _iv;

  AESEncryptionService(String key)
      : _encrypter = Encrypter(AES(Key.fromUtf8(key))),
        _iv = IV.fromLength(16);

  @override
  String encrypt(String data) {
    final encrypted = _encrypter.encrypt(data, iv: _iv);
    return encrypted.base64;
  }

  @override
  String decrypt(String encryptedData) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedData);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      throw Exception('복호화 실패: $e');
    }
  }

  @override
  bool isEncrypted(String data) {
    try {
      Encrypted.fromBase64(data);
      return true;
    } catch (e) {
      return false;
    }
  }
}
