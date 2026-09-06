import 'package:flutter/material.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';

extension BuildContextExtension on BuildContext {
  void showSnackbar(String text, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.danger : AppColors.navy900,
      ),
    );
  }

  /// 현재 화면 폭 (해상도 대응 규칙 참고용)
  double get screenWidth => MediaQuery.sizeOf(this).width;
}
