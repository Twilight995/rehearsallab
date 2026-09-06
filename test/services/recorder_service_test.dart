import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/services/recorder_service.dart';

/// fake 단조 시계: 테스트가 now를 직접 올리고 같은 양만큼 FakeAsync를 진행시킨다.
class _Clock {
  Duration now = Duration.zero;

  void advance(FakeAsync async, Duration d) {
    now += d;
    async.elapse(d);
  }
}

void main() {
  const cap = Duration(minutes: 20);

  group('MockRecorderService 20분 상한 (활성 구간 단조 누적, P0-REV-01)', () {
    test(
      '일시정지 없이 19:59 → 20:00에서 capReached 1회, 이후 resume 불가, stop은 1200초',
      () {
        fakeAsync((async) {
          final clock = _Clock();
          final recorder = MockRecorderService(clock: () => clock.now);
          final capTicks = <RecorderTick>[];
          recorder.ticks.listen((t) {
            if (t.capReached) capTicks.add(t);
          });
          recorder.start(cap: cap);
          clock.advance(async, const Duration(minutes: 19, seconds: 59));
          expect(capTicks, isEmpty);
          expect(recorder.elapsed, const Duration(minutes: 19, seconds: 59));
          clock.advance(async, const Duration(seconds: 1));
          expect(capTicks.length, 1);
          clock.advance(async, const Duration(seconds: 30));
          expect(capTicks.length, 1, reason: '상한 이벤트는 정확히 1회');
          expect(recorder.elapsed, cap);
          Result<void>? resumed;
          recorder.resume().then((r) => resumed = r);
          async.flushMicrotasks();
          expect(resumed, isA<Failure<void>>());
          RecordingResult? result;
          recorder.stop().then(
            (r) => result = (r as Success<RecordingResult>).value,
          );
          async.flushMicrotasks();
          expect(result!.durationSec, 1200);
          expect(result!.capReached, isTrue);
          recorder.dispose();
        });
      },
    );

    test('19:59.1 → pause 0.8s → resume 0.1s: 활성 누적 1199.2초, 상한 미도달', () {
      fakeAsync((async) {
        final clock = _Clock();
        final recorder = MockRecorderService(clock: () => clock.now);
        final capTicks = <RecorderTick>[];
        recorder.ticks.listen((t) {
          if (t.capReached) capTicks.add(t);
        });
        recorder.start(cap: cap);
        clock.advance(async, const Duration(milliseconds: 1199100));
        recorder.pause();
        async.flushMicrotasks();
        clock.advance(async, const Duration(milliseconds: 800));
        expect(
          recorder.elapsed,
          const Duration(milliseconds: 1199100),
          reason: '일시정지 중 누적 정지',
        );
        recorder.resume();
        async.flushMicrotasks();
        clock.advance(async, const Duration(milliseconds: 100));
        expect(recorder.elapsed, const Duration(milliseconds: 1199200));
        expect(capTicks, isEmpty, reason: '실제 활성 시간 1199.2초 < 1200초');
        clock.advance(async, const Duration(milliseconds: 800));
        expect(capTicks.length, 1, reason: '활성 누적이 정확히 1200초가 되는 순간 1회');
        expect(recorder.elapsed, cap);
        recorder.dispose();
      });
    });

    test('초 중간 pause/resume 반복 · 확인 대기(pause) 시간은 누적에서 제외', () {
      fakeAsync((async) {
        final clock = _Clock();
        final recorder = MockRecorderService(clock: () => clock.now);
        recorder.ticks.listen((_) {});
        recorder.start(cap: cap);
        clock.advance(async, const Duration(milliseconds: 2500));
        recorder.pause();
        async.flushMicrotasks();
        clock.advance(async, const Duration(seconds: 5)); // 종료 확인 대기
        recorder.resume();
        async.flushMicrotasks();
        clock.advance(async, const Duration(milliseconds: 1700));
        recorder.pause();
        async.flushMicrotasks();
        clock.advance(async, const Duration(seconds: 3));
        recorder.resume();
        async.flushMicrotasks();
        clock.advance(async, const Duration(milliseconds: 800));
        expect(
          recorder.elapsed,
          const Duration(seconds: 5),
          reason: '2.5 + 1.7 + 0.8',
        );
        RecordingResult? result;
        recorder.stop().then(
          (r) => result = (r as Success<RecordingResult>).value,
        );
        async.flushMicrotasks();
        expect(result!.durationSec, 5);
        expect(result!.capReached, isFalse);
        recorder.dispose();
      });
    });

    test('일시정지 틱은 isPaused=true 1회, 표시 틱 간격은 누적 계산에 영향 없음', () {
      fakeAsync((async) {
        final clock = _Clock();
        final recorder = MockRecorderService(
          clock: () => clock.now,
          tickInterval: const Duration(milliseconds: 700),
        );
        final ticks = <RecorderTick>[];
        recorder.ticks.listen(ticks.add);
        recorder.start(cap: cap);
        clock.advance(async, const Duration(seconds: 3));
        recorder.pause();
        async.flushMicrotasks();
        expect(ticks.where((t) => t.isPaused).length, 1);
        expect(
          recorder.elapsed,
          const Duration(seconds: 3),
          reason: '0.7초 틱 간격과 무관하게 정확히 3초',
        );
        recorder.discard();
        async.flushMicrotasks();
        expect(recorder.elapsed, Duration.zero);
        recorder.dispose();
      });
    });
  });
}
