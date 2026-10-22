import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/view_models.dart';
import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../state/auth_provider.dart';
import '../theme/theme.dart';

/// Direct port of `src/screens/CreatePostScreen.tsx`.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _tagsController = TextEditingController();

  String? _selectedSpace;
  bool _isAnonymous = false;
  List<SpaceView> _spaces = [];
  bool _submitting = false;
  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final auth = context.read<AuthProvider>();
      final userId = requireUserId(auth.user?.id, auth.isGuest);
      _selectedSpace = routeArgs(context)['spaceId'] as String? ?? 's1';
      _isAnonymous = userId == null;
      data.fetchSpaces().then((rows) {
        if (!mounted) return;
        setState(() => _spaces = rows.map(mapSpace).toList());
      });
    }
  }

  Future<void> _showAlert(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final auth = context.read<AuthProvider>();
    final userId = requireUserId(auth.user?.id, auth.isGuest);
    final isLoggedIn = userId != null;
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      await _showAlert('Missing fields', 'Please add a title and message.');
      return;
    }

    final postAnonymous = !isLoggedIn || _isAnonymous;
    setState(() => _submitting = true);
    try {
      await data.createPost(
        spaceId: _selectedSpace ?? 's1',
        authorId: postAnonymous ? null : userId,
        isAnonymous: postAnonymous,
        title: title,
        body: message,
        tags: _tagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
      );
      if (!mounted) return;
      context.goBack();
    } catch (e) {
      if (!mounted) return;
      await _showAlert('Could not post',
          e.toString().isNotEmpty ? e.toString() : 'Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = requireUserId(auth.user?.id, auth.isGuest);
    final isLoggedIn = userId != null;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New post',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary)),
                      SizedBox(height: 2),
                      Text('Be kind. Be honest. Be you.',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.mutedForeground)),
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
                    if (!isLoggedIn)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.tertiary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Posting anonymously',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Log in or create an account if you'd like your name to appear on posts.",
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.85),
                                  height: 18 / 13),
                            ),
                          ],
                        ),
                      ),
                    _FormGroup(
                      label: 'Choose a space',
                      child: SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _spaces.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final space = _spaces[i];
                            final isActive = _selectedSpace == space.id;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedSpace = space.id),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.secondary
                                      : AppColors.card,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: isActive
                                          ? AppColors.secondary
                                          : AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(space.icon,
                                        color: isActive
                                            ? AppColors.card
                                            : AppColors.secondary,
                                        size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      space.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isActive
                                            ? AppColors.card
                                            : AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    _FormGroup(
                      label: 'Title',
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          controller: _titleController,
                          style: const TextStyle(
                              fontSize: 16, color: AppColors.ink),
                          decoration:
                              _inputDecoration("Share what's on your mind"),
                        ),
                      ),
                    ),
                    _FormGroup(
                      label: 'Your message',
                      child: SizedBox(
                        height: 200,
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: const TextStyle(
                              fontSize: 16, color: AppColors.ink),
                          decoration:
                              _inputDecoration('Tell your story...').copyWith(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                    ),
                    _FormGroup(
                      label: 'Tags (comma separated)',
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          controller: _tagsController,
                          style: const TextStyle(
                              fontSize: 16, color: AppColors.ink),
                          decoration:
                              _inputDecoration('meltdown, school, sensory'),
                        ),
                      ),
                    ),
                    if (isLoggedIn)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _isAnonymous = !_isAnonymous),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Post anonymously',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.secondary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isAnonymous
                                            ? "Your name won't be shown."
                                            : 'Your display name will appear on this post.',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.mutedForeground),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _isAnonymous
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: _isAnonymous
                                            ? AppColors.primary
                                            : AppColors.border,
                                        width: 2),
                                  ),
                                  child: _isAnonymous
                                      ? const Text('✓',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold))
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: _submitting ? null : _handleSubmit,
                            child: Center(
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: AppColors.secondary,
                                          strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Post to community',
                                      style: TextStyle(
                                          color: AppColors.secondary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700),
                                    ),
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.mutedForeground),
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }
}

class _FormGroup extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormGroup({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
