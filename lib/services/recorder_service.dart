import 'dart:async';

import 'package:rehearsallab/app/app_config.dart';
import 'package:rehearsallab/core/models/result.dart';

/// 녹음 진행 관찰값. 누적 시간은 카운트다운 · 일시정지 · 확인 대기를 제외한다.
class RecorderTick {
  final Duration elapsed;
  final bool isPaused;

  /// 20:00 상한 도달 (이 틱 이후 자동 종료)
  final bool capReached;

  /// 0.0 ~ 1.0 (파형 표시용)
  final double amplitude;

  const RecorderTick({
    required this.elapsed,
    this.isPaused = false,
    this.capReached = false,
    this.amplitude = 0,
  });
}

/// 녹음 종료 결과.
class RecordingResult {
  final String filePath;
  final int durationSec;
  final bool capReached;

  const RecordingResult({
    required this.filePath,
    required this.durationSec,
    required this.capReached,
  });
}

/// 마이크 녹음 (X1-2). 화면 14 · 15 · 16 · 27 · 28 · 29.
///
/// 수명 규칙 (계약서 3.6장): OS 오디오 세션과 스트림 구독은 **이 서비스가 소유**하고
/// dispose()로 닫는다. Notifier는 RecordingState 등 업무 상태만 소유하며
/// ref.onDispose에서 dispose()를 호출한다. 녹음 중 invalidateSelf()로 재생성하지 않는다.
///
/// 상한: 누적 녹음 시간이 cap에 도달하면 capReached=true 틱을 1회 보내고 자동 정지한다.
/// 재개 · 텔레프롬프터 토글로 누적을 초기화하지 않는다.
abstract class RecorderService {
  Stream<RecorderTick> get ticks;

  Future<Result<void>> start({
    Duration cap = const Duration(minutes: AppConfig.recordingCapMinutes),
  });
  Future<Result<void>> pause();
  Future<Result<void>> resume();

  /// 확정 종료. 파일 경로와 누적 시간을 돌려준다.
  Future<Result<RecordingResult>> stop();

  /// 파일을 버린다 (28번 확정 시).
  Future<Result<void>> discard();

  Future<void> dispose();
}

/// 타이머 기반 Mock. 실제 마이크를 쓰지 않는다. mock 모드 전체 루프용.
class MockRecorderService implements RecorderService {
  final StreamController<RecorderTick> _controller =
      StreamController<RecorderTick>.broadcast();
  final Duration tickInterval;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  Duration _cap = const Duration(minutes: AppConfig.recordingCapMinutes);
  bool _paused = false;
  bool _capReached = false;
  bool _active = false;
  int _amplitudeSeed = 0;

  MockRecorderService({this.tickInterval = const Duration(seconds: 1)});

  @override
  Stream<RecorderTick> get ticks => _controller.stream;

  Duration get elapsed => _elapsed;

  @override
  Future<Result<void>> start({
    Duration cap = const Duration(minutes: AppConfig.recordingCapMinutes),
  }) async {
    if (_active) return Failure(Exception('이미 녹음 중입니다.'));
    _cap = cap;
    _elapsed = Duration.zero;
    _paused = false;
    _capReached = false;
    _active = true;
    _timer = Timer.periodic(tickInterval, (_) => _onTick());
    return const Success(null);
  }

  void _onTick() {
    if (!_active || _paused || _capReached) return;
    _elapsed += tickInterval;
    _amplitudeSeed = (_amplitudeSeed + 7) % 23;
    if (_elapsed >= _cap) {
      _elapsed = _cap;
      _capReached = true;
      _timer?.cancel();
    }
    _controller.add(
      RecorderTick(
        elapsed: _elapsed,
        capReached: _capReached,
        amplitude: 0.2 + _amplitudeSeed / 23 * 0.8,
      ),
    );
  }

  @override
  Future<Result<void>> pause() async {
    if (!_active) return Failure(Exception('녹음 중이 아닙니다.'));
    _paused = true;
    _controller.add(RecorderTick(elapsed: _elapsed, isPaused: true));
    return const Success(null);
  }

  @override
  Future<Result<void>> resume() async {
    if (!_active) return Failure(Exception('녹음 중이 아닙니다.'));
    if (_capReached) return Failure(Exception('20분 상한에 도달해 재개할 수 없습니다.'));
    _paused = false;
    return const Success(null);
  }

  @override
  Future<Result<RecordingResult>> stop() async {
    if (!_active) return Failure(Exception('녹음 중이 아닙니다.'));
    _timer?.cancel();
    _active = false;
    return Success(
      RecordingResult(
        filePath:
            'mock://recording-${DateTime.now().millisecondsSinceEpoch}.m4a',
        durationSec: _elapsed.inSeconds,
        capReached: _capReached,
      ),
    );
  }

  @override
  Future<Result<void>> discard() async {
    _timer?.cancel();
    _active = false;
    _elapsed = Duration.zero;
    return const Success(null);
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _controller.close();
  }
}
