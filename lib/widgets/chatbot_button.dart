import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

/// Direct port of `src/components/ChatbotButton.tsx`.
class ChatbotButton extends StatelessWidget {
  const ChatbotButton({super.key});

  void _openModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.4),
      builder: (ctx) => const _ChatbotSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 90,
      right: 20,
      child: GestureDetector(
        onTap: () => _openModal(context),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
            boxShadow: AppShadows.glow,
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(LucideIcons.messageCircle,
                    color: AppColors.card, size: 28),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.card, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatbotSheet extends StatelessWidget {
  const _ChatbotSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.sparkles,
                          color: AppColors.secondary, size: 24),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Support Assistant',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink),
                          ),
                          Text(
                            'Calm. Confidential. Here for you.',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.x,
                            color: AppColors.ink, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 12, top: 4),
                          decoration: BoxDecoration(
                            color: AppColors.tertiary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(LucideIcons.sparkles,
                              color: AppColors.secondary, size: 16),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text(
                              "Hello, I'm here to support you. How can I help today?",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.ink,
                                  height: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _QuickAction(
                      icon: LucideIcons.alertCircle,
                      label: 'I need help right now',
                      bg: AppColors.urgentBg,
                      border: AppColors.urgentBorder,
                      fg: AppColors.destructive,
                    ),
                    const SizedBox(height: 12),
                    _QuickAction(
                      icon: LucideIcons.wind,
                      label: 'Suggest calming strategies',
                      bg: AppColors.quickActionBg,
                      border: AppColors.quickActionBorder,
                      fg: AppColors.secondary,
                    ),
                    const SizedBox(height: 12),
                    _QuickAction(
                      icon: LucideIcons.stethoscope,
                      label: 'Find a therapist',
                      bg: AppColors.quickActionBg,
                      border: AppColors.quickActionBorder,
                      fg: AppColors.secondary,
                    ),
                    const SizedBox(height: 12),
                    _QuickAction(
                      icon: LucideIcons.users,
                      label: 'Show similar discussions',
                      bg: AppColors.quickActionBg,
                      border: AppColors.quickActionBorder,
                      fg: AppColors.secondary,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Message assistant...',
                            hintStyle:
                                TextStyle(color: AppColors.mutedForeground),
                          ),
                          style: TextStyle(fontSize: 16, color: AppColors.ink),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(LucideIcons.send,
                          color: AppColors.card, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color border;
  final Color fg;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.bg,
    required this.border,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  color: fg, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
