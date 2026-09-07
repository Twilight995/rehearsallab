import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/features/auth/auth_provider.dart';
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/ui/common/primary_button.dart';

/// 00 스플래시 (`TTj3V`). 잠시 보여준 뒤 동의 · 세션 상태에 따라 분기한다.
/// - 세션 있음: 그 계정의 동의가 현재 버전이면 06/07 홈, 아니면 01 소개(→ 03 재동의)
/// - 세션 없음: 미귀속(`local`) 동의가 현재 버전이면 04 로그인, 아니면 01 소개
/// 설정 · 동의 · 세션 로드에 실패하면 화면에 오류와 재시도 버튼을 보여준다 (C1-REV-03).
class SplashPage extends ConsumerStatefulWidget {
  /// 테스트에서 지연을 없애기 위해 주입
  final Duration delay;

  const SplashPage({
    super.key,
    this.delay = const Duration(milliseconds: 1200),
  });

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  Timer? _timer;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, _decide);
  }

  Future<void> _decide() async {
    try {
      // 동의 기록 · 세션 로드가 끝날 때까지 기다린 뒤 분기
      await ref.read(consentNotifierProvider.future);
      final user = await ref.read(authNotifierProvider.future);
      final current = await ref
          .read(consentNotifierProvider.notifier)
          .isCurrentFor(user?.id);
      if (!mounted) return;
      if (!current) {
        context.go(AppPage.onboardingIntro.path);
      } else {
        context.go(user == null ? AppPage.login.path : AppPage.home.path);
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _retry() {
    setState(() => _error = null);
    ref.invalidate(providerConfigProvider);
    ref.invalidate(consentNotifierProvider);
    ref.invalidate(authNotifierProvider);
    _decide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppSpacing.lg,
                  children: [
                    const Icon(
                      LucideIcons.asterisk,
                      size: 96,
                      color: AppColors.navy900,
                    ),
                    Text(
                      AppStrings.appName,
                      style: AppTheme.display(
                        fontSize: 24,
                        color: AppColors.navy900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  0,
                  AppSpacing.page,
                  40,
                ),
                child: _error == null
                    ? Text(
                        AppStrings.splashTagline,
                        textAlign: TextAlign.center,
                        style: AppTheme.body(
                          fontSize: 13,
                          color: AppColors.onDarkMuted,
                        ),
                      )
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppSpacing.contentMaxWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: AppSpacing.md,
                            children: [
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  AppStrings.splashLoadFailed,
                                  textAlign: TextAlign.center,
                                  style: AppTheme.body(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.onDark,
                                  ),
                                ),
                              ),
                              PrimaryButton(
                                label: AppStrings.commonRetry,
                                onDark: true,
                                onPressed: _retry,
                              ),
                            ],
                          ),
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
