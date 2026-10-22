import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../theme/theme.dart';
import '../utils/utils.dart';

class _ReplyItem {
  final String id;
  final String body;
  final String time;

  _ReplyItem({required this.id, required this.body, required this.time});
}

class EmotionalShareRepliesScreen extends StatefulWidget {
  const EmotionalShareRepliesScreen({super.key});

  @override
  State<EmotionalShareRepliesScreen> createState() =>
      _EmotionalShareRepliesScreenState();
}

class _EmotionalShareRepliesScreenState
    extends State<EmotionalShareRepliesScreen> {
  final _replyController = TextEditingController();
  String _shareId = '';
  bool _focusReply = false;
  String _shareBody = '';
  String _shareTime = '';
  List<_ReplyItem> _replies = [];
  bool _loading = true;
  bool _initialized = false;
  final _replyFocusNode = FocusNode();

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args = routeArgs(context);
    _shareId = (args['shareId'] as String?) ?? '';
    _focusReply = (args['focusReply'] as bool?) ?? false;
    _load();
    if (_focusReply) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _replyFocusNode.requestFocus();
      });
    }
  }

  Future<void> _load() async {
    if (_shareId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        data.fetchEmotionalShare(_shareId),
        data.fetchRepliesForShare(_shareId),
      ]);
      final share = results[0] as Map<String, dynamic>;
      final rows = results[1] as List<Map<String, dynamic>>;
      if (!mounted) return;
      setState(() {
        _shareBody = share['body'] as String? ?? '';
        _shareTime = timeAgo(
            share['created_at'] as String? ?? DateTime.now().toIso8601String());
        _replies = rows
            .map((r) => _ReplyItem(
                  id: r['id'] as String,
                  body: r['body'] as String? ?? '',
                  time: timeAgo(r['created_at'] as String? ??
                      DateTime.now().toIso8601String()),
                ))
            .toList();
      });
    } catch (_) {
      if (mounted)
        await _showAlert('Could not load', 'Please go back and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _shareId.isEmpty) return;
    try {
      await data.createEmotionalReply(_shareId, text);
      _replyController.clear();
      await _load();
    } catch (_) {
      await _showAlert('Could not reply', 'Please try again in a moment.');
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Replies',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary)),
                        const SizedBox(height: 2),
                        Text(
                          _replies.length == 1
                              ? '1 gentle reply'
                              : '${_replies.length} gentle replies',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: CircularProgressIndicator(color: AppColors.secondary),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        children: [
                          Container(
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
                                          borderRadius:
                                              BorderRadius.circular(18)),
                                      alignment: Alignment.center,
                                      child: const Text('AC',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.secondary)),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Anonymous Caregiver',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.secondary)),
                                          const SizedBox(height: 2),
                                          Text(_shareTime,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors
                                                      .mutedForeground)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(_shareBody,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.ink,
                                        height: 22 / 14)),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 24, bottom: 12),
                            child: Text('All replies',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary)),
                          ),
                          if (_replies.isEmpty)
                            const Text(
                              'No replies yet. Be the first to respond gently.',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.mutedForeground,
                                  height: 20 / 14),
                            )
                          else
                            Column(
                              children: _replies
                                  .map((reply) => Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: AppColors.card,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: AppColors.border),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 28,
                                                  height: 28,
                                                  margin: const EdgeInsets.only(
                                                      right: 10),
                                                  decoration: BoxDecoration(
                                                      color: AppColors.tertiary,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14)),
                                                  alignment: Alignment.center,
                                                  child: const Text('AC',
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .secondary)),
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text('Anonymous',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppColors
                                                                .secondary)),
                                                    const SizedBox(height: 1),
                                                    Text(reply.time,
                                                        style: const TextStyle(
                                                            fontSize: 10,
                                                            color: AppColors
                                                                .mutedForeground)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(reply.body,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: AppColors.ink,
                                                    height: 21 / 14)),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.card,
                        border:
                            Border(top: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  minHeight: 44, maxHeight: 100),
                              child: TextField(
                                controller: _replyController,
                                focusNode: _replyFocusNode,
                                maxLines: null,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Write a kind, supportive reply…',
                                  hintStyle: const TextStyle(
                                      color: AppColors.mutedForeground),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: AppColors.border)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: AppColors.border)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: AppColors.border)),
                                ),
                                style: const TextStyle(
                                    fontSize: 15, color: AppColors.ink),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _replyController.text.trim().isEmpty
                                ? null
                                : _submitReply,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _replyController.text.trim().isEmpty
                                    ? AppColors.border
                                    : AppColors.secondary,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(LucideIcons.send,
                                  color: AppColors.card, size: 18),
                            ),
                          ),
                        ],
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
}
