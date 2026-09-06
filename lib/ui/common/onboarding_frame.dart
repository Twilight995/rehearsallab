import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/ui/common/primary_button.dart';

/// Pen 01 · 02 · 03 온보딩 공통 골격: 히어로 그라데이션 배경, 상단(로고 · 건너뛰기),
/// 가운데 `hero`(Expanded), 하단(페이지 점 · 헤드라인 · 본문 · CTA). 높이 844 고정 프레임을
/// Column + Expanded로 옮겼으므로 어떤 높이에서도 하단 CTA가 보이고 hero만 남는 공간을 쓴다.
class OnboardingFrame extends StatelessWidget {
  final Widget hero;
  final int pageIndex;
  final int pageCount;
  final String headline;
  final String body;
  final String ctaLabel;
  final VoidCallback? onCta;
  final VoidCallback? onSkip;

  /// hero 세로 정렬 (01 · 02는 가운데, 03은 위쪽)
  final MainAxisAlignment heroAlignment;

  const OnboardingFrame({
    super.key,
    required this.hero,
    required this.pageIndex,
    this.pageCount = 3,
    required this.headline,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
    this.onSkip,
    this.heroAlignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      LucideIcons.asterisk,
                      size: 28,
                      color: AppColors.navy900,
                    ),
                    if (onSkip != null)
                      TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.navy900,
                          minimumSize: const Size(
                            AppSpacing.touchTarget,
                            AppSpacing.touchTarget,
                          ),
                          textStyle: AppTheme.body(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: const Text(AppStrings.commonSkip),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: _heroMinHeight(context),
                    ),
                    child: Column(
                      mainAxisAlignment: heroAlignment,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: AppSpacing.xl,
                      children: [hero],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  0,
                  AppSpacing.page,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.md,
                  children: [
                    Semantics(
                      label: '$pageCount쪽 중 ${pageIndex + 1}쪽',
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          spacing: 6,
                          children: [
                            for (var i = 0; i < pageCount; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: i == pageIndex ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == pageIndex
                                      ? AppColors.onDark
                                      : AppColors.onDarkMuted,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      headline,
                      style: AppTheme.display(
                        fontSize: 30,
                        color: AppColors.onDark,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      body,
                      style: AppTheme.body(
                        fontSize: 15,
                        color: AppColors.onDarkMuted,
                        height: 1.55,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: PrimaryButton(
                        label: ctaLabel,
                        onDark: true,
                        onPressed: onCta,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 작은 화면(높이 640)에서는 hero가 스크롤되고, 큰 화면에서는 가운데 정렬되도록 최소 높이를 준다.
  double _heroMinHeight(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return (height * 0.36).clamp(160.0, 420.0);
  }
}
