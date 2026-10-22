import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../navigation/nav.dart';
import '../state/community_provider.dart';
import '../theme/theme.dart';
import '../utils/utils.dart';
import '../widgets/icon_badge.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  void _goToHomeTab(BuildContext context, String screen) {
    MainTabsController.instance.pushOnTab('HomeTab', screen);
  }

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityProvider>();
    final editorialArticles = community.editorialArticles;
    final userArticles = community.articles;
    final artLikes = community.artLikes;
    final comments = community.comments;

    final featured =
        editorialArticles.isNotEmpty ? editorialArticles.first : null;
    final List<DbArticle> rest = editorialArticles.length > 1
        ? editorialArticles.sublist(1)
        : <DbArticle>[];
    final featuredIcon = getIcon(featured?.icon ?? 'BookOpen');

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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Learning Hub',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Trusted, accessible, empathetic',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pushNamed('CreateArticle'),
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6)),
                      alignment: Alignment.center,
                      child: const Icon(LucideIcons.plus,
                          color: AppColors.secondary, size: 20),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _goToHomeTab(context, 'Notifications'),
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: AppShadows.card,
                      ),
                      alignment: Alignment.center,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(LucideIcons.bell,
                              color: AppColors.secondary, size: 20),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _goToHomeTab(context, 'Profile'),
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: AppShadows.card,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(LucideIcons.user,
                          color: AppColors.secondary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                children: [
                  GestureDetector(
                    onTap: () => context.pushNamed('EmotionalSupport'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1F4EA),
                        border: Border.all(color: AppColors.tertiary),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(LucideIcons.heart,
                                color: AppColors.secondary, size: 20),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Emotional Support Space',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'A gentle place for caregiver wellbeing.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.secondary
                                          .withValues(alpha: 0.8)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevronRight,
                              color: AppColors.secondary, size: 20),
                        ],
                      ),
                    ),
                  ),
                  if (featured != null)
                    GestureDetector(
                      onTap: () => context.pushNamed('ArticleDetail',
                          arguments: {'id': featured.id}),
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
                              height: 160,
                              width: double.infinity,
                              color: const Color(0xFF1B5646),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Icon(LucideIcons.sparkles,
                                        color: Color(0x80FFFFFF), size: 24),
                                  ),
                                  Icon(featuredIcon,
                                      color: AppColors.primary, size: 64),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _chip(featured.category),
                                  const SizedBox(height: 8),
                                  Text(
                                    featured.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary,
                                      height: 24 / 18,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${featured.readMin} min read',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.mutedForeground),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (userArticles.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 28, bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Community Articles',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary),
                          ),
                          GestureDetector(
                            onTap: () => context.pushNamed('CreateArticle'),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.plus,
                                    color: AppColors.secondary, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Add yours',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        for (final a in userArticles) ...[
                          GestureDetector(
                            onTap: () => context.pushNamed('ArticleDetail',
                                arguments: {'id': a.id}),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                                boxShadow: AppShadows.card,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    margin: const EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(
                                        color: AppColors.tertiary,
                                        borderRadius: BorderRadius.circular(6)),
                                    alignment: Alignment.center,
                                    child: Icon(getIcon(a.icon),
                                        color: AppColors.secondary, size: 24),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _chipSmall(a.category),
                                            if (a.mediumUrl != null &&
                                                a.mediumUrl!.isNotEmpty)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFD1F4EA),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                        LucideIcons
                                                            .externalLink,
                                                        color:
                                                            AppColors.secondary,
                                                        size: 10),
                                                    Text(
                                                      ' Medium',
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .secondary),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          a.title,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.secondary,
                                              height: 20 / 15),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'by ${a.author} · ${timeAgo(DateTime.fromMillisecondsSinceEpoch(a.createdAt).toIso8601String())} ago · ${a.readMin} min read',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.mutedForeground),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(LucideIcons.heart,
                                                    color: AppColors
                                                        .mutedForeground,
                                                    size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${artLikes[a.id] ?? 0}',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .mutedForeground,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 12),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                    LucideIcons.messageSquare,
                                                    color: AppColors
                                                        .mutedForeground,
                                                    size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${comments[a.id]?.length ?? 0}',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .mutedForeground,
                                                      fontWeight:
                                                          FontWeight.w500),
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
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.only(top: 28, bottom: 16),
                    child: Text(
                      'All articles',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary),
                    ),
                  ),
                  Column(
                    children: [
                      for (final a in rest) ...[
                        GestureDetector(
                          onTap: () => context.pushNamed('ArticleDetail',
                              arguments: {'id': a.id}),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                              boxShadow: AppShadows.card,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  margin: const EdgeInsets.only(right: 16),
                                  decoration: BoxDecoration(
                                      color: AppColors.tertiary,
                                      borderRadius: BorderRadius.circular(6)),
                                  alignment: Alignment.center,
                                  child: Icon(getIcon(a.icon),
                                      color: AppColors.secondary, size: 24),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _chipSmall(a.category),
                                      const SizedBox(height: 6),
                                      Text(
                                        a.title,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.secondary,
                                            height: 20 / 15),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${a.readMin} min read',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.mutedForeground,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
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

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFFD1F4EA),
            borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary)),
      );

  Widget _chipSmall(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: const Color(0xFFD1F4EA),
              borderRadius: BorderRadius.circular(4)),
          child: Text(text,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary)),
        ),
      );
}
