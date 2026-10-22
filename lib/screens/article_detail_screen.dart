import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/view_models.dart';
import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../state/community_provider.dart';
import '../theme/theme.dart';
import '../utils/utils.dart';
import '../widgets/icon_badge.dart';

class _ArticleBase {
  final String id;
  final String title;
  final String category;
  final int readMin;
  final String icon;
  final String excerpt;
  final String? body;
  final String? mediumUrl;
  final String author;

  _ArticleBase({
    required this.id,
    required this.title,
    required this.category,
    required this.readMin,
    required this.icon,
    required this.excerpt,
    required this.body,
    required this.mediumUrl,
    required this.author,
  });

  factory _ArticleBase.fromCommunityArticle(CommunityArticle a) => _ArticleBase(
        id: a.id,
        title: a.title,
        category: a.category,
        readMin: a.readMin,
        icon: a.icon,
        excerpt: a.excerpt,
        body: a.body,
        mediumUrl: a.mediumUrl,
        author: a.author,
      );

  factory _ArticleBase.fromEditorial(dynamic a) => _ArticleBase(
        id: a.id as String,
        title: a.title as String,
        category: a.category as String,
        readMin: a.readMin as int,
        icon: a.icon as String,
        excerpt: a.excerpt as String,
        body: a.body as String?,
        mediumUrl: a.mediumUrl as String?,
        author: (a.authorDisplayName as String?) ?? 'United Editorial',
      );
}

class ArticleDetailScreen extends StatefulWidget {
  const ArticleDetailScreen({super.key});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  String? _loadedForId;
  dynamic _fetchedEditorial;
  final _nameController = TextEditingController();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = (routeArgs(context)['id'] as String?) ?? '';
    if (_loadedForId != id) {
      _loadedForId = id;
      final community = context.read<CommunityProvider>();
      if (id.isNotEmpty) community.loadComments(id, 'article');
      final fromList =
          community.editorialArticles.where((a) => a.id == id).toList();
      if (fromList.isNotEmpty) {
        setState(() => _fetchedEditorial = fromList.first);
      } else if (id.isNotEmpty) {
        data.fetchArticle(id).then((row) {
          if (row != null && mounted) setState(() => _fetchedEditorial = row);
        });
      }
    }
  }

  Future<void> _onComment(String id) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final name = _nameController.text.trim();
    await context
        .read<CommunityProvider>()
        .addComment(id, name.isNotEmpty ? name : 'Anonymous', text);
    _textController.clear();
  }

  Future<void> _share(String title) async {
    await Share.share(title, subject: title);
  }

  Future<void> _openMedium(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityProvider>();
    final id = (routeArgs(context)['id'] as String?) ?? '';
    final userArticle = community.articles.where((a) => a.id == id).toList();
    final CommunityArticle? userArt =
        userArticle.isNotEmpty ? userArticle.first : null;

    _ArticleBase? base;
    if (userArt != null) {
      base = _ArticleBase.fromCommunityArticle(userArt);
    } else if (_fetchedEditorial != null) {
      base = _ArticleBase.fromEditorial(_fetchedEditorial);
    }

    if (base == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final isUser = userArt != null;
    final likes = community.artLikes[base.id] ?? (isUser ? 0 : 124);
    final liked = community.myArtLikes[base.id] ?? false;
    final list = community.comments[base.id] ?? [];
    final icon = getIcon(base.icon);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 240,
              child: Stack(
                children: [
                  Container(
                      width: double.infinity,
                      height: 240,
                      color: const Color(0xFF1B5646)),
                  Positioned.fill(
                    child: Center(
                        child: Icon(icon, color: AppColors.primary, size: 80)),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: GestureDetector(
                          onTap: () => context.goBack(),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(LucideIcons.chevronLeft,
                                color: AppColors.card, size: 24),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _chip(base.category),
                      if (isUser &&
                          base.mediumUrl != null &&
                          base.mediumUrl!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: const Color(0xFFD1F4EA),
                              borderRadius: BorderRadius.circular(4)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.externalLink,
                                  color: AppColors.secondary, size: 12),
                              Text(' Medium',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    base.title,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                        height: 34 / 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isUser
                        ? 'by ${userArt.author} · ${timeAgo(DateTime.fromMillisecondsSinceEpoch(userArt.createdAt).toIso8601String())} ago · ${base.readMin} min read'
                        : '${base.readMin} min read · United Editorial',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedForeground,
                        fontWeight: FontWeight.w500),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          base.excerpt,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink.withValues(alpha: 0.9),
                              height: 26 / 16),
                        ),
                        const SizedBox(height: 16),
                        if (isUser &&
                            base.mediumUrl != null &&
                            base.mediumUrl!.isNotEmpty)
                          GestureDetector(
                            onTap: () => _openMedium(base!.mediumUrl),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              height: 44,
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(6)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Read full article on Medium',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.card)),
                                  SizedBox(width: 8),
                                  Icon(LucideIcons.externalLink,
                                      color: AppColors.card, size: 16),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          if (base.body != null && base.body!.isNotEmpty)
                            _paragraph(base.body!),
                          if (!isUser) ...[
                            _paragraph(
                              "Every child experiences the world differently. As a caregiver, your job isn't "
                              "to fix — it's to translate, to advocate, and to love loudly. This guide is "
                              "built around three gentle principles:",
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8, bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  _BulletItem(
                                      text: 'Connection before correction'),
                                  _BulletItem(
                                      text: 'Curiosity before conclusions'),
                                  _BulletItem(
                                      text:
                                          'Compassion — for them, and for you'),
                                ],
                              ),
                            ),
                            _paragraph(
                              "You don't need to do this perfectly. You just need to keep showing up — and "
                              "you already are.",
                            ),
                          ],
                          if (isUser &&
                              base.body != null &&
                              base.body!.isNotEmpty &&
                              (base.mediumUrl == null ||
                                  base.mediumUrl!.isEmpty))
                            const SizedBox.shrink(),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(color: AppColors.border),
                          bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context
                              .read<CommunityProvider>()
                              .toggleArticleLike(base!.id),
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: liked
                                  ? AppColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                  color: liked
                                      ? AppColors.primary
                                      : Colors.transparent),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.heart,
                                  color: liked
                                      ? AppColors.secondary
                                      : AppColors.ink,
                                  size: 20,
                                  fill: liked ? 1 : 0,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$likes',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: liked
                                        ? AppColors.secondary
                                        : AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(6)),
                          alignment: Alignment.center,
                          child: const Icon(LucideIcons.bookmark,
                              color: AppColors.ink, size: 18),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _share(base!.title),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(6)),
                            alignment: Alignment.center,
                            child: const Icon(LucideIcons.share2,
                                color: AppColors.ink, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comments (${list.length})',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary),
                        ),
                        const SizedBox(height: 12),
                        _commentInput(
                            controller: _nameController,
                            hint: 'Your name (optional)'),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _commentInput(
                                  controller: _textController,
                                  hint: 'Add a comment…',
                                  maxLength: 500),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _onComment(base!.id),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6)),
                                alignment: Alignment.center,
                                child: const Icon(LucideIcons.send,
                                    color: AppColors.secondary, size: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (list.isEmpty)
                          Text('Start the conversation.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedForeground)),
                        for (final cm in list)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.only(top: 12),
                            decoration: const BoxDecoration(
                                border: Border(
                                    top: BorderSide(color: AppColors.border))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary),
                                    children: [
                                      TextSpan(text: cm.author),
                                      TextSpan(
                                        text:
                                            ' · ${timeAgo(DateTime.fromMillisecondsSinceEpoch(cm.createdAt).toIso8601String())} ago',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.mutedForeground),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cm.text,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          AppColors.ink.withValues(alpha: 0.9)),
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
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0xFFD1F4EA),
            borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary)),
      );

  Widget _paragraph(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 16,
              color: AppColors.ink.withValues(alpha: 0.9),
              height: 26 / 16),
        ),
      );

  Widget _commentInput(
      {required TextEditingController controller,
      required String hint,
      int? maxLength}) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: AppColors.muted, borderRadius: BorderRadius.circular(6)),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        style: const TextStyle(fontSize: 14, color: AppColors.ink),
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

class _BulletItem extends StatelessWidget {
  final String text;

  const _BulletItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ',
              style: TextStyle(
                  fontSize: 16, color: AppColors.ink.withValues(alpha: 0.9))),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 16,
                  color: AppColors.ink.withValues(alpha: 0.9),
                  height: 26 / 16),
            ),
          ),
        ],
      ),
    );
  }
}
