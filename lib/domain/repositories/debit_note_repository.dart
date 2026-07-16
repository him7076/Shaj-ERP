import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_item_collection.dart';
import 'base_repository.dart';

abstract class DebitNoteRepository implements BaseRepository<DebitNote> {
  /// Generates the next automatic Debit Note reference number (DN-2026-XXXX)
  Future<String> generateNextDebitNoteNumber();

  /// Saves a Debit Note transaction header and return items, adjusts outstanding balance and inventory levels.
  Future<void> saveDebitNote(DebitNote note, List<DebitNoteItem> items);
}
