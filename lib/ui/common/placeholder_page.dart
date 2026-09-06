import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';

/// Phase 0 임시 페이지. Phase 1에서 담당자가 실제 화면으로 교체한다.
/// 라우트 연결과 뒤로 가기만 동작한다.
class PlaceholderPage extends StatelessWidget {
  final String title;
  final String task;
  final List<String> penIds;

  const PlaceholderPage({
    super.key,
    required this.title,
    required this.task,
    this.penIds = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(LucideIcons.chevronLeft),
                onPressed: () => context.pop(),
                tooltip: AppStrings.commonBack,
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                const Icon(
                  LucideIcons.construction,
                  size: 40,
                  color: AppColors.textTertiary,
                ),
                Text(
                  AppStrings.placeholderBody(task),
                  textAlign: TextAlign.center,
                  style: AppTheme.body(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (penIds.isNotEmpty)
                  Text(
                    'Pen: ${penIds.join(', ')}',
                    style: AppTheme.body(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
