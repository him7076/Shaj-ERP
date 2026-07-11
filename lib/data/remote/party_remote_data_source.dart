import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:business_sahaj_erp/core/services/firebase_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';

class PartyRemoteDataSource {
  final FirebaseService _firebaseService;

  PartyRemoteDataSource(this._firebaseService);

  CollectionReference get _partiesCollection => _firebaseService.firestore.collection('parties');

  /// Uploads or merges party data directly on Firestore
  Future<void> uploadParty(Map<String, dynamic> partyJson) async {
    try {
      final uuid = partyJson['uuid'] as String;
      logger.info('Uploading party $uuid to Firestore...');
      await _partiesCollection.doc(uuid).set(partyJson, SetOptions(merge: true));
      logger.info('Party $uuid uploaded successfully to Firestore.');
    } on FirebaseException catch (e) {
      logger.error('Firebase Firestore upload error', e);
      throw UploadException('Firestore Error: ${e.message}');
    } catch (e) {
      logger.error('Unexpected error during remote party upload', e);
      throw UploadException('Remote write failed: $e');
    }
  }

  /// Syncs a soft deletion directly on Firestore
  Future<void> softDeleteParty(String uuid, int version) async {
    try {
      logger.info('Syncing soft deletion for party $uuid to Firestore...');
      await _partiesCollection.doc(uuid).set({
        'uuid': uuid,
        'isDeleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
        'version': version,
        'deviceId': _firebaseService.deviceId,
        'lastModifiedBy': _firebaseService.currentUserEmail ?? 'admin@sahaj.com',
        'companyId': _firebaseService.companyId,
      }, SetOptions(merge: true));
      logger.info('Party soft deletion sync complete for $uuid.');
    } on FirebaseException catch (e) {
      logger.error('Firebase Firestore deletion sync error', e);
      throw UploadException('Firestore Error: ${e.message}');
    } catch (e) {
      logger.error('Unexpected error during remote party delete', e);
      throw UploadException('Remote delete failed: $e');
    }
  }
}
