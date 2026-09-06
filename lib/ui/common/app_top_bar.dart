import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/app/theme/preview.dart';

@AppThemePreview(group: 'Navigation', name: 'AppTopBar')
Widget preview() => Column(
  spacing: 12,
  children: [
    AppTopBar(onBack: () {}),
    AppTopBar(title: '새 발표', onBack: () {}),
    AppTopBar(
      title: '설정',
      onBack: () {},
      trailing: IconButton(
        onPressed: () {},
        icon: const Icon(LucideIcons.ellipsis),
      ),
    ),
  ],
);

/// Pen `AppBar` (Z3Hch5): 높이 56, 좌측 48×48 뒤로가기, 가운데 제목(17 · 600), 우측 48×48 슬롯.
/// 제목이 없으면 빈 칸(04 · 05처럼 뒤로가기만 있는 화면).
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  static const double barHeight = 56;

  final String? title;
  final VoidCallback? onBack;
  final Widget? trailing;

  const AppTopBar({super.key, this.title, this.onBack, this.trailing});

  @override
  Size get preferredSize => const Size.fromHeight(barHeight);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: barHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              SizedBox(
                width: AppSpacing.touchTarget,
                height: AppSpacing.touchTarget,
                child: onBack == null
                    ? null
                    : IconButton(
                        onPressed: onBack,
                        tooltip: AppStrings.commonBack,
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          LucideIcons.chevronLeft,
                          size: 24,
                          color: AppColors.textPrimary,
                        ),
                      ),
              ),
              Expanded(
                child: Text(
                  title ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                width: AppSpacing.touchTarget,
                height: AppSpacing.touchTarget,
                child: trailing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
