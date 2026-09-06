import 'package:flutter/material.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/app/theme/preview.dart';

@AppThemePreview(group: 'Button', name: 'PrimaryButton')
Widget preview() => Padding(
  padding: const EdgeInsets.all(20),
  child: Column(
    spacing: 12,
    children: [
      PrimaryButton(label: '리허설 시작', onPressed: () {}),
      PrimaryButton(label: '비활성', onPressed: null),
      DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.navy900),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: PrimaryButton(label: '다음', onDark: true, onPressed: () {}),
        ),
      ),
      PrimaryButton(label: '녹음 버리기', danger: true, onPressed: () {}),
    ],
  ),
);

/// Pen `PrimaryButton` (XGtBL). 높이 56, 필(pill), navy-900.
/// onDark: 다크 배경 위에서는 흰 배경 + navy 라벨. danger: 파괴적 확정.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool onDark;
  final bool danger;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.onDark = false,
    this.danger = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final background = danger
        ? AppColors.danger
        : onDark
        ? AppColors.surface
        : AppColors.navy900;
    final foreground = onDark && !danger ? AppColors.navy900 : AppColors.onDark;
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.4),
          disabledForegroundColor: foreground.withValues(alpha: 0.7),
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
