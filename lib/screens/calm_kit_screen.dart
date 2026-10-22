import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/view_models.dart';
import '../navigation/nav.dart';
import '../state/community_provider.dart';
import '../theme/theme.dart';
import '../utils/utils.dart';
import '../widgets/icon_badge.dart';

class _MergedKit {
  final String id;
  final String name;
  final String why;
  final String when;
  final String icon;
  final List<String> tags;
  final bool pinned;
  final bool community;
  final String? author;
  final int? createdAt;

  _MergedKit({
    required this.id,
    required this.name,
    required this.why,
    required this.when,
    required this.icon,
    required this.tags,
    required this.pinned,
    this.community = false,
    this.author,
    this.createdAt,
  });
}

class CalmKitScreen extends StatefulWidget {
  const CalmKitScreen({super.key});

  @override
  State<CalmKitScreen> createState() => _CalmKitScreenState();
}

class _CalmKitScreenState extends State<CalmKitScreen> {
  String _tab = 'mine';
  String? _confirmId;

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityProvider>();

    final myKits = <_MergedKit>[
      ...community.seedItems
          .where((c) => community.kitDeleted[c.id] != true)
          .map((c) {
        final p = community.kitEdits[c.id];
        return _MergedKit(
          id: c.id,
          name: p?.name ?? c.name,
          why: p?.why ?? c.why,
          when: p?.when ?? c.whenToUse,
          icon: p?.icon ?? c.icon,
          tags: p?.tags ?? c.tags,
          pinned: community.isPinned(c.id, seedDefault: false),
        );
      }),
      ...community.kits.map((k) => _MergedKit(
            id: k.id,
            name: k.name,
            why: k.why,
            when: k.when,
            icon: k.icon,
            tags: k.tags,
            pinned: community.isPinned(k.id, seedDefault: false),
            community: true,
            author: k.author,
            createdAt: k.createdAt,
          )),
    ];

    final sortedCommunity = [...community.kits]..sort(
        (a, b) => (community.kitVotes[b.id] ?? 0)
            .compareTo(community.kitVotes[a.id] ?? 0),
      );

    final pinnedItems = myKits.where((k) => k.pinned).toList();
    final restItems = myKits.where((k) => !k.pinned).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                children: [
                  _buildHeroBanner(),
                  const SizedBox(height: 20),
                  _buildTabBar(community),
                  if (_tab == 'mine') ...[
                    if (pinnedItems.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(LucideIcons.pin,
                              color: AppColors.mutedForeground, size: 12),
                          const SizedBox(width: 6),
                          Text('PINNED', style: _sectionLabelStyle),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...pinnedItems
                          .map((c) => _buildCalmCard(context, community, c)),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 12),
                      child: Text('ALL ITEMS', style: _sectionLabelStyle),
                    ),
                    if (restItems.isEmpty && pinnedItems.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'All your items are pinned.',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.mutedForeground),
                        ),
                      ),
                    ...restItems
                        .map((c) => _buildCalmCard(context, community, c)),
                  ] else ...[
                    if (sortedCommunity.isEmpty) _buildEmptyCommunity(context),
                    ...sortedCommunity
                        .map((k) => _buildCommunityCard(context, community, k)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _sectionLabelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.mutedForeground,
    letterSpacing: 1,
  );

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          _iconButton(
            icon: LucideIcons.chevronLeft,
            background: AppColors.card,
            border: AppColors.border,
            iconColor: AppColors.secondary,
            onTap: () => context.goBack(),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calm Kit Builder',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary),
                ),
                SizedBox(height: 2),
                Text(
                  'Tools that bring your child back to safe',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          _iconButton(
            icon: LucideIcons.plus,
            background: AppColors.primary,
            iconColor: AppColors.secondary,
            onTap: () => context.pushNamed('CreateCalmItem'),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color background,
    Color? border,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
          border: border != null ? Border.all(color: border) : null,
          boxShadow: border != null ? AppShadows.card : null,
        ),
        alignment: Alignment.center,
        child: Icon(icon,
            color: iconColor, size: icon == LucideIcons.plus ? 20 : 24),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.calmBannerBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.tertiary),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage your sensory regulation tools',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary),
          ),
          SizedBox(height: 4),
          Text(
            'Create your own kit or browse what helped other families most.',
            style: TextStyle(fontSize: 14, color: Color(0xCC0E4A3C)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(CommunityProvider community) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tabButton('mine', 'My Kit'),
          _tabButton('community', 'Community (${community.kits.length})'),
        ],
      ),
    );
  }

  Widget _tabButton(String value, String label) {
    final active = _tab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = value),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.card : null,
            borderRadius: BorderRadius.circular(4),
            boxShadow: active ? AppShadows.card : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.secondary : AppColors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalmCard(
      BuildContext context, CommunityProvider community, _MergedKit c) {
    return Container(
      key: ValueKey(c.id),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context
                      .pushNamed('CalmItemDetail', arguments: {'id': c.id}),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: AppColors.tertiary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.tertiary),
                        ),
                        alignment: Alignment.center,
                        child: Icon(getIcon(c.icon),
                            color: AppColors.secondary, size: 20),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                            if (c.community) ...[
                              const SizedBox(height: 2),
                              Text(
                                'shared · by ${c.author}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.mutedForeground),
                              ),
                            ],
                            const SizedBox(height: 6),
                            _tagsRow(c.tags),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showItemMenu(context, community, c),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(LucideIcons.moreVertical,
                      color: AppColors.mutedForeground, size: 16),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () =>
                context.pushNamed('CalmItemDetail', arguments: {'id': c.id}),
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.only(left: 12),
              decoration: const BoxDecoration(
                border: Border(
                    left: BorderSide(color: AppColors.primary, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WHEN TO USE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.when,
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xD90E1F1A)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagsRow(List<String> tags) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags
          .map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tertiary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#$t',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary),
                ),
              ))
          .toList(),
    );
  }

  void _showItemMenu(
      BuildContext context, CommunityProvider community, _MergedKit c) {
    showDialog(
      context: context,
      barrierColor: const Color(0x4D000000),
      builder: (dialogContext) {
        return Center(
          child: Container(
            constraints: const BoxConstraints(minWidth: 200),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _menuItem(
                  icon: c.pinned ? LucideIcons.pinOff : LucideIcons.pin,
                  label: c.pinned ? 'Unpin' : 'Pin to top',
                  onTap: () async {
                    Navigator.of(dialogContext).pop();
                    await community.togglePin(c.id, seedDefault: false);
                  },
                ),
                _menuItem(
                  icon: LucideIcons.pencil,
                  label: 'Edit',
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    context
                        .pushNamed('CreateCalmItem', arguments: {'id': c.id});
                  },
                ),
                _menuItem(
                  icon: LucideIcons.trash2,
                  label: 'Delete',
                  color: AppColors.destructive,
                  showBorder: false,
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    setState(() => _confirmId = c.id);
                    _showDeleteDialog(context, community);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    Color color = AppColors.secondary,
    bool showBorder = true,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: showBorder
              ? const Border(bottom: BorderSide(color: AppColors.border))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, CommunityProvider community) {
    showDialog(
      context: context,
      barrierColor: const Color(0x66000000),
      builder: (dialogContext) {
        return Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(8)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delete this Calm Kit?',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary),
                ),
                const SizedBox(height: 8),
                const Text(
                  "This action can't be undone.",
                  style:
                      TextStyle(fontSize: 14, color: AppColors.mutedForeground),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.destructive,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final id = _confirmId;
                      Navigator.of(dialogContext).pop();
                      if (id == null) return;
                      await community.deleteKit(id);
                      setState(() => _confirmId = null);
                      if (context.mounted) {
                        _showInfoDialog(
                            context, 'Deleted', 'Calm Kit removed.');
                      }
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                          color: AppColors.card,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      setState(() => _confirmId = null);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
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

  Widget _buildEmptyCommunity(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Text(
            'No community kits yet',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Be the first to share what works for your child.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.pushNamed('CreateCalmItem'),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.plus, color: AppColors.secondary, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Create & Share',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCard(
      BuildContext context, CommunityProvider community, CommunityCalmKit k) {
    final votes = community.kitVotes[k.id] ?? 0;
    final voted = community.myKitVotes[k.id] ?? false;
    final cCount = community.comments[k.id]?.length ?? 0;
    return Container(
      key: ValueKey(k.id),
      margin: const EdgeInsets.only(bottom: 12),
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
          GestureDetector(
            onTap: () => community.toggleKitVote(k.id),
            child: Container(
              width: 48,
              height: 64,
              decoration: BoxDecoration(
                color: voted ? AppColors.primary : AppColors.muted,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: voted ? AppColors.primary : AppColors.border),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.arrowBigUp,
                      color: AppColors.secondary, size: 20),
                  Text(
                    '$votes',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  context.pushNamed('CalmItemDetail', arguments: {'id': k.id}),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppColors.tertiary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.tertiary),
                        ),
                        alignment: Alignment.center,
                        child: Icon(getIcon(k.icon),
                            color: AppColors.secondary, size: 20),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              k.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'by ${k.author} · ${timeAgo(DateTime.fromMillisecondsSinceEpoch(k.createdAt).toIso8601String())}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.mutedForeground),
                            ),
                            const SizedBox(height: 6),
                            _tagsRow(k.tags.take(3).toList()),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    k.why,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xD90E1F1A)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.messageSquare,
                          color: AppColors.mutedForeground, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '$cCount comments',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedForeground,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
