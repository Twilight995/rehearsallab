import 'package:flutter/material.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/app/theme/preview.dart';

@AppThemePreview(group: 'Chip', name: 'AppChip')
Widget preview() => Padding(
  padding: const EdgeInsets.all(20),
  child: Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      AppChip(label: '학회 구두발표', selected: true, onTap: () {}),
      AppChip(label: '논문 심사(디펜스)', onTap: () {}),
      AppChip(label: '빠뜨린 것만 6', onTap: () {}),
    ],
  ),
);

/// Pen `Chip` (wR0xU). 선택 시 navy-900 배경 + 흰 라벨. 그룹은 `Wrap`으로 배치한다.
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.navy900 : AppColors.surfaceMuted,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.touchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 10,
              ),
              child: Text(
                label,
                style: AppTheme.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppColors.onDark : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
