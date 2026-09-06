import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/ui/common/app_top_bar.dart';
import 'package:rehearsallab/ui/common/primary_button.dart';

/// 04 로그인 · 05 가입 공통 골격 (Pen l6Fzv · ZiY21 `Content`):
/// AppBar(뒤로가기) → 스크롤 본문 [Header(로고 36 · 제목 28/800 · 부제 15) · Form(gap 16) · Actions(gap 8)].
/// 오류 문구는 Form 아래에 danger 색 + 텍스트로 표시(색만으로 상태를 전하지 않음).
/// 키보드가 올라와도 CTA가 가려지지 않도록 본문 전체를 스크롤에 둔다.
class AuthFormFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> fields;
  final String? errorText;
  final String submitLabel;
  final VoidCallback? onSubmit;
  final bool submitting;
  final List<Widget> altActions;
  final VoidCallback? onBack;

  const AuthFormFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
    this.errorText,
    required this.submitLabel,
    required this.onSubmit,
    this.submitting = false,
    this.altActions = const [],
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppTopBar(onBack: onBack),
      // 태블릿 · 가로 모드: 본문 읽기 폭 480 상한 · 중앙 정렬 (통합 문서 7장, C1-REV-05)
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.lg,
          AppSpacing.page,
          AppSpacing.xxl,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    const Icon(
                      LucideIcons.asterisk,
                      size: 36,
                      color: AppColors.navy900,
                    ),
                    Text(
                      title,
                      style: AppTheme.display(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTheme.body(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.lg,
                    children: [
                      ...fields,
                      if (errorText != null)
                        Semantics(
                          liveRegion: true,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: AppSpacing.sm,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  LucideIcons.circleAlert,
                                  size: 16,
                                  color: AppColors.danger,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  errorText!,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    PrimaryButton(
                      label: submitLabel,
                      onPressed: submitting ? null : onSubmit,
                    ),
                    ...altActions,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pen `AltButton` / `Alt2Button`: 텍스트 링크. 높이 ≥ 48 (padding 12 8 + 최소 크기).
class AuthAltButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool muted;

  const AuthAltButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: muted
            ? AppColors.textTertiary
            : AppColors.textSecondary,
        minimumSize: const Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        textStyle: AppTheme.body(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
