import 'package:flutter/widget_previews.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';

/// widget_previews용 프리뷰 (unitask와 동일한 패턴)
final class AppThemePreview extends Preview {
  const AppThemePreview({
    super.name,
    super.brightness,
    super.group,
    super.localizations,
    super.size,
    super.textScaleFactor,
    super.wrapper,
  }) : super(theme: AppThemePreview.themeBuilder);

  static PreviewThemeData themeBuilder() => PreviewThemeData(
    materialLight: AppTheme.light,
    materialDark: AppTheme.dark,
  );
}
