import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../state/auth_provider.dart';
import '../theme/theme.dart';

/// Direct port of `src/screens/SettingsScreen.tsx`.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _repliesOn = true;
  bool _remindersOn = true;
  bool _digestOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    data.fetchNotificationSettings(userId).then((s) {
      if (!mounted) return;
      setState(() {
        _repliesOn = s['replies_and_mentions'] as bool? ?? _repliesOn;
        _remindersOn = s['event_reminders'] as bool? ?? _remindersOn;
        _digestOn = s['weekly_digest'] as bool? ?? _digestOn;
      });
    }).catchError((_) {});
  }

  Future<void> _saveSetting(Map<String, bool> patch) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    await data.updateNotificationSettings(userId, patch);
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
                    'Settings',
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
                    _Section(
                      title: 'ACCOUNT',
                      child: Column(
                        children: [
                          _NavRow(
                            label: 'Edit profile',
                            showBorder: true,
                            onTap: () => context.pushNamed('EditProfile'),
                          ),
                          _NavRow(
                            label: 'Privacy',
                            showBorder: false,
                            onTap: () => context.pushNamed('Privacy'),
                          ),
                        ],
                      ),
                    ),
                    _Section(
                      title: 'NOTIFICATIONS',
                      child: Column(
                        children: [
                          _SwitchRow(
                            label: 'Replies & mentions',
                            value: _repliesOn,
                            showBorder: true,
                            onChanged: (v) {
                              setState(() => _repliesOn = v);
                              _saveSetting({'replies_and_mentions': v});
                            },
                          ),
                          _SwitchRow(
                            label: 'Event reminders',
                            value: _remindersOn,
                            showBorder: true,
                            onChanged: (v) {
                              setState(() => _remindersOn = v);
                              _saveSetting({'event_reminders': v});
                            },
                          ),
                          _SwitchRow(
                            label: 'Weekly digest',
                            value: _digestOn,
                            showBorder: false,
                            onChanged: (v) {
                              setState(() => _digestOn = v);
                              _saveSetting({'weekly_digest': v});
                            },
                          ),
                        ],
                      ),
                    ),
                    _Section(
                      title: 'COMMUNITY',
                      child: Column(
                        children: [
                          _NavRow(
                            label: 'Community guidelines',
                            showBorder: true,
                            onTap: () =>
                                context.pushNamed('CommunityGuidelines'),
                          ),
                          _NavRow(
                            label: 'Report an issue',
                            showBorder: false,
                            onTap: () => context.pushNamed('ReportIssue'),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'United for Autism · v1.0',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.mutedForeground),
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

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.mutedForeground,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String label;
  final bool showBorder;
  final VoidCallback onTap;
  const _NavRow(
      {required this.label, required this.showBorder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: showBorder
              ? const Border(bottom: BorderSide(color: AppColors.border))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary)),
            const Icon(LucideIcons.chevronRight,
                color: AppColors.mutedForeground, size: 16),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final bool showBorder;
  final ValueChanged<bool> onChanged;
  const _SwitchRow(
      {required this.label,
      required this.value,
      required this.showBorder,
      required this.onChanged});

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary)),
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
