import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:business_sahaj_erp/core/services/firebase_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';

class StorageService {
  final FirebaseService _firebaseService;

  StorageService(this._firebaseService);

  /// Uploads a local file to Firebase Storage and returns the download URL.
  Future<String> uploadFile(String localPath, String remotePath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        throw const UploadException('Local file to upload does not exist.');
      }

      logger.info('Uploading file from $localPath to Storage:$remotePath...');
      
      final ref = _firebaseService.storage.ref().child(remotePath);
      
      // Inject metadata like companyId for storage security rules verification
      final metadata = SettableMetadata(
        customMetadata: {
          'companyId': _firebaseService.companyId,
          'deviceId': _firebaseService.deviceId,
        },
      );

      final uploadTask = ref.putFile(file, metadata);
      final snapshot = await uploadTask;
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      logger.info('Upload complete. Download URL: $downloadUrl');
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      logger.error('Firebase Storage upload failed', e);
      throw UploadException('Firebase Storage Error: ${e.message}');
    } catch (e) {
      logger.error('Unexpected error during file upload', e);
      throw UploadException('Failed to upload file: $e');
    }
  }

  /// Helper to upload a product/item image
  Future<String> uploadItemImage(String itemId, String localPath) async {
    final fileExt = localPath.split('.').last;
    final remotePath = 'companies/${_firebaseService.companyId}/items/$itemId/image_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    return await uploadFile(localPath, remotePath);
  }

  /// Helper to upload a company logo
  Future<String> uploadLogo(String localPath) async {
    final fileExt = localPath.split('.').last;
    final remotePath = 'companies/${_firebaseService.companyId}/logo/logo.$fileExt';
    return await uploadFile(localPath, remotePath);
  }
}
