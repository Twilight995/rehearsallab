import 'package:flutter/material.dart';
import 'package:rehearsallab/ui/common/placeholder_page.dart';

/// Phase 0 placeholder. Phase 1에서 구현 (C1-4 · 31–32 삭제 확인).
class DeleteConfirmPage extends StatelessWidget {
  final int step;
  const DeleteConfirmPage({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: '모든 데이터 삭제',
      task: 'C1-4 · 31–32 삭제 확인',
      penIds: ['A9rwI', 'FtrHa'],
    );
  }
}
