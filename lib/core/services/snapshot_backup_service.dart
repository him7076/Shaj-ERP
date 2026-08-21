import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/services/web_mock_isar.dart';

// Conditional import for web HTML Blob downloading
import 'package:url_launcher/url_launcher.dart';

class SnapshotBackupResult {
  final String fileName;
  final String filePath;
  final int byteSize;
  final DateTime createdAt;

  SnapshotBackupResult({
    required this.fileName,
    required this.filePath,
    required this.byteSize,
    required this.createdAt,
  });
}

class SnapshotBackupService {
  static const String appNameMarker = 'Sahaj ERP Pro';
  static const int currentSchemaVersion = 1;

  /// Creates a full database snapshot (.sahaj archive) across Mobile and Web
  Future<SnapshotBackupResult> createSnapshotBackup({
    required DatabaseService dbService,
    required SharedPreferences prefs,
    List<String>? selectedFirmIds,
  }) async {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final fileName = 'Sahaj_ERP_Pro_Backup_$timestamp.sahaj';
    final activeFirmId = prefs.getString('active_firm_id') ?? 'firm_default';
    final firmsToExport = selectedFirmIds ?? prefs.getStringList('firms_list') ?? [activeFirmId];

    logger.info('Starting full database snapshot backup for firms: $firmsToExport');

    // 1. Create Archive
    final archive = Archive();

    // 2. Build manifest.json
    final manifestMap = {
      'appName': appNameMarker,
      'schemaVersion': currentSchemaVersion,
      'appVersion': '1.0.0',
      'createdAt': now.toIso8601String(),
      'activeFirmId': activeFirmId,
      'exportedFirms': firmsToExport,
      'isWebSource': kIsWeb,
    };
    final manifestBytes = utf8.encode(jsonEncode(manifestMap));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    // 3. Package Database Files / JSON Dumps
    for (final firmId in firmsToExport) {
      if (kIsWeb) {
        // Web: Dump WebMockIsar collections to JSON
        final isarInstance = dbService.isar;
        Map<String, dynamic> collectionsMap = {};
        if (isarInstance is WebMockIsar) {
          collectionsMap = isarInstance.exportCollectionsJson();
        }
        final jsonBytes = utf8.encode(jsonEncode(collectionsMap));
        archive.addFile(ArchiveFile('database_$firmId.json', jsonBytes.length, jsonBytes));
      } else {
        // Native (Android/iOS):
        // A. Copy raw Isar binary file using Isar.copyToFile
        try {
          final tempDir = await getTemporaryDirectory();
          final tempIsarPath = '${tempDir.path}/temp_$firmId.isar';
          final tempIsarFile = File(tempIsarPath);
          if (await tempIsarFile.exists()) {
            await tempIsarFile.delete();
          }

          if (firmId == activeFirmId) {
            await dbService.isar.copyToFile(tempIsarPath);
          }

          if (await tempIsarFile.exists() && await tempIsarFile.length() > 0) {
            final isarBytes = await tempIsarFile.readAsBytes();
            archive.addFile(ArchiveFile('database_$firmId.isar', isarBytes.length, isarBytes));
            await tempIsarFile.delete().catchError((_) {});
          } else {
            final appDocsDir = await getApplicationDocumentsDirectory();
            final isarFile = File('${appDocsDir.path}/$firmId.isar');
            if (await isarFile.exists()) {
              final isarBytes = await isarFile.readAsBytes();
              archive.addFile(ArchiveFile('database_$firmId.isar', isarBytes.length, isarBytes));
            }
          }
        } catch (e) {
          logger.warning('Could not copy raw Isar file for $firmId: $e');
        }

        // B. Also include JSON dump for cross-platform restoration compatibility on Web
        try {
          final collectionsMap = await dbService.exportCollectionsToJson(firmId);
          final jsonBytes = utf8.encode(jsonEncode(collectionsMap));
          archive.addFile(ArchiveFile('database_$firmId.json', jsonBytes.length, jsonBytes));
        } catch (e) {
          logger.warning('Could not export JSON collections for $firmId: $e');
        }
      }
    }

    // 4. Encode ZIP archive
    final zipEncoder = ZipEncoder();
    final encodedBytes = zipEncoder.encode(archive);
    if (encodedBytes == null) {
      throw Exception('Failed to compress snapshot backup archive.');
    }
    final archiveUint8List = Uint8List.fromList(encodedBytes);

    // 5. Handle Platform Storage
    if (kIsWeb) {
      // Trigger Web download via data URI
      final base64Data = base64Encode(archiveUint8List);
      final dataUri = 'data:application/octet-stream;base64,$base64Data';
      final uri = Uri.parse(dataUri);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      return SnapshotBackupResult(
        fileName: fileName,
        filePath: 'Browser Downloads',
        byteSize: archiveUint8List.length,
        createdAt: now,
      );
    } else {
      // Mobile (Android / iOS)
      String targetDirPath = '';
      if (Platform.isAndroid) {
        final downloadsFolder = Directory('/storage/emulated/0/Download/Sahaj ERP Pro');
        if (!await downloadsFolder.exists()) {
          await downloadsFolder.create(recursive: true);
        }
        targetDirPath = downloadsFolder.path;
      } else {
        final appDocs = await getApplicationDocumentsDirectory();
        final downloadsFolder = Directory('${appDocs.path}/Downloads/Sahaj ERP Pro');
        if (!await downloadsFolder.exists()) {
          await downloadsFolder.create(recursive: true);
        }
        targetDirPath = downloadsFolder.path;
      }

      final targetFile = File('$targetDirPath/$fileName');
      await targetFile.writeAsBytes(archiveUint8List, flush: true);

      logger.info('Snapshot backup saved successfully to ${targetFile.path}');

      return SnapshotBackupResult(
        fileName: fileName,
        filePath: targetFile.path,
        byteSize: archiveUint8List.length,
        createdAt: now,
      );
    }
  }

  /// Restores a full database snapshot from a .sahaj file (Native)
  Future<void> restoreSnapshotBackupFromFile({
    required File sahajFile,
    required DatabaseService dbService,
    required SharedPreferences prefs,
  }) async {
    if (!await sahajFile.exists()) {
      throw Exception('Backup file does not exist at: ${sahajFile.path}');
    }
    final bytes = await sahajFile.readAsBytes();
    await restoreSnapshotBackupFromBytes(
      bytes: bytes,
      dbService: dbService,
      prefs: prefs,
    );
  }

  /// Restores a full database snapshot from raw bytes (Cross-platform)
  Future<void> restoreSnapshotBackupFromBytes({
    required Uint8List bytes,
    required DatabaseService dbService,
    required SharedPreferences prefs,
  }) async {
    logger.info('Beginning full database snapshot restore from bytes (${bytes.length} bytes)...');

    // 1. Decode ZIP archive
    final archive = ZipDecoder().decodeBytes(bytes);

    // 2. Locate and parse manifest.json
    ArchiveFile? manifestFile;
    for (final file in archive) {
      if (file.name == 'manifest.json') {
        manifestFile = file;
        break;
      }
    }

    if (manifestFile == null) {
      throw Exception('Corrupted backup file: manifest.json missing.');
    }

    final manifestJsonStr = utf8.decode(manifestFile.content as List<int>);
    final manifest = jsonDecode(manifestJsonStr) as Map<String, dynamic>;

    final appName = manifest['appName'];
    if (appName != appNameMarker) {
      throw Exception('Invalid backup file: App name mismatch ($appName).');
    }

    final activeFirmId = manifest['activeFirmId']?.toString() ?? 'firm_default';
    final exportedFirms = (manifest['exportedFirms'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [activeFirmId];

    logger.info('Validated snapshot manifest. Active firm: $activeFirmId, Exported firms: $exportedFirms');

    // 3. Atomic Restore with Rollback Safeguard
    File? tempBackupFile;
    if (!kIsWeb) {
      try {
        final appDocsDir = await getApplicationDocumentsDirectory();
        final currentDbFile = File('${appDocsDir.path}/$activeFirmId.isar');
        if (await currentDbFile.exists()) {
          tempBackupFile = File('${appDocsDir.path}/backup_temp.db');
          if (await tempBackupFile.exists()) {
            await tempBackupFile.delete();
          }
          await currentDbFile.copy(tempBackupFile.path);
        }
      } catch (e) {
        logger.warning('Could not create temporary rollback database file: $e');
      }
    }

    try {
      if (kIsWeb) {
        // Web Restoration
        for (final firmId in exportedFirms) {
          ArchiveFile? jsonFile;
          for (final f in archive) {
            if (f.name == 'database_$firmId.json') {
              jsonFile = f;
              break;
            }
          }

          if (jsonFile != null) {
            final jsonStr = utf8.decode(jsonFile.content as List<int>);
            final collectionsData = jsonDecode(jsonStr) as Map<String, dynamic>;
            final isarInstance = dbService.isar;
            if (isarInstance is WebMockIsar) {
              isarInstance.importCollectionsJson(collectionsData);
              await isarInstance.saveToPrefs(prefs);
            }
          }
        }
      } else {
        // Native Restoration
        await dbService.close();

        final appDocsDir = await getApplicationDocumentsDirectory();

        for (final firmId in exportedFirms) {
          ArchiveFile? binaryIsarFile;
          ArchiveFile? jsonFile;

          for (final f in archive) {
            if (f.name == 'database_$firmId.isar') {
              binaryIsarFile = f;
            } else if (f.name == 'database_$firmId.json') {
              jsonFile = f;
            }
          }

          final targetDbFile = File('${appDocsDir.path}/$firmId.isar');
          if (await targetDbFile.exists()) {
            await targetDbFile.delete();
          }

          if (binaryIsarFile != null) {
            // Restore from raw binary Isar file
            final isarBytes = binaryIsarFile.content as List<int>;
            await targetDbFile.writeAsBytes(isarBytes, flush: true);
          } else if (jsonFile != null) {
            // Fallback: Restore from JSON collection dump
            final jsonStr = utf8.decode(jsonFile.content as List<int>);
            final collectionsData = jsonDecode(jsonStr) as Map<String, dynamic>;
            await dbService.importCollectionsFromJson(firmId, collectionsData);
          }
        }

        // Re-open active firm Isar database
        await prefs.setString('active_firm_id', activeFirmId);
        await dbService.init(prefs);
      }

      // Cleanup temp rollback file on success
      if (tempBackupFile != null && await tempBackupFile.exists()) {
        await tempBackupFile.delete().catchError((_) {});
      }

      logger.info('Snapshot database restore completed successfully!');
    } catch (e, stack) {
      logger.error('Snapshot database restore failed! Attempting atomic rollback...', e, stack);

      // Rollback to temp backup file
      if (tempBackupFile != null && await tempBackupFile.exists()) {
        try {
          final appDocsDir = await getApplicationDocumentsDirectory();
          final currentDbFile = File('${appDocsDir.path}/$activeFirmId.isar');
          if (await currentDbFile.exists()) {
            await currentDbFile.delete();
          }
          await tempBackupFile.copy(currentDbFile.path);
          await dbService.init(prefs);
          logger.info('Atomic rollback completed successfully. Original database state restored.');
        } catch (rollbackErr) {
          logger.error('Failed to perform atomic rollback: $rollbackErr');
        }
      }
      rethrow;
    }
  }
}
