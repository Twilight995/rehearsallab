import 'package:flutter/material.dart';
import 'package:rehearsallab/ui/common/placeholder_page.dart';

/// Phase 0 placeholder. Phase 1에서 구현 (X1-4 · 17–19 처리 중).
class ProcessingPage extends StatelessWidget {
  final String rehearsalId;
  const ProcessingPage({super.key, required this.rehearsalId});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: '리허설 처리 중',
      task: 'X1-4 · 17–19 처리 중',
      penIds: ['PCq55', 'GEzbr', 'iudTp'],
    );
  }
}
