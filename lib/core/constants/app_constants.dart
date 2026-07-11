class AppConstants {
  // App Info
  static const String appName = 'Business Sahaj ERP';
  static const String appVersion = '1.0.0';

  // Network Configuration
  static const String apiBaseUrl = 'https://api.businesssahaj.com/v1/'; // Placeholder
  static const int apiConnectTimeout = 15000; // milliseconds
  static const int apiReceiveTimeout = 15000; // milliseconds

  // Responsiveness Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1200.0;

  // Shared Preferences Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyAuthToken = 'auth_token';
  static const String keyUserEmail = 'user_email';
  static const String keyLastSyncTime = 'last_sync_time';

  // UI Styling Defaults
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultCardElevation = 2.0;
}
