import 'dart:async';

import 'package:rehearsallab/core/models/result.dart';

/// 재생 위치 관찰값.
class PlaybackPosition {
  final Duration position;
  final Duration duration;
  final bool isPlaying;

  const PlaybackPosition({
    required this.position,
    required this.duration,
    required this.isPlaying,
  });
}

/// 구간 재생 (X1-6). 리포트 타임라인 · 문장 탭 → seek 후 재생.
/// 수명 규칙: 플레이어 세션은 서비스가 소유, dispose()로 닫는다 (계약서 3.6장).
/// 빠뜨린 문장(missed)은 녹음에 없으므로 인접 구간을 재생한다 (가짜 시각 생성 금지).
abstract class PlaybackService {
  Stream<PlaybackPosition> get positions;

  Future<Result<void>> load(String filePath);
  Future<Result<void>> seek(Duration position);
  Future<Result<void>> play();
  Future<Result<void>> pause();
  Future<void> dispose();
}

/// 타이머 기반 Mock. 오디오 없이 위치만 흐른다.
class MockPlaybackService implements PlaybackService {
  final StreamController<PlaybackPosition> _controller =
      StreamController<PlaybackPosition>.broadcast();
  final Duration duration;
  Timer? _timer;
  Duration _position = Duration.zero;
  bool _playing = false;
  bool _loaded = false;

  MockPlaybackService({this.duration = const Duration(seconds: 760)});

  @override
  Stream<PlaybackPosition> get positions => _controller.stream;

  void _emit() => _controller.add(
    PlaybackPosition(
      position: _position,
      duration: duration,
      isPlaying: _playing,
    ),
  );

  @override
  Future<Result<void>> load(String filePath) async {
    _loaded = true;
    _position = Duration.zero;
    _emit();
    return const Success(null);
  }

  @override
  Future<Result<void>> seek(Duration position) async {
    if (!_loaded) return Failure(Exception('재생할 녹음이 없습니다.'));
    _position = position > duration ? duration : position;
    _emit();
    return const Success(null);
  }

  @override
  Future<Result<void>> play() async {
    if (!_loaded) return Failure(Exception('재생할 녹음이 없습니다.'));
    _playing = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _position += const Duration(seconds: 1);
      if (_position >= duration) {
        _position = duration;
        _playing = false;
        _timer?.cancel();
      }
      _emit();
    });
    _emit();
    return const Success(null);
  }

  @override
  Future<Result<void>> pause() async {
    _playing = false;
    _timer?.cancel();
    _emit();
    return const Success(null);
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _controller.close();
  }
}
