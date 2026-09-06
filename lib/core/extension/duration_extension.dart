extension DurationExtension on Duration {
  /// 12:40 형식 (시간 단위는 쓰지 않음. 녹음 상한 20분)
  String get mmss {
    final minutes = inMinutes;
    final seconds = inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 4:12 형식 (앞자리 0 없음. 타임라인 · 미니플레이어)
  String get mss {
    final minutes = inMinutes;
    final seconds = inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// "2분 20초" 형식 (남은 시간 · 초과 시간 안내)
  String get korean {
    final minutes = inMinutes;
    final seconds = inSeconds.remainder(60);
    if (minutes == 0) return '$seconds초';
    if (seconds == 0) return '$minutes분';
    return '$minutes분 $seconds초';
  }
}

extension SecondsExtension on int {
  Duration get seconds => Duration(seconds: this);
  Duration get minutes => Duration(minutes: this);
}
