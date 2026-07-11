import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class EncryptionService {
  /// Encrypts the source file using AES-256 (CBC mode) with a key derived from the password.
  /// Prepends the 16-byte random IV to the ciphertext before writing.
  Future<void> encryptFile({
    required String srcPath,
    required String destPath,
    required String password,
  }) async {
    try {
      logger.info('Encrypting file: $srcPath -> $destPath');
      final srcFile = File(srcPath);
      if (!await srcFile.exists()) {
        throw const FileNotFoundException('Source file to encrypt not found.');
      }

      final bytes = await srcFile.readAsBytes();

      // Derive key using SHA-256
      final keyBytes = sha256.convert(utf8.encode(password)).bytes;
      final key = enc.Key(Uint8List.fromList(keyBytes));

      // Generate random 16-byte IV
      final iv = enc.IV.fromLength(16);

      // Perform encryption
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encryptBytes(bytes, iv: iv);

      // Prepend IV to ciphertext
      final ivBytes = iv.bytes;
      final cipherBytes = encrypted.bytes;

      final resultBytes = BytesBuilder()
        ..add(ivBytes)
        ..add(cipherBytes);

      final destFile = File(destPath);
      await destFile.parent.create(recursive: true);
      await destFile.writeAsBytes(resultBytes.toBytes(), flush: true);

      logger.info('File encrypted successfully.');
    } catch (e, stackTrace) {
      logger.error('Encryption failed', e, stackTrace);
      throw EncryptionException('Failed to encrypt backup file: $e');
    }
  }

  /// Decrypts the source file using AES-256 (CBC mode) with a key derived from the password.
  /// Extracts the first 16 bytes as the IV, and the rest as the ciphertext.
  Future<void> decryptFile({
    required String srcPath,
    required String destPath,
    required String password,
  }) async {
    try {
      logger.info('Decrypting file: $srcPath -> $destPath');
      final srcFile = File(srcPath);
      if (!await srcFile.exists()) {
        throw const FileNotFoundException('Source file to decrypt not found.');
      }

      final bytes = await srcFile.readAsBytes();
      if (bytes.length < 16) {
        throw const CorruptedBackupException('Invalid encrypted file: too small.');
      }

      // Extract IV (first 16 bytes)
      final ivBytes = bytes.sublist(0, 16);
      final cipherBytes = bytes.sublist(16);

      // Derive key using SHA-256
      final keyBytes = sha256.convert(utf8.encode(password)).bytes;
      final key = enc.Key(Uint8List.fromList(keyBytes));
      final iv = enc.IV(ivBytes);

      // Perform decryption
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decryptedBytes = encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);

      final destFile = File(destPath);
      await destFile.parent.create(recursive: true);
      await destFile.writeAsBytes(decryptedBytes, flush: true);

      logger.info('File decrypted successfully.');
    } catch (e, stackTrace) {
      logger.error('Decryption failed', e, stackTrace);
      throw EncryptionException('Failed to decrypt backup file. Please verify password. Error: $e');
    }
  }
}

class FileNotFoundException implements Exception {
  final String message;
  const FileNotFoundException(this.message);
  @override
  String toString() => 'FileNotFoundException: $message';
}
