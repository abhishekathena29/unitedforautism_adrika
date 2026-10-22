import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/view_models.dart';
import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../theme/theme.dart';

/// Direct port of `src/screens/TherapistsScreen.tsx`.
class TherapistsScreen extends StatefulWidget {
  const TherapistsScreen({super.key});

  @override
  State<TherapistsScreen> createState() => _TherapistsScreenState();
}

class _TherapistsScreenState extends State<TherapistsScreen> {
  static const _filters = [
    'All',
    'Pediatrician',
    'Speech',
    'Occupational',
    'Behavioral'
  ];

  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  List<TherapistView> _therapists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    data.fetchTherapists().then((rows) {
      if (!mounted) return;
      setState(() => _therapists = rows.map(mapTherapist).toList());
    }).whenComplete(() {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TherapistView> get _filteredTherapists {
    final q = _searchController.text.toLowerCase();
    return _therapists.where((t) {
      final matchesSearch = t.name.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q);
      final matchesFilter =
          _selectedFilter == 'All' || t.specialty == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _handleBook(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Schedule Consultation'),
        content: Text(
            'Would you like to open the calendar to book a session with $name?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              debugPrint('Booking consultation with $name');
            },
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }

  void _handleMessage(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Secure Message'),
        content: Text('Opening encrypted chat channel with $name.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              debugPrint('Messaging $name');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTherapists;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Specialist Directory',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Connect with vetted autism care professionals',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.soft,
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.search,
                        color: AppColors.mutedForeground, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style:
                            const TextStyle(fontSize: 15, color: AppColors.ink),
                        decoration: const InputDecoration(
                          hintText: 'Search specialties, expertise, names...',
                          hintStyle:
                              TextStyle(color: AppColors.mutedForeground),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    for (var i = 0; i < _filters.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _FilterChip(
                        label: _filters[i],
                        active: _selectedFilter == _filters[i],
                        onTap: () =>
                            setState(() => _selectedFilter = _filters[i]),
                      ),
                    ],
                  ],
                ),
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
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: filtered.isNotEmpty
                          ? Column(
                              children: [
                                for (var i = 0; i < filtered.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 16),
                                  _TherapistCard(
                                    therapist: filtered[i],
                                    onMessage: () =>
                                        _handleMessage(filtered[i].name),
                                    onBook: () => _handleBook(filtered[i].name),
                                  ),
                                ],
                              ],
                            )
                          : const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'No specialists found matching your search criteria.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.mutedForeground),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.secondary : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: active ? AppColors.secondary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.card : AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}

class _TherapistCard extends StatelessWidget {
  final TherapistView therapist;
  final VoidCallback onMessage;
  final VoidCallback onBook;

  const _TherapistCard(
      {required this.therapist, required this.onMessage, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(right: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(24)),
                child: Text(
                  therapist.initials,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          therapist.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(LucideIcons.award,
                              color: AppColors.primary, size: 16),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${therapist.specialty} · ${therapist.experience}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.mapPin,
                              color: AppColors.mutedForeground, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            therapist.location,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(LucideIcons.star,
                      color: AppColors.warning, size: 14),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${therapist.rating}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary),
                    ),
                  ),
                  Text(
                    '(${therapist.reviews})',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.mutedForeground),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              therapist.description,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.ink, height: 20 / 14),
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: onMessage,
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.secondary),
                      color: AppColors.card,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.messageSquare,
                            color: AppColors.secondary, size: 16),
                        SizedBox(width: 8),
                        Text('Message',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: onBook,
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: AppColors.secondary,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.calendar,
                            color: AppColors.card, size: 16),
                        SizedBox(width: 8),
                        Text('Book Appointment',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.card)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
