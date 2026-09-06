import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/enum/dimension_key.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';

/// 통합 문서 8장 데모 데이터 일관성 (P0-REV-07). 그래프 · 근거 문구 · 요약값이 같은 원본에서 나와야 한다.
void main() {
  group('데모 지표 일관성', () {
    test('WPM 시계열 32점 · 평균 142', () {
      expect(DemoData.metrics3.wpmSeries.length, 32);
      expect(DemoData.metrics3.averageWpm, 142);
    });

    test('181 WPM 지점이 결과 섹션(08:40–11:30) 안에 정확히 존재하고 선택 지점과 같다', () {
      final peak = DemoData.metrics3.wpmSeries
          .where((p) => p.wpm == 181)
          .toList();
      expect(peak.length, 1);
      expect(peak.first.timeSec, inInclusiveRange(520, 690));
      expect(peak.first.timeSec, DemoData.selectedWpmTimeSec);
      expect(DemoData.metrics3.wpmSeries[DemoData.selectedWpmIndex].wpm, 181);
      final max = DemoData.metrics3.wpmSeries
          .map((p) => p.wpm)
          .reduce((a, b) => a > b ? a : b);
      expect(max, 181);
    });

    test('전달력 근거 문구가 인용하는 181과 필러 집중 구간이 지표와 일치한다', () {
      final delivery = DemoData.aiFeedback3.dimensions.firstWhere(
        (d) => d.key == DimensionKey.delivery,
      );
      expect(delivery.evidenceQuote, contains('181'));
      expect(delivery.evidenceQuote, contains('필러 7회 중 5회'));
      final fillersInResult = DemoData.metrics3.fillers
          .where((f) => f.timeSec >= 520 && f.timeSec < 690)
          .length;
      expect(DemoData.metrics3.fillers.length, 7);
      expect(fillersInResult, 5);
    });

    test('섹션 시간 합 = 총 시간 12:40 · 경계 02:00 / 03:30 / 08:40 / 11:30', () {
      expect(DemoData.metrics3.totalSec, 760);
      expect(DemoData.rehearsal3.durationSec, 760);
      final starts = DemoData.metrics3.sectionTimes
          .map((s) => s.startSec)
          .toList();
      expect(starts, [0, 120, 210, 520, 690]);
      expect(DemoData.metrics3.silences.length, 2);
    });

    test('회차 일치율 74% → 81% → 87%, 전 회차 대비 +6%p', () {
      expect(DemoData.report1.prevMatchRate, isNull);
      expect(DemoData.report2.matchRateDeltaPp, closeTo(7, 0.01));
      expect(DemoData.report3.matchRateDeltaPp, closeTo(6, 0.01));
    });

    test('원고 버전 v1 → v2 → v3 텍스트가 리라이트 치환 결과와 같다', () {
      expect(
        DemoData.scriptV2.text.contains(DemoData.rewrite2Replacement),
        isTrue,
      );
      expect(
        DemoData.scriptV3.text.contains(DemoData.rewrite1Replacement),
        isTrue,
      );
      expect(
        DemoData.scriptV3.text.contains(DemoData.rewrite1Original),
        isFalse,
      );
    });
  });
}
