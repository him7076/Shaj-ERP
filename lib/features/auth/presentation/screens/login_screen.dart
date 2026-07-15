import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';
import 'package:business_sahaj_erp/core/widgets/error_dialog.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (success && mounted) {
        context.go('/dashboard');
      } else if (mounted) {
        final errorMsg = ref.read(authProvider).errorMessage ?? 'Login failed';
        ErrorDialog.show(
          context,
          title: 'Login Error',
          message: errorMsg,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      body: Row(
        children: [
          // Visual Banner for Tablet/Desktop
          if (!ResponsiveLayout.isMobile(context))
            Expanded(
              flex: isDesktop ? 6 : 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withRed(30).withBlue(160),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -80,
                      left: -80,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: const BoxDecoration(
                          color: Colors.white12,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -100,
                      right: -100,
                      child: Container(
                        width: 350,
                        height: 350,
                        decoration: const BoxDecoration(
                          color: Colors.white12,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.business_center_rounded,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'Sahaj ERP Suite',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Manage your billing, purchases, items inventory, and customer outstanding registers in a secure offline environment.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 18,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Login Form Section
          Expanded(
            flex: isDesktop ? 4 : 5,
            child: Container(
              color: theme.colorScheme.background,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Mobile App Logo
                          if (ResponsiveLayout.isMobile(context)) ...[
                            Container(
                              alignment: Alignment.center,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.business_center_rounded,
                                  size: 54,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sahaj ERP',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                          ],
                          
                          Text(
                            'Sign In',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onBackground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your administrator credentials below',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 36),
                          
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outlined, color: theme.colorScheme.primary),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 36),
                          
                          // Login Button
                          authState.status == AuthStatus.loading
                              ? const Center(child: CircularProgressIndicator())
                              : Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.primary.withRed(30).withBlue(160),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'LOG IN',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                          
                          const SizedBox(height: 32),
                          // Demo credentials tips
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.12)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 16, color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Demo Credentials',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Email: admin@sahaj.com   |   Password: admin123',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
