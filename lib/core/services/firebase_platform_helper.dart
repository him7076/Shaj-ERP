import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io show Platform;

/// A safe, non-recursive platform detection helper.
///
/// Replaces the broken custom `Platform` class that was in firebase_service.dart,
/// which had an infinite recursion bug:
///   Platform.isAndroid -> operatingSystem -> Platform.isAndroid -> ... (stack overflow)
///
/// This helper uses dart:io's real Platform on native platforms
/// and kIsWeb for web detection. No recursion possible.
class AppPlatformHelper {
  static String get operatingSystem {
    if (kIsWeb) return 'web';
    try {
      return io.Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }

  static bool get isAndroid {
    if (kIsWeb) return false;
    try {
      return io.Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  static bool get isIOS {
    if (kIsWeb) return false;
    try {
      return io.Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  static bool get isWindows {
    if (kIsWeb) return false;
    try {
      return io.Platform.isWindows;
    } catch (_) {
      return false;
    }
  }

  static bool get isMacOS {
    if (kIsWeb) return false;
    try {
      return io.Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  static bool get isLinux {
    if (kIsWeb) return false;
    try {
      return io.Platform.isLinux;
    } catch (_) {
      return false;
    }
  }
}
