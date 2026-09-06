import 'package:flutter/material.dart';
import 'package:rehearsallab/ui/common/placeholder_page.dart';

/// Phase 0 placeholder. Phase 1에서 구현 (X1-2 · X1-3 · 14–16 · 27–30 녹음).
class RecordingPage extends StatelessWidget {
  final String presentationId;
  final String scriptVersionId;
  const RecordingPage({
    super.key,
    required this.presentationId,
    required this.scriptVersionId,
  });

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: '녹음',
      task: 'X1-2 · X1-3 · 14–16 · 27–30 녹음',
      penIds: ['A5qwt', 'DYCzF', 'b7wQyw', 'bIkRh'],
    );
  }
}
