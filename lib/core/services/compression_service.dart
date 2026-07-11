import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class CompressionService {
  /// Compresses a list of JSON files and an images directory into a single zip-based `.bserp` backup.
  Future<void> createBackupArchive({
    required List<File> jsonFiles,
    required Directory? imagesDir,
    required String destZipPath,
  }) async {
    try {
      logger.info('Starting compression for backup file: $destZipPath');
      final encoder = ZipFileEncoder();
      encoder.create(destZipPath);

      // Add JSON collection files
      for (final file in jsonFiles) {
        if (await file.exists()) {
          logger.debug('Adding file to archive: ${file.path}');
          encoder.addFile(file);
        }
      }

      // Add image directory contents under an "images/" virtual sub-folder
      if (imagesDir != null && await imagesDir.exists()) {
        logger.debug('Adding image directory to archive: ${imagesDir.path}');
        // To preserve a clean "images/" structure, we iterate files and add them individually
        final filesStream = imagesDir.list(recursive: true);
        await for (final entity in filesStream) {
          if (entity is File) {
            // Calculate relative path inside ZIP
            final relativePath = entity.path
                .replaceFirst(imagesDir.path, '')
                .replaceAll('\\', '/'); // normalize delimiters
            final zipPath = 'images$relativePath';
            logger.debug('Adding image file: $zipPath');
            encoder.addFile(entity, zipPath);
          }
        }
      }

      encoder.close();
      logger.info('Compression complete for: $destZipPath');
    } catch (e, stackTrace) {
      logger.error('Failed to compress backup archive', e, stackTrace);
      throw CorruptedBackupException('Failed to compress backup archive: $e');
    }
  }

  /// Extracts the backup `.bserp` archive into a temporary destination folder.
  Future<void> extractBackupArchive({
    required String zipPath,
    required String destExtractDir,
  }) async {
    try {
      logger.info('Extracting backup archive $zipPath to $destExtractDir');
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        throw FileNotFoundException('Backup archive file not found.');
      }

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        final destPath = '$destExtractDir/$filename';
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File(destPath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(data, flush: true);
        } else {
          final outDir = Directory(destPath);
          await outDir.create(recursive: true);
        }
      }
      logger.info('Extraction completed successfully.');
    } catch (e, stackTrace) {
      logger.error('Failed to extract backup archive', e, stackTrace);
      throw CorruptedBackupException('Failed to extract backup archive: $e');
    }
  }
}
