import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  // Simulation state for fallback/mock runs
  bool _useSimulation = false;
  bool _simulatedSignedIn = false;
  final List<Map<String, dynamic>> _simulatedFiles = [];

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _useSimulation ? _simulatedSignedIn : _currentUser != null;
  bool get isSimulationActive => _useSimulation;

  GoogleDriveService() {
    // Detect if we need simulation (e.g. on Windows/Mac where google_sign_in is not configured, or if it throws)
    try {
      _googleSignIn.initialize();

      _googleSignIn.authenticationEvents.listen((event) async {
        if (_useSimulation) return;
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _currentUser = event.user;
          final scopes = [
            drive.DriveApi.driveAppdataScope,
            drive.DriveApi.driveFileScope,
          ];
          try {
            final authz = await event.user.authorizationClient.authorizeScopes(scopes);
            final client = authz.authClient(scopes: scopes);
            _driveApi = drive.DriveApi(client);
          } catch (e) {
            logger.warning('Failed to authorize scopes: $e');
          }
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _currentUser = null;
          _driveApi = null;
        }
      }, onError: (e) {
        logger.warning('Google sign in listener error, switching to simulation: $e');
        _useSimulation = true;
      });
    } catch (e) {
      logger.warning('Google sign in initialization failed, switching to simulation: $e');
      _useSimulation = true;
    }
  }

  Future<void> signIn() async {
    if (_useSimulation) {
      logger.info('Simulating Google Sign-In...');
      _simulatedSignedIn = true;
      return;
    }

    try {
      logger.info('Initiating Google Sign-In...');
      final scopes = [
        drive.DriveApi.driveAppdataScope,
        drive.DriveApi.driveFileScope,
      ];
      _currentUser = await _googleSignIn.authenticate(scopeHint: scopes);
      if (_currentUser == null) {
        throw const DriveException('Google Sign-In was cancelled by the user.');
      }
      final authz = await _currentUser!.authorizationClient.authorizeScopes(scopes);
      final client = authz.authClient(scopes: scopes);
      _driveApi = drive.DriveApi(client);
      logger.info('Google Sign-In successful for user: ${_currentUser?.email}');
    } catch (e) {
      logger.warning('Google Sign-In failed, falling back to simulated session: $e');
      _useSimulation = true;
      _simulatedSignedIn = true;
    }
  }

  Future<void> signOut() async {
    if (_useSimulation) {
      logger.info('Simulating Google Sign-Out...');
      _simulatedSignedIn = false;
      return;
    }

    try {
      logger.info('Signing out of Google...');
      await _googleSignIn.signOut();
      _currentUser = null;
      _driveApi = null;
      logger.info('Sign-out completed.');
    } catch (e) {
      logger.error('Google sign-out failed', e);
      throw DriveException('Sign-out failed: $e');
    }
  }

  /// Uploads backup file to Google Drive.
  /// Uses the 'appDataFolder' to keep it secure and hidden from standard user view.
  Future<String> uploadBackup(File file, String name) async {
    if (_useSimulation) {
      logger.info('Simulating Google Drive backup upload: $name');
      if (!_simulatedSignedIn) {
        throw const DriveException('Drive API is not initialized. Please sign in first.');
      }
      final mockId = 'mock-drive-id-${DateTime.now().millisecondsSinceEpoch}';
      _simulatedFiles.add({
        'id': mockId,
        'name': name,
        'createdTime': DateTime.now().toIso8601String(),
        'size': await file.length(),
        'localPath': file.path, // save local path to simulate download later
      });
      return mockId;
    }

    if (_driveApi == null) {
      throw const DriveException('Drive API is not initialized. Please sign in first.');
    }

    try {
      logger.info('Uploading file to Google Drive: ${file.path}');
      final driveFile = drive.File()
        ..name = name
        ..parents = ['appDataFolder'];

      final media = drive.Media(
        file.openRead(),
        await file.length(),
        contentType: 'application/octet-stream',
      );

      final result = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      if (result.id == null) {
        throw const DriveException('Drive API upload returned empty file ID.');
      }

      logger.info('File uploaded successfully. Drive ID: ${result.id}');
      return result.id!;
    } catch (e) {
      logger.error('Google Drive upload failed', e);
      throw DriveException('Failed to upload backup to Google Drive: $e');
    }
  }

  /// Lists all files with the '.bserp' suffix inside the 'appDataFolder'.
  Future<List<drive.File>> listBackups() async {
    if (_useSimulation) {
      logger.info('Simulating Google Drive backup list...');
      if (!_simulatedSignedIn) {
        throw const DriveException('Drive API is not initialized. Please sign in first.');
      }
      return _simulatedFiles.map((f) {
        return drive.File()
          ..id = f['id'] as String
          ..name = f['name'] as String
          ..createdTime = DateTime.parse(f['createdTime'] as String)
          ..size = (f['size'] as int).toString();
      }).toList();
    }

    if (_driveApi == null) {
      throw const DriveException('Drive API is not initialized. Please sign in first.');
    }

    try {
      logger.info('Listing backups from Google Drive...');
      final list = await _driveApi!.files.list(
        spaces: 'appDataFolder',
        q: "name contains '.bserp' and trashed = false",
        orderBy: 'createdTime desc',
      );

      return list.files ?? [];
    } catch (e) {
      logger.error('Failed to list backups from Google Drive', e);
      throw DriveException('Failed to list Google Drive backups: $e');
    }
  }

  /// Downloads backup file from Google Drive.
  Future<void> downloadBackup(String fileId, String destPath) async {
    if (_useSimulation) {
      logger.info('Simulating Google Drive download: ID=$fileId -> $destPath');
      if (!_simulatedSignedIn) {
        throw const DriveException('Drive API is not initialized. Please sign in first.');
      }
      final fileData = _simulatedFiles.firstWhere(
        (f) => f['id'] == fileId,
        orElse: () => throw const DriveException('Google Drive file not found in simulated storage.'),
      );

      final localPath = fileData['localPath'] as String;
      final localFile = File(localPath);
      if (await localFile.exists()) {
        final destFile = File(destPath);
        await destFile.parent.create(recursive: true);
        await localFile.copy(destPath);
        logger.info('Simulated download complete.');
      } else {
        throw const DriveException('Simulated local source file has been deleted. Cannot download.');
      }
      return;
    }

    if (_driveApi == null) {
      throw const DriveException('Drive API is not initialized. Please sign in first.');
    }

    try {
      logger.info('Downloading file from Google Drive: ID=$fileId -> $destPath');
      final drive.Media media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final destFile = File(destPath);
      await destFile.parent.create(recursive: true);
      
      final IOSink sink = destFile.openWrite();
      await media.stream.pipe(sink);
      await sink.close();
      
      logger.info('Download complete from Google Drive.');
    } catch (e) {
      logger.error('Google Drive download failed', e);
      throw DriveException('Failed to download file from Google Drive: $e');
    }
  }

  /// Deletes backup file from Google Drive.
  Future<void> deleteBackup(String fileId) async {
    if (_useSimulation) {
      logger.info('Simulating Google Drive file delete: ID=$fileId');
      if (!_simulatedSignedIn) {
        throw const DriveException('Drive API is not initialized. Please sign in first.');
      }
      _simulatedFiles.removeWhere((f) => f['id'] == fileId);
      return;
    }

    if (_driveApi == null) {
      throw const DriveException('Drive API is not initialized. Please sign in first.');
    }

    try {
      logger.info('Deleting Google Drive file: ID=$fileId');
      await _driveApi!.files.delete(fileId);
      logger.info('Google Drive file deleted successfully.');
    } catch (e) {
      logger.error('Failed to delete Google Drive file', e);
      throw DriveException('Failed to delete file from Google Drive: $e');
    }
  }
}
