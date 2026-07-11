class ServerException implements Exception {
  final String message;
  const ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}

class RecordNotFoundException implements Exception {
  final String message;
  const RecordNotFoundException(this.message);

  @override
  String toString() => 'RecordNotFoundException: $message';
}

class DuplicateRecordException implements Exception {
  final String message;
  const DuplicateRecordException(this.message);

  @override
  String toString() => 'DuplicateRecordException: $message';
}

class SyncException implements Exception {
  final String message;
  const SyncException(this.message);

  @override
  String toString() => 'SyncException: $message';
}

class ConflictException implements Exception {
  final String message;
  const ConflictException(this.message);

  @override
  String toString() => 'ConflictException: $message';
}

class UploadException implements Exception {
  final String message;
  const UploadException(this.message);

  @override
  String toString() => 'UploadException: $message';
}

class InvalidGSTException implements Exception {
  final String message;
  const InvalidGSTException(this.message);

  @override
  String toString() => 'InvalidGSTException: $message';
}

class DuplicatePartyException implements Exception {
  final String message;
  const DuplicatePartyException(this.message);

  @override
  String toString() => 'DuplicatePartyException: $message';
}

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}

class DuplicateItemException implements Exception {
  final String message;
  const DuplicateItemException(this.message);

  @override
  String toString() => 'DuplicateItemException: $message';
}

class InvalidHSNException implements Exception {
  final String message;
  const InvalidHSNException(this.message);

  @override
  String toString() => 'InvalidHSNException: $message';
}

class StockException implements Exception {
  final String message;
  const StockException(this.message);

  @override
  String toString() => 'StockException: $message';
}

class BarcodeException implements Exception {
  final String message;
  const BarcodeException(this.message);

  @override
  String toString() => 'BarcodeException: $message';
}

class OrderException implements Exception {
  final String message;
  const OrderException(this.message);

  @override
  String toString() => 'OrderException: $message';
}

class GSTException implements Exception {
  final String message;
  const GSTException(this.message);

  @override
  String toString() => 'GSTException: $message';
}

class CartException implements Exception {
  final String message;
  const CartException(this.message);

  @override
  String toString() => 'CartException: $message';
}

class OrderConversionException implements Exception {
  final String message;
  const OrderConversionException(this.message);

  @override
  String toString() => 'OrderConversionException: $message';
}

class InvoiceException implements Exception {
  final String message;
  const InvoiceException(this.message);

  @override
  String toString() => 'InvoiceException: $message';
}

class PaymentException implements Exception {
  final String message;
  const PaymentException(this.message);

  @override
  String toString() => 'PaymentException: $message';
}

class PDFException implements Exception {
  final String message;
  const PDFException(this.message);

  @override
  String toString() => 'PDFException: $message';
}

class BackupException implements Exception {
  final String message;
  const BackupException(this.message);

  @override
  String toString() => 'BackupException: $message';
}

class RestoreException implements Exception {
  final String message;
  const RestoreException(this.message);

  @override
  String toString() => 'RestoreException: $message';
}

class CorruptedBackupException implements Exception {
  final String message;
  const CorruptedBackupException(this.message);

  @override
  String toString() => 'CorruptedBackupException: $message';
}

class EncryptionException implements Exception {
  final String message;
  const EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}

class DriveException implements Exception {
  final String message;
  const DriveException(this.message);

  @override
  String toString() => 'DriveException: $message';
}

class ReportException implements Exception {
  final String message;
  const ReportException(this.message);

  @override
  String toString() => 'ReportException: $message';
}

class ExportException implements Exception {
  final String message;
  const ExportException(this.message);

  @override
  String toString() => 'ExportException: $message';
}

class AnalyticsException implements Exception {
  final String message;
  const AnalyticsException(this.message);

  @override
  String toString() => 'AnalyticsException: $message';
}

class FileNotFoundException implements Exception {
  final String message;
  const FileNotFoundException(this.message);

  @override
  String toString() => 'FileNotFoundException: $message';
}


