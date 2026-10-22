import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../models/view_models.dart';
import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../state/auth_provider.dart';
import '../state/community_provider.dart';
import '../theme/theme.dart';
import '../widgets/icon_badge.dart';
import '../widgets/post_avatar.dart';

/// Direct port of `src/screens/HomeScreen.tsx`.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SpaceView> _spaces = [];
  List<PostView> _posts = [];
  List<EventView> _events = [];
  String _affirmation =
      'You are doing the unseen work that builds an entire world for your child.';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final userId = requireUserId(auth.user?.id, auth.isGuest);
    try {
      final results = await Future.wait([
        data.fetchSpaces(),
        data.fetchPosts(limit: 10),
        data.fetchEvents(),
        data.fetchDailyAffirmation(userId: userId),
      ]);
      final spaceRows = results[0] as List<DbSpace>;
      final postRows = results[1] as List<DbPost>;
      final eventRows = results[2] as List<DbEvent>;
      final aff = results[3] as DbRow?;
      final spaceMap = {for (final s in spaceRows) s.id: s.name};
      if (!mounted) return;
      setState(() {
        _spaces = spaceRows.take(3).map(mapSpace).toList();
        _posts = postRows
            .map((p) => mapPost(p, spaceName: spaceMap[p.spaceId] ?? ''))
            .toList();
        _events = eventRows.take(2).map(mapEvent).toList();
        _affirmation = aff?['text'] as String? ?? _affirmation;
      });
    } catch (_) {
      // Keep UI usable if a feed request fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final community = context.watch<CommunityProvider>();

    final myKitCount = community.seedKits
            .where((c) => community.kitDeleted[c.id] != true)
            .length +
        community.kits.length;
    final previewItems = community.seedKits
        .where((c) => community.kitDeleted[c.id] != true)
        .take(2)
        .map((c) {
      final p = community.kitEdits[c.id];
      return (
        id: c.id,
        name: p?.name ?? c.name,
        icon: getIcon(p?.icon ?? c.icon)
      );
    }).toList();

    final firstName = auth.profile?.displayName.split(' ').first ?? 'there';

    final quickActions = [
      (
        label: 'Calm Kit',
        icon: LucideIcons.wind,
        onPress: () => context.pushNamed('CalmKit')
      ),
      (
        label: 'Therapists',
        icon: LucideIcons.stethoscope,
        onPress: () => context.pushNamed('Therapists')
      ),
      (
        label: 'Events',
        icon: LucideIcons.calendar,
        onPress: () => MainTabsController.instance.switchTo('EventsTab')
      ),
      (
        label: 'Learn',
        icon: LucideIcons.bookOpen,
        onPress: () => MainTabsController.instance.switchTo('LearnTab')
      ),
    ];

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.card,
                      ),
                      child: Image.asset('assets/logo.png',
                          width: 40, height: 40, fit: BoxFit.contain),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.mutedForeground),
                          ),
                          Text(
                            'Hi, $firstName',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                    _IconButton(
                      onTap: () => context.pushNamed('Notifications'),
                      icon: LucideIcons.bell,
                      badge: true,
                      marginLeft: 12,
                    ),
                    _IconButton(
                      onTap: () => context.pushNamed('Profile'),
                      icon: LucideIcons.user,
                      marginLeft: 12,
                    ),
                  ],
                ),
              ),

              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: GestureDetector(
                  onTap: () => context.pushNamed('Search'),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.card,
                    ),
                    child: const Row(
                      children: [
                        Icon(LucideIcons.search,
                            color: AppColors.mutedForeground, size: 18),
                        SizedBox(width: 8),
                        Text('Search posts, members, resources...',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.mutedForeground)),
                      ],
                    ),
                  ),
                ),
              ),

              // Daily affirmation
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration:
                        const BoxDecoration(color: AppColors.affirmationBg),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: 0,
                          right: -10,
                          child: Opacity(
                            opacity: 0.15,
                            child: Icon(LucideIcons.sparkles,
                                color: AppColors.card, size: 100),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "TODAY'S REFLECTION",
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.card,
                                  letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '"$_affirmation"',
                              style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.card,
                                  height: 28 / 19),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () =>
                                  context.pushNamed('EmotionalSupport'),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Share how you're feeling",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(LucideIcons.chevronRight,
                                      color: AppColors.primary, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Quick actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final action in quickActions)
                      Expanded(
                        child: GestureDetector(
                          onTap: action.onPress,
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                margin: const EdgeInsets.only(bottom: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.tertiary,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: AppShadows.card,
                                ),
                                child: Icon(action.icon,
                                    color: AppColors.secondary, size: 24),
                              ),
                              Text(
                                action.label,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Your spaces
              _SectionHeader(
                title: 'Your spaces',
                onSeeAll: () =>
                    MainTabsController.instance.switchTo('SpacesTab'),
              ),
              SizedBox(
                height: 118,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final space in _spaces)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: () => context.pushNamed('SpaceDetail',
                              arguments: {'spaceId': space.id}),
                          child: Container(
                            width: 150,
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
                                Container(
                                  width: 44,
                                  height: 44,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.tertiary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(space.icon,
                                      color: AppColors.secondary, size: 20),
                                ),
                                Text(
                                  space.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary,
                                      height: 18 / 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${space.postCount} ${space.postCount == 1 ? 'post' : 'posts'}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.mutedForeground),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Community feed
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Text(
                  'Community feed',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
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
                                                  color: AppColors.secondary)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${post.time}${post.space.isNotEmpty ? ' · ${post.space}' : ''}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppColors.mutedForeground),
                                          ),
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.mutedForeground,
                                      height: 22 / 14),
                                ),
                                if (post.tags.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final tag in post.tags)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.tertiary,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text('#$tag',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.secondary)),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Upcoming nearby
              _SectionHeader(
                title: 'Upcoming nearby',
                onSeeAll: () =>
                    MainTabsController.instance.switchTo('EventsTab'),
              ),
              SizedBox(
                height: 210,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final event in _events)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: () => context.pushNamed('EventDetail',
                              arguments: {'id': event.id}),
                          child: Container(
                            width: 240,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                              boxShadow: AppShadows.card,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 100,
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  color: AppColors.tertiary,
                                  child: Icon(event.icon,
                                      color: AppColors.secondary, size: 32),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        decoration: BoxDecoration(
                                          color: AppColors.tertiary,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(event.type,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.secondary)),
                                      ),
                                      Text(
                                        event.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.secondary),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(event.date,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color:
                                                  AppColors.mutedForeground)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Your calm kit
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.calmBannerBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.tertiary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Calm Kit',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$myKitCount items ready when you need them.',
                                  style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.secondary)
                                      .copyWith(
                                          color: AppColors.secondary
                                              .withValues(alpha: 0.8)),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.pushNamed('CalmKit'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Open',
                                  style: TextStyle(
                                      color: AppColors.card,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          padding: const EdgeInsets.only(top: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: previewItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final item = previewItems[i];
                            return GestureDetector(
                              onTap: () => context.pushNamed('CalmItemDetail',
                                  arguments: {'id': item.id}),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(item.icon,
                                        color: AppColors.secondary, size: 16),
                                    const SizedBox(width: 8),
                                    Text(item.name,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.secondary)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary)),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text('See all',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary)),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final bool badge;
  final double marginLeft;

  const _IconButton(
      {required this.onTap,
      required this.icon,
      this.badge = false,
      this.marginLeft = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        margin: EdgeInsets.only(left: marginLeft),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: AppColors.secondary, size: 20),
            if (badge)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
