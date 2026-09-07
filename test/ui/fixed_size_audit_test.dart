import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 고정 크기 감사 — **보조 휴리스틱**이다 (계약서 8장 · C1-REV 감사 규칙 의견 반영).
///
/// 최종 근거는 실제 viewport(320 · 390 · 430 · 태블릿 1024 · 가로) · 큰 글자 · 키보드 위젯 테스트이고,
/// 이 검사는 화면 폭을 고정했을 가능성이 있는 **큰 리터럴**을 리뷰 전에 알려 줄 뿐이다.
/// - 잡는 것: `width: ≥100`, `height: ≥200`, `Size(w, h)` · `Size.square` · `Size.fromWidth/Height`의
///   세 자리 인자(어느 자리든), 줄바꿈된 인자
/// - 잡지 않는 것: `maxWidth`(작은 폭에 맞춰 줄어드는 상한 제약) · `minWidth`(의도적 미검출 — 하한 제약은 리뷰에서 확인), 아이콘 · 점 · 구분선 ·
///   버튼 높이 같은 작은 값, 상수 · 변수 · 계산식(→ 위젯 테스트가 담당)
/// - 예외: 같은 줄이나 바로 윗줄의 **주석** 안에 `fixed-size: <비어 있지 않은 이유>`. 문자열 속 marker는 무시.
void main() {
  const widthLimit = 100.0;
  const heightLimit = 200.0;

  test('lib/ui에 화면 폭을 고정한 큰 리터럴이 없다 (예외는 // fixed-size: <이유>)', () {
    final dir = Directory('lib/ui');
    expect(dir.existsSync(), isTrue, reason: '프로젝트 루트에서 실행해야 한다');

    final findings = <String>[];
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      for (final hit in FixedSizeAudit.scan(
        file.readAsStringSync(),
        widthLimit: widthLimit,
        heightLimit: heightLimit,
      )) {
        final path = file.path.replaceAll(r'\', '/');
        findings.add('$path:${hit.line}  ${hit.text}');
      }
    }

    expect(
      findings,
      isEmpty,
      reason:
          '고정 크기 발견. Expanded · stretch · FractionallySizedBox · maxWidth로 바꾸거나, '
          '정당한 고정값이면 같은 줄 또는 윗줄 주석에 "fixed-size: <이유>"를 적는다.\n'
          '${findings.join('\n')}',
    );
  });

  group('감사 규칙 자체 검증 (오탐 · 누락 fixture)', () {
    List<String> hits(String source) => FixedSizeAudit.scan(
      source,
      widthLimit: widthLimit,
      heightLimit: heightLimit,
    ).map((h) => h.text).toList();

    test('잡아야 하는 것', () {
      expect(hits('SizedBox(width: 350, child: card)'), ['width: 350']);
      expect(hits('Container(height: 844)'), ['height: 844']);
      expect(hits('const Size(390, 844)'), ['Size(390, 844)']);
      expect(hits('const Size(80, 900)'), ['Size(80, 900)'], reason: '두 번째 인자');
      expect(hits('Size.fromHeight(600)'), ['Size.fromHeight(600)']);
      expect(hits('Size.square(400)'), ['Size.square(400)']);
      expect(hits('SizedBox(\n  width:\n      350,\n)'), [
        'width:\n      350',
      ], reason: '줄바꿈된 인자');
      expect(hits('width: 100.0'), ['width: 100.0'], reason: '경계값 포함');
    });

    test('잡지 않아야 하는 것', () {
      expect(hits('Icon(size: 24), width: 24, height: 56'), isEmpty);
      expect(hits('border: Border.all(width: 1.5)'), isEmpty);
      expect(hits('height: 1.5, // 줄 높이'), isEmpty);
      expect(hits('BoxConstraints(maxWidth: 480)'), isEmpty, reason: '상한 제약');
      expect(
        hits('BoxConstraints(minWidth: 320)'),
        isEmpty,
        reason: '의도적 미검출(하한 제약은 리뷰에서 확인)',
      );
      expect(hits('Size(48, 48)'), isEmpty);
      expect(
        hits('width: AppSpacing.designWidth'),
        isEmpty,
        reason: '상수(위젯 테스트 담당)',
      );
    });

    test('예외 주석: 이유가 있어야 하고, 주석 안에 있어야 한다', () {
      expect(hits('SizedBox(width: 350), // fixed-size: 차트 눈금 폭'), isEmpty);
      expect(hits('// fixed-size: 차트 눈금 폭\nSizedBox(width: 350)'), isEmpty);
      expect(hits('SizedBox(width: 350), // fixed-size:'), [
        'width: 350',
      ], reason: '이유가 비어 있으면 예외 아님');
      expect(hits('SizedBox(width: 350), // fixed-size:   '), ['width: 350']);
      expect(
        hits("Text('fixed-size: 아님'), SizedBox(width: 350)"),
        ['width: 350'],
        reason: '문자열 속 marker는 무시',
      );
      expect(
        hits('// fixed-size: 위 줄\nfoo();\nSizedBox(width: 350)'),
        ['width: 350'],
        reason: '두 줄 위는 예외 아님',
      );
    });
  });
}

class FixedSizeHit {
  final int line;
  final String text;
  const FixedSizeHit(this.line, this.text);
}

/// 검출 로직. 테스트 fixture에서 직접 호출할 수 있게 분리했다.
class FixedSizeAudit {
  static final RegExp _marker = RegExp(r'//.*fixed-size:\s*\S');
  static final RegExp _width = RegExp(
    r'(?<![A-Za-z_])width:\s*(\d+(?:\.\d+)?)',
  );
  static final RegExp _height = RegExp(
    r'(?<![A-Za-z_])height:\s*(\d+(?:\.\d+)?)',
  );
  static final RegExp _size = RegExp(
    r'\bSize(?:\.square|\.fromWidth|\.fromHeight)?\(\s*(\d+(?:\.\d+)?)\s*(?:,\s*(\d+(?:\.\d+)?)\s*)?\)',
  );

  static List<FixedSizeHit> scan(
    String source, {
    required double widthLimit,
    required double heightLimit,
  }) {
    final lines = source.split('\n');
    final lineStarts = <int>[0];
    for (var i = 0; i < source.length; i++) {
      if (source.codeUnitAt(i) == 10) lineStarts.add(i + 1);
    }
    int lineOf(int offset) {
      var lo = 0, hi = lineStarts.length - 1;
      while (lo < hi) {
        final mid = (lo + hi + 1) >> 1;
        if (lineStarts[mid] <= offset) {
          lo = mid;
        } else {
          hi = mid - 1;
        }
      }
      return lo;
    }

    bool excused(int lineIndex) {
      for (final i in [lineIndex, lineIndex - 1]) {
        if (i >= 0 && i < lines.length && _marker.hasMatch(lines[i])) {
          return true;
        }
      }
      return false;
    }

    bool inComment(int offset) {
      final line = lines[lineOf(offset)];
      final column = offset - lineStarts[lineOf(offset)];
      final comment = line.indexOf('//');
      return comment >= 0 && comment < column;
    }

    final hits = <FixedSizeHit>[];
    void add(Match m, bool flagged) {
      if (!flagged || inComment(m.start)) return;
      final line = lineOf(m.start);
      if (excused(line)) return;
      hits.add(FixedSizeHit(line + 1, m.group(0)!));
    }

    for (final m in _width.allMatches(source)) {
      add(m, double.parse(m.group(1)!) >= widthLimit);
    }
    for (final m in _height.allMatches(source)) {
      add(m, double.parse(m.group(1)!) >= heightLimit);
    }
    for (final m in _size.allMatches(source)) {
      final a = double.parse(m.group(1)!);
      final b = m.group(2) == null ? 0.0 : double.parse(m.group(2)!);
      add(m, a >= widthLimit || b >= widthLimit);
    }
    hits.sort((x, y) => x.line.compareTo(y.line));
    return hits;
  }
}
