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
import 'package:rehearsallab/features/consent/consent_provider.dart';

/// 00 스플래시 (`TTj3V`). 잠시 보여준 뒤 동의 상태에 따라 분기한다.
/// - 저장된 동의가 현재 버전과 같음 → 04 로그인 (C1-2 전까지는 placeholder)
/// - 없거나 버전이 다름 → 01 소개
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

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, _decide);
  }

  Future<void> _decide() async {
    // 동의 기록 로드가 끝날 때까지 기다린 뒤 분기
    await ref.read(consentNotifierProvider.future);
    final current = await ref
        .read(consentNotifierProvider.notifier)
        .isCurrent();
    if (!mounted) return;
    context.go(current ? AppPage.login.path : AppPage.onboardingIntro.path);
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
                child: Text(
                  AppStrings.splashTagline,
                  textAlign: TextAlign.center,
                  style: AppTheme.body(
                    fontSize: 13,
                    color: AppColors.onDarkMuted,
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
