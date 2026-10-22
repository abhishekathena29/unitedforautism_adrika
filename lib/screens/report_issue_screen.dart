import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart' as data;
import '../state/auth_provider.dart';
import '../theme/theme.dart';

class _IssueType {
  final String label;
  final String value;
  const _IssueType(this.label, this.value);
}

const _issueTypes = [
  _IssueType('Bug or technical issue', 'bug'),
  _IssueType('Content concern', 'content'),
  _IssueType('Harassment', 'harassment'),
  _IssueType('Other', 'other'),
];

/// Direct port of `src/screens/ReportIssueScreen.tsx`.
class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  String _issueType = 'bug';
  bool _showTypes = false;
  final _subjectController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String get _selectedLabel => _issueTypes
      .firstWhere((t) => t.value == _issueType, orElse: () => _issueTypes[0])
      .label;

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

  Future<void> _handleSubmit() async {
    if (_subjectController.text.trim().isEmpty ||
        _detailsController.text.trim().isEmpty) {
      await _showAlert('Missing fields', 'Please add a subject and details.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final userId = context.read<AuthProvider>().user?.id;
      await data.submitIssueReport(
        userId: userId,
        issueType: _issueType,
        subject: _subjectController.text.trim(),
        details: _detailsController.text.trim(),
      );
      if (!mounted) return;
      await _showAlert(
          'Report submitted', 'Thank you. Our team will review your report.');
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      await _showAlert('Could not submit', e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
                    'Report an issue',
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Issue type',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setState(() => _showTypes = !_showTypes),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_selectedLabel,
                                    style: const TextStyle(
                                        fontSize: 16, color: AppColors.ink)),
                                const Icon(LucideIcons.chevronDown,
                                    color: AppColors.mutedForeground, size: 16),
                              ],
                            ),
                          ),
                        ),
                        if (_showTypes)
                          for (final t in _issueTypes)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _issueType = t.value;
                                  _showTypes = false;
                                }),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(t.label,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.secondary)),
                                ),
                              ),
                            ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Subject',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: TextField(
                            controller: _subjectController,
                            style: const TextStyle(
                                fontSize: 16, color: AppColors.ink),
                            decoration: InputDecoration(
                              hintText: 'Briefly describe the issue',
                              hintStyle: const TextStyle(
                                  color: AppColors.mutedForeground),
                              filled: true,
                              fillColor: AppColors.card,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Details',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 140,
                          child: TextField(
                            controller: _detailsController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: const TextStyle(
                                fontSize: 16, color: AppColors.ink),
                            decoration: InputDecoration(
                              hintText: 'Tell us what happened...',
                              hintStyle: const TextStyle(
                                  color: AppColors.mutedForeground),
                              filled: true,
                              fillColor: AppColors.card,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: Material(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: _submitting ? null : _handleSubmit,
                          child: Center(
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: AppColors.secondary,
                                        strokeWidth: 2),
                                  )
                                : const Text(
                                    'Submit report',
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
