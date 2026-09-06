import 'package:flutter/material.dart';
import 'package:rehearsallab/ui/common/placeholder_page.dart';

/// Phase 0 placeholder. Phase 1에서 구현 (X1-6 · X1-7 · 22 · 33 · 34 · 36 리포트).
class ReportPage extends StatelessWidget {
  final String rehearsalId;
  const ReportPage({super.key, required this.rehearsalId});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: '리허설 리포트',
      task: 'X1-6 · X1-7 · 22 · 33 · 34 · 36 리포트',
      penIds: ['uMPwe', 'MjJ5X', 'AxiyQ', 'AZx5w'],
    );
  }
}
