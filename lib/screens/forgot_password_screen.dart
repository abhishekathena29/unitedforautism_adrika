import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../navigation/nav.dart';
import '../state/auth_provider.dart';
import '../theme/theme.dart';
import '../utils/utils.dart';

/// Direct port of `src/screens/ForgotPasswordScreen.tsx`.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isSubmitted = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
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

  Future<void> _handleSubmit() async {
    final email = _emailController.text;
    if (!isValidEmail(email)) return;
    setState(() => _loading = true);
    final result = await context.read<AuthProvider>().resetPassword(email);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.error != null) {
      await _showAlert('Could not send reset link', result.error!);
      return;
    }
    setState(() => _isSubmitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final email = _emailController.text;
    final canSubmit = email.trim().isNotEmpty;

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
                        'Reset password',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Get back to your community',
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
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child:
                    _isSubmitted ? _buildSuccess(email) : _buildForm(canSubmit),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool canSubmit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Enter the email address associated with your account, and we'll send you a link to reset your password.",
          style: TextStyle(
              fontSize: 15, color: AppColors.mutedForeground, height: 22 / 15),
        ),
        const SizedBox(height: 28),
        const Text(
          'Email Address',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.mail,
                  color: AppColors.mutedForeground, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 16, color: AppColors.ink),
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                    hintStyle: TextStyle(color: AppColors.mutedForeground),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: canSubmit ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(6),
              boxShadow: AppShadows.card,
            ),
            child: Opacity(
              opacity: canSubmit ? 1 : 0.7,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: (!canSubmit || _loading) ? null : _handleSubmit,
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: AppColors.secondary, strokeWidth: 2),
                          )
                        : const Text(
                            'Send reset link',
                            style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSuccess(String email) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            margin: const EdgeInsets.only(bottom: 24),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.tertiary,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.checkCircle,
                color: AppColors.primary, size: 64),
          ),
          const Text(
            'Check your email',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary),
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.mutedForeground,
                  height: 24 / 15),
              children: [
                const TextSpan(
                    text: "We've sent password reset instructions to "),
                TextSpan(
                  text: email,
                  style: const TextStyle(
                      color: AppColors.secondary, fontWeight: FontWeight.w700),
                ),
                const TextSpan(
                    text: '. Please check your inbox and your spam folder.'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
                boxShadow: AppShadows.card,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => context.pushNamed('Login'),
                  child: const Center(
                    child: Text(
                      'Return to login',
                      style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => setState(() => _isSubmitted = false),
            child: const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Try another email address',
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
