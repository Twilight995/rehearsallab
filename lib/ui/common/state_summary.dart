import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/app/theme/preview.dart';
import 'package:rehearsallab/core/enum/audio_state.dart';
import 'package:rehearsallab/core/enum/stage_state.dart';

@AppThemePreview(group: 'Status', name: 'StateSummary')
Widget preview() => const Padding(
  padding: EdgeInsets.all(20),
  child: Column(
    spacing: 12,
    children: [
      StateSummary(
        aiState: StageState.failed,
        audioState: AudioState.stored,
        audioDateLabel: '9월 16일 21:14',
        retryDeadlineLabel: '9월 10일 21:14',
      ),
      StateSummary(
        aiState: StageState.pending,
        audioState: AudioState.localOnly,
        audioDateLabel: '9월 16일',
      ),
      StateSummary(
        aiState: StageState.succeeded,
        audioState: AudioState.expired,
      ),
    ],
  ),
);

/// Pen `StateSummary` (18 · 19 · 33 · 34). AI 상태와 오디오 상태를 **독립적으로 조합**해 보여준다.
class StateSummary extends StatelessWidget {
  final StageState aiState;
  final AudioState audioState;

  /// stored: 삭제 예정일 · localOnly: 재시도 가능 기한
  final String? audioDateLabel;
  final String? retryDeadlineLabel;

  const StateSummary({
    super.key,
    required this.aiState,
    required this.audioState,
    this.audioDateLabel,
    this.retryDeadlineLabel,
  });

  String get _audioText => switch (audioState) {
    AudioState.stored => AppStrings.stateAudioStored(audioDateLabel ?? '-'),
    AudioState.localOnly => AppStrings.stateAudioLocal(audioDateLabel ?? '-'),
    AudioState.expired || AudioState.deleted => AppStrings.stateAudioDeleted,
  };

  IconData get _audioIcon => switch (audioState) {
    AudioState.stored => LucideIcons.audioLines,
    AudioState.localOnly => LucideIcons.smartphone,
    AudioState.expired || AudioState.deleted => LucideIcons.volumeX,
  };

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String)>[
      (_audioIcon, _audioText),
      if (aiState == StageState.failed)
        (
          LucideIcons.sparkles,
          AppStrings.stateAiFailed(retryDeadlineLabel ?? '-'),
        ),
      if (aiState == StageState.succeeded)
        (LucideIcons.sparkles, AppStrings.stateAiOk),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          for (final (icon, text) in rows)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 14, color: AppColors.textSecondary),
                ),
                Expanded(
                  child: Text(
                    text,
                    style: AppTheme.body(fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
