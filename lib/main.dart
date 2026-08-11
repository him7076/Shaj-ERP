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

    debugPrint('[BOOT] Launching Business Sahaj ERP...');

    // 1. Initialize SharedPreferences for caching configs (1s timeout)
    SharedPreferences? sharedPrefs;
    try {
      sharedPrefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 1));
      debugPrint('[BOOT] SharedPreferences cache initialized.');
    } catch (e) {
      debugPrint('[BOOT WARNING] SharedPreferences init bypassed: $e');
    }

    // 2. Initialize Firebase (non-blocking in background)
    try {
      if (sharedPrefs != null) {
        final apiKey = sharedPrefs.getString('firebase_api_key');
        final projectId = sharedPrefs.getString('firebase_project_id');
        final appId = sharedPrefs.getString('firebase_app_id');
        final senderId = sharedPrefs.getString('firebase_sender_id');
        final storageBucket = sharedPrefs.getString('firebase_storage_bucket');

        if (apiKey != null && projectId != null && appId != null) {
          Firebase.initializeApp(
            options: FirebaseOptions(
              apiKey: apiKey,
              projectId: projectId,
              appId: appId,
              messagingSenderId: senderId ?? '',
              storageBucket: storageBucket ?? '$projectId.appspot.com',
            ),
          ).catchError((e) {
            debugPrint('[BOOT WARNING] Background Firebase init: $e');
          });
        }
      }
    } catch (e) {
      debugPrint('[BOOT WARNING] Firebase initialization bypassed: $e');
    }

    // 3. Initialize Isar database storage (non-blocking in background)
    final dbService = DatabaseService();
    dbService.init(sharedPrefs).catchError((e) {
      debugPrint('[BOOT WARNING] Non-fatal DatabaseService init error: $e');
    });

    // Run application IMMEDIATELY - 0ms delay!
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
    // Initialize background Sync Manager
    try {
      ref.read(syncManagerProvider).initialize();
    } catch (e, stack) {
      debugPrint('[BOOT ERROR] Failed to initialize sync manager on boot: $e');
      logger.error('Failed to initialize sync manager on boot', e, stack);
    }

    final themeState = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Business Sahaj ERP',
      theme: AppTheme.getLightTheme(themeState.gradientPreset),
      darkTheme: AppTheme.getDarkTheme(themeState.gradientPreset),
      themeMode: themeState.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
