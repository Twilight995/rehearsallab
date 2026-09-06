import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/core/enum/audio_state.dart';
import 'package:rehearsallab/core/enum/badge_tone.dart';
import 'package:rehearsallab/core/enum/rehearsal_scope.dart';
import 'package:rehearsallab/core/enum/stage_state.dart';
import 'package:rehearsallab/core/enum/transcript_state.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/ui/common/action_check_item.dart';
import 'package:rehearsallab/ui/common/app_chip.dart';
import 'package:rehearsallab/ui/common/bottom_action_bar.dart';
import 'package:rehearsallab/ui/common/bottom_dock.dart';
import 'package:rehearsallab/ui/common/detail_header.dart';
import 'package:rehearsallab/ui/common/dimension_card.dart';
import 'package:rehearsallab/ui/common/label_text_field.dart';
import 'package:rehearsallab/ui/common/presentation_card.dart';
import 'package:rehearsallab/ui/common/primary_button.dart';
import 'package:rehearsallab/ui/common/rehearsal_card.dart';
import 'package:rehearsallab/ui/common/secondary_button.dart';
import 'package:rehearsallab/ui/common/section_header.dart';
import 'package:rehearsallab/ui/common/stage_badge.dart';
import 'package:rehearsallab/ui/common/state_summary.dart';

/// 통합 문서 7장: 폭 320 · 390 · 430, 글자 배율 1.0 · 1.3에서 공용 위젯이 넘치지 않고,
/// 조작 요소의 히트 영역이 48px 이상이어야 한다 (P0-REV-08 · P0-REV-10 · R5).
void main() {
  const widths = [320.0, 390.0, 430.0];
  const scales = [1.0, 1.3];

  /// 실제 화면처럼 좌우 20px 페이지 여백 안에 둔다 (BottomDock은 전체 폭).
  Widget host(
    Widget child, {
    required double width,
    required double scale,
    bool fullWidth = false,
  }) => MaterialApp(
    theme: AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 900),
        textScaler: TextScaler.linear(scale),
      ),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(
              child: Padding(
                padding: fullWidth
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  final samples = <String, Widget Function()>{
    'PrimaryButton': () =>
        PrimaryButton(label: '이 문장 치환하고 v3 저장', onPressed: () {}),
    'SecondaryButton': () =>
        SecondaryButton(label: '원고 수정하러 가기', onPressed: () {}),
    'AppChip': () => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AppChip(label: '학회 구두발표', selected: true, onTap: () {}),
        AppChip(label: '논문 심사(디펜스)', onTap: () {}),
        AppChip(label: '랩 세미나', onTap: () {}),
        AppChip(label: '수업·기타', onTap: () {}),
      ],
    ),
    'StageBadge': () =>
        const StageBadge(label: '재분석 필요', tone: BadgeTone.warning),
    'LabelTextField': () =>
        const LabelTextField(label: '제목', hintText: '○○학회 구두발표'),
    'SectionHeader': () =>
        const SectionHeader(title: '예상 소요 시간 vs 규격', action: '14:40 / 15:00'),
    'ActionCheckItem': () => ActionCheckItem(
      text: '방법 섹션의 알고리즘 세부 설명 3문장을 한 문장으로 요약',
      checked: false,
      onChanged: (_) {},
    ),
    'PresentationCard': () => PresentationCard(
      presentation: DemoData.presentations[1],
      today: DemoData.today,
      stageLabel: '분석 완료',
      stageTone: BadgeTone.success,
      matchTrend: const [0.74, 0.81, 0.87],
      onTap: () {},
    ),
    'DimensionCard': () => DimensionCard(
      feedback: DemoData.analysisV1.dimensions[2],
      expanded: true,
      onToggle: () {},
    ),
    'RehearsalCard': () => RehearsalCard(
      rehearsal: DemoData.rehearsal3,
      report: DemoData.report3,
      talkMinutes: 15,
      onTap: () {},
    ),
    'RehearsalCard partial': () => RehearsalCard(
      rehearsal: DemoData.rehearsal2.copyWith(
        scope: RehearsalScope.partial,
        capReached: true,
      ),
      report: DemoData.report2.copyWith(clearPrevMatchRate: true),
      talkMinutes: 25,
      onTap: () {},
    ),
    'DetailHeader': () => DetailHeader(
      presentation: DemoData.presentation,
      today: DemoData.today,
      versionLabel: 'v1 분석 · 현재 v2',
      badgeLabel: '재분석 필요',
      badgeTone: BadgeTone.warning,
      activeTab: DetailTab.script,
      onTabChanged: (_) {},
    ),
    'BottomActionBar': () => BottomActionBar(
      primary: PrimaryButton(label: '다시 리허설', onPressed: () {}),
      secondary: SecondaryButton(label: '원고 수정하러 가기', onPressed: () {}),
    ),
    'StateSummary': () => const StateSummary(
      aiState: StageState.failed,
      audioState: AudioState.deleted,
      transcriptState: TranscriptState.tempRetained,
      retryDeadlineLabel: '9월 10일 21:16',
    ),
  };

  group('공용 위젯 반응형 (R5)', () {
    for (final entry in samples.entries) {
      for (final width in widths) {
        for (final scale in scales) {
          testWidgets('${entry.key} @ ${width.toInt()}px × ${scale}x 넘침 없음', (
            tester,
          ) async {
            await tester.pumpWidget(
              host(entry.value(), width: width, scale: scale),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
          });
        }
      }
    }

    for (final width in widths) {
      for (final scale in scales) {
        testWidgets(
          'BottomDock(FAB 포함) 전체 폭 @ ${width.toInt()}px × ${scale}x',
          (tester) async {
            await tester.pumpWidget(
              host(
                BottomDock(
                  current: DockTab.home,
                  onTap: (_) {},
                  onFabTap: () {},
                ),
                width: width,
                scale: scale,
                fullWidth: true,
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });

  group('히트 영역 48px (R6 · P0-REV-08)', () {
    Size sizeOfInkWellContaining(WidgetTester tester, Finder textFinder) {
      final inkWell = find
          .ancestor(of: textFinder, matching: find.byType(InkWell))
          .first;
      return tester.getSize(inkWell);
    }

    testWidgets('AppChip 탭 영역 높이 ≥ 48', (tester) async {
      await tester.pumpWidget(
        host(AppChip(label: '학회 구두발표', onTap: () {}), width: 390, scale: 1.0),
      );
      expect(
        sizeOfInkWellContaining(tester, find.text('학회 구두발표')).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('DimensionCard 펼침 행 높이 ≥ 48', (tester) async {
      await tester.pumpWidget(
        host(
          DimensionCard(
            feedback: DemoData.analysisV1.dimensions[0],
            onToggle: () {},
          ),
          width: 390,
          scale: 1.0,
        ),
      );
      expect(
        sizeOfInkWellContaining(tester, find.text('문제점 · 제안 보기')).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('DetailHeader 탭 항목 높이 ≥ 48', (tester) async {
      await tester.pumpWidget(
        host(
          DetailHeader(
            presentation: DemoData.presentation,
            today: DemoData.today,
            badgeLabel: '분석 완료',
            badgeTone: BadgeTone.info,
            activeTab: DetailTab.script,
            onTabChanged: (_) {},
          ),
          width: 390,
          scale: 1.0,
        ),
      );
      expect(
        sizeOfInkWellContaining(tester, find.text('리허설')).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('ActionCheckItem 행 높이 ≥ 48, BottomDock 항목 ≥ 48', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          ActionCheckItem(text: '짧은 액션', checked: false, onChanged: (_) {}),
          width: 390,
          scale: 1.0,
        ),
      );
      expect(
        sizeOfInkWellContaining(tester, find.text('짧은 액션')).height,
        greaterThanOrEqualTo(48),
      );
      await tester.pumpWidget(
        host(
          BottomDock(current: DockTab.home, onTap: (_) {}),
          width: 390,
          scale: 1.0,
          fullWidth: true,
        ),
      );
      final item = sizeOfInkWellContaining(tester, find.text('설정'));
      expect(item.height, greaterThanOrEqualTo(48));
      expect(item.width, greaterThanOrEqualTo(48));
    });

    testWidgets('버튼 높이 56', (tester) async {
      await tester.pumpWidget(
        host(
          PrimaryButton(label: '저장', onPressed: () {}),
          width: 390,
          scale: 1.0,
        ),
      );
      expect(tester.getSize(find.byType(FilledButton)).height, 56);
    });
  });
}
