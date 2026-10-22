import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/models.dart';
import '../models/view_models.dart';
import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../theme/theme.dart';
import '../widgets/post_avatar.dart';

/// Direct port of `src/screens/SpaceDetailScreen.tsx`.
class SpaceDetailScreen extends StatefulWidget {
  const SpaceDetailScreen({super.key});

  @override
  State<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends State<SpaceDetailScreen> {
  SpaceView? _space;
  List<PostView> _posts = [];
  bool _loading = true;
  String? _spaceId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_spaceId == null) {
      _spaceId = routeArgs(context)['spaceId'] as String? ?? 's1';
      _load(_spaceId!);
    }
  }

  Future<void> _load(String spaceId) async {
    try {
      final results = await Future.wait([
        data.fetchSpace(spaceId),
        data.fetchPosts(limit: 20, spaceId: spaceId),
      ]);
      final s = results[0] as DbSpace;
      final p = results[1] as List<DbPost>;
      if (!mounted) return;
      setState(() {
        _space = mapSpace(s);
        _posts = p.map((row) => mapPost(row, spaceName: s.name)).toList();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final space = _space;
    if (_loading || space == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  color: AppColors.secondary,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => context.goBack(),
                          child: Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.only(bottom: 24),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(LucideIcons.chevronLeft,
                                color: AppColors.card, size: 24),
                          ),
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          margin: const EdgeInsets.only(bottom: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(space.icon,
                              color: AppColors.secondary, size: 32),
                        ),
                        Text(
                          space.name,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.card),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          space.description,
                          style: TextStyle(
                              fontSize: 15,
                              color: AppColors.card.withValues(alpha: 0.9)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${space.postCount} ${space.postCount == 1 ? 'post' : 'posts'}',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.card.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_posts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No posts yet. Be the first to share.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14, color: AppColors.mutedForeground),
                          ),
                        ),
                      for (final post in _posts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            onTap: () => context.pushNamed('PostDetail',
                                arguments: {'postId': post.id}),
                            child: Container(
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
                                          anonymous: post.isAnonymous,
                                          initials: post.initials,
                                          size: 40),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(post.author,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppColors.secondary)),
                                            const SizedBox(height: 2),
                                            Text(post.time,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors
                                                        .mutedForeground)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    post.title,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary,
                                        height: 22 / 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    post.body,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.mutedForeground,
                                        height: 22 / 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            right: 20,
            child: GestureDetector(
              onTap: () => context
                  .pushNamed('CreatePost', arguments: {'spaceId': _spaceId}),
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.glow,
                ),
                child: const Icon(LucideIcons.plus,
                    color: AppColors.secondary, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
