import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/view_models.dart';
import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../theme/theme.dart';

/// Direct port of `src/screens/SpacesScreen.tsx`.
class SpacesScreen extends StatefulWidget {
  const SpacesScreen({super.key});

  @override
  State<SpacesScreen> createState() => _SpacesScreenState();
}

class _SpacesScreenState extends State<SpacesScreen> with AppRouteAware {
  List<SpaceView> _spaces = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onRefocus() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await data.fetchSpaces();
      if (!mounted) return;
      setState(() => _spaces = rows.map(mapSpace).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _spaces = [];
        _error = e.toString().isNotEmpty
            ? e.toString()
            : 'Could not load spaces. Pull to refresh by leaving and returning.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Community Spaces',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary),
                        ),
                        SizedBox(height: 2),
                        Text('Find your people',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.mutedForeground)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pushNamed('CreatePost'),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: AppShadows.card,
                      ),
                      child: const Icon(LucideIcons.plus,
                          color: AppColors.secondary, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 12),
            Text('Loading spaces…',
                style:
                    TextStyle(fontSize: 14, color: AppColors.mutedForeground)),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                    height: 20 / 14),
              ),
              const SizedBox(height: 16),
              _RetryButton(onTap: _load),
            ],
          ),
        ),
      );
    }
    if (_spaces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No spaces yet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Run the seed migration in Supabase, then tap Try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                    height: 20 / 14),
              ),
              const SizedBox(height: 16),
              _RetryButton(onTap: _load),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      itemCount: _spaces.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final space = _spaces[i];
        return GestureDetector(
          onTap: () => context
              .pushNamed('SpaceDetail', arguments: {'spaceId': space.id}),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(space.icon, color: AppColors.secondary, size: 24),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          space.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          space.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.mutedForeground),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${space.postCount} ${space.postCount == 1 ? 'post' : 'posts'}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                ),
                const Icon(LucideIcons.chevronRight,
                    color: AppColors.mutedForeground, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RetryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RetryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.tertiary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('Try again',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary)),
      ),
    );
  }
}
