import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rehearsallab/app/app_config.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/core/enum/app_mode.dart';

/// mock 모드일 때 화면 우상단에 "개발용 목업" 배지를 상시 표시한다 (통합 문서 5장 앱 모드).
/// MaterialApp.router의 builder에서 감싼다.
class AppModeOverlay extends ConsumerWidget {
  final Widget child;

  const AppModeOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);
    if (mode != AppMode.mock) return child;
    return Stack(
      children: [
        child,
        Positioned(
          top: MediaQuery.paddingOf(context).top + 6,
          right: 8,
          child: IgnorePointer(
            child: Semantics(
              label: AppStrings.commonMockBadge,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  AppStrings.commonMockBadge,
                  style: AppTheme.body(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
