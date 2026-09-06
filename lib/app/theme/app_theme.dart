import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';

///
/// 앱 테마
/// - 디자인 토큰: Pen `font/display` = Manrope (숫자 · 헤드라인), `font/body` = Noto Sans KR (본문)
/// - 프로토타입은 라이트 테마만 디자인됨. dark는 시스템 대응용 최소 정의.
class AppTheme {
  AppTheme._();

  /// 숫자 · 헤드라인용 (Manrope)
  static TextStyle display({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w800,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) => GoogleFonts.manrope(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  /// 본문용 (Noto Sans KR)
  static TextStyle body({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.notoSansKr(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static ThemeData get light => ThemeData.light(useMaterial3: true).copyWith(
    brightness: Brightness.light,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.navy900,
      secondary: AppColors.blue500,
      surface: AppColors.surface,
      error: AppColors.danger,
      onPrimary: AppColors.onDark,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: GoogleFonts.notoSansKrTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: body(fontSize: 17, fontWeight: FontWeight.w600),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceMuted,
      hintStyle: body(color: AppColors.textTertiary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.blue500),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navy900,
      contentTextStyle: body(fontSize: 14, color: AppColors.onDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
    ),
  );

  static ThemeData get dark => ThemeData.dark(useMaterial3: true).copyWith(
    brightness: Brightness.dark,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: AppColors.navy900,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.ice300,
      secondary: AppColors.blue500,
      surface: AppColors.navy700,
      error: AppColors.danger,
      onPrimary: AppColors.navy900,
      onSurface: AppColors.onDark,
    ),
    textTheme: GoogleFonts.notoSansKrTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.navy900,
      foregroundColor: AppColors.onDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: body(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.onDark,
      ),
    ),
  );
}
