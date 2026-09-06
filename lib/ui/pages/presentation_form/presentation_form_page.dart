import 'package:flutter/material.dart';
import 'package:rehearsallab/ui/common/placeholder_page.dart';

/// Phase 0 placeholder. Phase 1에서 구현 (C1-3 · 08 발표 생성).
class PresentationFormPage extends StatelessWidget {
  final String? presentationId;
  const PresentationFormPage({super.key, this.presentationId});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: '새 발표',
      task: 'C1-3 · 08 발표 생성',
      penIds: ['xfwQs'],
    );
  }
}
