import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/app/theme/preview.dart';

@AppThemePreview(group: 'Navigation', name: 'BottomDock')
// 실제 배치와 같게 바깥 여백 없이 전체 폭에 둔다 (여백은 BottomDock 자신이 16px 소유).
Widget preview() => Column(
  spacing: 16,
  children: [
    BottomDock(current: DockTab.home, onTap: (_) {}, onFabTap: () {}),
    BottomDock(current: DockTab.settings, onTap: (_) {}),
  ],
);

enum DockTab { home, presentation, settings }

extension DockTabExtension on DockTab {
  String get label => switch (this) {
    DockTab.home => AppStrings.tabHome,
    DockTab.presentation => AppStrings.tabPresentation,
    DockTab.settings => AppStrings.tabSettings,
  };

  IconData get icon => switch (this) {
    DockTab.home => LucideIcons.house,
    DockTab.presentation => LucideIcons.asterisk,
    DockTab.settings => LucideIcons.settings,
  };
}

/// Pen `BottomTabBar` (dfj81) + `FAB` (J9SAWM)를 담는 `BottomDock`.
/// 다크 캡슐 탭바(홈 · 발표 · 설정)와 새 발표 FAB. 절대 위치가 아니라 Column 하단에 둔다.
class BottomDock extends StatelessWidget {
  final DockTab current;
  final ValueChanged<DockTab> onTap;
  final VoidCallback? onFabTap;

  const BottomDock({
    super.key,
    required this.current,
    required this.onTap,
    this.onFabTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.navy900,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy900.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                for (final tab in DockTab.values)
                  _DockItem(
                    tab: tab,
                    selected: tab == current,
                    onTap: () => onTap(tab),
                  ),
              ],
            ),
          ),
          if (onFabTap != null)
            Semantics(
              button: true,
              label: AppStrings.formTitle,
              child: Material(
                color: AppColors.blue500,
                shape: const CircleBorder(),
                elevation: 6,
                shadowColor: AppColors.blue500.withValues(alpha: 0.3),
                child: InkWell(
                  onTap: onFabTap,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(
                      LucideIcons.plus,
                      color: AppColors.onDark,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final DockTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _DockItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.onDark : AppColors.onDarkMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: Material(
        color: selected ? AppColors.onDarkSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: 64,
            height: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 2,
              children: [
                Icon(tab.icon, size: 20, color: color),
                Text(
                  tab.label,
                  style: AppTheme.body(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
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
