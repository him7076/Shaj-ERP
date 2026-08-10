import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

// Services & Core
import 'package:business_sahaj_erp/core/theme/app_theme.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/router.dart';

void main() {
  runZonedGuarded(() async {
    // Ensure that Flutter widget binding is initialized before asynchronous calls
    WidgetsFlutterBinding.ensureInitialized();

    // Catch framework-level errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('CRITICAL FLUTTER ERROR: ${details.exception}\n${details.stack}');
      logger.error('Flutter Framework Error', details.exception, details.stack);
    };

    // Override global ErrorWidget to present explicit UI error instead of red/grey screen
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          backgroundColor: const Color(0xFF1E1E2C),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bug_report_rounded, size: 64, color: Colors.amberAccent),
                      const SizedBox(height: 16),
                      const Text(
                        'Application Error Detected',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amberAccent.withOpacity(0.4)),
                        ),
                        child: Text(
                          details.exceptionAsString(),
                          textAlign: TextAlign.left,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.amber),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        details.stack?.toString().split('\n').take(8).join('\n') ?? '',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    };

    debugPrint('[BOOT] Initializing Business Sahaj ERP services...');
    logger.info('Initializing Business Sahaj ERP services...');

    // 1. Initialize SharedPreferences for caching configs
    SharedPreferences? sharedPrefs;
    try {
      sharedPrefs = await SharedPreferences.getInstance();
      debugPrint('[BOOT] SharedPreferences cache initialized.');
      logger.info('SharedPreferences cache initialized.');
    } catch (e, stack) {
      debugPrint('[BOOT ERROR] Failed to initialize SharedPreferences: $e');
      logger.error('Failed to initialize SharedPreferences', e, stack);
    }

    // 2. Initialize Firebase (non-blocking with timeout to prevent startup hang)
    try {
      if (sharedPrefs != null) {
        final apiKey = sharedPrefs.getString('firebase_api_key');
        final projectId = sharedPrefs.getString('firebase_project_id');
        final appId = sharedPrefs.getString('firebase_app_id');
        final senderId = sharedPrefs.getString('firebase_sender_id');
        final storageBucket = sharedPrefs.getString('firebase_storage_bucket');

        if (apiKey != null && projectId != null && appId != null) {
          await Firebase.initializeApp(
            options: FirebaseOptions(
              apiKey: apiKey,
              projectId: projectId,
              appId: appId,
              messagingSenderId: senderId ?? '',
              storageBucket: storageBucket ?? '$projectId.appspot.com',
            ),
          ).timeout(const Duration(seconds: 1));
          debugPrint('[BOOT] Firebase Core dynamically initialized for Project: $projectId');
          logger.info('Firebase Core dynamically initialized for Project: $projectId');
        } else {
          debugPrint('[BOOT] Firebase API keys not set. Bypassing Firebase init to launch instantly.');
          logger.info('Firebase API keys not set. Bypassing Firebase init to launch instantly.');
        }
      }
    } catch (e, stack) {
      debugPrint('[BOOT WARNING] Firebase initialization bypassed or timed out: $e');
      logger.warning('Firebase initialization bypassed or timed out: $e');
    }

    // 3. Initialize Isar database storage
    final dbService = DatabaseService();
    try {
      await dbService.init(sharedPrefs);
      debugPrint('[BOOT] Isar Database initialized successfully.');
    } catch (e, stack) {
      debugPrint('[BOOT ERROR] Database initialization failed: $e');
      logger.error('Database initialization failed.', e, stack);
    }

    // Run application wrapped in ProviderScope, overriding late dependencies
    runApp(
      ProviderScope(
        overrides: [
          if (sharedPrefs != null)
            sharedPreferencesProvider.overrideWithValue(sharedPrefs),
          databaseServiceProvider.overrideWithValue(dbService),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('[RUN ZONED GUARDED UNCAUGHT ERROR] $error\n$stack');
    logger.error('Uncaught Zoned Error', error, stack);
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if database service is initialized
    final dbService = ref.read(databaseServiceProvider);
    
    // Catch database initialization error
    bool isDbInitialized = false;
    String? initError;
    try {
      final _ = dbService.isar;
      isDbInitialized = true;
    } catch (e) {
      initError = dbService.initErrorMessage ?? e.toString();
    }

    if (!isDbInitialized) {
      return MaterialApp(
        title: 'Business Sahaj ERP - Database Error',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Database Initialization Failed',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Text(
                      initError ?? 'Unknown database error occurred during startup.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'monospace', color: Colors.redAccent),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Please make sure that the app has all required permissions and the device storage is not full.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Initialize background Sync Manager
    try {
      ref.read(syncManagerProvider).initialize();
    } catch (e, stack) {
      debugPrint('[BOOT ERROR] Failed to initialize sync manager on boot: $e');
      logger.error('Failed to initialize sync manager on boot', e, stack);
    }

    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Business Sahaj ERP',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
