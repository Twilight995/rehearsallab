import 'package:flutter/material.dart';
import 'package:rehearsallab/ui/common/placeholder_page.dart';

/// Phase 0 placeholder. Phase 1에서 구현 (C1-1 · 01–02 소개).
class OnboardingIntroPage extends StatelessWidget {
  const OnboardingIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: '소개',
      task: 'C1-1 · 01–02 소개',
      penIds: ['ynwPV', 'D4U0Y5'],
    );
  }
}
