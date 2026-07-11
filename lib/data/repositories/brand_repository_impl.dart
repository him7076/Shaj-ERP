import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/brand_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/brand_repository.dart';
import 'package:business_sahaj_erp/data/repositories/base_isar_repository.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';

class BrandRepositoryImpl extends BaseIsarRepository<Brand> implements BrandRepository {
  BrandRepositoryImpl(Isar isar) : super(isar, 'Brand');

  @override
  IsarCollection<Brand> get collection => isar.collection<Brand>();

  @override
  Future<Brand?> getByName(String name) async {
    try {
      return await collection
          .filter()
          .isDeletedEqualTo(false)
          .brandNameEqualTo(name, caseSensitive: false)
          .findFirst();
    } catch (e) {
      throw DatabaseException('Failed to retrieve brand by name "$name": $e');
    }
  }
}
