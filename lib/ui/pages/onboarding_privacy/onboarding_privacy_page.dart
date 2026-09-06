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
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/models/consent_record.dart';
import 'package:rehearsallab/models/provider_config.dart';
import 'package:rehearsallab/ui/common/onboarding_frame.dart';

/// 03 프라이버시 동의 (`e9S60s`). 제공사명 · 보관 · 삭제 안내 카드 + 필수 동의 체크.
/// 체크해야 "동의하고 시작하기"가 활성화되고, 동의 시각 · 버전을 저장한 뒤 04 로그인으로 간다.
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

  Future<void> _accept() async {
    setState(() => _saving = true);
    final result = await ref.read(consentNotifierProvider.notifier).accept();
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success<ConsentRecord>():
        context.go(AppPage.login.path);
      case Failure<ConsentRecord>(:final exception):
        context.showSnackbar(exception.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config =
        ref.watch(providerConfigProvider).value ?? ProviderConfig.empty;
    final version = ref.watch(currentConsentVersionProvider).value ?? '-';
    return OnboardingFrame(
      pageIndex: 2,
      heroAlignment: MainAxisAlignment.start,
      headline: AppStrings.privacyHeadline,
      body: AppStrings.privacyBody,
      ctaLabel: AppStrings.privacyAgreeButton,
      onCta: _checked && !_saving ? _accept : null,
      hero: Column(
        spacing: AppSpacing.xl,
        children: [
          _PrivacyCard(config: config),
          _ConsentRow(
            checked: _checked,
            version: version,
            onChanged: (v) => setState(() => _checked = v),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  final ProviderConfig config;

  const _PrivacyCard({required this.config});

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String)>[
      (
        LucideIcons.cloudUpload,
        AppStrings.privacyTransferTitle,
        AppStrings.privacyTransferDesc(config.sttName, config.llmName),
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
    return Container(
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
                    ? const Border(bottom: BorderSide(color: AppColors.border))
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
                            color: AppColors.textSecondary,
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
    );
  }
}

/// 필수 동의 체크 행. 행 전체가 탭 영역(≥48px), 체크 상태를 Semantics로 전달.
class _ConsentRow extends StatelessWidget {
  final bool checked;
  final String version;
  final ValueChanged<bool> onChanged;

  const _ConsentRow({
    required this.checked,
    required this.version,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final text = AppStrings.privacyConsentText(version);
    return Semantics(
      checked: checked,
      label: text,
      child: InkWell(
        onTap: () => onChanged(!checked),
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
                  border: Border.all(color: AppColors.navy900, width: 1.5),
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
                    color: AppColors.navy900,
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
