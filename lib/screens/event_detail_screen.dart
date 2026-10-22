import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/view_models.dart';
import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../state/auth_provider.dart';
import '../theme/theme.dart';
import '../utils/utils.dart';

class _Discussion {
  final String author;
  final String initials;
  final String time;
  final String body;

  _Discussion(
      {required this.author,
      required this.initials,
      required this.time,
      required this.body});
}

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  String? _loadedForId;
  EventView? _event;
  bool _isGoing = false;
  _Discussion? _discussion;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final eventId = (routeArgs(context)['id'] as String?) ?? '';
    if (_loadedForId != eventId) {
      _loadedForId = eventId;
      _load(eventId);
    }
  }

  Future<void> _load(String eventId) async {
    if (eventId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final userId = requireUserId(auth.user?.id, auth.isGuest);
    try {
      final row = await data.fetchEvent(eventId);
      if (row != null && mounted) {
        setState(() => _event = mapEvent(row));
      }
      final comments = await data.fetchComments('event', eventId);
      if (comments.isNotEmpty && mounted) {
        final c = comments.first;
        final name = c.authorDisplayName;
        setState(() {
          _discussion = _Discussion(
            author: name,
            initials: name.length > 2
                ? name.substring(0, 2).toUpperCase()
                : name.toUpperCase(),
            time: timeAgo(c.createdAt),
            body: c.text,
          );
        });
      }
      if (userId != null) {
        final rsvps = await data.fetchUserRsvps(userId);
        if (mounted) setState(() => _isGoing = rsvps.contains(eventId));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleRsvp() async {
    final auth = context.read<AuthProvider>();
    final userId = requireUserId(auth.user?.id, auth.isGuest);
    final event = _event;
    if (userId == null || event == null) return;
    await data.toggleEventRsvp(userId, event.id, _isGoing);
    setState(() => _isGoing = !_isGoing);
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    if (_loading || event == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 240,
                    child: Stack(
                      children: [
                        Container(
                            width: double.infinity,
                            height: 240,
                            color: const Color(0xFFD1F4EA)),
                        Positioned(
                          top: 56,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              event.type,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Icon(event.icon,
                                color: AppColors.secondary, size: 80),
                          ),
                        ),
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20, top: 0),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: GestureDetector(
                                onTap: () => context.goBack(),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(LucideIcons.chevronLeft,
                                      color: AppColors.secondary, size: 24),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                            height: 32 / 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hosted by ${event.host}',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.mutedForeground),
                        ),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            _InfoCard(
                              icon: LucideIcons.calendar,
                              label: 'When',
                              value: event.date,
                            ),
                            const SizedBox(height: 12),
                            _InfoCard(
                              icon: event.isVirtual
                                  ? LucideIcons.video
                                  : LucideIcons.mapPin,
                              label: event.isVirtual ? 'Virtual' : 'Where',
                              value: event.location,
                            ),
                            const SizedBox(height: 12),
                            _InfoCard(
                              icon: LucideIcons.users,
                              label: 'Going',
                              value:
                                  '${event.rsvps + (_isGoing ? 1 : 0)} people',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'About this event',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.description.isNotEmpty
                              ? event.description
                              : 'No description provided.',
                          style: TextStyle(
                              fontSize: 15,
                              color: AppColors.ink.withValues(alpha: 0.85),
                              height: 24 / 15),
                        ),
                        if (_discussion != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.messageCircle,
                                    color: AppColors.secondary, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Discussion',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: AppShadows.card,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.tertiary,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        _discussion!.initials,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.secondary),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _discussion!.author,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.secondary),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _discussion!.time,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppColors.mutedForeground),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _discussion!.body,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.ink,
                                      height: 20 / 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border:
                    Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _toggleRsvp,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color:
                              _isGoing ? AppColors.tertiary : AppColors.primary,
                          border: _isGoing
                              ? Border.all(color: const Color(0x330E4A3C))
                              : null,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: _isGoing
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.check,
                                      color: AppColors.secondary, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "You're going",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary),
                                  ),
                                ],
                              )
                            : const Text(
                                'RSVP',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(LucideIcons.bell,
                        color: AppColors.ink, size: 24),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.tertiary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.secondary, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.mutedForeground)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
