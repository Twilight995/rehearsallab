import 'package:flutter/material.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/app/theme/preview.dart';

@AppThemePreview(group: 'Text', name: 'SectionHeader')
Widget preview() => const Padding(
  padding: EdgeInsets.all(20),
  child: Column(
    spacing: 16,
    children: [
      SectionHeader(title: '내 발표', action: 'D-day 순'),
      SectionHeader(title: 'Top 3 개선 액션', action: '체크하면 이력에 기록'),
      SectionHeader(title: '타임라인'),
    ],
  ),
);

/// Pen `SectionHeader` (gMuSE) · `SectionTitle`. 제목(17/700) + 우측 보조 문구(12~13/tertiary).
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final actionText = action == null
        ? null
        : Text(
            action!,
            style: AppTheme.body(fontSize: 12, color: AppColors.textTertiary),
            textAlign: TextAlign.end,
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 12,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTheme.body(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        if (actionText != null)
          Flexible(
            child: onActionTap == null
                ? actionText
                : InkWell(onTap: onActionTap, child: actionText),
          ),
      ],
    );
  }
}
