import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../state/auth_provider.dart';
import '../theme/theme.dart';

/// Direct port of `src/screens/PrivacyScreen.tsx`.
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _profileOn = true;
  bool _dmOn = true;
  bool _searchOn = false;
  bool _anonOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    data.fetchPrivacySettings(userId).then((s) {
      if (!mounted) return;
      setState(() {
        _profileOn = s['public_profile'] as bool? ?? _profileOn;
        _dmOn = s['allow_direct_messages'] as bool? ?? _dmOn;
        _searchOn = s['show_in_search'] as bool? ?? _searchOn;
        _anonOn = s['post_anonymously_default'] as bool? ?? _anonOn;
      });
    }).catchError((_) {});
  }

  Future<void> _handleSave() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      await data.updatePrivacySettings(userId, {
        'public_profile': _profileOn,
        'allow_direct_messages': _dmOn,
        'show_in_search': _searchOn,
        'post_anonymously_default': _anonOn,
      });
    }
    if (!mounted) return;
    context.goBack();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  const Text(
                    'Privacy',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        children: [
                          _PrivacyRow(
                            title: 'Public profile',
                            hint: 'Allow other members to view your profile',
                            value: _profileOn,
                            showBorder: true,
                            onChanged: (v) => setState(() => _profileOn = v),
                          ),
                          _PrivacyRow(
                            title: 'Allow direct messages',
                            hint: 'Members can message you privately',
                            value: _dmOn,
                            showBorder: true,
                            onChanged: (v) => setState(() => _dmOn = v),
                          ),
                          _PrivacyRow(
                            title: 'Show me in search',
                            hint: 'Appear in member directory results',
                            value: _searchOn,
                            showBorder: true,
                            onChanged: (v) => setState(() => _searchOn = v),
                          ),
                          _PrivacyRow(
                            title: 'Post anonymously by default',
                            hint: 'Hide your name on new posts',
                            value: _anonOn,
                            showBorder: false,
                            onChanged: (v) => setState(() => _anonOn = v),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 56,
                      child: Material(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: _handleSave,
                          child: const Center(
                            child: Text(
                              'Save',
                              style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
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
}

class _PrivacyRow extends StatelessWidget {
  final String title;
  final String hint;
  final bool value;
  final bool showBorder;
  final ValueChanged<bool> onChanged;

  const _PrivacyRow({
    required this.title,
    required this.hint,
    required this.value,
    required this.showBorder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: showBorder
            ? const Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary)),
                const SizedBox(height: 2),
                Text(hint,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.mutedForeground)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: const Color(0xFFE2E8F0),
            thumbColor: const WidgetStatePropertyAll(AppColors.card),
          ),
        ],
      ),
    );
  }
}
