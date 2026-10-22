import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/view_models.dart';
import '../navigation/nav.dart';
import '../state/community_provider.dart';
import '../theme/theme.dart';
import '../utils/utils.dart';
import '../widgets/icon_badge.dart';

class CalmItemDetailScreen extends StatefulWidget {
  const CalmItemDetailScreen({super.key});

  @override
  State<CalmItemDetailScreen> createState() => _CalmItemDetailScreenState();
}

class _CalmItemDetailScreenState extends State<CalmItemDetailScreen> {
  final _nameController = TextEditingController();
  final _textController = TextEditingController();
  final _shareAuthorController = TextEditingController();
  bool _showDelete = false;
  bool _showShare = false;
  bool _commentsLoaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _textController.dispose();
    _shareAuthorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = (routeArgs(context)['id'] as String?) ?? '';
    final community = context.watch<CommunityProvider>();

    if (!_commentsLoaded) {
      _commentsLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        community.loadComments(id, 'calm_kit');
      });
    }

    final communityKit = community.kits.where((k) => k.id == id).firstOrNull;
    final seed = communityKit == null
        ? community.seedKits.where((x) => x.id == id).firstOrNull
        : null;

    if ((community.kitDeleted[id] ?? false) && communityKit == null) {
      return _notFoundScaffold(context, "This Calm Kit was removed.");
    }

    final base = communityKit ?? seed;
    if (base == null) {
      return _notFoundScaffold(context, 'Item not found.');
    }

    final patch = communityKit != null ? null : community.kitEdits[base.id];
    final name = patch?.name ?? base.name;
    final why = patch?.why ?? base.why;
    final when = patch?.when ?? base.when;
    final icon = patch?.icon ?? base.icon;
    final tags = patch?.tags ?? base.tags;
    final author = communityKit?.author;
    final createdAt = communityKit?.createdAt;

    final isCommunity = communityKit != null;
    final votes = community.kitVotes[base.id] ?? 0;
    final voted = community.myKitVotes[base.id] ?? false;
    final list = community.comments[base.id] ?? [];
    final pinned = community.isPinned(base.id, seedDefault: seed != null);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHero(
                  context, name, icon, tags, isCommunity, author, createdAt),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoCard('WHY IT HELPS', why),
                    const SizedBox(height: 16),
                    _infoCard('WHEN TO USE', when),
                    const SizedBox(height: 16),
                    _buildActionRow(context, community, base.id, isCommunity,
                        votes, voted, pinned, seed != null),
                    const SizedBox(height: 12),
                    _buildManageRow(
                        context, community, base.id, isCommunity, name),
                    const SizedBox(height: 20),
                    _buildCommentsCard(context, community, base.id, list),
                  ],
                ),
              ),
            ],
          ),
          if (_showDelete)
            _buildDeleteModal(context, community, base.id, isCommunity),
          if (_showShare) _buildShareModal(context, community, base.id),
        ],
      ),
    );
  }

  Widget _notFoundScaffold(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.mutedForeground)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => context.pushNamed('CalmKit'),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6)),
                    alignment: Alignment.center,
                    child: const Text(
                      'Back to Calm Kit',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(
    BuildContext context,
    String name,
    String icon,
    List<String> tags,
    bool isCommunity,
    String? author,
    int? createdAt,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.calmBannerBg,
        border: Border(bottom: BorderSide(color: AppColors.tertiary)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => context.goBack(),
                child: Container(
                  width: 44,
                  height: 44,
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
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              alignment: Alignment.center,
              child: Icon(getIcon(icon), color: AppColors.secondary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
                height: 30 / 24,
              ),
            ),
            if (isCommunity) ...[
              const SizedBox(height: 4),
              Text(
                'by $author · ${timeAgo(DateTime.fromMillisecondsSinceEpoch(createdAt!).toIso8601String())} ago',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xCC0E4A3C),
                    fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          '#$t',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedForeground,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(text,
              style: const TextStyle(
                  fontSize: 15, height: 24 / 15, color: Color(0xE60E1F1A))),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    CommunityProvider community,
    String id,
    bool isCommunity,
    int votes,
    bool voted,
    bool pinned,
    bool isSeed,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (isCommunity)
          GestureDetector(
            onTap: () => community.toggleKitVote(id),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: voted ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: voted ? AppColors.primary : AppColors.border),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.arrowBigUp,
                      color: AppColors.secondary, size: 16),
                  const SizedBox(width: 6),
                  Text('Upvote · $votes',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary)),
                ],
              ),
            ),
          ),
        GestureDetector(
          onTap: () async {
            await community.togglePin(id, seedDefault: isSeed);
            if (context.mounted) {
              _showAlert(context, pinned ? 'Unpinned' : 'Pinned to top', null);
            }
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: pinned ? AppColors.secondary : AppColors.card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: pinned ? AppColors.secondary : AppColors.border),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(pinned ? LucideIcons.pinOff : LucideIcons.pin,
                    color: pinned ? AppColors.card : AppColors.secondary,
                    size: 16),
                const SizedBox(width: 6),
                Text(
                  pinned ? 'Unpin' : 'Pin to top',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: pinned ? AppColors.card : AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _shareLink(context, community, id),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: AppColors.muted, borderRadius: BorderRadius.circular(6)),
            alignment: Alignment.center,
            child: const Icon(LucideIcons.share2,
                color: AppColors.secondary, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildManageRow(
    BuildContext context,
    CommunityProvider community,
    String id,
    bool isCommunity,
    String name,
  ) {
    return Row(
      children: [
        Expanded(
          child: _manageButton(
            icon: LucideIcons.pencil,
            label: 'Edit',
            onTap: () =>
                context.pushNamed('CreateCalmItem', arguments: {'id': id}),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: !isCommunity
              ? _manageButton(
                  icon: LucideIcons.upload,
                  label: 'Share',
                  onTap: () => setState(() => _showShare = true),
                )
              : _manageButton(
                  icon: LucideIcons.share2,
                  label: 'Share',
                  onTap: () => _shareLink(context, community, id),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _manageButton(
            icon: LucideIcons.trash2,
            label: 'Delete',
            color: AppColors.destructive,
            borderColor: const Color(0x66D13232),
            onTap: () => setState(() => _showDelete = true),
          ),
        ),
      ],
    );
  }

  Widget _manageButton({
    required IconData icon,
    required String label,
    Color color = AppColors.secondary,
    Color borderColor = AppColors.border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsCard(
    BuildContext context,
    CommunityProvider community,
    String id,
    List<CommentView> list,
  ) {
    return Container(
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
          Text('Comments (${list.length})',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary)),
          const SizedBox(height: 12),
          _commentField(_nameController, 'Your name (optional)'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                  child: _commentField(
                      _textController, 'Share your experience…',
                      maxLength: 500)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _submitComment(community, id),
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
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Be the first to comment.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.mutedForeground)),
            ),
          ...list.map((cm) => Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border))),
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
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(cm.text,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xE60E1F1A))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _commentField(TextEditingController controller, String placeholder,
      {int? maxLength}) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        decoration: InputDecoration(
          counterText: '',
          hintText: placeholder,
          hintStyle: const TextStyle(color: AppColors.mutedForeground),
          filled: true,
          fillColor: AppColors.muted,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none),
        ),
        style: const TextStyle(fontSize: 14, color: AppColors.ink),
      ),
    );
  }

  Future<void> _submitComment(CommunityProvider community, String id) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final name = _nameController.text.trim();
    await community.addComment(id, name.isNotEmpty ? name : 'Anonymous', text);
    _textController.clear();
    setState(() {});
  }

  Future<void> _shareLink(
      BuildContext context, CommunityProvider community, String id) async {
    final base = community.kits.where((k) => k.id == id).firstOrNull ??
        community.seedKits.where((k) => k.id == id).firstOrNull;
    final name = base?.name ?? '';
    await Share.share('Check out this Calm Kit: $name', subject: name);
  }

  void _showAlert(BuildContext context, String title, String? message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: message != null ? Text(message) : null,
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))
        ],
      ),
    );
  }

  Widget _buildDeleteModal(BuildContext context, CommunityProvider community,
      String id, bool isCommunity) {
    return Container(
      color: const Color(0x66000000),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delete this Calm Kit?',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary)),
            const SizedBox(height: 8),
            Text(
              "This removes it from your kit${isCommunity ? ' and the community feed' : ''}. This action can't be undone.",
              style: const TextStyle(
                  fontSize: 14, color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.destructive,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () async {
                  await community.deleteKit(id);
                  setState(() => _showDelete = false);
                  if (context.mounted) {
                    await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Deleted'),
                        content: const Text('Calm Kit removed.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                    if (context.mounted) context.pushNamed('CalmKit');
                  }
                },
                child: const Text('Delete',
                    style: TextStyle(
                        color: AppColors.card,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => setState(() => _showDelete = false),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareModal(
      BuildContext context, CommunityProvider community, String id) {
    return Container(
      color: const Color(0x66000000),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share with community',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary)),
            const SizedBox(height: 8),
            const Text(
              'Publish a copy of this kit so other families can browse and upvote it.',
              style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 16),
            _commentField(
                _shareAuthorController, 'Your display name (optional)'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () async {
                  final author = _shareAuthorController.text.trim();
                  final item = await community.shareSeedToCommunity(
                      id, author.isNotEmpty ? author : 'Anonymous');
                  setState(() => _showShare = false);
                  if (context.mounted) {
                    await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Shared'),
                        content: const Text('Now live in the community.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed(
                          'CalmItemDetail',
                          arguments: {'id': item.id});
                    }
                  }
                },
                child: const Text('Publish',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => setState(() => _showShare = false),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
