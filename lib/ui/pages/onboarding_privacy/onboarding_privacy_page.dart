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
import 'package:rehearsallab/features/auth/auth_provider.dart';
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/models/consent_record.dart';
import 'package:rehearsallab/models/provider_config.dart';
import 'package:rehearsallab/services/consent_service.dart';
import 'package:rehearsallab/ui/common/onboarding_frame.dart';
import 'package:rehearsallab/ui/common/secondary_button.dart';

/// 03 프라이버시 동의 (`e9S60s`). 제공사명 · 보관 · 삭제 안내 카드 + 필수 동의 체크.
/// 고지(제공사 설정 · 버전)가 **다 불러와진 뒤에만** 체크 · 동의가 가능하고, 화면에 표시한 버전을
/// 그대로 저장한다. 불러오기 실패는 재시도 버튼, 설정 변경으로 버전이 바뀌면 체크를 해제한다 (C1-REV-02).
/// 로그인 전이면 미귀속(`local`) 기록으로 저장하고 04로, 세션이 있으면(재동의) 그 계정으로 저장하고 홈으로 간다.
/// 건너뛰기는 없다 (통합 문서 4장). 설정 09 "프라이버시 고지 다시 보기"에서도 이 화면을 연다.
class OnboardingPrivacyPage extends ConsumerStatefulWidget {
  const OnboardingPrivacyPage({super.key});

  @override
  ConsumerState<OnboardingPrivacyPage> createState() =>
      _OnboardingPrivacyPageState();
}

class _OnboardingPrivacyPageState extends ConsumerState<OnboardingPrivacyPage> {
  bool _checked = false;
  bool _saving = false;

  Future<void> _accept(String version) async {
    setState(() => _saving = true);
    final user = ref.read(authNotifierProvider).value;
    final result = await ref
        .read(consentNotifierProvider.notifier)
        .accept(
          userId: user?.id ?? ConsentService.unboundUserId,
          version: version,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success<ConsentRecord>():
        context.go(user == null ? AppPage.login.path : AppPage.home.path);
      case Failure<ConsentRecord>(:final exception):
        context.showSnackbar(exception.toString(), isError: true);
    }
  }

  void _retry() {
    ref.invalidate(providerConfigProvider);
  }

  @override
  Widget build(BuildContext context) {
    // 버전이 바뀌면(설정 변경 · 재로딩) 이전 체크는 무효
    ref.listen(currentConsentVersionProvider, (previous, next) {
      if (previous?.value != next.value && _checked) {
        setState(() => _checked = false);
      }
    });
    final config = ref.watch(providerConfigProvider);
    final version = ref.watch(currentConsentVersionProvider);
    final loaded = config.hasValue && version.hasValue && !version.isLoading;
    final failed = config.hasError || version.hasError;
    final versionLabel = version.value ?? AppStrings.privacyVersionPending;

    return OnboardingFrame(
      pageIndex: 2,
      heroAlignment: MainAxisAlignment.start,
      headline: AppStrings.privacyHeadline,
      body: AppStrings.privacyBody,
      ctaLabel: AppStrings.privacyAgreeButton,
      onCta: loaded && _checked && !_saving
          ? () => _accept(version.value!)
          : null,
      hero: Column(
        spacing: AppSpacing.xl,
        children: [
          if (failed)
            _LoadFailedCard(onRetry: _retry)
          else
            _PrivacyCard(
              config: config.value ?? ProviderConfig.empty,
              loading: !loaded,
            ),
          _ConsentRow(
            checked: _checked,
            enabled: loaded,
            version: versionLabel,
            onChanged: (v) => setState(() => _checked = v),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  final ProviderConfig config;
  final bool loading;

  const _PrivacyCard({required this.config, required this.loading});

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String)>[
      (
        LucideIcons.cloudUpload,
        AppStrings.privacyTransferTitle,
        loading
            ? AppStrings.privacyLoading
            : AppStrings.privacyTransferDesc(config.sttName, config.llmName),
      ),
      (
        LucideIcons.timer,
        AppStrings.privacyRetentionTitle,
        AppStrings.privacyRetentionDesc,
      ),
      (
        LucideIcons.trash2,
        AppStrings.privacyDeleteTitle,
        AppStrings.privacyDeleteDesc,
      ),
    ];
    return Semantics(
      liveRegion: loading,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.onDark.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  border: i < rows.length - 1
                      ? const Border(
                          bottom: BorderSide(color: AppColors.border),
                        )
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 14,
                  children: [
                    Icon(rows[i].$1, size: 20, color: AppColors.blue500),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Text(
                            rows[i].$2,
                            style: AppTheme.body(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            rows[i].$3,
                            style: AppTheme.body(
                              fontSize: 13,
                              color: loading && i == 0
                                  ? AppColors.textTertiary
                                  : AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// providers.json을 읽지 못했을 때. "제공사 미지정"(정상 · 빈 설정)과 구분한다.
class _LoadFailedCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadFailedCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.onDark.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              const Icon(
                LucideIcons.circleAlert,
                size: 20,
                color: AppColors.danger,
              ),
              Expanded(
                child: Text(
                  AppStrings.privacyLoadFailed,
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

/// 필수 동의 체크 행. 행 전체가 탭 영역(≥48px), 체크 상태를 Semantics로 전달.
/// 고지를 다 불러오기 전에는 비활성(회색 · 탭 무시).
class _ConsentRow extends StatelessWidget {
  final bool checked;
  final bool enabled;
  final String version;
  final ValueChanged<bool> onChanged;

  const _ConsentRow({
    required this.checked,
    required this.enabled,
    required this.version,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final text = AppStrings.privacyConsentText(version);
    final color = enabled ? AppColors.navy900 : AppColors.textTertiary;
    return Semantics(
      checked: checked,
      enabled: enabled,
      label: text,
      child: InkWell(
        onTap: enabled ? () => onChanged(!checked) : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: checked ? AppColors.navy900 : AppColors.onDark,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color, width: 1.5),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
