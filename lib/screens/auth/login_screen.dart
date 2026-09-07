import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/bouncy.dart';
import '../home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _continueToApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  Future<void> _submit(AuthProvider auth) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;

    final success = _isSignUp ? await auth.signUp(email, password) : await auth.signIn(email, password);
    if (success && mounted) _continueToApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final loading = auth.status == AuthStatus.loading;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Center(child: const AppLogo(size: 56).animate().fadeIn().scale(begin: const Offset(0.85, 0.85))),
                  const SizedBox(height: 20),
                  const Text(
                    'WeatherGPT',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isSignUp ? 'Create an account to get started' : 'Sign in to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13.5),
                  ),
                  const SizedBox(height: 40),

                  if (!auth.isSupabaseConfigured)
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Text(
                        'Account sign-in isn\'t configured for this build yet — continue as guest below to use the full app.',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12.5, height: 1.4),
                      ),
                    ),

                  _AuthField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    enabled: auth.isSupabaseConfigured && !loading,
                  ),
                  const SizedBox(height: 14),
                  _AuthField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    enabled: auth.isSupabaseConfigured && !loading,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),

                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      auth.errorMessage!,
                      style: const TextStyle(color: Color(0xFFE0837E), fontSize: 12.5),
                    ),
                  ],

                  const SizedBox(height: 26),
                  Bouncy(
                    onTap: (auth.isSupabaseConfigured && !loading) ? () => _submit(auth) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: auth.isSupabaseConfigured ? AppColors.gold : AppColors.gold.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: loading
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyDeep),
                              )
                            : Text(
                                _isSignUp ? 'Create account' : 'Sign in',
                                style: const TextStyle(color: AppColors.navyDeep, fontWeight: FontWeight.w700, fontSize: 14.5),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: auth.isSupabaseConfigured
                        ? () => setState(() {
                              _isSignUp = !_isSignUp;
                            })
                        : null,
                    child: Text(
                      _isSignUp ? 'Already have an account? Sign in' : "Don't have an account? Create one",
                      style: TextStyle(color: Colors.white.withOpacity(auth.isSupabaseConfigured ? 0.75 : 0.3), fontSize: 13),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      auth.continueAsGuest();
                      _continueToApp();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(color: Colors.white.withOpacity(0.25)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Continue as guest', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.enabled = true,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool enabled;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      style: const TextStyle(color: Colors.white, fontSize: 14.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
        ),
      ),
    );
  }
}
