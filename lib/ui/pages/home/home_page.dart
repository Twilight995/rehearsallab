import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/core/extension/date_time_extension.dart';
import 'package:rehearsallab/features/auth/auth_provider.dart';
import 'package:rehearsallab/features/presentation/presentation_provider.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/ui/common/bottom_dock.dart';
import 'package:rehearsallab/ui/common/presentation_card.dart';
import 'package:rehearsallab/ui/common/primary_button.dart';
import 'package:rehearsallab/ui/common/secondary_button.dart';
import 'package:rehearsallab/ui/common/section_header.dart';

/// 06 빈 홈 (`tHmhQ`) · 07 홈 목록 (`LbWZK`). 같은 위젯의 상태 분기.
/// 구조: 다크 헤더(브랜드 · 요약) → 흰 시트(내 발표 · 카드 목록 또는 빈 상태, 스크롤) → 하단 독(FAB는 07만).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _openForm(BuildContext context) =>
      context.push(AppPage.presentationForm.path);

  void _openDetail(BuildContext context, Presentation p) => context.push(
    AppPage.presentationDetail.location({RouteParam.presentationId: p.id}),
  );

  void _onDockTap(BuildContext context, DockTab tab, Presentation? next) {
    switch (tab) {
      case DockTab.home:
        break;
      case DockTab.presentation:
        if (next != null) {
          _openDetail(context, next);
        } else {
          _openForm(context);
        }
      case DockTab.settings:
        context.push(AppPage.settings.path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(homeCardsProvider);
    final today = ref.watch(todayProvider);
    final user = ref.watch(authNotifierProvider).value;
    final next = ref.watch(nextPresentationProvider);
    final list = cards.value ?? const <HomeCard>[];
    final isEmpty = cards.hasValue && list.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.navy900,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroHeader(
              greeting: isEmpty || next == null
                  ? AppStrings.homeGreeting(user?.displayName ?? 'K')
                  : AppStrings.homeNextLabel,
              bigValue: isEmpty || next == null
                  ? AppStrings.homeEmptyBig
                  : (next.date == null
                        ? AppStrings.commonDateTbd
                        : AppStrings.homeDday(next.date!.daysFrom(today))),
              subValue: isEmpty || next == null
                  ? AppStrings.homeEmptySub
                  : AppStrings.homeNextSummary(
                      next.title,
                      next.date?.koreanMonthDay ?? AppStrings.commonDateTbd,
                      rehearsalCountOf(list, next),
                    ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.sheet),
                  ),
                ),
                child: _Sheet(
                  cards: cards,
                  today: today,
                  onCardTap: (p) => _openDetail(context, p),
                  onCreate: () => _openForm(context),
                  onSample: () => context.push(
                    AppPage.report.location({
                      RouteParam.rehearsalId: DemoData.rehearsal3.id,
                      RouteParam.sampleMode: 'true',
                    }),
                  ),
                  onRetry: () {
                    ref.invalidate(presentationsProvider);
                    ref.invalidate(homeCardsProvider);
                  },
                ),
              ),
            ),
            ColoredBox(
              color: AppColors.bg,
              child: SafeArea(
                top: false,
                child: BottomDock(
                  current: DockTab.home,
                  onTap: (tab) => _onDockTap(context, tab, next),
                  onFabTap: isEmpty ? null : () => _openForm(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pen `HeroHeader`: 상단 행(로고 + 앱 이름 · 종) + 요약(인사 · 큰 값 · 보조 문구)
class _HeroHeader extends StatelessWidget {
  final String greeting;
  final String bigValue;
  final String subValue;

  const _HeroHeader({
    required this.greeting,
    required this.bigValue,
    required this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.darkHeaderGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    spacing: AppSpacing.sm,
                    children: [
                      const Icon(
                        LucideIcons.asterisk,
                        size: 22,
                        color: AppColors.onDark,
                      ),
                      Flexible(
                        child: Text(
                          AppStrings.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 알림은 프로토타입 범위 밖: 장식 아이콘만 (통합 문서 4장 백그라운드 알림 미약속)
                const ExcludeSemantics(
                  child: Icon(
                    LucideIcons.bell,
                    size: 22,
                    color: AppColors.onDark,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.page,
              vertical: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  greeting,
                  style: AppTheme.body(
                    fontSize: 14,
                    color: AppColors.onDarkMuted,
                  ),
                ),
                Text(
                  bigValue,
                  style: AppTheme.display(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onDark,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  subValue,
                  style: AppTheme.body(
                    fontSize: 14,
                    color: AppColors.onDarkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pen `Sheet`: 섹션 헤더 + 카드 목록 / 빈 상태 / 로딩 / 실패
class _Sheet extends StatelessWidget {
  final AsyncValue<List<HomeCard>> cards;
  final DateTime today;
  final ValueChanged<Presentation> onCardTap;
  final VoidCallback onCreate;
  final VoidCallback onSample;
  final VoidCallback onRetry;

  const _Sheet({
    required this.cards,
    required this.today,
    required this.onCardTap,
    required this.onCreate,
    required this.onSample,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final list = cards.value ?? const <HomeCard>[];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xl,
            AppSpacing.page,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: AppStrings.homeSectionTitle,
                action: switch (cards) {
                  AsyncData(:final value) when value.isNotEmpty =>
                    AppStrings.homeSectionSort,
                  AsyncData() => AppStrings.homeSectionCount(0),
                  _ => null,
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              switch (cards) {
                AsyncData(:final value) when value.isEmpty => _EmptyState(
                  onCreate: onCreate,
                  onSample: onSample,
                ),
                AsyncData() => Column(
                  spacing: AppSpacing.md,
                  children: [
                    for (final card in list)
                      PresentationCard(
                        presentation: card.presentation,
                        today: today,
                        stageLabel: card.stageLabel,
                        stageTone: card.stageTone,
                        matchTrend: card.matchTrend,
                        onTap: () => onCardTap(card.presentation),
                      ),
                  ],
                ),
                AsyncError() => _LoadFailed(onRetry: onRetry),
                _ => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

/// Pen `EmptyState` (06): 아이콘 원 · 제목 · 설명 · 버튼 2개
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onSample;

  const _EmptyState({required this.onCreate, required this.onSample});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 36,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        spacing: 14,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.ice100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.mic,
              size: 28,
              color: AppColors.blue500,
            ),
          ),
          Text(
            AppStrings.homeEmptyTitle,
            textAlign: TextAlign.center,
            style: AppTheme.body(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          Text(
            AppStrings.homeEmptyDesc,
            textAlign: TextAlign.center,
            style: AppTheme.body(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                PrimaryButton(
                  label: AppStrings.homeCreateFirst,
                  onPressed: onCreate,
                ),
                SecondaryButton(
                  label: AppStrings.homeSample,
                  onPressed: onSample,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadFailed({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Row(
            spacing: 10,
            children: [
              const Icon(
                LucideIcons.circleAlert,
                size: 20,
                color: AppColors.danger,
              ),
              Expanded(
                child: Text(
                  AppStrings.homeLoadFailed,
                  style: AppTheme.body(fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ),
          SecondaryButton(label: AppStrings.commonRetry, onPressed: onRetry),
        ],
      ),
    );
  }
}
