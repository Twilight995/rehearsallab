import 'package:flutter/material.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/app/theme/preview.dart';

@AppThemePreview(group: 'Button', name: 'SecondaryButton')
Widget preview() => Padding(
  padding: const EdgeInsets.all(20),
  child: Column(
    spacing: 12,
    children: [
      SecondaryButton(label: '편집', onPressed: () {}),
      SecondaryButton(label: '영구 삭제', danger: true, onPressed: () {}),
      SecondaryButton(
        label: '파일 열기 (.txt)',
        icon: Icons.description_outlined,
        onPressed: () {},
      ),
    ],
  ),
);

/// Pen `SecondaryButton` (Z9a3V). 높이 56, 필, 흰 배경 + 1px border.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  final IconData? icon;
  final double height;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.danger = false,
    this.icon,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = danger ? AppColors.danger : AppColors.textPrimary;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: foreground,
          side: BorderSide(color: danger ? AppColors.danger : AppColors.border),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          textStyle: AppTheme.body(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            if (icon != null) Icon(icon, size: 18),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
