import 'package:rehearsallab/app/app_config.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/script_analysis.dart';

/// 원고 섹션. `## 이름` 줄로 나뉜다. 섹션 표시가 없으면 이름은 "전체".
class ScriptSection {
  final String name;
  final String body;

  const ScriptSection({required this.name, required this.body});
}

/// 코드가 즉시 계산하는 원고 정보 (기획서 §5.1 상태 B).
class ScriptEstimate {
  final int wordCount;
  final int totalSeconds;
  final List<SectionEstimate> sections;

  const ScriptEstimate({
    required this.wordCount,
    required this.totalSeconds,
    required this.sections,
  });

  /// 규격 대비 초과(+) · 여유(-) 초
  int deltaSeconds(int talkMinutes) => totalSeconds - talkMinutes * 60;
}

/// 어절 수 · 섹션 분리 · 예상 시간. 순수 동기 계산, `Result<T>` 반환.
class ScriptEstimateService {
  static final RegExp _sectionLine = RegExp(
    r'^##\s*(.+?)\s*$',
    multiLine: true,
  );
  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _sentenceEnd = RegExp(r'(?<=[.!?。])\s+|(?<=다\.)\s*|\n+');

  /// 어절 = 공백으로 나뉜 토큰 수 (한국어 관습)
  int countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(_whitespace).where((w) => w.isNotEmpty).length;
  }

  /// `## 섹션 이름` 기준 분리. 없으면 전체 하나.
  List<ScriptSection> splitSections(String text) {
    final matches = _sectionLine.allMatches(text).toList();
    if (matches.isEmpty) {
      return [ScriptSection(name: '전체', body: text.trim())];
    }
    final sections = <ScriptSection>[];
    final preamble = text.substring(0, matches.first.start).trim();
    if (preamble.isNotEmpty) {
      sections.add(ScriptSection(name: '도입', body: preamble));
    }
    for (var i = 0; i < matches.length; i++) {
      final start = matches[i].end;
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      sections.add(
        ScriptSection(
          name: matches[i].group(1)!.trim(),
          body: text.substring(start, end).trim(),
        ),
      );
    }
    return sections;
  }

  /// 문장 단위 분리 (원고 대조 · 텔레프롬프터용). 섹션 제목 줄은 제외.
  List<String> splitSentences(String text) {
    final withoutHeaders = text.replaceAll(_sectionLine, '\n');
    return withoutHeaders
        .split(_sentenceEnd)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// 평균 속도(어절/분)로 읽었을 때의 예상 시간.
  Result<ScriptEstimate> estimate(
    String text, {
    int wordsPerMinute = AppConfig.averageWordsPerMinute,
  }) {
    if (wordsPerMinute <= 0) {
      return Failure(Exception('평균 속도는 0보다 커야 합니다.'));
    }
    final sections = splitSections(text);
    final sectionEstimates = sections
        .map(
          (s) => SectionEstimate(
            name: s.name,
            seconds: _secondsFor(countWords(s.body), wordsPerMinute),
          ),
        )
        .toList();
    final wordCount = countWords(text.replaceAll(_sectionLine, ' '));
    return Success(
      ScriptEstimate(
        wordCount: wordCount,
        totalSeconds: sectionEstimates.fold(0, (s, e) => s + e.seconds),
        sections: sectionEstimates,
      ),
    );
  }

  int _secondsFor(int words, int wordsPerMinute) =>
      (words * 60 / wordsPerMinute).round();
}
