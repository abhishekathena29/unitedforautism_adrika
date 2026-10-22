import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../navigation/nav.dart';
import '../state/community_provider.dart';
import '../theme/theme.dart';

const List<Map<String, dynamic>> _iconChoices = [
  {'name': 'BookOpen', 'icon': LucideIcons.bookOpen},
  {'name': 'Waves', 'icon': LucideIcons.waves},
  {'name': 'Lightbulb', 'icon': LucideIcons.lightbulb},
  {'name': 'GraduationCap', 'icon': LucideIcons.graduationCap},
  {'name': 'Heart', 'icon': LucideIcons.heart},
  {'name': 'Brain', 'icon': LucideIcons.brain},
  {'name': 'Compass', 'icon': LucideIcons.compass},
  {'name': 'Sparkles', 'icon': LucideIcons.sparkles},
];

const List<String> _categories = [
  'Understanding Autism',
  'Sensory Processing',
  'Behavior Strategies',
  'School Readiness',
  'Therapy & Interventions',
  'Caregiver Wellbeing',
];

class CreateArticleScreen extends StatefulWidget {
  const CreateArticleScreen({super.key});

  @override
  State<CreateArticleScreen> createState() => _CreateArticleScreenState();
}

class _CreateArticleScreenState extends State<CreateArticleScreen> {
  String _mode = 'link';
  String _icon = 'BookOpen';
  String _category = _categories[0];
  final _titleController = TextEditingController();
  final _excerptController = TextEditingController();
  final _bodyController = TextEditingController();
  final _mediumUrlController = TextEditingController();
  final _authorController = TextEditingController();
  final _readMinController = TextEditingController(text: '5');
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _excerptController.dispose();
    _bodyController.dispose();
    _mediumUrlController.dispose();
    _authorController.dispose();
    _readMinController.dispose();
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

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _excerptController.text.trim().isEmpty) {
      await _showAlert('Missing fields', 'Please fill in title and summary.');
      return;
    }

    if (_mode == 'link') {
      if (!RegExp(r'^https?://').hasMatch(_mediumUrlController.text.trim())) {
        await _showAlert('Invalid link', 'Please paste a valid http(s) URL.');
        return;
      }
    } else if (_bodyController.text.trim().isEmpty) {
      await _showAlert('Missing content', 'Please write your article content.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final readMin = int.tryParse(_readMinController.text) ?? 5;
      final clampedReadMin = readMin.clamp(1, 60);
      final a = await context.read<CommunityProvider>().addArticle(
            title: _titleController.text.trim(),
            category: _category,
            readMin: clampedReadMin,
            icon: _icon,
            excerpt: _excerptController.text.trim(),
            body: _mode == 'write' ? _bodyController.text.trim() : null,
            mediumUrl:
                _mode == 'link' ? _mediumUrlController.text.trim() : null,
            author: _authorController.text.trim().isNotEmpty
                ? _authorController.text.trim()
                : 'Anonymous',
          );

      if (!mounted) return;
      await _showAlert('Published', 'Your article is live.');
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacementNamed('ArticleDetail', arguments: {'id': a.id});
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const iconCols = 4;
    const iconGap = 8.0;
    final iconBtnSize =
        (screenWidth - 40 - iconGap * (iconCols - 1)) / iconCols;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => context.goBack(),
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 12),
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
                        'Publish an Article',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Share what you've learned with the community",
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
                    Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          for (final m in ['link', 'write'])
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _mode = m),
                                child: Container(
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _mode == m
                                        ? AppColors.card
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow:
                                        _mode == m ? AppShadows.card : null,
                                  ),
                                  child: Text(
                                    m == 'link'
                                        ? 'Medium link'
                                        : 'Write in-app',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _mode == m
                                          ? AppColors.secondary
                                          : AppColors.mutedForeground,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _label('Cover icon'),
                    Wrap(
                      spacing: iconGap,
                      runSpacing: iconGap,
                      children: [
                        for (final choice in _iconChoices)
                          GestureDetector(
                            onTap: () => setState(
                                () => _icon = choice['name'] as String),
                            child: Container(
                              width: iconBtnSize,
                              height: iconBtnSize,
                              decoration: BoxDecoration(
                                color: _icon == choice['name']
                                    ? AppColors.secondary
                                    : AppColors.card,
                                border: Border.all(
                                  color: _icon == choice['name']
                                      ? AppColors.secondary
                                      : AppColors.border,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                choice['icon'] as IconData,
                                color: _icon == choice['name']
                                    ? AppColors.primary
                                    : AppColors.secondary,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                    _label('Title'),
                    _input(
                        controller: _titleController,
                        hint: 'Article title',
                        maxLength: 120),
                    _label('Category'),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final c in _categories)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _category = c),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _category == c
                                        ? AppColors.primary
                                        : AppColors.card,
                                    border: Border.all(
                                        color: _category == c
                                            ? AppColors.primary
                                            : AppColors.border),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    c,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.secondary),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    _label('Short summary'),
                    _input(
                      controller: _excerptController,
                      hint: 'A brief summary of your article',
                      maxLines: 2,
                      minHeight: 72,
                      alignTop: true,
                      maxLength: 200,
                    ),
                    if (_mode == 'link') ...[
                      _label('Medium / external URL'),
                      _input(
                        controller: _mediumUrlController,
                        hint: 'https://medium.com/@you/your-article',
                        keyboardType: TextInputType.url,
                      ),
                    ] else ...[
                      _label('Article content'),
                      _input(
                        controller: _bodyController,
                        hint: 'Write your article…',
                        maxLines: null,
                        minHeight: 200,
                        alignTop: true,
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Read time (min)', top: 0),
                                _input(
                                  controller: _readMinController,
                                  hint: '5',
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Display name', top: 0),
                                _input(
                                    controller: _authorController,
                                    hint: 'Anonymous'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _submitting ? null : _submit,
                      child: Container(
                        height: 56,
                        margin: const EdgeInsets.only(top: 24),
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6)),
                        alignment: Alignment.center,
                        child: _submitting
                            ? const CircularProgressIndicator(
                                color: AppColors.secondary)
                            : const Text(
                                'Publish Article',
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

  Widget _label(String text, {double top = 16}) => Padding(
        padding: EdgeInsets.only(top: top, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary),
        ),
      );

  Widget _input({
    required TextEditingController controller,
    required String hint,
    int? maxLines = 1,
    double? minHeight,
    bool alignTop = false,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 48),
      padding:
          EdgeInsets.symmetric(horizontal: 14, vertical: alignTop ? 12 : 0),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: alignTop ? Alignment.topLeft : Alignment.centerLeft,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        textAlignVertical:
            alignTop ? TextAlignVertical.top : TextAlignVertical.center,
        style: const TextStyle(fontSize: 15, color: AppColors.ink),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          counterText: '',
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.mutedForeground),
        ),
      ),
    );
  }
}
