import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../theme/theme.dart';

/// Direct port of `src/screens/CommunityGuidelinesScreen.tsx`.
class CommunityGuidelinesScreen extends StatefulWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  State<CommunityGuidelinesScreen> createState() =>
      _CommunityGuidelinesScreenState();
}

class _Rule {
  final String title;
  final String body;
  const _Rule({required this.title, required this.body});
}

class _CommunityGuidelinesScreenState extends State<CommunityGuidelinesScreen> {
  List<_Rule> _rules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    data.fetchGuidelines().then((rows) {
      if (!mounted) return;
      setState(() {
        _rules = rows
            .map((r) => _Rule(
                title: r['title'] as String? ?? '',
                body: r['body'] as String? ?? ''))
            .toList();
      });
    }).whenComplete(() {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  const Expanded(
                    child: Text(
                      'Community guidelines',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < _rules.length; i++) ...[
                            if (i != 0) const SizedBox(height: 16),
                            _RuleCard(index: i, rule: _rules[i]),
                          ],
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

class _RuleCard extends StatelessWidget {
  final int index;
  final _Rule rule;
  const _RuleCard({required this.index, required this.rule});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RULE ${index + 1}',
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            rule.title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary),
          ),
          const SizedBox(height: 6),
          Text(
            rule.body,
            style: const TextStyle(
                fontSize: 15,
                color: Color.fromRGBO(14, 31, 26, 0.85),
                height: 22 / 15),
          ),
        ],
      ),
    );
  }
}
