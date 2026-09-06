import 'package:flutter/material.dart';
import 'package:rehearsallab/ui/common/placeholder_page.dart';

/// Phase 0 placeholder. Phase 1에서 구현 (X1-1 · 25–26 마이크 권한).
class MicPermissionPage extends StatelessWidget {
  final String presentationId;
  const MicPermissionPage({super.key, required this.presentationId});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: '마이크 권한',
      task: 'X1-1 · 25–26 마이크 권한',
      penIds: ['GODHo', 'ULwnI'],
    );
  }
}
