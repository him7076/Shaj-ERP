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
    // If you compile for web or mobile, uncomment or configure DefaultFirebaseOptions:
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await Firebase.initializeApp();
    logger.info('Firebase Core initialized successfully.');
  } catch (e) {
    logger.warning('Firebase initialization bypassed: Configuration files might be missing. Details: $e');
  }

  // 3. Initialize Isar database storage
  final dbService = DatabaseService();
  try {
    await dbService.init();
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
    // Initialize background Sync Manager
    ref.read(syncManagerProvider).initialize();

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
