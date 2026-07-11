import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class PartyLocalDataSource {
  final DatabaseService _dbService;

  PartyLocalDataSource(this._dbService);

  IsarCollection<Party> get _partyCollection => _dbService.isar.partys;

  /// Generates the next unique Party Code based on type prefix (e.g. CUS0001)
  Future<String> generateNextPartyCode(String partyType) async {
    String prefix;
    switch (partyType) {
      case 'Customer':
        prefix = 'CUS';
        break;
      case 'Retailer':
        prefix = 'RET';
        break;
      case 'Wholesaler':
        prefix = 'WHL';
        break;
      case 'Distributor':
        prefix = 'DST';
        break;
      case 'Supplier':
        prefix = 'SUP';
        break;
      default:
        prefix = 'PRT'; // Custom type fallback
    }

    try {
      final lastParty = await _partyCollection
          .filter()
          .partyCodeStartsWith(prefix)
          .sortByPartyCodeDesc()
          .findFirst();

      if (lastParty == null || lastParty.partyCode == null || lastParty.partyCode!.length <= prefix.length) {
        return '${prefix}0001';
      }

      final numPart = lastParty.partyCode!.substring(prefix.length);
      final lastNumber = int.tryParse(numPart) ?? 0;
      final nextNumber = lastNumber + 1;
      
      return '$prefix${nextNumber.toString().padLeft(4, '0')}';
    } catch (e) {
      logger.error('Failed to generate next party code', e);
      return '${prefix}0001';
    }
  }

  /// Validates duplicate GST numbers
  Future<bool> isGstNumberUnique(String gstNumber, {int? excludeId}) async {
    try {
      if (excludeId != null) {
        final matches = await _partyCollection
            .where()
            .idNotEqualTo(excludeId)
            .filter()
            .gstNumberEqualTo(gstNumber)
            .findFirst();
        return matches == null;
      }
      final matches = await _partyCollection
          .filter()
          .gstNumberEqualTo(gstNumber)
          .findFirst();
      return matches == null;
    } catch (e) {
      logger.error('Duplicate GST check failed', e);
      return true;
    }
  }

  /// Validates duplicate mobile numbers
  Future<bool> isMobileNumberUnique(String mobileNumber, {int? excludeId}) async {
    try {
      if (excludeId != null) {
        final matches = await _partyCollection
            .where()
            .idNotEqualTo(excludeId)
            .filter()
            .mobileNumberEqualTo(mobileNumber)
            .findFirst();
        return matches == null;
      }
      final matches = await _partyCollection
          .filter()
          .mobileNumberEqualTo(mobileNumber)
          .findFirst();
      return matches == null;
    } catch (e) {
      logger.error('Duplicate mobile check failed', e);
      return true;
    }
  }

  /// Updates GPS coordinates for a party
  Future<void> updateGPSLocation(
    String uuid,
    double latitude,
    double longitude,
    String locationAddress,
    String googleMapUrl,
  ) async {
    try {
      final party = await _partyCollection.filter().uuidEqualTo(uuid).findFirst();
      if (party == null) {
        throw RecordNotFoundException('Party with UUID $uuid not found.');
      }

      party.latitude = latitude;
      party.longitude = longitude;
      party.locationAddress = locationAddress;
      party.googleMapUrl = googleMapUrl;
      party.updatedAt = DateTime.now();
      party.isSynced = false;
      party.version += 1;

      await _dbService.isar.writeTxn(() async {
        await _partyCollection.put(party);
      });
      logger.info('GPS Location updated locally for Party ${party.partyName}.');
    } catch (e) {
      throw DatabaseException('Failed to update Party GPS location: $e');
    }
  }
}
