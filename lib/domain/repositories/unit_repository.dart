import 'package:business_sahaj_erp/data/local/collections/unit_collection.dart';
import 'base_repository.dart';

abstract class UnitRepository implements BaseRepository<Unit> {
  /// Fetches a unit by shortName (e.g. PCS, KG, LTR)
  Future<Unit?> getByShortName(String shortName);
}
