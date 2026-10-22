import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/view_models.dart';
import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../state/auth_provider.dart';
import '../theme/theme.dart';

/// Direct port of `src/screens/ProfileScreen.tsx`.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  data.ProfileStats _stats = data.ProfileStats(posts: 0, comments: 0, saved: 0);
  int _rsvpCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    data.fetchProfileStats(userId).then((s) {
      if (mounted) setState(() => _stats = s);
    });
    data.fetchUserRsvps(userId).then((s) {
      if (mounted) setState(() => _rsvpCount = s.length);
    });
  }

  Future<void> _showLogoutModal() {
    return showDialog<void>(
      context: context,
      barrierColor: const Color.fromRGBO(14, 31, 26, 0.5),
      builder: (dialogContext) => _ConfirmModal(
        iconBg: const Color(0xFFFDECEC),
        icon: const Icon(LucideIcons.logOut,
            color: AppColors.destructive, size: 28),
        title: 'Log out?',
        subtitle: "You'll need to log back in to access your community.",
        confirmLabel: 'Yes, log out',
        onConfirm: () => _handleLogout(dialogContext),
      ),
    );
  }

  Future<void> _showDeleteModal() {
    return showDialog<void>(
      context: context,
      barrierColor: const Color.fromRGBO(14, 31, 26, 0.5),
      builder: (dialogContext) => _ConfirmModal(
        iconBg: const Color(0xFFFDECEC),
        icon: const Icon(LucideIcons.trash2,
            color: AppColors.destructive, size: 28),
        title: 'Delete account?',
        subtitle:
            'This is permanent and cannot be undone. All your posts, comments, and data will be erased.',
        confirmLabel: 'Delete my account',
        onConfirm: () => _handleDeleteAccount(dialogContext),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil('Welcome', (route) => false);
  }

  Future<void> _handleDeleteAccount(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Deletion'),
        content:
            const Text('Your account deletion request has been submitted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleRowPress(_MenuRow row) {
    if (row.isTab) {
      MainTabsController.instance.switchTo(row.to);
    } else {
      context.pushNamed(row.to);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    final displayName = profile?.displayName ?? 'Guest';
    final initials = profile?.initials ??
        displayName
            .substring(0, displayName.length >= 2 ? 2 : displayName.length)
            .toUpperCase();
    final roleCity = [
      profile?.role != null && profile!.role.isNotEmpty
          ? formatRole(profile.role)
          : null,
      profile?.city,
    ].where((e) => e != null && e.isNotEmpty).join(' · ');

    final statItems = [
      _StatItem('POSTS', _stats.posts, LucideIcons.fileText),
      _StatItem('COMMENTS', _stats.comments, LucideIcons.messageSquare),
      _StatItem('SAVED', _stats.saved, LucideIcons.bookmark),
    ];

    final menuRows = [
      _MenuRow('CalmKit', LucideIcons.heart, 'My Calm Kit',
          'Manage your sensory tools'),
      _MenuRow('EventsTab', LucideIcons.calendar, 'My events',
          '$_rsvpCount upcoming RSVPs',
          isTab: true),
      _MenuRow('MembersDirectory', LucideIcons.users, 'Members directory',
          'Browse the community'),
      _MenuRow('SavedPosts', LucideIcons.bookmark, 'Saved posts',
          'Things you bookmarked'),
      _MenuRow('Settings', LucideIcons.settings, 'Settings',
          'Account, privacy, notifications'),
    ];

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary),
                  ),
                  GestureDetector(
                    onTap: () => context.pushNamed('Settings'),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.card,
                      ),
                      child: const Icon(LucideIcons.settings,
                          color: AppColors.secondary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.card,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                margin: const EdgeInsets.only(right: 16),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            displayName,
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.secondary),
                                          ),
                                        ),
                                        if (profile?.isVerified ?? false) ...[
                                          const SizedBox(width: 4),
                                          const Icon(LucideIcons.badgeCheck,
                                              color: AppColors.primary,
                                              size: 16),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      roleCity.isNotEmpty
                                          ? roleCity
                                          : 'Community member',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.mutedForeground),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (profile?.bio != null && profile!.bio!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                '"${profile.bio}"',
                                style: const TextStyle(
                                    fontSize: 15,
                                    color: Color.fromRGBO(14, 31, 26, 0.85),
                                    height: 22 / 15),
                              ),
                            ),
                          Container(
                            margin: const EdgeInsets.only(top: 20),
                            padding: const EdgeInsets.only(top: 16),
                            decoration: const BoxDecoration(
                              border: Border(
                                  top: BorderSide(color: AppColors.border)),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: () => context.pushNamed('EditProfile'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: AppColors.secondary),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (var i = 0; i < statItems.length; i++) ...[
                          if (i != 0) const SizedBox(width: 12),
                          Expanded(child: _StatBox(item: statItems[i])),
                        ],
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < menuRows.length; i++)
                            _MenuRowTile(
                              row: menuRows[i],
                              showBorder: i != menuRows.length - 1,
                              onTap: () => _handleRowPress(menuRows[i]),
                            ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _showLogoutModal,
                      child: Container(
                        margin: const EdgeInsets.only(top: 16),
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(LucideIcons.logOut,
                                color: AppColors.destructive, size: 16),
                            SizedBox(width: 8),
                            Text('Log out',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.destructive)),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showDeleteModal,
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECEC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF8B4B4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(LucideIcons.trash2,
                                color: AppColors.destructive, size: 14),
                            SizedBox(width: 8),
                            Text('Delete account',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.destructive)),
                          ],
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

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  const _StatItem(this.label, this.value, this.icon);
}

class _StatBox extends StatelessWidget {
  final _StatItem item;
  const _StatBox({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(item.icon, color: AppColors.secondary, size: 16),
          const SizedBox(height: 6),
          Text(
            '${item.value}',
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.mutedForeground,
                letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

class _MenuRow {
  final String to;
  final IconData icon;
  final String label;
  final String hint;
  final bool isTab;
  const _MenuRow(this.to, this.icon, this.label, this.hint,
      {this.isTab = false});
}

class _MenuRowTile extends StatelessWidget {
  final _MenuRow row;
  final bool showBorder;
  final VoidCallback onTap;
  const _MenuRowTile(
      {required this.row, required this.showBorder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: showBorder
              ? const Border(bottom: BorderSide(color: AppColors.border))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.tertiary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(row.icon, color: AppColors.secondary, size: 16),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.label,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary)),
                  const SizedBox(height: 2),
                  Text(row.hint,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.mutedForeground)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                color: AppColors.mutedForeground, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ConfirmModal extends StatelessWidget {
  final Color iconBg;
  final Widget icon;
  final String title;
  final String subtitle;
  final String confirmLabel;
  final VoidCallback onConfirm;

  const _ConfirmModal({
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(bottom: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: icon,
            ),
            Text(title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                  height: 20 / 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Material(
                color: AppColors.destructive,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onConfirm,
                  child: Center(
                    child: Text(confirmLabel,
                        style: const TextStyle(
                            color: AppColors.card,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Material(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text('Cancel',
                          style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
