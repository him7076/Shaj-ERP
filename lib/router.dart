import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Screens
import 'package:business_sahaj_erp/features/auth/presentation/screens/splash_screen.dart';
import 'package:business_sahaj_erp/features/auth/presentation/screens/login_screen.dart';
import 'package:business_sahaj_erp/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:business_sahaj_erp/features/parties/presentation/screens/parties_screen.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/items_screen.dart';
import 'package:business_sahaj_erp/features/orders/presentation/screens/orders_screen.dart';
import 'package:business_sahaj_erp/features/sales/presentation/screens/sales_screen.dart';
import 'package:business_sahaj_erp/features/reports/presentation/screens/reports_screen.dart';
import 'package:business_sahaj_erp/features/settings/presentation/screens/settings_screen.dart';
import 'package:business_sahaj_erp/features/backup/presentation/screens/backup_screen.dart';
import 'package:business_sahaj_erp/features/backup/presentation/screens/sync_center_screen.dart';
import 'package:business_sahaj_erp/features/purchases/presentation/screens/purchases_screen.dart';
import 'package:business_sahaj_erp/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/transactions_screen.dart';

// Shell components
import 'package:business_sahaj_erp/core/widgets/main_layout.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';

// Router Provider
final routerProvider = Provider<GoRouter>((ref) {
  // Listen to Auth State changes to trigger re-routing evaluation
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/parties',
            name: 'parties',
            builder: (context, state) => const PartiesScreen(),
          ),
          GoRoute(
            path: '/items',
            name: 'items',
            builder: (context, state) => const ItemsScreen(),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) {
              final create = state.uri.queryParameters['create'] == 'true';
              return OrdersScreen(createImmediately: create);
            },
          ),
          GoRoute(
            path: '/sales',
            name: 'sales',
            builder: (context, state) {
              final create = state.uri.queryParameters['create'] == 'true';
              return SalesScreen(createImmediately: create);
            },
          ),
          GoRoute(
            path: '/purchases',
            name: 'purchases',
            builder: (context, state) {
              final create = state.uri.queryParameters['create'] == 'true';
              return PurchasesScreen(createImmediately: create);
            },
          ),
          GoRoute(
            path: '/expenses',
            name: 'expenses',
            builder: (context, state) {
              final create = state.uri.queryParameters['create'] == 'true';
              return ExpensesScreen(createImmediately: create);
            },
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/backup',
            name: 'backup',
            builder: (context, state) => const BackupScreen(),
          ),
          GoRoute(
            path: '/sync-center',
            name: 'sync-center',
            builder: (context, state) => const SyncCenterScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/receipts',
            name: 'receipts',
            builder: (context, state) {
              final create = state.uri.queryParameters['create'] == 'true';
              return TransactionsScreen(lockedType: 'Receipt', createImmediately: create);
            },
          ),
          GoRoute(
            path: '/payments',
            name: 'payments',
            builder: (context, state) {
              final create = state.uri.queryParameters['create'] == 'true';
              return TransactionsScreen(lockedType: 'Payment', createImmediately: create);
            },
          ),
          GoRoute(
            path: '/credit-notes',
            name: 'credit-notes',
            builder: (context, state) {
              final create = state.uri.queryParameters['create'] == 'true';
              return TransactionsScreen(lockedType: 'Credit Note', createImmediately: create);
            },
          ),
          GoRoute(
            path: '/debit-notes',
            name: 'debit-notes',
            builder: (context, state) {
              final create = state.uri.queryParameters['create'] == 'true';
              return TransactionsScreen(lockedType: 'Debit Note', createImmediately: create);
            },
          ),
          GoRoute(
            path: '/party-transfers',
            name: 'party-transfers',
            builder: (context, state) {
              final create = state.uri.queryParameters['create'] == 'true';
              return TransactionsScreen(lockedType: 'Transfer', createImmediately: create);
            },
          ),
          GoRoute(
            path: '/other-incomes',
            name: 'other-incomes',
            builder: (context, state) {
              final create = state.uri.queryParameters['create'] == 'true';
              return TransactionsScreen(lockedType: 'Other Income', createImmediately: create);
            },
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final status = authState.status;

      final isLoggingIn = state.matchedLocation == '/login';
      final isSplashing = state.matchedLocation == '/splash';

      // Keep showing splash if auth notifier isn't initialized yet
      if (status == AuthStatus.initial) {
        return isSplashing ? null : '/splash';
      }

      // If user is unauthenticated, force them to login
      if (status == AuthStatus.unauthenticated) {
        return isLoggingIn ? null : '/login';
      }

      // If user is authenticated, redirect them out of splash/login to dashboard
      if (status == AuthStatus.authenticated) {
        if (isLoggingIn || isSplashing) {
          return '/dashboard';
        }
      }

      // No redirect necessary
      return null;
    },
  );
});
