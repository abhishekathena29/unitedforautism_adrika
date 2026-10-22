import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../state/auth_provider.dart';
import '../theme/theme.dart';
import '../utils/utils.dart';
import '../widgets/icon_badge.dart';

/// Direct port of `src/screens/NotificationsScreen.tsx`.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<DbNotification> _notifications = [];
  bool _loading = true;
  String? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final userId = requireUserId(auth.user?.id, auth.isGuest);
    if (userId != _userId) {
      _userId = userId;
      _load();
    }
  }

  Future<void> _load() async {
    if (_userId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await data.fetchNotifications(_userId!);
      if (!mounted) return;
      setState(() => _notifications = result);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handlePress(DbNotification n) async {
    if (!n.isRead) {
      await data.markNotificationRead(n.id);
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((x) => x.id == n.id
                ? DbNotification(
                    id: x.id,
                    type: x.type,
                    title: x.title,
                    body: x.body,
                    icon: x.icon,
                    isRead: true,
                    createdAt: x.createdAt,
                  )
                : x)
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Mentions, replies, reminders',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    )
                  : _notifications.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text(
                              'No notifications yet.',
                              style:
                                  TextStyle(color: AppColors.mutedForeground),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final n = _notifications[index];
                            return GestureDetector(
                              onTap: () => _handlePress(n),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: n.isRead
                                      ? AppColors.card
                                      : const Color(0xFFF0FBF7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: n.isRead
                                        ? AppColors.border
                                        : AppColors.primary,
                                  ),
                                  boxShadow: AppShadows.card,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      margin: const EdgeInsets.only(right: 12),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.tertiary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(notificationIcon(n.icon),
                                          color: AppColors.secondary, size: 16),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            n.title,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                          if (n.body != null &&
                                              n.body!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              n.body!,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors
                                                      .mutedForeground),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            timeAgo(n.createdAt),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppColors.mutedForeground),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!n.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(left: 8),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
