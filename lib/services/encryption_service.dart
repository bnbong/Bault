abstract class EncryptionService {
  String encrypt(String data);
  String decrypt(String encryptedData);
  bool isEncrypted(String data);
}
