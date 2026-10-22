import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../navigation/nav.dart';
import '../state/auth_provider.dart';
import '../theme/theme.dart';
import '../utils/utils.dart';

/// Direct port of `src/screens/LoginScreen.tsx`.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showAlert(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (!isValidEmail(email)) {
      await _showAlert(
          'Check your email', 'Please enter an email with an @ symbol.');
      return;
    }
    if (password.isEmpty) {
      await _showAlert('Missing password', 'Please enter your password.');
      return;
    }

    setState(() => _loading = true);
    final result = await context.read<AuthProvider>().signIn(email, password);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.error != null) {
      await _showAlert('Could not log in', result.error!);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('MainTabs', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.goBack(),
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.card,
                      ),
                      child: const Icon(LucideIcons.chevronLeft,
                          color: AppColors.secondary, size: 24),
                    ),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Log in to your community',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputGroup(
                      label: 'Email',
                      controller: _emailController,
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                    ),
                    _buildInputGroup(
                      label: 'Password',
                      controller: _passwordController,
                      hint: '••••••••',
                      obscureText: true,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: GestureDetector(
                          onTap: () => context.pushNamed('ForgotPassword'),
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: _loading ? null : _handleLogin,
                            child: Center(
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: AppColors.secondary,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Log in',
                                      style: TextStyle(
                                        color: AppColors.secondary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: () => context.pushNamed('Signup'),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                                fontSize: 14, color: AppColors.mutedForeground),
                            children: [
                              TextSpan(text: 'New here? '),
                              TextSpan(
                                text: 'Create account',
                                style: TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputGroup({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool autocorrect = true,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            autocorrect: autocorrect,
            textCapitalization: keyboardType == TextInputType.emailAddress
                ? TextCapitalization.none
                : TextCapitalization.sentences,
            obscureText: obscureText,
            style: const TextStyle(fontSize: 16, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.mutedForeground),
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
