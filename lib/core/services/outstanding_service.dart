import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/party_repository.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class OutstandingService {
  final PartyRepository partyRepository;

  OutstandingService(this.partyRepository);

  /// Automatically updates a party's outstanding balance on invoice registration.
  /// Pending Amount = Grand Total - Paid Amount.
  Future<void> addOutstanding(Party party, double pendingAmount) async {
    try {
      if (pendingAmount < 0) {
        throw const PaymentException('Pending amount cannot be negative for outstanding updates.');
      }
      if (pendingAmount == 0) return;

      final currentOutstanding = party.outstandingBalance ?? 0.0;
      party.outstandingBalance = currentOutstanding + pendingAmount;
      party.updatedAt = DateTime.now();

      await partyRepository.update(party);
      logger.info('Outstanding balance updated for party "${party.partyName}". Added: ₹$pendingAmount. New Balance: ₹${party.outstandingBalance}');
    } catch (e) {
      throw PaymentException('Failed to update outstanding balance for party "${party.partyName}": $e');
    }
  }

  /// Reduces a party's outstanding balance (e.g. on cancellation of invoice or payment received).
  Future<void> reduceOutstanding(Party party, double pendingAmount) async {
    try {
      if (pendingAmount < 0) {
        throw const PaymentException('Pending amount cannot be negative for outstanding updates.');
      }
      if (pendingAmount == 0) return;

      final currentOutstanding = party.outstandingBalance ?? 0.0;
      party.outstandingBalance = currentOutstanding - pendingAmount;
      party.updatedAt = DateTime.now();

      await partyRepository.update(party);
      logger.info('Outstanding balance updated for party "${party.partyName}". Reduced: ₹$pendingAmount. New Balance: ₹${party.outstandingBalance}');
    } catch (e) {
      throw PaymentException('Failed to reduce outstanding balance for party "${party.partyName}": $e');
    }
  }
}
