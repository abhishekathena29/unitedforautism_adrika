import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../state/auth_provider.dart';
import '../theme/theme.dart';
import '../utils/utils.dart';

class _ShareItem {
  final String id;
  final String initials;
  final String name;
  final String time;
  final String body;
  final int likes;
  final bool liked;
  final int replyCount;

  _ShareItem({
    required this.id,
    required this.initials,
    required this.name,
    required this.time,
    required this.body,
    required this.likes,
    required this.liked,
    required this.replyCount,
  });

  _ShareItem copyWith({int? likes, bool? liked}) => _ShareItem(
        id: id,
        initials: initials,
        name: name,
        time: time,
        body: body,
        likes: likes ?? this.likes,
        liked: liked ?? this.liked,
        replyCount: replyCount,
      );
}

_ShareItem _mapShareRow(
    Map<String, dynamic> row, Set<String> likedIds, int replyCount) {
  return _ShareItem(
    id: row['id'] as String,
    initials: 'AC',
    name: 'Anonymous Caregiver',
    time: timeAgo(
        row['created_at'] as String? ?? DateTime.now().toIso8601String()),
    body: row['body'] as String? ?? '',
    likes: (row['held_count'] as num?)?.toInt() ?? 0,
    liked: likedIds.contains(row['id']),
    replyCount: replyCount,
  );
}

class EmotionalSupportScreen extends StatefulWidget {
  const EmotionalSupportScreen({super.key});

  @override
  State<EmotionalSupportScreen> createState() => _EmotionalSupportScreenState();
}

class _EmotionalSupportScreenState extends State<EmotionalSupportScreen>
    with AppRouteAware {
  String? _selectedPrompt;
  String? _selectedPromptId;
  final _reflectionController = TextEditingController();
  List<Map<String, dynamic>> _prompts = [];
  List<_ShareItem> _shares = [];
  String? _likerKey;
  bool _loaded = false;

  static const _defaultPrompts = [
    {'id': 'p1', 'text': "What's one tiny win from today?"},
    {'id': 'p2', 'text': 'Where do you need extra grace right now?'},
    {'id': 'p3', 'text': 'What felt heavy today?'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void onRefocus() => _load();

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  String? get _userId {
    final auth = context.read<AuthProvider>();
    return requireUserId(auth.user?.id, auth.isGuest);
  }

  Future<List<_ShareItem>> _loadShares(String key) async {
    final rows = await data.fetchEmotionalShares();
    final likedIds = await data.fetchLikedShareIds(key);
    final replyCounts = await data
        .fetchEmotionalReplyCounts(rows.map((r) => r['id'] as String).toList());
    return rows
        .map((row) => _mapShareRow(row, likedIds, replyCounts[row['id']] ?? 0))
        .toList();
  }

  Future<void> _load() async {
    final userId = _userId;
    final key = await data.getEmotionalLikerKey(userId: userId);
    final prompts = await data.fetchEmotionalPrompts(userId: userId, limit: 3);
    final shares = await _loadShares(key);
    if (!mounted) return;
    setState(() {
      _likerKey = key;
      _prompts = prompts;
      _shares = shares;
      _loaded = true;
    });
  }

  Future<void> _submitReflection() async {
    final text = _reflectionController.text.trim();
    if (text.isEmpty) return;
    try {
      await data.createEmotionalShare(text, promptId: _selectedPromptId);
      if (mounted) Navigator.of(context).pop();
      await _showAlert('Thank you',
          'Your reflection has been shared anonymously with the community.');
      _reflectionController.clear();
      setState(() => _selectedPrompt = null);
      final key = _likerKey;
      if (key != null) {
        final shares = await _loadShares(key);
        if (mounted) setState(() => _shares = shares);
      }
    } catch (_) {
      await _showAlert('Could not share', 'Please try again in a moment.');
    }
  }

  Future<void> _openReplies(String shareId, {bool focusReply = false}) async {
    await context.pushNamed('EmotionalShareReplies', arguments: {
      'shareId': shareId,
      'focusReply': focusReply,
    });
    _load();
  }

  String _replyCountLabel(int count) {
    if (count == 0) return 'View replies';
    if (count == 1) return 'View 1 reply';
    return 'View $count replies';
  }

  Future<void> _toggleLike(String id) async {
    final key = _likerKey;
    if (key == null) return;
    final index = _shares.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final share = _shares[index];
    try {
      await data.toggleShareLike(key, id, share.liked);
      setState(() {
        _shares[index] = share.copyWith(
          liked: !share.liked,
          likes: share.liked
              ? (share.likes - 1).clamp(0, 1 << 30)
              : share.likes + 1,
        );
      });
    } catch (_) {
      await _showAlert(
          'Could not update like', 'Please try again in a moment.');
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

  void _openPromptModal(String text, String id) {
    setState(() {
      _selectedPrompt = text;
      _selectedPromptId = id;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x800E1F1A),
      builder: (ctx) => _buildReflectionModal(ctx),
    ).whenComplete(() {
      setState(() => _selectedPrompt = null);
    });
  }

  Widget _buildReflectionModal(BuildContext sheetContext) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.tertiary,
                      borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.eyeOff,
                      color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Share anonymously',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary)),
                      SizedBox(height: 2),
                      Text('Only you know this is from you',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.mutedForeground)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _reflectionController.clear();
                    Navigator.of(sheetContext).pop();
                  },
                  child: const Icon(LucideIcons.x,
                      color: AppColors.mutedForeground, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.calmBannerBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.tertiary),
              ),
              child: Text(
                _selectedPrompt ?? '',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                    height: 22 / 15),
              ),
            ),
            StatefulBuilder(
              builder: (ctx, setSheetState) {
                return TextField(
                  controller: _reflectionController,
                  autofocus: true,
                  maxLines: 5,
                  minLines: 4,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Write your honest reflection here…',
                    hintStyle:
                        const TextStyle(color: AppColors.mutedForeground),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border)),
                  ),
                  style: const TextStyle(fontSize: 15, color: AppColors.ink),
                );
              },
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (ctx, setSheetState) {
                final canSubmit = _reflectionController.text.trim().isNotEmpty;
                return GestureDetector(
                  onTap: canSubmit ? _submitReflection : null,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: canSubmit ? AppColors.secondary : AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.send, color: AppColors.card, size: 16),
                        SizedBox(width: 8),
                        Text('Share with community',
                            style: TextStyle(
                                color: AppColors.card,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
            child: Center(
                child: CircularProgressIndicator(color: AppColors.secondary))),
      );
    }

    final promptsList = _prompts.isNotEmpty ? _prompts : _defaultPrompts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.goBack(),
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 16),
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Emotional Support',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary)),
                        SizedBox(height: 2),
                        Text('A gentle, moderated space',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.mutedForeground)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.calmBannerBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.tertiary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('REFLECTION PROMPTS',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xB30E4A3C),
                                letterSpacing: 1.5)),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap a prompt to share your reflection anonymously with the community.',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondary,
                              height: 18 / 13),
                        ),
                        const SizedBox(height: 14),
                        Column(
                          children: promptsList
                              .map((p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: GestureDetector(
                                      onTap: () => _openPromptModal(
                                          p['text'] as String,
                                          p['id'] as String),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 13),
                                        decoration: BoxDecoration(
                                          color: AppColors.card,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: AppColors.border),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(p['text'] as String,
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColors.secondary)),
                                            ),
                                            const Icon(LucideIcons.chevronRight,
                                                color: AppColors.secondary,
                                                size: 14),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                        color: AppColors.tertiary,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Row(
                      children: [
                        Icon(LucideIcons.eyeOff,
                            color: AppColors.secondary, size: 16),
                        SizedBox(width: 8),
                        Text('Posts here are anonymous and held with care.',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary)),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 28, bottom: 12),
                    child: Text('Shared softly',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary)),
                  ),
                  Column(
                    children:
                        _shares.map((share) => _buildShareCard(share)).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCard(_ShareItem share) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
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
                    borderRadius: BorderRadius.circular(18)),
                alignment: Alignment.center,
                child: Text(share.initials,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(share.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary)),
                    const SizedBox(height: 2),
                    Text(share.time,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.mutedForeground)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(share.body,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.ink, height: 22 / 14)),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: GestureDetector(
                  onTap: () => _toggleLike(share.id),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 52),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: share.liked
                          ? AppColors.secondary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.secondary),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.heart,
                            color: share.liked
                                ? AppColors.card
                                : AppColors.secondary,
                            size: 15,
                            fill: share.liked ? 1 : 0),
                        const SizedBox(width: 6),
                        Text('${share.likes}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: share.liked
                                    ? AppColors.card
                                    : AppColors.secondary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: GestureDetector(
                  onTap: () => _openReplies(share.id, focusReply: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.messageCircle,
                            color: AppColors.mutedForeground, size: 15),
                        SizedBox(width: 6),
                        Text('Reply gently',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.mutedForeground)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _openReplies(share.id),
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                  color: AppColors.tertiary,
                  borderRadius: BorderRadius.circular(6)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_replyCountLabel(share.replyCount),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary)),
                  const Icon(LucideIcons.chevronRight,
                      color: AppColors.secondary, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
