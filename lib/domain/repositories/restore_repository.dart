import 'package:flutter/foundation.dart';
import 'package:business_sahaj_erp/domain/models/backup_metadata.dart';

abstract class RestoreRepository {
  Future<BackupMetadata> validate(
    String filePath, {
    String? password,
  });

  Future<BackupMetadata> validateBytes(
    Uint8List bytes, {
    String? password,
  });

  Future<void> restore(
    String filePath, {
    String? password,
    bool restoreParties = true,
    bool restoreItems = true,
    bool restoreOrders = true,
    bool restoreInvoices = true,
    bool restoreSettings = true,
    String duplicateStrategy = 'replace',
  });

  Future<void> restoreBytes(
    Uint8List bytes, {
    String? password,
    bool restoreParties = true,
    bool restoreItems = true,
    bool restoreOrders = true,
    bool restoreInvoices = true,
    bool restoreSettings = true,
    String duplicateStrategy = 'replace',
  });
}
