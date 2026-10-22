import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

/// Direct port of `src/components/PostAvatar.tsx`.
class PostAvatar extends StatelessWidget {
  final bool anonymous;
  final String initials;
  final double size;

  const PostAvatar({
    super.key,
    this.anonymous = false,
    this.initials = 'ME',
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = (size * 0.35).roundToDouble();
    final iconSize = (size * 0.45).roundToDouble();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: anonymous
          ? Icon(LucideIcons.user, color: AppColors.secondary, size: iconSize)
          : Text(
              initials,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
    );
  }
}
