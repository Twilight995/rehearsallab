import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/services/script_estimate_service.dart';

void main() {
  final service = ScriptEstimateService();

  group('어절 수 · 섹션 분리', () {
    test('## 5섹션 분리', () {
      final sections = service.splitSections(DemoData.scriptV1Text);
      expect(sections.map((s) => s.name), ['배경', '문제', '방법', '결과', '기여']);
      expect(sections.every((s) => s.body.isNotEmpty), isTrue);
    });

    test('섹션 표시가 없으면 전체 하나', () {
      final sections = service.splitSections('첫 문장입니다. 둘째 문장입니다.');
      expect(sections.length, 1);
      expect(sections.first.name, '전체');
    });

    test('어절 = 공백 토큰 수', () {
      expect(service.countWords('안녕하세요  발표를   시작하겠습니다.'), 3);
      expect(service.countWords(''), 0);
      expect(service.countWords('   '), 0);
    });

    test('문장 분리는 섹션 제목을 제외한다', () {
      final sentences = service.splitSentences(
        '## 배경\n첫 문장입니다. 둘째 문장입니다.\n## 방법\n셋째 문장입니다.',
      );
      expect(sentences, ['첫 문장입니다.', '둘째 문장입니다.', '셋째 문장입니다.']);
    });
  });

  group('예상 시간 계산', () {
    test('2,100어절 → 약 15:30 (평균 135어절/분)', () {
      final text = List.filled(2100, '어절').join(' ');
      final result = service.estimate(text);
      expect(result, isA<Success<ScriptEstimate>>());
      final est = (result as Success<ScriptEstimate>).value;
      expect(est.wordCount, 2100);
      expect(est.totalSeconds, inInclusiveRange(925, 940)); // 15:25 ~ 15:40
      expect(est.deltaSeconds(15), greaterThan(0)); // 규격 초과
    });

    test('섹션별 합 = 전체', () {
      final est =
          (service.estimate(DemoData.scriptV1Text) as Success<ScriptEstimate>)
              .value;
      expect(est.sections.length, 5);
      expect(est.sections.fold(0, (s, e) => s + e.seconds), est.totalSeconds);
    });

    test('속도 0이면 Failure', () {
      expect(
        service.estimate('원고', wordsPerMinute: 0),
        isA<Failure<ScriptEstimate>>(),
      );
    });
  });
}
