import 'package:flutter/material.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/app/theme/preview.dart';

@AppThemePreview(group: 'Input', name: 'LabelTextField')
Widget preview() => const Padding(
  padding: EdgeInsets.all(20),
  child: Column(
    spacing: 16,
    children: [
      LabelTextField(label: '제목', hintText: '○○학회 구두발표'),
      LabelTextField(label: '비밀번호', hintText: '8자 이상', obscureText: true),
    ],
  ),
);

/// Pen `TextField` (Y4cpJ). 라벨(13 · secondary) + 높이 52 입력창 (surface-muted, radius md).
class LabelTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final bool enabled;
  final List<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const LabelTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTheme.body(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          maxLines: maxLines,
          enabled: enabled,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: AppTheme.body(fontSize: 15),
          decoration: InputDecoration(hintText: hintText, suffixIcon: suffix),
        ),
      ],
    );
  }
}
