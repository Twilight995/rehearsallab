import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/core/enum/badge_tone.dart';
import 'package:rehearsallab/core/extension/build_context_extension.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/presentation/presentation_provider.dart';
import 'package:rehearsallab/features/settings/settings_provider.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/ui/common/app_top_bar.dart';
import 'package:rehearsallab/ui/common/bottom_action_bar.dart';
import 'package:rehearsallab/ui/common/detail_header.dart';
import 'package:rehearsallab/ui/common/primary_button.dart';

/// 발표 상세 탭 컨테이너 (C1-5). AppBar(발표 상세 · ⋯ 메뉴) + DetailHeader(제목 · 배지 · 메타 · 탭 4개) + 탭 본문.
/// - 원고 탭: C1-6~C1-8, 리허설 탭: X1 — 그 전까지는 임시 안내
/// - Q&A(23 `RPAMd`) · 이력(24 `zw5nf`): "2차 기능 · 준비 중" + 하단 버튼으로 리허설 탭 이동
/// 딥링크 `?tab=script|rehearsal|qa|history`. 없으면 마지막에 보던 탭, 그것도 없으면 원고 (통합 문서 4장).
class PresentationDetailPage extends ConsumerStatefulWidget {
  final String presentationId;
  final String? initialTab;

  const PresentationDetailPage({
    super.key,
    required this.presentationId,
    this.initialTab,
  });

  @override
  ConsumerState<PresentationDetailPage> createState() =>
      _PresentationDetailPageState();
}

class _PresentationDetailPageState
    extends ConsumerState<PresentationDetailPage> {
  DetailTab? _tab;

  DetailTab? _parse(String? name) {
    if (name == null) return null;
    for (final t in DetailTab.values) {
      if (t.name == name) return t;
    }
    return null;
  }

  void _select(DetailTab tab) {
    setState(() => _tab = tab);
    ref
        .read(settingsServiceProvider)
        .saveLastTab(widget.presentationId, tab.name);
    ref.invalidate(lastDetailTabProvider(widget.presentationId));
  }

  Future<void> _onMenu(String action, Presentation p) async {
    switch (action) {
      case 'edit':
        await context.push(
          AppPage.presentationForm.location({RouteParam.presentationId: p.id}),
        );
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppStrings.detailDeleteTitle(p.title)),
            content: const Text(AppStrings.detailDeleteDesc),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppStrings.commonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  AppStrings.detailDeleteConfirm,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
        final result = await ref
            .read(presentationsProvider.notifier)
            .delete(p.id);
        if (!mounted) return;
        switch (result) {
          case Success():
            context.go(AppPage.home.path);
          case Failure():
            context.showSnackbar(AppStrings.detailDeleteFailed, isError: true);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentation = ref.watch(
      presentationByIdProvider(widget.presentationId),
    );
    final presentationsLoaded = ref.watch(presentationsProvider).hasValue;
    if (presentation == null) {
      return _Missing(loaded: presentationsLoaded);
    }
    final lastTab = ref.watch(lastDetailTabProvider(widget.presentationId));
    final tab =
        _tab ??
        _parse(widget.initialTab) ??
        _parse(lastTab.value) ??
        DetailTab.script;
    final cards = ref.watch(homeCardsProvider).value ?? const <HomeCard>[];
    HomeCard? card;
    for (final c in cards) {
      if (c.presentation.id == presentation.id) card = c;
    }
    final today = ref.watch(todayProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppTopBar(
        title: AppStrings.detailTitle,
        onBack: () =>
            context.canPop() ? context.pop() : context.go(AppPage.home.path),
        trailing: PopupMenuButton<String>(
          tooltip: AppStrings.detailMenu,
          icon: const Icon(
            LucideIcons.ellipsis,
            size: 22,
            color: AppColors.textPrimary,
          ),
          onSelected: (action) => _onMenu(action, presentation),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text(AppStrings.commonEdit),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text(
                AppStrings.detailDeleteMenu,
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          DetailHeader(
            presentation: presentation,
            today: today,
            badgeLabel: card?.stageLabel ?? AppStrings.detailBadgeLoading,
            badgeTone: card?.stageTone ?? BadgeTone.neutral,
            activeTab: tab,
            onTabChanged: _select,
          ),
          Expanded(
            child: switch (tab) {
              DetailTab.script => _TabPlaceholder(
                task: AppStrings.detailScriptPending,
              ),
              DetailTab.rehearsal => _TabPlaceholder(
                task: AppStrings.detailRehearsalPending,
              ),
              DetailTab.qa => _ComingSoon(
                title: AppStrings.qaTitle,
                desc: AppStrings.qaDesc,
                features: const [
                  (LucideIcons.circleQuestionMark, AppStrings.qaPlanned1),
                  (LucideIcons.mic, AppStrings.qaPlanned2),
                  (LucideIcons.badgeCheck, AppStrings.qaPlanned3),
                ],
                action: AppStrings.qaBack,
                onAction: () => _select(DetailTab.rehearsal),
              ),
              DetailTab.history => _ComingSoon(
                title: AppStrings.historyTitle,
                desc: AppStrings.historyDesc,
                features: const [
                  (LucideIcons.chartLine, AppStrings.historyPlanned1),
                  (LucideIcons.listChecks, AppStrings.historyPlanned2),
                  (LucideIcons.gitCommitHorizontal, AppStrings.historyPlanned3),
                ],
                action: AppStrings.historyBack,
                onAction: () => _select(DetailTab.rehearsal),
              ),
            },
          ),
        ],
      ),
    );
  }
}

/// 23 · 24 준비 중 (Pen `Content` + `BottomBar`)
class _ComingSoon extends StatelessWidget {
  final String title;
  final String desc;
  final List<(IconData, String)> features;
  final String action;
  final VoidCallback onAction;

  const _ComingSoon({
    required this.title,
    required this.desc,
    required this.features,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              28,
              AppSpacing.page,
              AppSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.contentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.lg,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        AppStrings.commonPrepared,
                        style: AppTheme.body(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      title,
                      style: AppTheme.display(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      desc,
                      style: AppTheme.body(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpacing.md,
                        children: [
                          Text(
                            AppStrings.plannedHeading,
                            style: AppTheme.body(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          for (final (icon, text) in features)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 10,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    icon,
                                    size: 16,
                                    color: AppColors.blue500,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    text,
                                    style: AppTheme.body(
                                      fontSize: 14,
                                      height: 1.45,
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
              ),
            ),
          ),
        ),
        BottomActionBar(
          primary: PrimaryButton(label: action, onPressed: onAction),
        ),
      ],
    );
  }
}

/// 원고 · 리허설 탭이 구현되기 전 임시 안내 (C1-6 · X1)
class _TabPlaceholder extends StatelessWidget {
  final String task;

  const _TabPlaceholder({required this.task});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Text(
          AppStrings.placeholderBody(task),
          textAlign: TextAlign.center,
          style: AppTheme.body(fontSize: 14, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

/// 없는 발표(삭제됨 · 잘못된 id): 로드 중이면 스피너, 아니면 안내 + 홈으로
class _Missing extends StatelessWidget {
  final bool loaded;

  const _Missing({required this.loaded});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppTopBar(
        title: AppStrings.detailTitle,
        onBack: () =>
            context.canPop() ? context.pop() : context.go(AppPage.home.path),
      ),
      body: Center(
        child: !loaded
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(AppSpacing.page),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.lg,
                  children: [
                    Text(
                      AppStrings.detailMissing,
                      textAlign: TextAlign.center,
                      style: AppTheme.body(fontSize: 15),
                    ),
                    PrimaryButton(
                      label: AppStrings.tabHome,
                      onPressed: () => context.go(AppPage.home.path),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
