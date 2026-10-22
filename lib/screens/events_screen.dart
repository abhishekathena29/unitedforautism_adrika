import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/view_models.dart';
import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../theme/theme.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _activeTab = 'All';
  List<EventView> _allEvents = [];
  bool _loading = true;

  static const _tabs = ['All', 'Workshops', 'Webinars', 'Meetups', 'Awareness'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await data.fetchEvents();
      if (!mounted) return;
      setState(() => _allEvents = rows.map(mapEvent).toList());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<EventView> get _filteredEvents => _allEvents.where((e) {
        if (_activeTab == 'All') return true;
        final prefix = _activeTab.toLowerCase().substring(
              0,
              _activeTab.length < 5 ? _activeTab.length : 5,
            );
        return e.type.toLowerCase().startsWith(prefix);
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Events',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Workshops, meetups & support',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pushNamed('CreateEvent'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: AppShadows.card,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(LucideIcons.plus,
                          color: AppColors.secondary, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final tab in _tabs) ...[
                    _TabButton(
                      label: tab,
                      active: _activeTab == tab,
                      onTap: () => setState(() => _activeTab = tab),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      children: [
                        for (final event in _filteredEvents) ...[
                          _EventCard(event: event),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.secondary : AppColors.card,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: active ? AppColors.secondary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.card : AppColors.secondary,
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventView event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.pushNamed('EventDetail', arguments: {'id': event.id}),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 128,
              width: double.infinity,
              color: const Color(0xFFD1F4EA),
              alignment: Alignment.center,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.type,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                  Icon(event.icon, color: AppColors.secondary, size: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.date,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              event.isVirtual
                                  ? LucideIcons.video
                                  : LucideIcons.mapPin,
                              color: AppColors.mutedForeground,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                event.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.mutedForeground),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.users,
                              color: AppColors.mutedForeground, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${event.rsvps}',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ],
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
