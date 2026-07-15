import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'base_repository.dart';

abstract class TransactionRepository implements BaseRepository<Transaction> {
  Future<List<Transaction>> searchTransactions(String query);
  Future<String> generateNextTransactionNumber(String type);
  Future<void> saveTransaction(Transaction transaction);
  Future<void> deleteTransaction(Transaction transaction);
}
