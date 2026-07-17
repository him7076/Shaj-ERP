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

void main() async {
  // Ensure that Flutter widget binding is initialized before asynchronous calls
  WidgetsFlutterBinding.ensureInitialized();

  logger.info('Initializing Business Sahaj ERP services...');

  // 1. Initialize SharedPreferences for caching configs
  SharedPreferences? sharedPrefs;
  try {
    sharedPrefs = await SharedPreferences.getInstance();
    logger.info('SharedPreferences cache initialized.');
  } catch (e) {
    logger.error('Failed to initialize SharedPreferences', e);
  }

  // 2. Initialize Firebase (with try-catch to avoid crashes during early setup without google-services config)
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
        );
        logger.info('Firebase Core dynamically initialized for Project: $projectId');
      } else {
        await Firebase.initializeApp();
        logger.info('Firebase Core initialized with default config.');
      }
    } else {
      await Firebase.initializeApp();
      logger.info('Firebase Core initialized successfully.');
    }
  } catch (e) {
    logger.warning('Firebase initialization bypassed: Configuration files might be missing. Details: $e');
  }

  // 3. Initialize Isar database storage
  final dbService = DatabaseService();
  try {
    await dbService.init(sharedPrefs);
  } catch (e) {
    logger.error('Database initialization failed.', e);
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
      initError = e.toString();
    }

    if (!isDbInitialized) {
      return MaterialApp(
        title: 'Business Sahaj ERP - Crash',
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
    } catch (e) {
      logger.error('Failed to initialize sync manager on boot', e);
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
