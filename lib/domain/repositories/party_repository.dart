import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'base_repository.dart';

abstract class PartyRepository implements BaseRepository<Party> {
  /// Searches parties by matching name, mobile number, or GST number
  Future<List<Party>> searchParties(String query);

  /// Generates the next sequential unique party code based on type
  Future<String> generateNextPartyCode(String partyType);

  /// Checks if a GST number is unique (active record check)
  Future<bool> isGstNumberUnique(String gstNumber, {int? excludeId});

  /// Checks if a mobile number is unique
  Future<bool> isMobileNumberUnique(String mobileNumber, {int? excludeId});

  /// Updates GPS latitude, longitude, and geocoded address
  Future<void> updateGPSLocation(
    String uuid,
    double latitude,
    double longitude,
    String locationAddress,
    String googleMapUrl,
  );
}
