import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/core/enum/audio_state.dart';
import 'package:rehearsallab/core/enum/badge_tone.dart';
import 'package:rehearsallab/core/enum/stage_state.dart';
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

Widget wrap(Widget child, {double width = 390}) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        child: SingleChildScrollView(child: child),
      ),
    ),
  ),
);

void main() {
  setUpAll(() {
    // google_fonts 네트워크 호출 없이 fallback 폰트 사용
  });

  group('공용 위젯 렌더 · 콜백', () {
    testWidgets('PrimaryButton · SecondaryButton 탭', (tester) async {
      var primary = 0;
      var secondary = 0;
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              PrimaryButton(label: '리허설 시작', onPressed: () => primary++),
              SecondaryButton(label: '편집', onPressed: () => secondary++),
            ],
          ),
        ),
      );
      await tester.tap(find.text('리허설 시작'));
      await tester.tap(find.text('편집'));
      expect(primary, 1);
      expect(secondary, 1);
    });

    testWidgets('AppChip 선택 상태 · StageBadge 텍스트', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              AppChip(
                label: '학회 구두발표',
                selected: true,
                onTap: () => tapped = true,
              ),
              const StageBadge(label: '재분석 필요', tone: BadgeTone.warning),
            ],
          ),
        ),
      );
      await tester.tap(find.text('학회 구두발표'));
      expect(tapped, isTrue);
      expect(find.text('재분석 필요'), findsOneWidget);
    });

    testWidgets('LabelTextField 입력 · SectionHeader', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              LabelTextField(
                label: '제목',
                controller: controller,
                hintText: '○○학회 구두발표',
              ),
              const SectionHeader(title: '내 발표', action: 'D-day 순'),
            ],
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '석사 논문 심사');
      expect(controller.text, '석사 논문 심사');
      expect(find.text('D-day 순'), findsOneWidget);
    });

    testWidgets('BottomDock 탭 라벨과 FAB', (tester) async {
      DockTab? selected;
      var fab = 0;
      await tester.pumpWidget(
        wrap(
          BottomDock(
            current: DockTab.home,
            onTap: (t) => selected = t,
            onFabTap: () => fab++,
          ),
        ),
      );
      expect(find.text('홈'), findsOneWidget);
      expect(find.text('발표'), findsOneWidget);
      expect(find.text('설정'), findsOneWidget);
      await tester.tap(find.text('설정'));
      expect(selected, DockTab.settings);
      await tester.tap(
        find.byIcon(Icons.add).evaluate().isEmpty
            ? find.byType(InkWell).last
            : find.byIcon(Icons.add),
      );
      expect(fab, 1);
    });

    testWidgets('ActionCheckItem 행 전체 탭', (tester) async {
      bool? value;
      await tester.pumpWidget(
        wrap(
          ActionCheckItem(
            text: '결과 섹션에서 속도를 낮추기',
            checked: false,
            onChanged: (v) => value = v,
          ),
        ),
      );
      await tester.tap(find.text('결과 섹션에서 속도를 낮추기'));
      expect(value, isTrue);
    });

    testWidgets('PresentationCard 날짜 미정 · D-day', (tester) async {
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              PresentationCard(
                presentation: DemoData.presentations[0],
                today: DemoData.today,
                stageLabel: '리허설 2회',
                stageTone: BadgeTone.info,
                matchTrend: const [0.74, 0.81, 0.87],
              ),
              PresentationCard(
                presentation: DemoData.presentations[2],
                today: DemoData.today,
                stageLabel: '원고 없음',
                stageTone: BadgeTone.neutral,
              ),
            ],
          ),
        ),
      );
      expect(find.text('D-3'), findsOneWidget);
      expect(find.text('날짜 미정'), findsOneWidget);
      expect(find.text('15분 + Q&A 5분'), findsOneWidget);
    });

    testWidgets('DimensionCard 펼침 시 문제점 · 제안', (tester) async {
      var toggled = 0;
      await tester.pumpWidget(
        wrap(
          DimensionCard(
            feedback: DemoData.analysisV1.dimensions[0],
            expanded: true,
            onToggle: () => toggled++,
          ),
        ),
      );
      expect(find.text('문제점'), findsOneWidget);
      expect(find.text('제안'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      await tester.tap(find.text('접기'));
      expect(toggled, 1);
    });

    testWidgets('RehearsalCard 종합 점수 없음 · 전 회차 대비 · 첫 회차', (tester) async {
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              RehearsalCard(
                rehearsal: DemoData.rehearsal3,
                report: DemoData.report3,
                talkMinutes: 15,
              ),
              RehearsalCard(
                rehearsal: DemoData.rehearsal1,
                report: DemoData.report1,
                talkMinutes: 15,
              ),
            ],
          ),
        ),
      );
      expect(find.text('+6%p'), findsOneWidget);
      expect(find.text('전 회차 대비'), findsOneWidget);
      expect(find.text('첫 회차'), findsOneWidget);
      expect(find.textContaining('3.8'), findsNothing);
    });

    testWidgets('DetailHeader 320px에서 배지가 제목 행에 있고 탭 4개', (tester) async {
      DetailTab? tab;
      await tester.pumpWidget(
        wrap(
          DetailHeader(
            presentation: DemoData.presentation,
            today: DemoData.today,
            versionLabel: 'v1 분석 · 현재 v2',
            badgeLabel: '분석 완료',
            badgeTone: BadgeTone.info,
            activeTab: DetailTab.script,
            onTabChanged: (t) => tab = t,
          ),
          width: 320,
        ),
      );
      expect(find.text('분석 완료'), findsOneWidget);
      expect(find.text('원고'), findsOneWidget);
      expect(find.text('이력'), findsOneWidget);
      await tester.tap(find.text('리허설'));
      expect(tab, DetailTab.rehearsal);
      expect(tester.takeException(), isNull);
    });

    testWidgets('BottomActionBar · StateSummary', (tester) async {
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              BottomActionBar(
                primary: PrimaryButton(label: '다시 리허설', onPressed: () {}),
                secondary: SecondaryButton(
                  label: '원고 수정하러 가기',
                  onPressed: () {},
                ),
              ),
              const StateSummary(
                aiState: StageState.failed,
                audioState: AudioState.stored,
                audioDateLabel: '9월 16일 21:14',
                retryDeadlineLabel: '9월 10일 21:14',
              ),
            ],
          ),
          width: 320,
        ),
      );
      expect(find.text('다시 리허설'), findsOneWidget);
      expect(find.textContaining('AI 해석: 실패'), findsOneWidget);
      expect(find.textContaining('녹음: 보관 중'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
