import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/view_models.dart';
import '../navigation/nav.dart';
import '../services/data_service.dart' as data;
import '../state/auth_provider.dart';
import '../theme/theme.dart';

/// Direct port of `src/screens/MembersDirectoryScreen.tsx`.
class MembersDirectoryScreen extends StatefulWidget {
  const MembersDirectoryScreen({super.key});

  @override
  State<MembersDirectoryScreen> createState() => _MembersDirectoryScreenState();
}

class _MembersDirectoryScreenState extends State<MembersDirectoryScreen> {
  static const _roles = ['All', 'Parent', 'Educator', 'Advocate'];
  static const _noUser = '__none__';

  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'All';
  List<MemberView> _members = [];
  Set<String> _connections = {};
  bool _loading = true;
  String? _loadedKey;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final userId = requireUserId(auth.user?.id, auth.isGuest);
    final key = userId ?? _noUser;
    if (_loadedKey == key) return;
    _loadedKey = key;
    _load(userId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load(String? userId) async {
    setState(() => _loading = true);
    try {
      final rows = await data.fetchMembers();
      final members = rows.where((m) => m.id != userId).map(mapMember).toList();
      var connections = <String>{};
      if (userId != null) {
        connections = await data.fetchUserConnections(userId);
      }
      if (!mounted) return;
      setState(() {
        _members = members;
        _connections = connections;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MemberView> get _filteredMembers {
    final q = _searchController.text.toLowerCase();
    return _members.where((m) {
      final matchesSearch =
          m.name.toLowerCase().contains(q) || m.bio.toLowerCase().contains(q);
      final matchesRole = _selectedRole == 'All' || m.role == _selectedRole;
      return matchesSearch && matchesRole;
    }).toList();
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))
        ],
      ),
    );
  }

  Future<void> _toggleConnect(String id, String name) async {
    final auth = context.read<AuthProvider>();
    final userId = requireUserId(auth.user?.id, auth.isGuest);
    if (userId == null) {
      _showAlert('Sign in required', 'Please log in to connect with members.');
      return;
    }
    final wasConnected = _connections.contains(id);
    await data.toggleConnection(userId, id);
    if (!mounted) return;
    setState(() {
      if (wasConnected) {
        _connections.remove(id);
      } else {
        _connections.add(id);
      }
    });
    if (!wasConnected) {
      _showAlert('Connected', 'You are now connected with $name.');
    }
  }

  void _handleMessage(String name) {
    _showAlert('Start Conversation', 'Starting a conversation with $name.');
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>();
    final filtered = _filteredMembers;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                        const Text(
                          'Members Directory',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Connect with parents and advocates in your community',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
                        controller: _searchController,
                        style:
                            const TextStyle(fontSize: 14, color: AppColors.ink),
                        decoration: const InputDecoration(
                          hintText: 'Search community members by name, tags...',
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
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    for (var i = 0; i < _roles.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _RoleChip(
                        label: _roles[i],
                        active: _selectedRole == _roles[i],
                        onTap: () => setState(() => _selectedRole = _roles[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: Column(
                        children: [
                          for (var i = 0; i < filtered.length; i++) ...[
                            if (i > 0) const SizedBox(height: 12),
                            _MemberCard(
                              member: filtered[i],
                              isConnected:
                                  _connections.contains(filtered[i].id),
                              onConnect: () => _toggleConnect(
                                  filtered[i].id, filtered[i].name),
                              onMessage: () => _handleMessage(filtered[i].name),
                            ),
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

class _RoleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _RoleChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active ? AppColors.secondary : AppColors.card,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: active ? AppColors.secondary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.card : AppColors.secondary),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final MemberView member;
  final bool isConnected;
  final VoidCallback onConnect;
  final VoidCallback onMessage;

  const _MemberCard({
    required this.member,
    required this.isConnected,
    required this.onConnect,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final tags = member.tags.take(3).toList();
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(right: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  member.initials,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.mapPin,
                              color: AppColors.mutedForeground, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${member.role} · ${member.location}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: Text(
              member.bio,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                  height: 20 / 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in tags)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.tertiary,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text('#$tag',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary)),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onConnect,
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: isConnected
                              ? AppColors.tertiary
                              : AppColors.border),
                      color: isConnected ? AppColors.tertiary : AppColors.card,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            isConnected
                                ? LucideIcons.userCheck
                                : LucideIcons.userPlus,
                            color: AppColors.secondary,
                            size: 16),
                        const SizedBox(width: 6),
                        Text(
                          isConnected ? 'Connected' : 'Connect',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onMessage,
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: AppColors.primary),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.messageSquare,
                            color: AppColors.secondary, size: 16),
                        SizedBox(width: 6),
                        Text('Message',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
