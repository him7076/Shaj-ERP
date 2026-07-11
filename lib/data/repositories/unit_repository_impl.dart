import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/unit_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/unit_repository.dart';
import 'package:business_sahaj_erp/data/repositories/base_isar_repository.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';

class UnitRepositoryImpl extends BaseIsarRepository<Unit> implements UnitRepository {
  UnitRepositoryImpl(Isar isar) : super(isar, 'Unit');

  @override
  IsarCollection<Unit> get collection => isar.collection<Unit>();

  @override
  Future<Unit?> getByShortName(String shortName) async {
    try {
      return await collection
          .filter()
          .isDeletedEqualTo(false)
          .shortNameEqualTo(shortName, caseSensitive: false)
          .findFirst();
    } catch (e) {
      throw DatabaseException('Failed to retrieve unit by short name "$shortName": $e');
    }
  }
}
