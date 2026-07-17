import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class FirebaseService {
  final SharedPreferences _prefs;

  FirebaseService(this._prefs) {
    _initDeviceId();
  }

  bool get _isFirebaseReady {
    try {
      // Check if any FirebaseApp is initialized
      return _hasFirebaseApp();
    } catch (_) {
      return false;
    }
  }

  bool _hasFirebaseApp() {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseAuth get auth {
    if (!_isFirebaseReady) {
      throw StateError('Firebase is not initialized.');
    }
    return FirebaseAuth.instance;
  }

  FirebaseFirestore get firestore {
    if (!_isFirebaseReady) {
      throw StateError('Firebase is not initialized.');
    }
    return FirebaseFirestore.instance;
  }

  FirebaseStorage get storage {
    if (!_isFirebaseReady) {
      throw StateError('Firebase is not initialized.');
    }
    return FirebaseStorage.instance;
  }

  String? _deviceId;
  String get deviceId => _deviceId ?? 'unknown_device';

  void _initDeviceId() {
    _deviceId = _prefs.getString('device_id');
    if (_deviceId == null) {
      final rand = Random().nextInt(1000000).toString().padLeft(6, '0');
      _deviceId = 'device_${Platform.operatingSystem}_$rand';
      _prefs.setString('device_id', _deviceId!);
      logger.info('Generated new unique Device ID: $_deviceId');
    } else {
      logger.info('Loaded existing Device ID: $_deviceId');
    }
  }

  /// Get current user email
  String? get currentUserEmail => _isFirebaseReady ? auth.currentUser?.email : null;

  /// Get company context for document security isolation
  String get companyId {
    // In a production app, the companyId would be fetched from the User profile doc in Firestore.
    // As a robust placeholder, we derive it from the user's logged-in email.
    final email = currentUserEmail ?? 'admin@sahaj.com';
    final userPart = email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return 'company_$userPart';
  }

  /// Check if the user is authenticated
  bool get isAuthenticated => _isFirebaseReady && auth.currentUser != null;

  /// Ensures that the client is authenticated with Firebase (anonymously or fallback user)
  Future<void> ensureAuthenticated() async {
    if (!_isFirebaseReady) return;
    if (auth.currentUser == null) {
      try {
        // Try anonymous sign-in first
        try {
          await auth.signInAnonymously();
          logger.info('Firebase anonymous login successful.');
          return;
        } catch (_) {}

        // Fallback: try signing in with default credentials
        final email = _prefs.getString('user_email') ?? 'admin@sahaj.com';
        try {
          await auth.signInWithEmailAndPassword(email: email, password: 'admin123');
          logger.info('Firebase email/password login successful.');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found') {
            await auth.createUserWithEmailAndPassword(email: email, password: 'admin123');
            logger.info('Firebase email/password user created and logged in.');
          } else {
            rethrow;
          }
        }
      } catch (e) {
        logger.error('Firebase authentication failed', e);
      }
    }
  }
}

// Simple Platform checking helper
class Platform {
  static String get operatingSystem {
    try {
      if (identical(0, 0.0)) return 'web';
      if (Platform.isAndroid) return 'android';
      if (Platform.isWindows) return 'windows';
      if (Platform.isIOS) return 'ios';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isLinux) return 'linux';
    } catch (_) {}
    return 'unknown';
  }
  static bool get isAndroid => operatingSystem == 'android';
  static bool get isWindows => operatingSystem == 'windows';
  static bool get isIOS => operatingSystem == 'ios';
  static bool get isMacOS => operatingSystem == 'macos';
  static bool get isLinux => operatingSystem == 'linux';
}
