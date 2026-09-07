import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/app/theme/preview.dart';

@AppThemePreview(group: 'Input', name: 'StepperField')
Widget preview() => Padding(
  padding: const EdgeInsets.all(20),
  child: Row(
    spacing: 12,
    children: [
      Expanded(
        child: StepperField(
          label: '발표',
          value: 15,
          unit: '분',
          min: 1,
          max: 60,
          onChanged: (_) {},
        ),
      ),
      Expanded(
        child: StepperField(
          label: 'Q&A',
          value: 0,
          unit: '분',
          min: 0,
          max: 60,
          onChanged: (_) {},
        ),
      ),
    ],
  ),
);

/// Pen 08 `Stepper_발표` · `Stepper_Q&A`: 라벨(14 · secondary) + [－ 값 단위 ＋]. 높이 52, surface-muted, radius md.
/// − · + 는 48px 히트 영역, 범위 끝에서는 비활성(tertiary 색 + 탭 무시). Semantics는 "발표 15분" 형태의 값 라벨.
class StepperField extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const StepperField({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canDecrease = value > min;
    final canIncrease = value < max;
    return Semantics(
      label: '$label $value$unit',
      value: '$value',
      increasedValue: canIncrease ? '${value + 1}' : null,
      decreasedValue: canDecrease ? '${value - 1}' : null,
      onIncrease: canIncrease ? () => onChanged(value + 1) : null,
      onDecrease: canDecrease ? () => onChanged(value - 1) : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTheme.body(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            _StepButton(
              icon: LucideIcons.minus,
              enabled: canDecrease,
              tooltip: '$label 1$unit 줄이기',
              onTap: () => onChanged(value - 1),
            ),
            ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 2,
                children: [
                  Text(
                    '$value',
                    style: AppTheme.body(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      unit,
                      style: AppTheme.body(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _StepButton(
              icon: LucideIcons.plus,
              enabled: canIncrease,
              tooltip: '$label 1$unit 늘리기',
              onTap: () => onChanged(value + 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final String tooltip;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: AppSpacing.touchTarget,
        minHeight: AppSpacing.touchTarget,
      ),
      icon: Icon(
        icon,
        size: 18,
        color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
      ),
    );
  }
}
