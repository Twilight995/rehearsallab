import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/ui/common/onboarding_frame.dart';

/// 01 · 02 소개 (`ynwPV`, `D4U0Y5`). 두 쪽을 PageView로 넘기고, 마지막 "다음"과 "건너뛰기"는 03 동의로 간다.
/// 동의는 건너뛸 수 없다 (통합 문서 4장: 03 필수 동의 체크).
class OnboardingIntroPage extends StatefulWidget {
  const OnboardingIntroPage({super.key});

  @override
  State<OnboardingIntroPage> createState() => _OnboardingIntroPageState();
}

class _OnboardingIntroPageState extends State<OnboardingIntroPage> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goPrivacy() => context.go(AppPage.onboardingPrivacy.path);

  void _next() {
    if (_index >= 1) {
      _goPrivacy();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      onPageChanged: (i) => setState(() => _index = i),
      children: [
        OnboardingFrame(
          pageIndex: 0,
          headline: AppStrings.intro1Headline,
          body: AppStrings.intro1Body,
          ctaLabel: AppStrings.commonNext,
          onCta: _next,
          onSkip: _goPrivacy,
          hero: const _LoopDiagram(),
        ),
        OnboardingFrame(
          pageIndex: 1,
          headline: AppStrings.intro2Headline,
          body: AppStrings.intro2Body,
          ctaLabel: AppStrings.commonNext,
          onCta: _next,
          onSkip: _goPrivacy,
          hero: const _MetricPreviewList(),
        ),
      ],
    );
  }
}

/// Pen `LoopDiagram`: 원고 → 분석 → 리허설 → 피드백 (+ 반복 아이콘). 좁은 폭에서는 Wrap으로 줄바꿈.
class _LoopDiagram extends StatelessWidget {
  const _LoopDiagram();

  static const List<String> _steps = [
    AppStrings.introLoopScript,
    AppStrings.introLoopAnalysis,
    AppStrings.introLoopRehearsal,
    AppStrings.introLoopFeedback,
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${_steps.join(' → ')} 반복',
      child: Column(
        spacing: AppSpacing.xl,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.onDark.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.onDark.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _steps[i],
                    style: AppTheme.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy900,
                    ),
                  ),
                ),
                if (i < _steps.length - 1)
                  const Icon(
                    LucideIcons.arrowRight,
                    size: 14,
                    color: AppColors.navy900,
                  ),
              ],
            ],
          ),
          const Icon(LucideIcons.repeat, size: 20, color: AppColors.navy900),
        ],
      ),
    );
  }
}

/// Pen `MetricPreview` × 3: 속도 142 WPM · 필러 7회 · 원고 일치 87%.
class _MetricPreviewList extends StatelessWidget {
  const _MetricPreviewList();

  static const List<(IconData, String, String, String)> _items = [
    (
      LucideIcons.gauge,
      AppStrings.intro2MetricSpeed,
      '142',
      AppStrings.intro2MetricSpeedUnit,
    ),
    (
      LucideIcons.messageSquareDashed,
      AppStrings.intro2MetricFiller,
      '7',
      AppStrings.intro2MetricFillerUnit,
    ),
    (
      LucideIcons.fileCheck,
      AppStrings.intro2MetricMatch,
      '87',
      AppStrings.intro2MetricMatchUnit,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 250),
      child: Column(
        spacing: AppSpacing.md,
        children: [
          for (final (icon, label, value, unit) in _items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.onDark.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                spacing: 14,
                children: [
                  Icon(icon, size: 22, color: AppColors.navy900),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTheme.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.navy900,
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 3,
                    children: [
                      Text(
                        value,
                        style: AppTheme.display(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy900,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          unit,
                          style: AppTheme.body(
                            fontSize: 12,
                            color: AppColors.navy700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
