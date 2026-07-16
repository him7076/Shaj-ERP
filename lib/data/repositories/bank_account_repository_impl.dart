import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/bank_account_repository.dart';
import 'package:business_sahaj_erp/data/repositories/base_isar_repository.dart';

class BankAccountRepositoryImpl extends BaseIsarRepository<BankAccount> implements BankAccountRepository {
  BankAccountRepositoryImpl(Isar isar) : super(isar, 'BankAccount');

  @override
  IsarCollection<BankAccount> get collection => isar.collection<BankAccount>();
}
