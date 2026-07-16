import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_item_collection.dart';
import 'base_repository.dart';

abstract class CreditNoteRepository implements BaseRepository<CreditNote> {
  /// Generates the next automatic Credit Note reference number (CN-2026-XXXX)
  Future<String> generateNextCreditNoteNumber();

  /// Saves a Credit Note transaction header and return items, adjusts outstanding balance and inventory levels.
  Future<void> saveCreditNote(CreditNote note, List<CreditNoteItem> items);
}
