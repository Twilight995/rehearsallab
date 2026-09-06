import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/app/theme/preview.dart';
import 'package:rehearsallab/core/enum/dimension_key.dart';
import 'package:rehearsallab/models/feedback.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';

@AppThemePreview(group: 'Card', name: 'DimensionCard')
Widget preview() => Padding(
  padding: const EdgeInsets.all(20),
  child: Column(
    spacing: 12,
    children: [
      DimensionCard(
        feedback: DemoData.analysisV1.dimensions[0],
        expanded: true,
        onToggle: () {},
      ),
      DimensionCard(
        feedback: DemoData.analysisV1.dimensions[2],
        onToggle: () {},
      ),
    ],
  ),
);

/// Pen `DimensionCard` (s91LYi). 근거 인용(왼쪽 2px blue 선) → 근거 위치 → 펼침 행(문제점 · 제안).
/// 점수는 우상단에 작게. 점수 2 이하는 danger 색.
class DimensionCard extends StatelessWidget {
  final DimensionFeedback feedback;
  final bool expanded;
  final VoidCallback? onToggle;

  /// true면 원고 분석용 긴 제목("명료성 · 용어")
  final bool scriptTitles;

  const DimensionCard({
    super.key,
    required this.feedback,
    this.expanded = false,
    this.onToggle,
    this.scriptTitles = false,
  });

  @override
  Widget build(BuildContext context) {
    final key = feedback.key;
    final scoreColor = feedback.score <= 2
        ? AppColors.danger
        : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            children: [
              Icon(key.icon, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  scriptTitles ? key.scriptTitle : key.title,
                  style: AppTheme.body(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Semantics(
                label: '점수 ${feedback.score}점 만점 5점',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 2,
                  children: [
                    Text(
                      '${feedback.score}',
                      style: AppTheme.display(fontSize: 15, color: scoreColor),
                    ),
                    Text(
                      AppStrings.dimensionScoreMax,
                      style: AppTheme.display(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.blue500, width: 2),
              ),
            ),
            child: Text(
              feedback.evidenceQuote,
              style: AppTheme.body(fontSize: 14, height: 1.55),
            ),
          ),
          Text(
            feedback.evidenceLocation,
            style: AppTheme.body(fontSize: 12, color: AppColors.textTertiary),
          ),
          const Divider(),
          if (expanded) ...[
            _DetailRow(
              label: AppStrings.dimensionProblem,
              text: feedback.problem,
              color: AppColors.danger,
              background: AppColors.dangerBg,
            ),
            _DetailRow(
              label: AppStrings.dimensionSuggestion,
              text: feedback.suggestion,
              color: AppColors.success,
              background: AppColors.successBg,
            ),
          ],
          InkWell(
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    expanded
                        ? AppStrings.dimensionCollapseShort
                        : AppStrings.dimensionExpand,
                    style: AppTheme.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Icon(
                    expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  final Color background;

  const _DetailRow({
    required this.label,
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            label,
            style: AppTheme.body(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        Expanded(
          child: Text(text, style: AppTheme.body(fontSize: 13, height: 1.55)),
        ),
      ],
    );
  }
}
