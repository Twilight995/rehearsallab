import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/router/app_router.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/ui/common/app_mode_overlay.dart';

void main() {
  runApp(const ProviderScope(child: RehearsalLabApp()));
}

class RehearsalLabApp extends StatelessWidget {
  const RehearsalLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      // 프로토타입은 라이트 테마만 디자인됨. 시스템 다크 모드에서도 라이트 유지.
      themeMode: ThemeMode.light,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
      builder: (context, child) =>
          AppModeOverlay(child: child ?? const SizedBox()),
    );
  }
}
