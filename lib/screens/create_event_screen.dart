import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../state/auth_provider.dart';
import '../theme/theme.dart';
import 'package:provider/provider.dart';

String? _parseDateInput(String input) {
  final parts = input.trim().split('/');
  if (parts.length != 3) return null;
  final d = parts[0];
  final m = parts[1];
  final y = parts[2];
  return '$y-${m.padLeft(2, '0')}-${d.padLeft(2, '0')}';
}

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  static const _types = [
    'Workshop',
    'Webinar',
    'Therapy',
    'Meetup',
    'Awareness'
  ];

  String _type = 'Workshop';
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isVirtual = false;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _showAlert(String title, String message) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final auth = context.read<AuthProvider>();
    final userId = requireUserId(auth.user?.id, auth.isGuest);
    if (userId == null) {
      await _showAlert('Sign in required', 'Please log in to create an event.');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      await _showAlert('Missing title', 'Please add an event title.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await data.createEvent(
        hostId: userId,
        hostName: auth.profile?.displayName ?? 'Community member',
        type: _type,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        eventDate: _parseDateInput(_dateController.text),
        eventTime: _timeController.text.trim(),
        location: _locationController.text.trim(),
        isVirtual: _isVirtual,
      );
      if (mounted) context.goBack();
    } catch (e) {
      await _showAlert('Could not create event', e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => context.goBack(),
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: AppShadows.card,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(LucideIcons.chevronLeft,
                          color: AppColors.secondary, size: 24),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create event',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bring the community together',
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Type'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in _types)
                          _TypeButton(
                            label: t,
                            active: _type == t,
                            onTap: () => setState(() => _type = t),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _label('Title'),
                    _textField(
                      controller: _titleController,
                      hint: 'e.g. Sensory-friendly park meetup',
                    ),
                    const SizedBox(height: 20),
                    _label('Description'),
                    _textField(
                      controller: _descriptionController,
                      hint: 'What can attendees expect?',
                      maxLines: 5,
                      height: 120,
                      alignTop: true,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Date'),
                              _iconField(
                                controller: _dateController,
                                hint: 'dd/mm/yyyy',
                                icon: LucideIcons.calendar,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Time'),
                              _iconField(
                                controller: _timeController,
                                hint: '--:-- --',
                                icon: LucideIcons.clock,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Virtual event',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Toggle on for online meetings',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedForeground),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isVirtual,
                            onChanged: (v) => setState(() => _isVirtual = v),
                            activeThumbColor: AppColors.card,
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: const Color(0xFFE2E8F0),
                            inactiveThumbColor: AppColors.card,
                          ),
                        ],
                      ),
                    ),
                    _label(_isVirtual ? 'Meeting link' : 'Location'),
                    _textField(
                      controller: _locationController,
                      hint:
                          _isVirtual ? 'https://...' : 'Park, hall, or address',
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _submitting ? null : _handleSubmit,
                      child: Container(
                        height: 56,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: _submitting
                            ? const CircularProgressIndicator(
                                color: AppColors.secondary)
                            : const Text(
                                'Publish event',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary),
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    double height = 48,
    bool alignTop = false,
  }) {
    return Container(
      height: height,
      padding:
          EdgeInsets.symmetric(horizontal: 16, vertical: alignTop ? 16 : 0),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: alignTop ? Alignment.topLeft : Alignment.centerLeft,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textAlignVertical:
            alignTop ? TextAlignVertical.top : TextAlignVertical.center,
        style: const TextStyle(fontSize: 16, color: AppColors.ink),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.mutedForeground),
        ),
      ),
    );
  }

  Widget _iconField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: TextField(
                controller: controller,
                style: const TextStyle(fontSize: 16, color: AppColors.ink),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: hint,
                  hintStyle: TextStyle(color: AppColors.mutedForeground),
                ),
              ),
            ),
          ),
          Icon(icon, color: AppColors.ink, size: 16),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TypeButton(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.secondary : AppColors.card,
          border: Border.all(
              color: active ? AppColors.secondary : AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.card : AppColors.secondary,
          ),
        ),
      ),
    );
  }
}
