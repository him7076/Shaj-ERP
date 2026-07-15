import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
              theme.colorScheme.primary.withRed(20).withBlue(160),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Visual decorative circle elements in background
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -50,
              child: Container(
                width: 400,
                height: 400,
                decoration: const BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo Container
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.business_center_rounded,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // App Name
                  const Text(
                    'Sahaj ERP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    'ENTERPRISE MANAGER SYSTEM',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 64),
                  // Modern Loading Indicator
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
