import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/core/enum/external_deletion_state.dart';
import 'package:rehearsallab/core/enum/retention_option.dart';
import 'package:rehearsallab/core/extension/build_context_extension.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/auth/auth_provider.dart';
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/features/presentation/presentation_provider.dart';
import 'package:rehearsallab/features/settings/settings_provider.dart';
import 'package:rehearsallab/models/provider_config.dart';
import 'package:rehearsallab/models/rehearsal.dart';
import 'package:rehearsallab/ui/common/app_top_bar.dart';
import 'package:rehearsallab/ui/common/bottom_dock.dart';

/// 09 설정 (`dWVnU`). 계정 · 데이터 · 정보 그룹 + 보관 정책 상시 문구 + 하단 독(설정 선택).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _pickRetention(
    BuildContext context,
    WidgetRef ref,
    RetentionOption current,
  ) async {
    final picked = await showModalBottomSheet<RetentionOption>(
      context: context,
      showDragHandle: true,
      builder: (context) => _RetentionSheet(current: current),
    );
    if (picked == null || !context.mounted) return;
    final result = await ref.read(retentionOptionProvider.notifier).set(picked);
    if (result is Failure && context.mounted) {
      context.showSnackbar(AppStrings.settingsSaveFailed, isError: true);
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(authNotifierProvider.notifier).signOut();
    if (!context.mounted) return;
    switch (result) {
      case Success():
        context.go(AppPage.login.path);
      case Failure():
        context.showSnackbar(AppStrings.settingsLogoutFailed, isError: true);
    }
  }

  void _showProviders(BuildContext context, ProviderConfig config) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.settingsProviders),
        content: Text(
          config.isConfigured
              ? AppStrings.settingsProvidersDetail(
                  config.llmName,
                  config.llm!.region,
                  config.llm!.policyVersion,
                  config.sttName,
                  config.stt!.region,
                  config.stt!.policyVersion,
                )
              : AppStrings.commonProviderUnset,
          style: AppTheme.body(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.commonClose),
          ),
        ],
      ),
    );
  }

  void _onDockTap(BuildContext context, WidgetRef ref, DockTab tab) {
    switch (tab) {
      case DockTab.home:
        context.go(AppPage.home.path);
      case DockTab.presentation:
        final next = ref.read(nextPresentationProvider);
        context.go(
          next == null
              ? AppPage.presentationForm.path
              : AppPage.presentationDetail.location({
                  RouteParam.presentationId: next.id,
                }),
        );
      case DockTab.settings:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;
    final retention =
        ref.watch(retentionOptionProvider).value ?? RetentionOption.days7;
    final external =
        ref.watch(externalDeletionProvider).value ?? const ExternalDeletion();
    final config =
        ref.watch(providerConfigProvider).value ?? ProviderConfig.empty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppTopBar(
        title: AppStrings.settingsTitle,
        onBack: () =>
            context.canPop() ? context.pop() : context.go(AppPage.home.path),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
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
                    spacing: 28,
                    children: [
                      _Group(
                        title: AppStrings.settingsGroupAccount,
                        rows: [
                          _SettingsRow(
                            icon: LucideIcons.mail,
                            label: AppStrings.settingsEmail,
                            value: user?.email ?? '-',
                          ),
                          _SettingsRow(
                            icon: LucideIcons.logOut,
                            label: AppStrings.settingsLogout,
                            onTap: () => _logout(context, ref),
                          ),
                        ],
                      ),
                      _Group(
                        title: AppStrings.settingsGroupData,
                        rows: [
                          _SettingsRow(
                            icon: LucideIcons.timer,
                            label: AppStrings.settingsRetention,
                            value: AppStrings.settingsRetentionValue(
                              retention.title,
                            ),
                            onTap: () =>
                                _pickRetention(context, ref, retention),
                          ),
                          _SettingsRow(
                            icon: LucideIcons.trash2,
                            label: AppStrings.settingsDeleteAll,
                            danger: true,
                            showChevron: false,
                            onTap: () => context.push(
                              AppPage.deleteConfirm.location({
                                RouteParam.step: '1',
                              }),
                            ),
                          ),
                        ],
                        note: AppStrings.settingsRetentionNote,
                      ),
                      _Group(
                        title: AppStrings.settingsGroupInfo,
                        rows: [
                          _SettingsRow(
                            icon: LucideIcons.shield,
                            label: AppStrings.settingsPrivacyAgain,
                            onTap: () =>
                                context.push(AppPage.onboardingPrivacy.path),
                          ),
                          _SettingsRow(
                            icon: LucideIcons.cpu,
                            label: AppStrings.settingsProviders,
                            value: AppStrings.settingsProvidersValue(
                              config.llmName,
                              config.sttName,
                            ),
                            onTap: () => _showProviders(context, config),
                          ),
                          _SettingsRow(
                            icon: LucideIcons.database,
                            label: AppStrings.settingsExternal,
                            value: AppStrings.settingsExternalValue(
                              config.stt?.retentionLabel('audio') ??
                                  AppStrings.commonUndetermined,
                              config.llm?.retentionLabel('text') ??
                                  AppStrings.commonUndetermined,
                              _externalStatusLabel(external),
                            ),
                          ),
                          const _SettingsRow(
                            icon: LucideIcons.info,
                            label: AppStrings.settingsVersion,
                            value: AppStrings.settingsVersionValue,
                            showChevron: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: BottomDock(
              current: DockTab.settings,
              onTap: (tab) => _onDockTap(context, ref, tab),
            ),
          ),
        ],
      ),
    );
  }

  /// STT · LLM 상태가 같으면 하나로, 다르면 둘 다 표기
  static String _externalStatusLabel(ExternalDeletion e) =>
      e.stt == e.llm ? e.stt.title : '${e.stt.title} / ${e.llm.title}';
}

/// Pen `Group_*`: 소제목(12 · tertiary · 600) + GroupBox(surface-muted · radius md · 좌우 16) + 선택적 하단 문구
class _Group extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  final String? note;

  const _Group({required this.title, required this.rows, this.note});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Text(
          title,
          style: AppTheme.body(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                Container(
                  decoration: BoxDecoration(
                    border: i < rows.length - 1
                        ? const Border(
                            bottom: BorderSide(color: AppColors.border),
                          )
                        : null,
                  ),
                  child: rows[i],
                ),
            ],
          ),
        ),
        if (note != null)
          Text(
            note!,
            style: AppTheme.body(
              fontSize: 12,
              color: AppColors.textTertiary,
              height: 1.5,
            ),
          ),
      ],
    );
  }
}

/// Pen `Row_*`: 아이콘 20 · 라벨(15) · 값(14 · secondary) · 셰브론 18. 높이 ≥ 54, 값이 길면 줄바꿈.
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool danger;
  final bool showChevron;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.danger = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 14,
      ),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          Icon(
            icon,
            size: 20,
            color: danger ? AppColors.danger : AppColors.textSecondary,
          ),
          Expanded(
            child: Text(
              label,
              style: AppTheme.body(fontSize: 15, color: color),
            ),
          ),
          if (value != null)
            Flexible(
              child: Text(
                value!,
                textAlign: TextAlign.end,
                style: AppTheme.body(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          if (showChevron && onTap != null)
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.textTertiary,
            ),
        ],
      ),
    );
    return Semantics(
      button: onTap != null,
      label: value == null ? label : '$label, $value',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: onTap == null
            ? row
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: row,
              ),
      ),
    );
  }
}

/// 보관 기간 선택 바텀시트 (7일 · 30일 · 처리 후 즉시 삭제)
class _RetentionSheet extends StatelessWidget {
  final RetentionOption current;

  const _RetentionSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                AppStrings.settingsRetention,
                style: AppTheme.body(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            for (final option in RetentionOption.values)
              Semantics(
                button: true,
                selected: option == current,
                label: option.title,
                child: Material(
                  color: option == current
                      ? AppColors.blue100
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(option),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 52),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.title,
                              style: AppTheme.body(
                                fontSize: 15,
                                fontWeight: option == current
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (option == current)
                            const Icon(
                              LucideIcons.check,
                              size: 18,
                              color: AppColors.blue500,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
