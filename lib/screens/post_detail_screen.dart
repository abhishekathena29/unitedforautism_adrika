import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/view_models.dart';
import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../state/auth_provider.dart';
import '../theme/theme.dart';
import '../utils/utils.dart';
import '../widgets/post_avatar.dart';

class _Reply {
  final String author;
  final String initials;
  final String time;
  final String body;
  final bool isAnonymous;

  _Reply({
    required this.author,
    required this.initials,
    required this.time,
    required this.body,
    required this.isAnonymous,
  });
}

/// Direct port of `src/screens/PostDetailScreen.tsx`.
class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _replyController = TextEditingController();

  String? _postId;
  PostView? _post;
  bool _liked = false;
  int _likeCount = 0;
  bool _bookmarked = false;
  List<_Reply> _replies = [];
  bool _loading = true;
  String? _likerKey;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_postId == null) {
      final args = routeArgs(context);
      _postId = args['postId'] as String? ?? '';
      if (_postId!.isNotEmpty) {
        _load(_postId!);
      } else {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _load(String postId) async {
    final auth = context.read<AuthProvider>();
    final userId = requireUserId(auth.user?.id, auth.isGuest);
    try {
      final key = await data.getEmotionalLikerKey(userId: userId);
      _likerKey = key;
      final row = await data.fetchPost(postId);
      final space = await data.fetchSpace(row.spaceId);
      final mapped = mapPost(row, spaceName: space.name);
      final comments = await data.fetchComments('post', postId);
      final results = await Future.wait([
        data.fetchPostLikes(key, [postId]),
        userId != null
            ? data.fetchSavedPostIds(userId)
            : Future.value(<String>{}),
      ]);
      final likes = results[0];
      final saved = results[1];
      if (!mounted) return;
      setState(() {
        _post = mapped;
        _likeCount = mapped.likes;
        _replies = comments
            .map((c) => _Reply(
                  author: c.authorDisplayName,
                  initials: c.authorDisplayName.length > 2
                      ? c.authorDisplayName.substring(0, 2).toUpperCase()
                      : c.authorDisplayName.toUpperCase(),
                  time: timeAgo(c.createdAt),
                  body: c.text,
                  isAnonymous: c.authorDisplayName == 'Anonymous',
                ))
            .toList();
        _liked = likes.contains(postId);
        _bookmarked = saved.contains(postId);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
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

  Future<void> _handleLike() async {
    final key = _likerKey;
    final post = _post;
    if (key == null || post == null) return;
    try {
      await data.togglePostLike(key, post.id, _liked);
      setState(() {
        _likeCount =
            _liked ? (_likeCount > 0 ? _likeCount - 1 : 0) : _likeCount + 1;
        _liked = !_liked;
      });
    } catch (_) {
      await _showAlert('Could not update like', 'Please try again.');
    }
  }

  Future<void> _handleBookmark() async {
    final post = _post;
    if (post == null) return;
    final auth = context.read<AuthProvider>();
    final userId = requireUserId(auth.user?.id, auth.isGuest);
    if (userId == null) {
      await _showAlert(
          'Sign in to save', 'Log in or create an account to bookmark posts.');
      return;
    }
    try {
      await data.toggleSavedPost(userId, post.id, _bookmarked);
      setState(() => _bookmarked = !_bookmarked);
    } catch (_) {
      await _showAlert('Could not save', 'Please try again.');
    }
  }

  Future<void> _handleShare() async {
    final post = _post;
    if (post == null) return;
    final tags = post.tags.isNotEmpty
        ? '\n\n${post.tags.map((t) => '#$t').join(' ')}'
        : '';
    final text = '${post.title}\n\n${post.body}$tags';
    await Share.share(text);
  }

  Future<void> _handleSend() async {
    final text = _replyController.text.trim();
    final post = _post;
    if (text.isEmpty || post == null) return;
    final auth = context.read<AuthProvider>();
    final userId = requireUserId(auth.user?.id, auth.isGuest);
    final authorName = auth.profile?.displayName ?? 'Anonymous';
    await data.addComment(
      targetType: 'post',
      targetId: post.id,
      authorId: userId,
      authorName: authorName,
      text: text,
    );
    setState(() {
      _replies = [
        ..._replies,
        _Reply(
          author: authorName,
          initials: auth.profile?.initials ?? initialsFromName(authorName),
          time: 'Just now',
          body: text,
          isAnonymous: authorName == 'Anonymous',
        ),
      ];
    });
    _replyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    if (_loading || post == null) {
      return const SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: Column(
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
                        Text(
                          post.space,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${post.time} · ${post.author}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        PostAvatar(
                            anonymous: post.isAnonymous,
                            initials: post.initials,
                            size: 48),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(post.author,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary)),
                              const SizedBox(height: 2),
                              Text(
                                '${post.role.isNotEmpty ? '${post.role} · ' : ''}${post.time}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.mutedForeground),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      post.title,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                          height: 32 / 24),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      post.body,
                      style: TextStyle(
                          fontSize: 16,
                          color: AppColors.ink.withValues(alpha: 0.9),
                          height: 24 / 16),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in post.tags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.tertiary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('#$tag',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                          bottom: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _handleLike,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 24),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.heart,
                                    color: _liked
                                        ? AppColors.destructive
                                        : AppColors.mutedForeground,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_likeCount',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _liked
                                          ? AppColors.destructive
                                          : AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 24),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.messageCircle,
                                    color: AppColors.secondary, size: 20),
                                const SizedBox(width: 8),
                                Text('${_replies.length}',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _handleBookmark,
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Icon(
                                LucideIcons.bookmark,
                                color: _bookmarked
                                    ? AppColors.secondary
                                    : AppColors.mutedForeground,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _handleShare,
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(6)),
                              child: const Icon(LucideIcons.share2,
                                  color: AppColors.secondary, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'REPLIES',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedForeground,
                          letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        for (final reply in _replies)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              width: double.infinity,
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
                                      PostAvatar(
                                          anonymous: reply.isAnonymous,
                                          initials: reply.initials,
                                          size: 36),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(reply.author,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppColors.secondary)),
                                            const SizedBox(height: 2),
                                            Text(reply.time,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors
                                                        .mutedForeground)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(reply.body,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.ink,
                                          height: 20 / 14)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20,
                  MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 0),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _replyController,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _handleSend(),
                          textInputAction: TextInputAction.send,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.ink),
                          decoration: const InputDecoration(
                            hintText: 'Write a kind reply...',
                            hintStyle:
                                TextStyle(color: AppColors.mutedForeground),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _replyController.text.trim().isEmpty
                          ? null
                          : _handleSend,
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _replyController.text.trim().isEmpty
                              ? AppColors.border
                              : AppColors.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(LucideIcons.send,
                            color: AppColors.card, size: 18),
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
}
