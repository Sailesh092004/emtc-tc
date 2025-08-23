import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling file encryption/decryption using AES-GCM
/// with platform-specific keystore integration
class CryptoService {
  static const String _keyPrefix = 'emtc_backup_key_';
  static const int _keyLength = 32; // 256-bit key
  static const int _ivLength = 12; // 96-bit IV for GCM
  
  /// Encrypts a file using AES-GCM
  /// Returns the path to the encrypted file and the encrypted key
  Future<EncryptedFile> encryptFile(String inputPath) async {
    try {
      // Generate a random AES key
      final key = _generateRandomKey();
      final iv = _generateRandomIV();
      
      // Read the input file
      final inputFile = File(inputPath);
      final bytes = await inputFile.readAsBytes();
      
      // Encrypt the data
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      final encrypted = encrypter.encrypt(base64Encode(bytes), iv: iv);
      
      // Create output path
      final outputPath = '${inputPath}_encrypted';
      final outputFile = File(outputPath);
      
      // Write encrypted data
      await outputFile.writeAsBytes(encrypted.bytes);
      
      // Encrypt the AES key with a master key from keystore
      final encryptedKey = await _encryptKeyWithMasterKey(key);
      
      return EncryptedFile(
        outputPath: outputPath,
        encryptedKey: encryptedKey,
        iv: iv.base64,
        originalSize: bytes.length,
      );
    } catch (e) {
      throw Exception('Failed to encrypt file: $e');
    }
  }
  
  /// Decrypts an encrypted file
  /// Returns the path to the decrypted file
  Future<String> decryptFile(String encryptedPath, String encryptedKey, String iv) async {
    try {
      // Decrypt the AES key
      final key = await _decryptKeyWithMasterKey(encryptedKey);
      
      // Read the encrypted file
      final encryptedFile = File(encryptedPath);
      final encryptedBytes = await encryptedFile.readAsBytes();
      
      // Decrypt the data
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      final decrypted = encrypter.decrypt64(base64Encode(encryptedBytes), iv: IV.fromBase64(iv));
      
      // Create output path
      final outputPath = encryptedPath.replaceAll('_encrypted', '_decrypted');
      final outputFile = File(outputPath);
      
      // Write decrypted data
      await outputFile.writeAsBytes(utf8.encode(decrypted));
      
      return outputPath;
    } catch (e) {
      throw Exception('Failed to decrypt file: $e');
    }
  }
  
  /// Generates a SHA256 hash of a file
  Future<String> generateFileHash(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final digest = crypto.sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      throw Exception('Failed to generate file hash: $e');
    }
  }
  
  /// Generates a SHA256 hash of data
  String generateDataHash(String data) {
    final bytes = utf8.encode(data);
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Generates a random AES key
  Key _generateRandomKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(_keyLength, (i) => random.nextInt(256));
    return Key(Uint8List.fromList(keyBytes));
  }
  
  /// Generates a random IV
  IV _generateRandomIV() {
    final random = Random.secure();
    final ivBytes = List<int>.generate(_ivLength, (i) => random.nextInt(256));
    return IV(Uint8List.fromList(ivBytes));
  }
  
  /// Encrypts the AES key with a master key from keystore
  Future<String> _encryptKeyWithMasterKey(Key key) async {
    try {
      // For now, we'll use a simple approach with SharedPreferences
      // In production, this should use platform-specific keystore (Android Keystore/iOS Keychain)
      final masterKey = await _getOrGenerateMasterKey();
      
      // Use a simple XOR encryption for the master key (placeholder)
      // TODO: Replace with proper keystore integration
      final encryptedKey = _xorEncrypt(key.bytes.toList(), masterKey);
      
      return base64Encode(encryptedKey);
    } catch (e) {
      throw Exception('Failed to encrypt key with master key: $e');
    }
  }
  
  /// Decrypts the AES key with a master key from keystore
  Future<Key> _decryptKeyWithMasterKey(String encryptedKey) async {
    try {
      final masterKey = await _getOrGenerateMasterKey();
      
      // Decrypt the key
      final encryptedBytes = base64Decode(encryptedKey);
      final decryptedBytes = _xorDecrypt(encryptedBytes, masterKey);
      
      return Key(Uint8List.fromList(decryptedBytes));
    } catch (e) {
      throw Exception('Failed to decrypt key with master key: $e');
    }
  }
  
  /// Gets or generates a master key for encrypting AES keys
  Future<List<int>> _getOrGenerateMasterKey() async {
    final prefs = await SharedPreferences.getInstance();
    final masterKeyString = prefs.getString('${_keyPrefix}master');
    
    if (masterKeyString != null) {
      return base64Decode(masterKeyString);
    }
    
    // Generate new master key
    final random = Random.secure();
    final masterKey = List<int>.generate(_keyLength, (i) => random.nextInt(256));
    
    // Store the master key
    await prefs.setString('${_keyPrefix}master', base64Encode(masterKey));
    
    return masterKey;
  }
  
  /// Simple XOR encryption (placeholder - replace with proper keystore)
  List<int> _xorEncrypt(List<int> data, List<int> key) {
    final result = <int>[];
    for (int i = 0; i < data.length; i++) {
      result.add(data[i] ^ key[i % key.length]);
    }
    return result;
  }
  
  /// Simple XOR decryption (placeholder - replace with proper keystore)
  List<int> _xorDecrypt(List<int> data, List<int> key) {
    return _xorEncrypt(data, key); // XOR is symmetric
  }
  
  /// Gets the backup directory path
  Future<String> getBackupDirectory() async {
    if (Platform.isAndroid) {
      // Android: Use app's external files directory
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final backupDir = Directory('${directory.path}/emtc/backups');
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        return backupDir.path;
      }
    } else if (Platform.isIOS) {
      // iOS: Use app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/emtc/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      return backupDir.path;
    }
    
    // Fallback: Use app's documents directory
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/emtc/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }
  
  /// Generates a unique backup filename
  String generateBackupFilename({
    required String centerCode,
    required String periodId,
    required String loId,
    required int version,
  }) {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    
    return '${centerCode}_${periodId}_${loId}_v${version}_$timestamp.emtc.zip';
  }
}

/// Result of file encryption operation
class EncryptedFile {
  final String outputPath;
  final String encryptedKey;
  final String iv;
  final int originalSize;
  
  const EncryptedFile({
    required this.outputPath,
    required this.encryptedKey,
    required this.iv,
    required this.originalSize,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'outputPath': outputPath,
      'encryptedKey': encryptedKey,
      'iv': iv,
      'originalSize': originalSize,
    };
  }
  
  factory EncryptedFile.fromJson(Map<String, dynamic> json) {
    return EncryptedFile(
      outputPath: json['outputPath'] as String,
      encryptedKey: json['encryptedKey'] as String,
      iv: json['iv'] as String,
      originalSize: json['originalSize'] as int,
    );
  }
} 