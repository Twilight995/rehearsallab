import 'package:flutter/material.dart';
import 'package:rehearsallab/ui/common/placeholder_page.dart';

/// Phase 0 placeholder. Phase 1에서 구현 (C1-5 ~ C1-8 · 원고 탭, X1-1 · X1-7 · 리허설 탭).
class PresentationDetailPage extends StatelessWidget {
  final String presentationId;
  final String? initialTab;
  const PresentationDetailPage({
    super.key,
    required this.presentationId,
    this.initialTab,
  });

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: '발표 상세',
      task: 'C1-5 ~ C1-8 · 원고 탭, X1-1 · X1-7 · 리허설 탭',
      penIds: ['F6rAqv', 'SOEjW', 'GN4OJ', 'hM12e', 'jZBm9', 'Po4di'],
    );
  }
}
