import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/models.dart';
import '../models/view_models.dart';
import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../theme/theme.dart';

/// Direct port of `src/screens/SearchScreen.tsx`.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  Map<String, String> _spaceNames = {};
  SearchResults? _results;

  @override
  void initState() {
    super.initState();
    data.fetchSpaces().then((rows) {
      if (!mounted) return;
      setState(() => _spaceNames = {for (final s in rows) s.id: s.name});
    }).catchError((_) {});
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    setState(() {});
    _debounce?.cancel();
    final text = _controller.text;
    _debounce =
        Timer(const Duration(milliseconds: 300), () => _runSearch(text));
  }

  Future<void> _runSearch(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      setState(() => _results = null);
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await data.searchCommunity(trimmed);
      if (!mounted) return;
      setState(() => _results = r);
    } catch (_) {
      if (!mounted) return;
      setState(() => _results = SearchResults.empty());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text;
    final hasQuery = query.trim().isNotEmpty;
    final results = _results;
    final total = (results?.posts.length ?? 0) +
        (results?.members.length ?? 0) +
        (results?.articles.length ?? 0) +
        (results?.events.length ?? 0) +
        (results?.spaces.length ?? 0);

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => context.goBack(),
                    child: Container(
                      width: 44,
                      height: 44,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.card,
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.search,
                              color: AppColors.mutedForeground, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (text) {
                                _debounce?.cancel();
                                _runSearch(text);
                              },
                              style: const TextStyle(
                                  fontSize: 16, color: AppColors.ink),
                              decoration: const InputDecoration(
                                hintText: 'Search posts, members, resources...',
                                hintStyle:
                                    TextStyle(color: AppColors.mutedForeground),
                                border: InputBorder.none,
                                isCollapsed: true,
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!hasQuery)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Try a topic like "IEP", "meltdown", or a member name.',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedForeground,
                              height: 20 / 14),
                        ),
                      ),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      ),
                    if (hasQuery && !_loading && results != null && total == 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Center(
                          child: Text(
                            'No results for "${query.trim()}"',
                            style: const TextStyle(
                                fontSize: 15, color: AppColors.mutedForeground),
                          ),
                        ),
                      ),
                    if (results != null && results.posts.isNotEmpty)
                      _Section(
                        title: 'Posts',
                        icon: LucideIcons.fileText,
                        children: [
                          for (final post in results.posts.map((p) => mapPost(p,
                              spaceName: _spaceNames[p.spaceId] ?? '')))
                            _ResultCard(
                              title: post.title,
                              meta: '${post.author} · ${post.space}',
                              onTap: () => context.pushNamed('PostDetail',
                                  arguments: {'postId': post.id}),
                            ),
                        ],
                      ),
                    if (results != null && results.members.isNotEmpty)
                      _Section(
                        title: 'Members',
                        icon: LucideIcons.users,
                        children: [
                          for (final member in results.members.map(mapMember))
                            _ResultCard(
                              title: member.name,
                              meta:
                                  '${member.role}${member.location.isNotEmpty ? ' · ${member.location}' : ''}',
                              onTap: () =>
                                  context.pushNamed('MembersDirectory'),
                            ),
                        ],
                      ),
                    if (results != null && results.articles.isNotEmpty)
                      _Section(
                        title: 'Articles',
                        icon: LucideIcons.bookOpen,
                        children: [
                          for (final a in results.articles)
                            _ResultCard(
                              title: a.title,
                              meta: '${a.category} · ${a.readMin} min read',
                              onTap: () => context.pushNamed('ArticleDetail',
                                  arguments: {'id': a.id}),
                            ),
                        ],
                      ),
                    if (results != null && results.events.isNotEmpty)
                      _Section(
                        title: 'Events',
                        icon: LucideIcons.calendar,
                        children: [
                          for (final event in results.events.map(mapEvent))
                            _ResultCard(
                              title: event.title,
                              meta: '${event.type} · ${event.date}',
                              onTap: () => context.pushNamed('EventDetail',
                                  arguments: {'id': event.id}),
                            ),
                        ],
                      ),
                    if (results != null && results.spaces.isNotEmpty)
                      _Section(
                        title: 'Spaces',
                        icon: LucideIcons.hash,
                        children: [
                          for (final space in results.spaces.map(mapSpace))
                            _ResultCard(
                              title: space.name,
                              meta: space.description,
                              metaMaxLines: 1,
                              onTap: () => context.pushNamed('SpaceDetail',
                                  arguments: {'spaceId': space.id}),
                            ),
                        ],
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

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(icon, color: AppColors.secondary, size: 16),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary)),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String meta;
  final int? metaMaxLines;
  final VoidCallback onTap;

  const _ResultCard(
      {required this.title,
      required this.meta,
      this.metaMaxLines,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary),
              ),
              const SizedBox(height: 4),
              Text(
                meta,
                maxLines: metaMaxLines,
                overflow: metaMaxLines != null ? TextOverflow.ellipsis : null,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
