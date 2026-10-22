import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

/// Direct port of `src/components/IconBadge.tsx`'s icon name → icon map.
const Map<String, IconData> _iconMap = {
  'Users': LucideIcons.users,
  'Search': LucideIcons.search,
  'GraduationCap': LucideIcons.graduationCap,
  'HeartHandshake': LucideIcons.heartHandshake,
  'Stethoscope': LucideIcons.stethoscope,
  'Wind': LucideIcons.wind,
  'Trees': LucideIcons.trees,
  'Heart': LucideIcons.heart,
  'BookOpen': LucideIcons.bookOpen,
  'Waves': LucideIcons.waves,
  'Lightbulb': LucideIcons.lightbulb,
  'Headphones': LucideIcons.headphones,
  'Bed': LucideIcons.bed,
  'Flower2': LucideIcons.flower2,
  'CalendarCheck': LucideIcons.calendarCheck,
  'MessageSquare': LucideIcons.messageSquare,
  'Ticket': LucideIcons.ticket,
  'Megaphone': LucideIcons.megaphone,
  'Sparkles': LucideIcons.sparkles,
  'Calendar': LucideIcons.calendar,
  'BookMarked': LucideIcons.bookMarked,
  'Compass': LucideIcons.compass,
  'Hand': LucideIcons.hand,
  'Brain': LucideIcons.brain,
  'Smile': LucideIcons.smile,
  'Star': LucideIcons.star,
};

IconData getIcon(String? name) => _iconMap[name] ?? LucideIcons.sparkles;

IconData notificationIcon(String? name) => getIcon(name ?? 'MessageSquare');

class IconBadge extends StatelessWidget {
  final String name;
  final double size;
  final double iconSize;
  final BoxDecoration? decoration;

  const IconBadge({
    super.key,
    required this.name,
    this.size = 40,
    this.iconSize = 20,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: decoration ??
          BoxDecoration(
            color: AppColors.tertiary,
            borderRadius: BorderRadius.circular(6),
          ),
      child: Icon(getIcon(name), color: AppColors.secondary, size: iconSize),
    );
  }
}
