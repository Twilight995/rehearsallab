import 'package:flutter/material.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';

/// StageBadge · StateSummary 등에서 쓰는 색 톤. 색만으로 상태를 전달하지 않고 항상 텍스트를 함께 둔다.
enum BadgeTone { info, success, warning, danger, neutral }

extension BadgeToneExtension on BadgeTone {
  Color get foreground => switch (this) {
    BadgeTone.info => AppColors.blue500,
    BadgeTone.success => AppColors.success,
    BadgeTone.warning => AppColors.warning,
    BadgeTone.danger => AppColors.danger,
    BadgeTone.neutral => AppColors.textSecondary,
  };

  Color get background => switch (this) {
    BadgeTone.info => AppColors.blue100,
    BadgeTone.success => AppColors.successBg,
    BadgeTone.warning => AppColors.warningBg,
    BadgeTone.danger => AppColors.dangerBg,
    BadgeTone.neutral => AppColors.surfaceMuted,
  };
}
