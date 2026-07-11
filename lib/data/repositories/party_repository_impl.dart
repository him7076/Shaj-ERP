import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/party_repository.dart';
import 'package:business_sahaj_erp/data/repositories/base_isar_repository.dart';
import 'package:business_sahaj_erp/data/local/party_local_data_source.dart';
import 'package:business_sahaj_erp/data/remote/party_remote_data_source.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';

class PartyRepositoryImpl extends BaseIsarRepository<Party> implements PartyRepository {
  final PartyLocalDataSource _localDataSource;
  final PartyRemoteDataSource _remoteDataSource;

  PartyRepositoryImpl(
    Isar isar,
    this._localDataSource,
    this._remoteDataSource,
  ) : super(isar, 'Party');

  @override
  IsarCollection<Party> get collection => isar.collection<Party>();

  @override
  Future<List<Party>> searchParties(String query) async {
    if (query.trim().isEmpty) {
      return await getAll();
    }

    try {
      // Offline matching on indexes: name, code, mobile, gst, city
      return await collection
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .group((q) => q
              .partyNameContains(query, caseSensitive: false)
              .or()
              .partyCodeContains(query, caseSensitive: false)
              .or()
              .mobileNumberContains(query)
              .or()
              .gstNumberContains(query, caseSensitive: false)
              .or()
              .cityContains(query, caseSensitive: false))
          .findAll();
    } catch (e) {
      throw DatabaseException('Failed to search parties offline: $e');
    }
  }

  @override
  Future<String> generateNextPartyCode(String partyType) async {
    return await _localDataSource.generateNextPartyCode(partyType);
  }

  @override
  Future<bool> isGstNumberUnique(String gstNumber, {int? excludeId}) async {
    return await _localDataSource.isGstNumberUnique(gstNumber, excludeId: excludeId);
  }

  @override
  Future<bool> isMobileNumberUnique(String mobileNumber, {int? excludeId}) async {
    return await _localDataSource.isMobileNumberUnique(mobileNumber, excludeId: excludeId);
  }

  @override
  Future<void> updateGPSLocation(
    String uuid,
    double latitude,
    double longitude,
    String locationAddress,
    String googleMapUrl,
  ) async {
    // 1. Update location coordinates in Isar local storage
    await _localDataSource.updateGPSLocation(uuid, latitude, longitude, locationAddress, googleMapUrl);

    // 2. Queue sync operation in sync loop
    // BaseIsarRepository handles SyncQueue automatically during put/update,
    // but since we updated it directly inside LocalDataSource for direct access,
    // we can retrieve the updated entity and write it via the standard update() method
    // to trigger the sync queue log!
    final updatedParty = await getByUuid(uuid);
    if (updatedParty != null) {
      await update(updatedParty);
    }
  }
}
