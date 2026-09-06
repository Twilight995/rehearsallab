import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/enum/script_version_origin.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/script_version.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/services/rewrite_service.dart';

void main() {
  var counter = 0;
  final service = RewriteService(
    idGenerator: () => 'sv-${++counter}',
    now: () => DateTime(2026, 9, 6, 11),
  );

  group('리라이트 치환 (확정 1회 = 버전 +1)', () {
    test('정확 일치 원문 치환 → v+1, parent 연결, 원문 사라짐', () {
      final result = service.apply(
        current: DemoData.scriptV1,
        rewrite: DemoData.analysisV1.rewrites[1],
      );
      expect(result, isA<Success<ScriptVersion>>());
      final v2 = (result as Success<ScriptVersion>).value;
      expect(v2.version, 2);
      expect(v2.parentVersionId, DemoData.scriptV1.id);
      expect(v2.createdBy, ScriptVersionOrigin.rewrite);
      expect(v2.text.contains(DemoData.rewrite2Original), isFalse);
      expect(v2.text.contains(DemoData.rewrite2Replacement), isTrue);
      expect(v2.text, DemoData.scriptV2.text);
    });

    test('두 번 확정하면 v3 (배치 적용 없음)', () {
      final v2 =
          (service.apply(
                    current: DemoData.scriptV1,
                    rewrite: DemoData.analysisV1.rewrites[1],
                  )
                  as Success<ScriptVersion>)
              .value;
      final v3 =
          (service.apply(current: v2, rewrite: DemoData.analysisV1.rewrites[0])
                  as Success<ScriptVersion>)
              .value;
      expect(v3.version, 3);
      expect(v3.text, DemoData.scriptV3.text);
    });

    test('원문이 현재 원고와 다르면 치환하지 않고 Failure', () {
      final edited = DemoData.scriptV1.copyWith(text: '전혀 다른 원고입니다.');
      final result = service.apply(
        current: edited,
        rewrite: DemoData.analysisV1.rewrites[0],
      );
      expect(result, isA<Failure<ScriptVersion>>());
      expect(
        (result as Failure<ScriptVersion>).exception.toString(),
        contains('원문을 찾을 수 없어요'),
      );
    });
  });

  group('되돌리기 (과거 텍스트를 현재 version+1로 저장)', () {
    test('v3에서 v2 텍스트로 → v4', () {
      final result = service.revert(
        current: DemoData.scriptV3,
        target: DemoData.scriptV2,
      );
      final v4 = (result as Success<ScriptVersion>).value;
      expect(v4.version, 4);
      expect(v4.text, DemoData.scriptV2.text);
      expect(v4.parentVersionId, DemoData.scriptV3.id);
      expect(v4.createdBy, ScriptVersionOrigin.revert);
    });

    test('다른 발표의 버전으로는 되돌릴 수 없음', () {
      final other = DemoData.scriptV2.copyWith(presentationId: 'other');
      expect(
        service.revert(current: DemoData.scriptV3, target: other),
        isA<Failure<ScriptVersion>>(),
      );
    });
  });
}
