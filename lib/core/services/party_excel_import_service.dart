import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.g.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';

class ImportPartyResult {
  final int totalPartiesImported;
  final int totalPartiesUpdated;
  final List<String> errors;

  ImportPartyResult({
    required this.totalPartiesImported,
    required this.totalPartiesUpdated,
    required this.errors,
  });
}

class PartyExcelImportService {
  /// Generates the sample Excel template (.xlsx) for Parties & Customers Import
  static List<int>? generateSampleTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Header row as specified
    sheet.appendRow([
      TextCellValue('Party Name'),
      TextCellValue('Mobile Number'),
      TextCellValue('Email ID'),
      TextCellValue('Address'),
      TextCellValue('GST Number'),
      TextCellValue('Receivable Balance'),
      TextCellValue('Payable Balance'),
      TextCellValue('Credit Limit'),
    ]);

    // Sample Row 1 (Customer / Receivable)
    sheet.appendRow([
      TextCellValue('Shree Krishna Traders'),
      TextCellValue('9876543210'),
      TextCellValue('shreekrishna@gmail.com'),
      TextCellValue('45 Main Market Road, Mumbai'),
      TextCellValue('27AAACS1234A1Z5'),
      DoubleCellValue(15000.00),
      DoubleCellValue(0.00),
      DoubleCellValue(50000.00),
    ]);

    // Sample Row 2 (Supplier / Payable)
    sheet.appendRow([
      TextCellValue('Apex Wholesale Pvt Ltd'),
      TextCellValue('9123456789'),
      TextCellValue('contact@apexwholesale.com'),
      TextCellValue('88 Industrial Zone, Pune'),
      TextCellValue('27AAACA9876B1Z2'),
      DoubleCellValue(0.00),
      DoubleCellValue(22500.00),
      DoubleCellValue(100000.00),
    ]);

    return excel.encode();
  }

  /// Imports Parties & Customers from decoded Excel bytes
  static Future<ImportPartyResult> importPartiesFromBytes(
    Uint8List bytes,
    DatabaseService dbService,
  ) async {
    final List<String> errors = [];
    int totalPartiesImported = 0;
    int totalPartiesUpdated = 0;

    try {
      final excel = Excel.decodeBytes(bytes);
      final isar = dbService.isar;

      final sheetKeys = excel.tables.keys.toList();
      if (sheetKeys.isEmpty) {
        return ImportPartyResult(
          totalPartiesImported: 0,
          totalPartiesUpdated: 0,
          errors: ['The selected Excel file contains no worksheets.'],
        );
      }

      final Sheet? sheet = excel.tables['Sheet1'] ?? excel.tables[sheetKeys.first];
      if (sheet == null || sheet.rows.length <= 1) {
        return ImportPartyResult(
          totalPartiesImported: 0,
          totalPartiesUpdated: 0,
          errors: ['The Excel worksheet contains no data rows.'],
        );
      }

      for (int r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        if (row.isEmpty) continue;

        final partyName = _getCellValue(row, 0).trim(); // Col A: Party Name
        final mobile = _getCellValue(row, 1).trim(); // Col B: Mobile Number
        final email = _getCellValue(row, 2).trim(); // Col C: Email ID
        final address = _getCellValue(row, 3).trim(); // Col D: Address
        final gstNumber = _getCellValue(row, 4).trim(); // Col E: GST Number
        final receivableBal = _parseDouble(_getCellValue(row, 5)); // Col F: Receivable Balance
        final payableBal = _parseDouble(_getCellValue(row, 6)); // Col G: Payable Balance
        final creditLimit = _parseDouble(_getCellValue(row, 7)); // Col H: Credit Limit

        if (partyName.isEmpty && mobile.isEmpty && gstNumber.isEmpty) continue;

        final effectiveName = partyName.isNotEmpty ? partyName : 'Party ${mobile.isNotEmpty ? mobile : r}';

        double openingBalance = 0.0;
        String balanceType = 'Dr';
        String partyType = 'Customer';

        if (receivableBal > 0) {
          openingBalance = receivableBal;
          balanceType = 'Dr';
          partyType = 'Customer';
        } else if (payableBal > 0) {
          openingBalance = payableBal;
          balanceType = 'Cr';
          partyType = 'Supplier';
        }

        final gstType = (gstNumber.isNotEmpty && gstNumber.length >= 15) ? 'Registered' : 'Unregistered';

        try {
          // Check if party exists by partyName, gstNumber, or mobileNumber
          Party? existingParty;
          if (gstNumber.isNotEmpty) {
            existingParty = await isar.partys.filter().gstNumberEqualTo(gstNumber).findFirst();
          }
          if (existingParty == null && partyName.isNotEmpty) {
            existingParty = await isar.partys.filter().partyNameEqualTo(effectiveName).findFirst();
          }
          if (existingParty == null && mobile.isNotEmpty) {
            existingParty = await isar.partys.filter().mobileNumberEqualTo(mobile).findFirst();
          }

          if (existingParty != null) {
            // Update existing Party
            existingParty.partyName = effectiveName;
            existingParty.mobileNumber = mobile.isNotEmpty ? mobile : existingParty.mobileNumber;
            existingParty.email = email.isNotEmpty ? email : existingParty.email;
            existingParty.addressLine1 = address.isNotEmpty ? address : existingParty.addressLine1;
            existingParty.gstNumber = gstNumber.isNotEmpty ? gstNumber : existingParty.gstNumber;
            existingParty.gstType = gstType;
            existingParty.openingBalance = openingBalance > 0 ? openingBalance : existingParty.openingBalance;
            existingParty.balanceType = openingBalance > 0 ? balanceType : existingParty.balanceType;
            existingParty.creditLimit = creditLimit > 0 ? creditLimit : existingParty.creditLimit;
            existingParty.updatedAt = DateTime.now();

            await isar.writeTxn(() async {
              await isar.partys.put(existingParty!);
            });

            // Enqueue for Sync
            final queueItem = SyncQueue()
              ..uuid = const Uuid().v4()
              ..entityType = 'Party'
              ..entityId = existingParty.id
              ..entityUuid = existingParty.uuid
              ..operation = 'Update'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now();

            await isar.writeTxn(() async {
              await isar.syncQueues.put(queueItem);
            });

            totalPartiesUpdated++;
          } else {
            // Create New Party
            final newParty = Party()
              ..uuid = const Uuid().v4()
              ..partyCode = 'P-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-$r'
              ..partyName = effectiveName
              ..partyType = partyType
              ..mobileNumber = mobile
              ..email = email
              ..addressLine1 = address
              ..gstNumber = gstNumber
              ..gstType = gstType
              ..openingBalance = openingBalance
              ..balanceType = balanceType
              ..creditLimit = creditLimit
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now();

            await isar.writeTxn(() async {
              newParty.id = await isar.partys.put(newParty);
            });

            // Enqueue for Sync
            final queueItem = SyncQueue()
              ..uuid = const Uuid().v4()
              ..entityType = 'Party'
              ..entityId = newParty.id
              ..entityUuid = newParty.uuid
              ..operation = 'Create'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now();

            await isar.writeTxn(() async {
              await isar.syncQueues.put(queueItem);
            });

            totalPartiesImported++;
          }
        } catch (partyErr) {
          logger.error('Error importing party row $r', partyErr);
          errors.add('Row $r ($effectiveName): ${partyErr.toString()}');
        }
      }
    } catch (e, stackTrace) {
      logger.error('Failed to parse party excel file', e, stackTrace);
      errors.add('Failed to parse Excel file: $e');
    }

    return ImportPartyResult(
      totalPartiesImported: totalPartiesImported,
      totalPartiesUpdated: totalPartiesUpdated,
      errors: errors,
    );
  }

  static String _getCellValue(List<Data?> row, int colIndex) {
    if (colIndex >= row.length || row[colIndex] == null) return '';
    final val = row[colIndex]?.value;
    if (val == null) return '';
    return val.toString().trim();
  }

  static double _parseDouble(String val) {
    if (val.isEmpty) return 0.0;
    final clean = val.replaceAll('₹', '').replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }
}
