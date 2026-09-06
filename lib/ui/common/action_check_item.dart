import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/app/theme/preview.dart';

@AppThemePreview(group: 'List', name: 'ActionCheckItem')
Widget preview() => Padding(
  padding: const EdgeInsets.all(20),
  child: Column(
    children: [
      ActionCheckItem(
        text: '방법 섹션의 알고리즘 세부 설명 3문장을 한 문장으로 요약',
        checked: true,
        onChanged: (_) {},
      ),
      ActionCheckItem(
        text: "'정렬(alignment)' 용어를 첫 등장에서 한 줄로 정의",
        checked: false,
        onChanged: (_) {},
      ),
    ],
  ),
);

/// Pen `ActionCheckItem` (YHDFW). Top 3 액션 한 줄. 행 전체가 탭 영역(48px 이상).
/// 체크는 "반영함" 기록만 남기고 원고를 바꾸지 않는다.
class ActionCheckItem extends StatelessWidget {
  final String text;
  final bool checked;
  final ValueChanged<bool>? onChanged;

  const ActionCheckItem({
    super.key,
    required this.text,
    required this.checked,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      label: text,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!checked),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: checked ? AppColors.navy900 : AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: checked
                          ? AppColors.navy900
                          : AppColors.textTertiary,
                      width: 1.5,
                    ),
                  ),
                  child: checked
                      ? const Icon(
                          LucideIcons.check,
                          size: 14,
                          color: AppColors.onDark,
                        )
                      : null,
                ),
                Expanded(
                  child: Text(
                    text,
                    style: AppTheme.body(
                      fontSize: 15,
                      height: 1.5,
                      color: checked
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
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
