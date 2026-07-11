import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:business_sahaj_erp/core/services/compression_service.dart';
import 'package:business_sahaj_erp/core/services/encryption_service.dart';
import 'package:business_sahaj_erp/domain/models/backup_metadata.dart';
import 'package:business_sahaj_erp/domain/models/backup_history_entry.dart';

void main() {
  group('Backup Metadata & History Entry Tests', () {
    test('BackupMetadata serialization/deserialization', () {
      final now = DateTime.now();
      final meta = BackupMetadata(
        appVersion: '1.2.0',
        databaseVersion: 2,
        backupDate: now,
        hasPassword: true,
        includeImages: false,
        collectionsList: ['parties', 'items'],
      );

      final jsonMap = meta.toJson();
      expect(jsonMap['appVersion'], '1.2.0');
      expect(jsonMap['databaseVersion'], 2);
      expect(jsonMap['hasPassword'], true);
      expect(jsonMap['includeImages'], false);
      expect(jsonMap['collectionsList'], ['parties', 'items']);

      final decoded = BackupMetadata.fromJson(jsonMap);
      expect(decoded.appVersion, '1.2.0');
      expect(decoded.databaseVersion, 2);
      expect(decoded.hasPassword, true);
      expect(decoded.includeImages, false);
      expect(decoded.collectionsList, ['parties', 'items']);
    });

    test('BackupHistoryEntry serialization/deserialization', () {
      final now = DateTime.now();
      final entry = BackupHistoryEntry(
        backupName: 'test.bserp',
        date: now,
        size: 2048,
        location: '/path/to/test.bserp',
        isCloud: false,
        isEncrypted: true,
      );

      final jsonMap = entry.toJson();
      expect(jsonMap['backupName'], 'test.bserp');
      expect(jsonMap['size'], 2048);
      expect(jsonMap['location'], '/path/to/test.bserp');
      expect(jsonMap['isCloud'], false);
      expect(jsonMap['isEncrypted'], true);

      final decoded = BackupHistoryEntry.fromJson(jsonMap);
      expect(decoded.backupName, 'test.bserp');
      expect(decoded.size, 2048);
      expect(decoded.location, '/path/to/test.bserp');
      expect(decoded.isCloud, false);
      expect(decoded.isEncrypted, true);
    });
  });

  group('EncryptionService Tests', () {
    late EncryptionService encryptionService;
    late Directory tempDir;
    late String srcPath;
    late String encPath;
    late String decPath;
    const testContent = "Business Sahaj ERP - Phase 8 Backup System Verification Content";
    const password = "securePassword123";

    setUp(() async {
      encryptionService = EncryptionService();
      tempDir = await Directory.systemTemp.createTemp('enc_test');
      srcPath = '${tempDir.path}/source.txt';
      encPath = '${tempDir.path}/encrypted.enc';
      decPath = '${tempDir.path}/decrypted.txt';

      await File(srcPath).writeAsString(testContent);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Encrypt and decrypt file successfully', () async {
      // 1. Encrypt
      await encryptionService.encryptFile(
        srcPath: srcPath,
        destPath: encPath,
        password: password,
      );

      expect(await File(encPath).exists(), true);
      expect(await File(encPath).readAsBytes(), isNot(utf8.encode(testContent))); // Ciphertext check

      // 2. Decrypt
      await encryptionService.decryptFile(
        srcPath: encPath,
        destPath: decPath,
        password: password,
      );

      expect(await File(decPath).exists(), true);
      expect(await File(decPath).readAsString(), testContent); // Plaintext check
    });

    test('Decryption fails with incorrect password', () async {
      await encryptionService.encryptFile(
        srcPath: srcPath,
        destPath: encPath,
        password: password,
      );

      expect(
        () => encryptionService.decryptFile(
          srcPath: encPath,
          destPath: decPath,
          password: 'wrong_password',
        ),
        throwsException,
      );
    });
  });

  group('CompressionService Tests', () {
    late CompressionService compressionService;
    late Directory tempDir;
    late Directory zipSourceDir;
    late Directory extractDir;
    late String zipDestPath;
    final Map<String, String> testFiles = {
      'parties.json': '[{"name": "John Doe", "balance": 150.0}]',
      'items.json': '[{"name": "Green Tea", "mrp": 250}]',
    };

    setUp(() async {
      compressionService = CompressionService();
      tempDir = await Directory.systemTemp.createTemp('comp_test');
      zipSourceDir = await Directory('${tempDir.path}/source').create();
      extractDir = await Directory('${tempDir.path}/extracted').create();
      zipDestPath = '${tempDir.path}/backup_archive.zip';

      for (var entry in testFiles.entries) {
        await File('${zipSourceDir.path}/${entry.key}').writeAsString(entry.value);
      }
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Compress and extract files successfully', () async {
      final List<File> filesToZip = testFiles.keys
          .map((filename) => File('${zipSourceDir.path}/$filename'))
          .toList();

      // Compress
      await compressionService.createBackupArchive(
        jsonFiles: filesToZip,
        imagesDir: null,
        destZipPath: zipDestPath,
      );

      expect(await File(zipDestPath).exists(), true);

      // Extract
      await compressionService.extractBackupArchive(
        zipPath: zipDestPath,
        destExtractDir: extractDir.path,
      );

      for (var entry in testFiles.entries) {
        final extractedFile = File('${extractDir.path}/${entry.key}');
        expect(await extractedFile.exists(), true);
        expect(await extractedFile.readAsString(), entry.value);
      }
    });
  });
}
