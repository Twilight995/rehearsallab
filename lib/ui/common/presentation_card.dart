import 'package:flutter/material.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/app/theme/preview.dart';
import 'package:rehearsallab/core/enum/badge_tone.dart';
import 'package:rehearsallab/core/enum/presentation_type.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/ui/common/stage_badge.dart';

@AppThemePreview(group: 'Card', name: 'PresentationCard')
Widget preview() => Padding(
  padding: const EdgeInsets.all(20),
  child: Column(
    spacing: 12,
    children: [
      PresentationCard(
        presentation: DemoData.presentations[0],
        today: DemoData.today,
        stageLabel: '리허설 2회',
        stageTone: BadgeTone.info,
        matchTrend: const [0.74, 0.81, 0.87],
        onTap: () {},
      ),
      PresentationCard(
        presentation: DemoData.presentations[2],
        today: DemoData.today,
        stageLabel: '원고 없음',
        stageTone: BadgeTone.neutral,
        onTap: () {},
      ),
    ],
  ),
);

/// Pen `PresentationCard` (gugYg). 제목 · D-day(또는 날짜 미정) · 유형 · 시간 규격 · 단계 배지 · 일치율 추이.
class PresentationCard extends StatelessWidget {
  final Presentation presentation;
  final DateTime today;
  final String stageLabel;
  final BadgeTone stageTone;

  /// 회차별 원고 일치율(0~1). 종합 점수는 쓰지 않는다.
  final List<double> matchTrend;
  final VoidCallback? onTap;

  const PresentationCard({
    super.key,
    required this.presentation,
    required this.today,
    required this.stageLabel,
    required this.stageTone,
    this.matchTrend = const [],
    this.onTap,
  });

  String get _ddayLabel {
    final date = presentation.date;
    if (date == null) return AppStrings.commonDateTbd;
    final d = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    if (d < 0) return 'D+${-d}';
    return AppStrings.homeDday(d);
  }

  @override
  Widget build(BuildContext context) {
    final isTbd = presentation.date == null;
    return Semantics(
      button: onTap != null,
      label: '${presentation.title}, $_ddayLabel, $stageLabel',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 14,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    Expanded(
                      child: Text(
                        presentation.title,
                        style: AppTheme.body(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                    Text(
                      _ddayLabel,
                      style: isTbd
                          ? AppTheme.body(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            )
                          : AppTheme.display(fontSize: 22),
                    ),
                  ],
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      presentation.type.title,
                      style: AppTheme.body(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const _Dot(),
                    Text(
                      presentation.timeSpecLabel,
                      style: AppTheme.body(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StageBadge(label: stageLabel, tone: stageTone),
                    if (matchTrend.isNotEmpty)
                      _MatchRateTrend(values: matchTrend),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Container(
    width: 3,
    height: 3,
    decoration: const BoxDecoration(
      color: AppColors.textTertiary,
      shape: BoxShape.circle,
    ),
  );
}

/// 일치율 스파크라인 (막대). 값은 0~1, 높이 20 안에서 비례.
class _MatchRateTrend extends StatelessWidget {
  final List<double> values;

  const _MatchRateTrend({required this.values});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '회차별 원고 일치율 ${values.map((v) => '${(v * 100).round()}%').join(', ')}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 3,
        children: [
          for (final v in values)
            Container(
              width: 5,
              height: (4 + 16 * v.clamp(0, 1)).toDouble(),
              decoration: BoxDecoration(
                color: AppColors.blue500,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
