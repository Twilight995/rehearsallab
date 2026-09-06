import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/services/recorder_service.dart';

void main() {
  group('MockRecorderService 상한 · 일시정지', () {
    test('누적이 cap에 도달하면 capReached 틱 1회 후 정지, 재개 불가', () {
      fakeAsync((async) {
        final recorder = MockRecorderService(
          tickInterval: const Duration(seconds: 1),
        );
        final ticks = <RecorderTick>[];
        recorder.ticks.listen(ticks.add);
        recorder.start(cap: const Duration(seconds: 5));
        async.elapse(const Duration(seconds: 8));
        final capTicks = ticks.where((t) => t.capReached).toList();
        expect(capTicks.length, 1);
        expect(recorder.elapsed, const Duration(seconds: 5));
        Result<void>? resumed;
        recorder.resume().then((r) => resumed = r);
        async.flushMicrotasks();
        expect(resumed, isA<Failure<void>>());
        recorder.dispose();
      });
    });

    test('일시정지 중에는 누적이 늘지 않고 재개 후 이어진다', () {
      fakeAsync((async) {
        final recorder = MockRecorderService(
          tickInterval: const Duration(seconds: 1),
        );
        recorder.ticks.listen((_) {});
        recorder.start(cap: const Duration(minutes: 20));
        async.elapse(const Duration(seconds: 3));
        recorder.pause();
        async.elapse(const Duration(seconds: 5));
        expect(recorder.elapsed, const Duration(seconds: 3));
        recorder.resume();
        async.elapse(const Duration(seconds: 2));
        expect(recorder.elapsed, const Duration(seconds: 5));
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
  });
}
