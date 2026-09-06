import 'dart:async';

import 'package:rehearsallab/app/app_config.dart';
import 'package:rehearsallab/core/models/result.dart';

/// 녹음 진행 관찰값. elapsed는 **활성 구간만 누적한 실제 녹음 시간**이며
/// 카운트다운 · 일시정지 · 확인 대기를 제외한다. 표시용 틱과 별개로 상한은 단조 시계로 판정한다.
class RecorderTick {
  final Duration elapsed;
  final bool isPaused;

  /// 20:00 상한 도달 (정확히 1회만 true로 전달되고 그 뒤 자동 정지)
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

  /// 활성 구간 누적 초 (일시정지 제외)
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
/// 상한 규칙 (통합 문서 9장 합의):
/// - 누적은 **활성 구간의 단조 시간**으로 계산한다. 일시정지 · 확인 대기 중에는 늘지 않는다.
/// - 누적이 cap에 도달하면 capReached=true 틱을 정확히 1회 보내고 자동 정지한다. 이후 resume 불가.
/// - 재개 · 텔레프롬프터 토글로 누적을 초기화하지 않는다.
/// - 표시용 틱(tickInterval)은 누적 계산에 쓰지 않는다.
abstract class RecorderService {
  Stream<RecorderTick> get ticks;

  /// 현재 활성 누적 시간 (일시정지 제외)
  Duration get elapsed;

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

/// 단조 시계 기반 Mock. 실제 마이크를 쓰지 않는다. mock 모드 전체 루프와 상한 규칙 테스트용.
/// `clock`은 단조 증가하는 경과 시간을 돌려주는 함수(기본 Stopwatch). 테스트는 fake clock을 주입한다.
class MockRecorderService implements RecorderService {
  final StreamController<RecorderTick> _controller =
      StreamController<RecorderTick>.broadcast();
  final Duration tickInterval;
  final Duration Function() _clock;

  Timer? _tickTimer;
  Timer? _capTimer;

  /// 이전 활성 구간들의 누적
  Duration _accumulated = Duration.zero;

  /// 현재 활성 구간 시작 시각 (일시정지 중이면 null)
  Duration? _activeSince;
  Duration _cap = const Duration(minutes: AppConfig.recordingCapMinutes);
  bool _capReached = false;
  bool _active = false;
  int _amplitudeSeed = 0;

  MockRecorderService({
    this.tickInterval = const Duration(seconds: 1),
    Duration Function()? clock,
  }) : _clock = clock ?? _defaultClock();

  static Duration Function() _defaultClock() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }

  @override
  Stream<RecorderTick> get ticks => _controller.stream;

  @override
  Duration get elapsed {
    final since = _activeSince;
    if (since == null) return _accumulated;
    final total = _accumulated + (_clock() - since);
    return total > _cap ? _cap : total;
  }

  bool get isPaused => _active && _activeSince == null;
  bool get capReached => _capReached;

  @override
  Future<Result<void>> start({
    Duration cap = const Duration(minutes: AppConfig.recordingCapMinutes),
  }) async {
    if (_active) return Failure(Exception('이미 녹음 중입니다.'));
    _cap = cap;
    _accumulated = Duration.zero;
    _capReached = false;
    _active = true;
    _beginActiveSegment();
    return const Success(null);
  }

  void _beginActiveSegment() {
    _activeSince = _clock();
    final remaining = _cap - _accumulated;
    _capTimer?.cancel();
    _capTimer = Timer(remaining, _onCapReached);
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(tickInterval, (_) => _emitTick());
  }

  void _endActiveSegment() {
    final since = _activeSince;
    if (since != null) {
      _accumulated += _clock() - since;
      if (_accumulated > _cap) _accumulated = _cap;
      _activeSince = null;
    }
    _capTimer?.cancel();
    _tickTimer?.cancel();
  }

  void _emitTick() {
    if (!_active || _activeSince == null || _capReached) return;
    _amplitudeSeed = (_amplitudeSeed + 7) % 23;
    _controller.add(
      RecorderTick(
        elapsed: elapsed,
        amplitude: 0.2 + _amplitudeSeed / 23 * 0.8,
      ),
    );
  }

  void _onCapReached() {
    if (!_active || _capReached) return;
    _endActiveSegment();
    _accumulated = _cap;
    _capReached = true;
    _controller.add(RecorderTick(elapsed: _cap, capReached: true));
  }

  @override
  Future<Result<void>> pause() async {
    if (!_active) return Failure(Exception('녹음 중이 아닙니다.'));
    if (_capReached) return Failure(Exception('이미 자동 종료됐습니다.'));
    if (_activeSince == null) return const Success(null);
    _endActiveSegment();
    _controller.add(RecorderTick(elapsed: _accumulated, isPaused: true));
    return const Success(null);
  }

  @override
  Future<Result<void>> resume() async {
    if (!_active) return Failure(Exception('녹음 중이 아닙니다.'));
    if (_capReached) {
      return Failure(Exception('20분 상한에 도달해 재개할 수 없습니다.'));
    }
    if (_activeSince != null) return const Success(null);
    _beginActiveSegment();
    return const Success(null);
  }

  @override
  Future<Result<RecordingResult>> stop() async {
    if (!_active) return Failure(Exception('녹음 중이 아닙니다.'));
    _endActiveSegment();
    _active = false;
    return Success(
      RecordingResult(
        filePath:
            'mock://recording-${DateTime.now().millisecondsSinceEpoch}.m4a',
        durationSec: _accumulated.inSeconds,
        capReached: _capReached,
      ),
    );
  }

  @override
  Future<Result<void>> discard() async {
    _endActiveSegment();
    _active = false;
    _accumulated = Duration.zero;
    _capReached = false;
    return const Success(null);
  }

  @override
  Future<void> dispose() async {
    _capTimer?.cancel();
    _tickTimer?.cancel();
    await _controller.close();
  }
}
