import 'package:flutter/material.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/app/theme/preview.dart';
import 'package:rehearsallab/core/enum/badge_tone.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/ui/common/stage_badge.dart';

@AppThemePreview(group: 'Header', name: 'DetailHeader')
Widget preview() => DetailHeader(
  presentation: DemoData.presentation,
  today: DemoData.today,
  versionLabel: 'v1 분석 · 현재 v2',
  badgeLabel: '분석 완료',
  badgeTone: BadgeTone.info,
  activeTab: DetailTab.script,
  onTabChanged: (_) {},
);

enum DetailTab { script, rehearsal, qa, history }

extension DetailTabExtension on DetailTab {
  String get label => switch (this) {
    DetailTab.script => AppStrings.detailTabScript,
    DetailTab.rehearsal => AppStrings.detailTabRehearsal,
    DetailTab.qa => AppStrings.detailTabQa,
    DetailTab.history => AppStrings.detailTabHistory,
  };
}

/// Pen `DetailHeader` + `DetailTabs`. 제목 행(제목 + 단계 배지) · 메타 행(D-day · 규격 · 버전, Wrap) · 탭 4개.
/// 320px에서 배지가 잘리지 않도록 배지는 제목 행에 둔다 (통합 문서 9장 검사 결과).
class DetailHeader extends StatelessWidget {
  final Presentation presentation;
  final DateTime today;
  final String? versionLabel;
  final String badgeLabel;
  final BadgeTone badgeTone;
  final DetailTab activeTab;
  final ValueChanged<DetailTab> onTabChanged;

  const DetailHeader({
    super.key,
    required this.presentation,
    required this.today,
    this.versionLabel,
    required this.badgeLabel,
    required this.badgeTone,
    required this.activeTab,
    required this.onTabChanged,
  });

  String get _dday {
    final date = presentation.date;
    if (date == null) return AppStrings.commonDateTbd;
    final d = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    return d < 0 ? 'D+${-d}' : AppStrings.homeDday(d);
  }

  @override
  Widget build(BuildContext context) {
    final metaStyle = AppTheme.body(
      fontSize: 13,
      color: AppColors.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            4,
            AppSpacing.page,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Text(
                      presentation.title,
                      style: AppTheme.body(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  StageBadge(label: badgeLabel, tone: badgeTone),
                ],
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(_dday, style: AppTheme.display(fontSize: 14)),
                  const _Dot(),
                  Text(presentation.timeSpecLabel, style: metaStyle),
                  if (versionLabel != null) ...[
                    const _Dot(),
                    Text(versionLabel!, style: metaStyle),
                  ],
                ],
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              for (final tab in DetailTab.values)
                Expanded(
                  child: _TabItem(
                    tab: tab,
                    selected: tab == activeTab,
                    onTap: () => onTabChanged(tab),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final DetailTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 10),
              child: Text(
                tab.label,
                style: AppTheme.body(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
              ),
            ),
            Container(
              height: 2,
              color: selected ? AppColors.navy900 : Colors.transparent,
            ),
          ],
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
