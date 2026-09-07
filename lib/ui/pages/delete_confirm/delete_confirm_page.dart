import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/core/extension/build_context_extension.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/settings/settings_provider.dart';
import 'package:rehearsallab/ui/common/app_top_bar.dart';
import 'package:rehearsallab/ui/common/label_text_field.dart';
import 'package:rehearsallab/ui/common/primary_button.dart';
import 'package:rehearsallab/ui/common/secondary_button.dart';

/// 31 · 32 모든 데이터 삭제 (`A9rwI` · `FtrHa`). step 1 = 안내 + 다음 확인, step 2 = "삭제" 입력 일치 후 영구 삭제.
/// 삭제 실패는 지워진 척하지 않고 문구 + 재시도 (통합 문서 4장). 성공 → 06 빈 홈.
class DeleteConfirmPage extends ConsumerStatefulWidget {
  final int step;

  const DeleteConfirmPage({super.key, required this.step});

  @override
  ConsumerState<DeleteConfirmPage> createState() => _DeleteConfirmPageState();
}

class _DeleteConfirmPageState extends ConsumerState<DeleteConfirmPage> {
  final _keyword = TextEditingController();
  bool _deleting = false;
  String? _error;

  bool get _isStep2 => widget.step >= 2;
  bool get _keywordMatches => _keyword.text.trim() == AppStrings.delete2Keyword;

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  void _cancel() => context.go(AppPage.settings.path);

  void _next() =>
      context.push(AppPage.deleteConfirm.location({RouteParam.step: '2'}));

  Future<void> _deleteAll() async {
    setState(() {
      _deleting = true;
      _error = null;
    });
    Result<void> result;
    try {
      result = await ref.read(deleteAllDataProvider)();
    } on Object catch (e) {
      result = Failure(e is Exception ? e : Exception(e.toString()));
    }
    if (!mounted) return;
    switch (result) {
      case Success():
        context.go(AppPage.home.path);
        context.showSnackbar(AppStrings.deleteDone);
      case Failure():
        setState(() {
          _deleting = false;
          _error = AppStrings.deleteFailed;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = ref.watch(deleteScopeProvider).value;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppTopBar(
        title: AppStrings.deleteTitle,
        onBack: () => context.canPop() ? context.pop() : _cancel(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.lg,
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
                      Text(
                        AppStrings.deleteStep(_isStep2 ? 2 : 1),
                        style: AppTheme.body(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppColors.dangerBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.trash2,
                          size: 28,
                          color: AppColors.danger,
                        ),
                      ),
                      Text(
                        _isStep2
                            ? AppStrings.delete2Headline
                            : AppStrings.delete1Headline,
                        style: AppTheme.display(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        _isStep2
                            ? AppStrings.delete2Desc
                            : AppStrings.delete1Desc,
                        style: AppTheme.body(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.55,
                        ),
                      ),
                      const _Warning(),
                      _ScopeCard(scope: scope),
                      if (_isStep2) ...[
                        LabelTextField(
                          label: AppStrings.delete2InputLabel,
                          controller: _keyword,
                          hintText: AppStrings.delete2Keyword,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                        ),
                        Text(
                          AppStrings.delete2Note,
                          style: AppTheme.body(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                      if (_error != null)
                        Semantics(
                          liveRegion: true,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: AppSpacing.sm,
                            children: [
                              const Icon(
                                LucideIcons.circleAlert,
                                size: 16,
                                color: AppColors.danger,
                              ),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: AppTheme.body(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.danger,
                                    height: 1.4,
                                  ),
                                ),
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
          // Pen `BottomBar`: 취소(주 버튼) 위, 파괴적 동작(보조 · danger) 아래
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.md,
                  AppSpacing.page,
                  AppSpacing.xl,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.contentMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.sm,
                      children: [
                        PrimaryButton(
                          label: AppStrings.deleteCancel,
                          onPressed: _deleting ? null : _cancel,
                        ),
                        SecondaryButton(
                          label: _isStep2
                              ? AppStrings.delete2Confirm
                              : AppStrings.delete1Next,
                          danger: true,
                          onPressed: _isStep2
                              ? (_keywordMatches && !_deleting
                                    ? _deleteAll
                                    : null)
                              : _next,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              LucideIcons.triangleAlert,
              size: 16,
              color: AppColors.danger,
            ),
          ),
          Expanded(
            child: Text(
              AppStrings.deleteWarning,
              style: AppTheme.body(
                fontSize: 13,
                color: AppColors.danger,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pen `DeleteScope`: 삭제되는 데이터 집계 (저장소 실제 값)
class _ScopeCard extends StatelessWidget {
  final DeleteScope? scope;

  const _ScopeCard({required this.scope});

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.body(
      fontSize: 14,
      color: AppColors.textSecondary,
      height: 1.5,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Text(
            AppStrings.deleteScopeHeading,
            style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          Text(
            AppStrings.deleteScopePresentations(
              scope?.presentations ?? 0,
              scope?.scriptVersions ?? 0,
            ),
            style: style,
          ),
          Text(
            AppStrings.deleteScopeRehearsals(
              scope?.rehearsals ?? 0,
              scope?.reports ?? 0,
            ),
            style: style,
          ),
          Text(AppStrings.deleteScopeAnalyses, style: style),
        ],
      ),
    );
  }
}
