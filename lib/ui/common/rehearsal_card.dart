import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/app/theme/preview.dart';
import 'package:rehearsallab/core/enum/badge_tone.dart';
import 'package:rehearsallab/core/enum/rehearsal_scope.dart';
import 'package:rehearsallab/core/extension/duration_extension.dart';
import 'package:rehearsallab/models/rehearsal.dart';
import 'package:rehearsallab/models/report.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/ui/common/stage_badge.dart';

@AppThemePreview(group: 'Card', name: 'RehearsalCard')
Widget preview() => Padding(
  padding: const EdgeInsets.all(20),
  child: Column(
    spacing: 12,
    children: [
      RehearsalCard(
        rehearsal: DemoData.rehearsal3,
        report: DemoData.report3,
        talkMinutes: 15,
        onTap: () {},
      ),
      RehearsalCard(
        rehearsal: DemoData.rehearsal1,
        report: DemoData.report1,
        talkMinutes: 15,
        onTap: () {},
      ),
      RehearsalCard(
        rehearsal: DemoData.rehearsal2.copyWith(
          scope: RehearsalScope.partial,
          capReached: true,
        ),
        report: DemoData.report2.copyWith(clearPrevMatchRate: true),
        talkMinutes: 25,
        onTap: () {},
      ),
    ],
  ),
);

/// Pen `RehearsalCard` (i1oaVW). #회차 원형 · 날짜 · (부분 리허설 배지) · 메타 · 전 회차 대비 변화.
/// 종합 점수는 사용하지 않는다. 부분 리허설이면 증감 대신 "평가 범위 다름".
/// 좁은 폭(320 · 큰 글자)에서는 날짜 · 배지가 Wrap으로 줄바꿈되고 비교값은 메타 아래 줄로 내려간다.
class RehearsalCard extends StatelessWidget {
  final Rehearsal rehearsal;
  final Report? report;
  final int talkMinutes;
  final VoidCallback? onTap;

  const RehearsalCard({
    super.key,
    required this.rehearsal,
    required this.report,
    required this.talkMinutes,
    this.onTap,
  });

  static const List<String> _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  String get _dateLabel {
    final d = rehearsal.recordedAt;
    final w = _weekdays[d.weekday - 1];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.month}월 ${d.day}일 ($w) $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final r = report;
    final isPartial = rehearsal.scope == RehearsalScope.partial;
    final spec = Duration(minutes: talkMinutes).mmss;
    final meta = r == null
        ? '${rehearsal.duration.mmss} / $spec'
        : AppStrings.listMeta(
            rehearsal.duration.mmss,
            spec,
            (r.matchRate * 100).round(),
            r.metrics.fillers.length,
          );
    final delta = r?.matchRateDeltaPp;
    final String deltaText;
    final Color deltaColor;
    if (delta == null) {
      deltaText = isPartial
          ? AppStrings.reportScopeDiffers
          : AppStrings.listFirstRound;
      deltaColor = AppColors.textTertiary;
    } else {
      deltaText = '${delta >= 0 ? '+' : ''}${delta.round()}%p';
      deltaColor = delta >= 0 ? AppColors.success : AppColors.danger;
    }

    return Semantics(
      button: onTap != null,
      label: '리허설 ${rehearsal.round}회차, $_dateLabel, $meta, $deltaText',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 14,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.navy900,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '#${rehearsal.round}',
                    style: AppTheme.display(
                      fontSize: 14,
                      color: AppColors.onDark,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            _dateLabel,
                            style: AppTheme.body(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isPartial)
                            const StageBadge(
                              label: AppStrings.reportPartialRehearsalBadge,
                              tone: BadgeTone.warning,
                            ),
                        ],
                      ),
                      Text(
                        meta,
                        style: AppTheme.body(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: 6,
                        children: [
                          if (delta != null)
                            Text(
                              AppStrings.listVsPrev,
                              style: AppTheme.body(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          Flexible(
                            child: Text(
                              deltaText,
                              style: AppTheme.display(
                                fontSize: delta == null ? 12 : 16,
                                color: deltaColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 13),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
