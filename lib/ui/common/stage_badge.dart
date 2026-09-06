import 'package:flutter/material.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/app/theme/preview.dart';
import 'package:rehearsallab/core/enum/badge_tone.dart';

@AppThemePreview(group: 'Badge', name: 'StageBadge')
Widget preview() => const Padding(
  padding: EdgeInsets.all(20),
  child: Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      StageBadge(label: '분석 완료', tone: BadgeTone.info),
      StageBadge(label: '리허설 2회', tone: BadgeTone.info),
      StageBadge(label: '재분석 필요', tone: BadgeTone.warning),
      StageBadge(label: '분석 실패', tone: BadgeTone.danger),
      StageBadge(label: '원고 없음', tone: BadgeTone.neutral),
      StageBadge(label: '부분 리허설', tone: BadgeTone.warning),
    ],
  ),
);

/// Pen `StageBadge` (WUcga). 점 + 라벨. 색과 텍스트를 항상 함께 둔다.
class StageBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;

  const StageBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.info,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: tone.foreground,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            label,
            style: AppTheme.body(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tone.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
