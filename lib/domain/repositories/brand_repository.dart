import 'package:business_sahaj_erp/data/local/collections/brand_collection.dart';
import 'base_repository.dart';

abstract class BrandRepository implements BaseRepository<Brand> {
  /// Fetches a brand by name
  Future<Brand?> getByName(String name);
}
