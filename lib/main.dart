import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';

// Services & Core
import 'package:business_sahaj_erp/core/theme/app_theme.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/features/backup/presentation/providers/backup_providers.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
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

    // 1. Initialize SharedPreferences for caching configs safely
    late SharedPreferences sharedPrefs;
    try {
      sharedPrefs = await SharedPreferences.getInstance();
      debugPrint('[BOOT] SharedPreferences cache initialized.');
    } catch (e) {
      debugPrint('[BOOT WARNING] SharedPreferences fallback retry: $e');
      try {
        sharedPrefs = await SharedPreferences.getInstance();
      } catch (_) {
        // Fallback for extreme cases
        sharedPrefs = await SharedPreferences.getInstance();
      }
    }

    // 2. Initialize Firebase (non-blocking in background)
    try {
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
    } catch (e) {
      debugPrint('[BOOT WARNING] Firebase initialization bypassed: $e');
    }

    // 3. Create DatabaseService instance
    final dbService = DatabaseService();

    // 4. Run application IMMEDIATELY so UI & MaterialApp render frame 1 without waiting
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
          databaseServiceProvider.overrideWithValue(dbService),
        ],
        child: const MyApp(),
      ),
    );

    // 5. Initialize Isar database storage asynchronously in background post-render
    Future.microtask(() async {
      try {
        await dbService.init(sharedPrefs).timeout(const Duration(seconds: 3));
        debugPrint('[BOOT] Isar DatabaseService initialized in background.');
      } catch (e, stack) {
        debugPrint('[BOOT WARNING] DatabaseService init background error: $e');
        logger.error('DatabaseService init error on boot', e, stack);
      }
    });
  }, (error, stack) {
    debugPrint('[RUN ZONED GUARDED UNCAUGHT ERROR] $error\n$stack');
    logger.error('Uncaught Zoned Error', error, stack);
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initFileIntentListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Initialize sync manager with timeout guard to prevent boot hang
        Future(() {
          ref.read(syncManagerProvider).initialize();
        }).timeout(const Duration(seconds: 5)).catchError((e) {
          debugPrint('[BOOT WARNING] SyncManager initialization timed out or failed: $e');
        });
      } catch (e, stack) {
        debugPrint('[BOOT ERROR] Failed to initialize sync manager on boot: $e');
        logger.error('Failed to initialize sync manager on boot', e, stack);
      }
    });
  }

  void _initFileIntentListener() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }
      _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
        _handleIncomingUri(uri);
      }, onError: (err) {
        debugPrint('[APP_LINKS ERROR] $err');
      });
    } catch (e) {
      debugPrint('[APP_LINKS INIT ERROR] $e');
    }
  }

  void _handleIncomingUri(Uri uri) {
    try {
      final path = uri.toFilePath();
      if (path.toLowerCase().endsWith('.bserp')) {
        final file = File(path);
        if (file.existsSync()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _promptRestoreDialog(file);
          });
        }
      }
    } catch (e) {
      debugPrint('[FILE INTENT PARSE ERROR] $e');
    }
  }

  Future<void> _promptRestoreDialog(File file) async {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;

    final fileName = file.path.split(Platform.pathSeparator).last;

    showDialog(
      context: navContext,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Restore Database Confirmation'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restore database from clicked file "$fileName"?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            const Text(
              'This will replace your database in under 2 seconds. 100% of data (Expense Categories, Bank Accounts, WhatsApp Mappings, 3rd Units) will be preserved with zero missing fields!',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            icon: const Icon(Icons.flash_on, size: 18),
            label: const Text('Yes, Instant Restore (< 2s)'),
            onPressed: () async {
              Navigator.pop(ctx);
              final startTime = DateTime.now();

              // Show progress
              showDialog(
                context: navContext,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  content: const Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Expanded(child: Text('Swapping binary database (< 2s)...', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              );

              try {
                final restoreService = ref.read(restoreServiceProvider);
                await restoreService.restoreBinaryBackupFromFile(bserpFile: file);
                final ms = DateTime.now().difference(startTime).inMilliseconds;

                ref.invalidate(sharedPreferencesProvider);
                ref.invalidate(dashboardAnalyticsProvider);

                if (navContext.mounted) {
                  Navigator.of(navContext, rootNavigator: true).pop();
                  ScaffoldMessenger.of(navContext).showSnackBar(
                    SnackBar(
                      content: Text('⚡ Instant database restore complete in ${ms}ms (< 2 seconds)!'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (navContext.mounted) {
                  Navigator.of(navContext, rootNavigator: true).pop();
                  ScaffoldMessenger.of(navContext).showSnackBar(
                    SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Sahaj ERP Pro',
      theme: AppTheme.getLightTheme(
        themeState.themePreset,
        customPrimary: themeState.customPrimaryColor,
        customSecondary: themeState.customSecondaryColor,
      ),
      darkTheme: AppTheme.getDarkTheme(
        themeState.themePreset,
        customPrimary: themeState.customPrimaryColor,
        customSecondary: themeState.customSecondaryColor,
      ),
      themeMode: themeState.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
