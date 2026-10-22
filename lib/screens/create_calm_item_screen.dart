import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/view_models.dart';
import '../navigation/nav.dart';
import '../state/community_provider.dart';
import '../theme/theme.dart';

const _suggestedTags = [
  'meltdown',
  'school',
  'travel',
  'bedtime',
  'sensory',
  'routine'
];

const _iconChoices = <MapEntry<String, IconData>>[
  MapEntry('Headphones', LucideIcons.headphones),
  MapEntry('Bed', LucideIcons.bed),
  MapEntry('Flower2', LucideIcons.flower2),
  MapEntry('CalendarCheck', LucideIcons.calendarCheck),
  MapEntry('Wind', LucideIcons.wind),
  MapEntry('Sparkles', LucideIcons.sparkles),
  MapEntry('Heart', LucideIcons.heart),
  MapEntry('Star', LucideIcons.star),
];

class CreateCalmItemScreen extends StatefulWidget {
  const CreateCalmItemScreen({super.key});

  @override
  State<CreateCalmItemScreen> createState() => _CreateCalmItemScreenState();
}

class _CreateCalmItemScreenState extends State<CreateCalmItemScreen> {
  final _nameController = TextEditingController();
  final _whyController = TextEditingController();
  final _whenController = TextEditingController();
  final _authorController = TextEditingController();

  String _icon = 'Headphones';
  List<String> _tags = [];
  bool _share = true;
  bool _submitting = false;
  bool _initialized = false;

  String? _id;
  bool _isEdit = false;

  @override
  void dispose() {
    _nameController.dispose();
    _whyController.dispose();
    _whenController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    _id = routeArgs(context)['id'] as String?;
    _isEdit = _id != null;
    _share = !_isEdit;

    if (_id != null) {
      final community = context.read<CommunityProvider>();
      final id = _id!;
      final communityKit = community.kits.where((k) => k.id == id).firstOrNullX;
      if (communityKit != null) {
        _nameController.text = communityKit.name;
        _whyController.text = communityKit.why;
        _whenController.text = communityKit.when;
        _icon = communityKit.icon;
        _tags = List<String>.from(communityKit.tags);
      } else {
        final seed = community.seedKits.where((k) => k.id == id).firstOrNullX;
        if (seed != null) {
          final patch = community.kitEdits[id];
          _nameController.text = patch?.name ?? seed.name;
          _whyController.text = patch?.why ?? seed.why;
          _whenController.text = patch?.when ?? seed.when;
          _icon = patch?.icon ?? seed.icon;
          _tags = List<String>.from(patch?.tags ?? seed.tags);
        }
      }
    }
  }

  void _toggleTag(String t) {
    setState(() {
      if (_tags.contains(t)) {
        _tags = _tags.where((x) => x != t).toList();
      } else {
        _tags = [..._tags, t];
      }
    });
  }

  Future<void> _onSubmit() async {
    final name = _nameController.text.trim();
    final why = _whyController.text.trim();
    final when = _whenController.text.trim();
    if (name.isEmpty || why.isEmpty || when.isEmpty) {
      _showAlert('Missing fields', 'Please fill in all required fields.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final community = context.read<CommunityProvider>();
      if (_isEdit && _id != null) {
        await community.updateKit(
          _id!,
          CalmKitPatch(
              name: name, why: why, when: when, icon: _icon, tags: _tags),
        );
        await _showAlert('Saved', 'Your changes are live.');
        if (mounted) {
          Navigator.of(context)
              .pushReplacementNamed('CalmItemDetail', arguments: {'id': _id});
        }
        return;
      }

      if (_share) {
        final author = _authorController.text.trim();
        final item = await community.addKit(
          name: name,
          why: why,
          when: when,
          icon: _icon,
          tags: _tags,
          author: author.isNotEmpty ? author : 'Anonymous',
        );
        await _showAlert(
            'Published', 'Your Calm Kit is live for the community.');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('CalmItemDetail',
              arguments: {'id': item.id});
        }
      } else {
        await community.addKit(
          name: name,
          why: why,
          when: when,
          icon: _icon,
          tags: _tags,
          author: 'Anonymous',
          shareToCommunity: false,
        );
        await _showAlert('Saved', 'Item added to your Calm Kit.');
        if (mounted) context.goBack();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showAlert(String title, String message) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    const gap = 8.0;
    final iconBtnSize = (width - 40 - gap * 3) / 4;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.goBack(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.card,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(LucideIcons.chevronLeft,
                          color: AppColors.secondary, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEdit ? 'Edit Calm Kit' : 'Add to Calm Kit',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isEdit
                            ? 'Update what works best'
                            : 'Capture what works for your child',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  _label('Choose an icon'),
                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: _iconChoices.map((entry) {
                      final active = _icon == entry.key;
                      return GestureDetector(
                        onTap: () => setState(() => _icon = entry.key),
                        child: Container(
                          width: iconBtnSize,
                          height: iconBtnSize,
                          decoration: BoxDecoration(
                            color:
                                active ? AppColors.secondary : AppColors.card,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: active
                                    ? AppColors.secondary
                                    : AppColors.border),
                          ),
                          alignment: Alignment.center,
                          child: Icon(entry.value,
                              color: active
                                  ? AppColors.primary
                                  : AppColors.secondary,
                              size: 20),
                        ),
                      );
                    }).toList(),
                  ),
                  _label('Item name'),
                  _textField(
                      _nameController, 'e.g. Noise-Cancelling Headphones'),
                  _label('Why it helps'),
                  _textArea(
                      _whyController, 'What does this do for your child?'),
                  _label('When to use'),
                  _textArea(
                      _whenController, 'In what moments does this work best?'),
                  _label('Tags'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestedTags.map((t) {
                      final active = _tags.contains(t);
                      return GestureDetector(
                        onTap: () => _toggleTag(t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : AppColors.card,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.border),
                          ),
                          child: Text('#$t',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary)),
                        ),
                      );
                    }).toList(),
                  ),
                  if (!_isEdit) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Share with community',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary)),
                                SizedBox(height: 2),
                                Text('Anyone can browse and upvote it.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.mutedForeground)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _share,
                            onChanged: (v) => setState(() => _share = v),
                            activeTrackColor: AppColors.primary,
                            thumbColor:
                                const WidgetStatePropertyAll(AppColors.card),
                          ),
                        ],
                      ),
                    ),
                    if (_share) ...[
                      _label('Your display name (optional)'),
                      _textField(_authorController, 'Anonymous'),
                    ],
                  ],
                  GestureDetector(
                    onTap: _submitting ? null : _onSubmit,
                    child: Container(
                      height: 56,
                      margin: const EdgeInsets.only(top: 24),
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6)),
                      alignment: Alignment.center,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: AppColors.secondary, strokeWidth: 2.5),
                            )
                          : Text(
                              _isEdit
                                  ? 'Save changes'
                                  : (_share
                                      ? 'Publish to Community'
                                      : 'Save to Calm Kit'),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary)),
    );
  }

  Widget _textField(TextEditingController controller, String placeholder) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: AppColors.mutedForeground),
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.border)),
        ),
        style: const TextStyle(fontSize: 15, color: AppColors.ink),
      ),
    );
  }

  Widget _textArea(TextEditingController controller, String placeholder) {
    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 5,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(color: AppColors.mutedForeground),
        filled: true,
        fillColor: AppColors.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border)),
      ),
      style: const TextStyle(fontSize: 15, color: AppColors.ink),
    );
  }
}

extension _FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNullX => isEmpty ? null : first;
}
