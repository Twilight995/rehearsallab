import 'package:flutter/material.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/preview.dart';
import 'package:rehearsallab/ui/common/primary_button.dart';
import 'package:rehearsallab/ui/common/secondary_button.dart';

@AppThemePreview(group: 'Navigation', name: 'BottomActionBar')
Widget preview() => Column(
  spacing: 16,
  children: [
    BottomActionBar(
      primary: PrimaryButton(label: '리허설 시작', onPressed: () {}),
      secondary: SecondaryButton(label: '원고 편집', onPressed: () {}),
    ),
    BottomActionBar(
      primary: PrimaryButton(label: '저장', onPressed: () {}),
    ),
  ],
);

/// Pen `BottomBar`. 스크롤 본문 밖에 고정되는 하단 액션 바.
/// 보조 버튼은 고정폭(130), 주 버튼은 Expanded (320px에서도 주 버튼 140px 이상).
class BottomActionBar extends StatelessWidget {
  final Widget primary;
  final Widget? secondary;
  final double secondaryWidth;

  const BottomActionBar({
    super.key,
    required this.primary,
    this.secondary,
    this.secondaryWidth = 130,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            12,
            AppSpacing.page,
            12,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.contentMaxWidth,
              ),
              child: Row(
                spacing: 10,
                children: [
                  if (secondary != null)
                    SizedBox(width: secondaryWidth, child: secondary),
                  Expanded(child: primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
