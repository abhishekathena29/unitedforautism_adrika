import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/view_models.dart';
import '../services/data_service.dart' as data;
import '../state/auth_provider.dart';
import '../theme/theme.dart';
import '../utils/utils.dart';

/// Direct port of `src/screens/EditProfileScreen.tsx`.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late final TextEditingController _cityController;
  late final TextEditingController _bioController;
  bool _saving = false;
  bool _initializedFromProfile = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    _nameController = TextEditingController(text: profile?.displayName ?? '');
    _roleController = TextEditingController(
      text: profile?.role != null && profile!.role.isNotEmpty
          ? formatRole(profile.role)
          : 'Parent',
    );
    _cityController = TextEditingController(text: profile?.city ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _initializedFromProfile = profile != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _syncFromProfile(Profile? profile) {
    if (profile == null) return;
    _nameController.text = profile.displayName;
    _roleController.text = formatRole(profile.role);
    _cityController.text = profile.city ?? '';
    _bioController.text = profile.bio ?? '';
  }

  Future<void> _showAlert(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    final profile = context.read<AuthProvider>().profile;
    if (profile?.id == null) return;
    setState(() => _saving = true);
    try {
      await data.updateProfile(profile!.id, {
        'display_name': _nameController.text.trim(),
        'initials': initialsFromName(_nameController.text.trim()),
        'role': normalizeRole(_roleController.text),
        'city': _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        'bio': _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
      });
      if (!mounted) return;
      await context.read<AuthProvider>().refreshProfile();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      await _showAlert('Could not save', e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    if (profile != null && !_initializedFromProfile) {
      _initializedFromProfile = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncFromProfile(profile);
      });
    }
    final initials = profile?.initials ??
        initialsFromName(
            _nameController.text.isEmpty ? 'U' : _nameController.text);

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
                    onTap: () => Navigator.of(context).pop(),
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
                  const Text(
                    'Edit profile',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.card,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary),
                                  ),
                                ),
                                Positioned(
                                  bottom: -4,
                                  right: -4,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(6),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: const Icon(LucideIcons.camera,
                                        color: AppColors.card, size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Tap to change your profile photo',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.mutedForeground),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _FormField(label: 'Full name', controller: _nameController),
                    const SizedBox(height: 20),
                    _FormField(label: 'Role', controller: _roleController),
                    const SizedBox(height: 20),
                    _FormField(label: 'City', controller: _cityController),
                    const SizedBox(height: 20),
                    _FormField(
                        label: 'Bio',
                        controller: _bioController,
                        multiline: true),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: Material(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: _saving ? null : _handleSave,
                          child: Center(
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: AppColors.secondary,
                                        strokeWidth: 2),
                                  )
                                : const Text(
                                    'Save changes',
                                    style: TextStyle(
                                        color: AppColors.secondary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                          ),
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
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool multiline;
  const _FormField(
      {required this.label, required this.controller, this.multiline = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink)),
        const SizedBox(height: 8),
        Container(
          height: multiline ? 100 : 48,
          padding: EdgeInsets.symmetric(
              horizontal: 16, vertical: multiline ? 12 : 0),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextField(
            controller: controller,
            maxLines: multiline ? null : 1,
            expands: multiline,
            textAlignVertical:
                multiline ? TextAlignVertical.top : TextAlignVertical.center,
            style: const TextStyle(fontSize: 16, color: AppColors.ink),
            decoration:
                const InputDecoration(border: InputBorder.none, isDense: true),
          ),
        ),
      ],
    );
  }
}
