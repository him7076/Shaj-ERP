import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
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
  /// Generates sample Excel template (.xlsx) containing ALL Sahaj ERP party form fields
  static List<int>? generateSampleTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Comprehensive Header row matching Sahaj ERP Party Form
    sheet.appendRow([
      TextCellValue('Party Name'),
      TextCellValue('Party Type'), // Customer, Supplier, Retailer, Wholesaler, etc.
      TextCellValue('Mobile Number'),
      TextCellValue('WhatsApp Number'),
      TextCellValue('Email ID'),
      TextCellValue('Contact Person'),
      TextCellValue('GST Number'),
      TextCellValue('PAN Number'),
      TextCellValue('GST Type'), // Registered, Unregistered, Composition
      TextCellValue('Address Line 1'),
      TextCellValue('Address Line 2'),
      TextCellValue('City'),
      TextCellValue('State'),
      TextCellValue('Pincode'),
      TextCellValue('Opening Balance'),
      TextCellValue('Balance Type'), // Dr (Receivable) / Cr (Payable)
      TextCellValue('Credit Limit'),
      TextCellValue('Payment Terms'), // Net 15, Net 30, Cash
      TextCellValue('Business Category'),
      TextCellValue('Notes'),
    ]);

    // Sample Row 1 (Customer / Receivable)
    sheet.appendRow([
      TextCellValue('Shree Krishna Traders'),
      TextCellValue('Customer'),
      TextCellValue('9876543210'),
      TextCellValue('9876543210'),
      TextCellValue('shreekrishna@gmail.com'),
      TextCellValue('Rajesh Kumar'),
      TextCellValue('27AAACS1234A1Z5'),
      TextCellValue('AAACS1234A'),
      TextCellValue('Registered'),
      TextCellValue('45 Main Market Road'),
      TextCellValue('Near Bus Stand'),
      TextCellValue('Mumbai'),
      TextCellValue('Maharashtra'),
      TextCellValue('400001'),
      DoubleCellValue(15000.00),
      TextCellValue('Dr'),
      DoubleCellValue(50000.00),
      TextCellValue('Net 30'),
      TextCellValue('Retail Hardware'),
      TextCellValue('Key retail customer in Mumbai market'),
    ]);

    // Sample Row 2 (Supplier / Payable)
    sheet.appendRow([
      TextCellValue('Apex Wholesale Pvt Ltd'),
      TextCellValue('Supplier'),
      TextCellValue('9123456789'),
      TextCellValue('9123456789'),
      TextCellValue('contact@apexwholesale.com'),
      TextCellValue('Amit Shah'),
      TextCellValue('27AAACA9876B1Z2'),
      TextCellValue('AAACA9876B'),
      TextCellValue('Registered'),
      TextCellValue('88 Industrial Zone'),
      TextCellValue('Phase 2'),
      TextCellValue('Pune'),
      TextCellValue('Maharashtra'),
      TextCellValue('411001'),
      DoubleCellValue(22500.00),
      TextCellValue('Cr'),
      DoubleCellValue(100000.00),
      TextCellValue('Net 15'),
      TextCellValue('FMCG Wholesale'),
      TextCellValue('Primary raw material distributor'),
    ]);

    return excel.encode();
  }

  /// Imports Parties & Customers from decoded Excel bytes supporting flexible headers
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

      final colMap = _buildColumnMap(sheet.rows[0]);

      final colName = _findCol(colMap, ['party name', 'name', 'customer name', 'supplier name', 'party'], 0);
      final colType = _findCol(colMap, ['party type', 'type', 'category', 'role'], 1);
      final colMobile = _findCol(colMap, ['mobile number', 'mobile', 'phone number', 'phone', 'contact'], 2);
      final colWhatsapp = _findCol(colMap, ['whatsapp number', 'whatsapp', 'wa number'], 3);
      final colEmail = _findCol(colMap, ['email id', 'email', 'mail'], 4);
      final colContactPerson = _findCol(colMap, ['contact person', 'owner', 'manager'], 5);
      final colGst = _findCol(colMap, ['gst number', 'gstin', 'gst', 'tax id'], 6);
      final colPan = _findCol(colMap, ['pan number', 'pan'], 7);
      final colGstType = _findCol(colMap, ['gst type', 'registration type', 'tax type'], 8);
      final colAddr1 = _findCol(colMap, ['address line 1', 'address', 'location', 'street'], 9);
      final colAddr2 = _findCol(colMap, ['address line 2', 'area', 'landmark'], 10);
      final colCity = _findCol(colMap, ['city', 'town', 'district'], 11);
      final colState = _findCol(colMap, ['state', 'province'], 12);
      final colPincode = _findCol(colMap, ['pincode', 'pin code', 'zip', 'postal code'], 13);
      final colOpeningBal = _findCol(colMap, ['opening balance', 'receivable balance', 'payable balance', 'balance'], 14);
      final colBalType = _findCol(colMap, ['balance type', 'dr/cr', 'type dr cr'], 15);
      final colCreditLimit = _findCol(colMap, ['credit limit', 'limit'], 16);
      final colPaymentTerms = _findCol(colMap, ['payment terms', 'credit terms', 'due days', 'terms'], 17);
      final colBusinessCat = _findCol(colMap, ['business category', 'segment'], 18);
      final colNotes = _findCol(colMap, ['notes', 'remarks', 'description'], 19);

      final allParties = await isar.partys.filter().isDeletedEqualTo(false).findAll();

      for (int r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        if (row.isEmpty) continue;

        final partyName = _getCellValue(row, colName).trim();
        final partyTypeStr = _getCellValue(row, colType).trim();
        final mobile = _getCellValue(row, colMobile).trim();
        final whatsapp = _getCellValue(row, colWhatsapp).trim();
        final email = _getCellValue(row, colEmail).trim();
        final contactPerson = _getCellValue(row, colContactPerson).trim();
        final gstNumber = _getCellValue(row, colGst).trim();
        final panNumber = _getCellValue(row, colPan).trim();
        final gstTypeStr = _getCellValue(row, colGstType).trim();
        final addr1 = _getCellValue(row, colAddr1).trim();
        final addr2 = _getCellValue(row, colAddr2).trim();
        final city = _getCellValue(row, colCity).trim();
        final state = _getCellValue(row, colState).trim();
        final pincode = _getCellValue(row, colPincode).trim();
        final openingBal = _parseDouble(_getCellValue(row, colOpeningBal));
        final balTypeStr = _getCellValue(row, colBalType).trim();
        final creditLimit = _parseDouble(_getCellValue(row, colCreditLimit));
        final paymentTerms = _getCellValue(row, colPaymentTerms).trim();
        final businessCat = _getCellValue(row, colBusinessCat).trim();
        final notes = _getCellValue(row, colNotes).trim();

        if (partyName.isEmpty && mobile.isEmpty && gstNumber.isEmpty) continue;

        final effectiveName = partyName.isNotEmpty ? partyName : 'Party ${mobile.isNotEmpty ? mobile : r}';

        String partyType = 'Customer';
        if (partyTypeStr.isNotEmpty) {
          partyType = partyTypeStr;
        }

        String balanceType = 'Dr';
        if (balTypeStr.isNotEmpty) {
          balanceType = (balTypeStr.toLowerCase().contains('cr') || balTypeStr.toLowerCase().contains('payable')) ? 'Cr' : 'Dr';
        }

        String gstType = (gstNumber.isNotEmpty && gstNumber.length >= 15) ? 'Registered' : 'Unregistered';
        if (gstTypeStr.isNotEmpty) {
          gstType = gstTypeStr;
        }

        try {
          Party? existingParty;
          if (gstNumber.isNotEmpty) {
            existingParty = allParties.where((p) => p.gstNumber?.trim().toUpperCase() == gstNumber.toUpperCase()).firstOrNull;
          }
          if (existingParty == null && partyName.isNotEmpty) {
            existingParty = allParties.where((p) => p.partyName?.trim().toLowerCase() == effectiveName.toLowerCase()).firstOrNull;
          }
          if (existingParty == null && mobile.isNotEmpty) {
            existingParty = allParties.where((p) => p.mobileNumber?.trim() == mobile).firstOrNull;
          }

          if (existingParty != null) {
            // Update existing Party
            existingParty.partyName = effectiveName;
            existingParty.partyType = partyType;
            existingParty.mobileNumber = mobile.isNotEmpty ? mobile : existingParty.mobileNumber;
            existingParty.whatsappNumber = whatsapp.isNotEmpty ? whatsapp : existingParty.whatsappNumber;
            existingParty.email = email.isNotEmpty ? email : existingParty.email;
            existingParty.contactPerson = contactPerson.isNotEmpty ? contactPerson : existingParty.contactPerson;
            existingParty.gstNumber = gstNumber.isNotEmpty ? gstNumber : existingParty.gstNumber;
            existingParty.panNumber = panNumber.isNotEmpty ? panNumber : existingParty.panNumber;
            existingParty.gstType = gstType;
            existingParty.addressLine1 = addr1.isNotEmpty ? addr1 : existingParty.addressLine1;
            existingParty.addressLine2 = addr2.isNotEmpty ? addr2 : existingParty.addressLine2;
            existingParty.city = city.isNotEmpty ? city : existingParty.city;
            existingParty.state = state.isNotEmpty ? state : existingParty.state;
            existingParty.pincode = pincode.isNotEmpty ? pincode : existingParty.pincode;
            existingParty.openingBalance = openingBal > 0 ? openingBal : existingParty.openingBalance;
            existingParty.balanceType = openingBal > 0 ? balanceType : existingParty.balanceType;
            existingParty.creditLimit = creditLimit > 0 ? creditLimit : existingParty.creditLimit;
            existingParty.paymentTerms = paymentTerms.isNotEmpty ? paymentTerms : existingParty.paymentTerms;
            existingParty.businessCategory = businessCat.isNotEmpty ? businessCat : existingParty.businessCategory;
            existingParty.notes = notes.isNotEmpty ? notes : existingParty.notes;
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
              ..whatsappNumber = whatsapp
              ..email = email
              ..contactPerson = contactPerson
              ..gstNumber = gstNumber
              ..panNumber = panNumber
              ..gstType = gstType
              ..addressLine1 = addr1
              ..addressLine2 = addr2
              ..city = city
              ..state = state
              ..pincode = pincode
              ..openingBalance = openingBal
              ..balanceType = balanceType
              ..creditLimit = creditLimit
              ..paymentTerms = paymentTerms
              ..businessCategory = businessCat
              ..notes = notes
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

  static Map<String, int> _buildColumnMap(List<Data?> headerRow) {
    final Map<String, int> map = {};
    for (int i = 0; i < headerRow.length; i++) {
      final cell = headerRow[i];
      if (cell != null && cell.value != null) {
        final val = cell.value.toString().trim().toLowerCase();
        if (val.isNotEmpty) {
          map[val] = i;
        }
      }
    }
    return map;
  }

  static int _findCol(Map<String, int> colMap, List<String> candidates, int defaultIndex) {
    for (var cand in candidates) {
      if (colMap.containsKey(cand)) {
        return colMap[cand]!;
      }
    }
    for (var entry in colMap.entries) {
      for (var cand in candidates) {
        if (entry.key.contains(cand)) {
          return entry.value;
        }
      }
    }
    return defaultIndex;
  }

  static String _getCellValue(List<Data?> row, int colIndex) {
    if (colIndex < 0 || colIndex >= row.length || row[colIndex] == null) return '';
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
