import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 고정 크기 감사 (통합 문서 7장 해상도 대응 규칙의 보조 장치).
///
/// `lib/ui` 소스에서 화면 폭을 고정했을 가능성이 있는 큰 숫자를 찾아 실패시킨다.
/// - `width: 100` 이상, `height: 200` 이상, `Size(390, …)`처럼 세 자리 숫자
/// - 아이콘 · 점 · 구분선 · 썸네일 · 버튼 높이 같은 작은 값은 통과
/// - 정말 필요한 고정값은 같은 줄이나 바로 윗줄에 `// fixed-size: <이유>` 주석을 달면 통과
///
/// 320 · 390 · 430 오버플로 위젯 테스트가 "결과가 깨졌는지"를 본다면, 이 테스트는
/// "깨질 원인이 되는 코드가 들어왔는지"를 본다. 변수로 우회한 값은 잡지 못하므로 보조용이다.
void main() {
  const widthLimit = 100.0;
  const heightLimit = 200.0;
  const marker = 'fixed-size:';

  final patterns = <RegExp, double Function(Match)>{
    RegExp(r'\bwidth:\s*(\d+(?:\.\d+)?)'): (m) =>
        double.parse(m.group(1)!) >= widthLimit ? double.parse(m.group(1)!) : 0,
    RegExp(r'\bheight:\s*(\d+(?:\.\d+)?)'): (m) =>
        double.parse(m.group(1)!) >= heightLimit
        ? double.parse(m.group(1)!)
        : 0,
    RegExp(r'\bSize(?:\.square)?\(\s*(\d{3,})'): (m) =>
        double.parse(m.group(1)!),
    RegExp(r'\b(?:maxWidth|minWidth):\s*(\d{3,})'): (m) =>
        double.parse(m.group(1)!),
  };

  test('lib/ui에 화면 폭을 고정한 숫자가 없다 (예외는 // fixed-size: 주석)', () {
    final dir = Directory('lib/ui');
    expect(dir.existsSync(), isTrue, reason: '프로젝트 루트에서 실행해야 한다');

    final findings = <String>[];
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final code = line.split('//').first;
        final previous = i > 0 ? lines[i - 1] : '';
        final excused = line.contains(marker) || previous.contains(marker);
        for (final entry in patterns.entries) {
          for (final match in entry.key.allMatches(code)) {
            final value = entry.value(match);
            if (value == 0 || excused) continue;
            final path = file.path.replaceAll(r'\', '/');
            findings.add('$path:${i + 1}  ${match.group(0)}  (${line.trim()})');
          }
        }
      }
    }

    expect(
      findings,
      isEmpty,
      reason:
          '고정 크기 발견. Expanded · stretch · FractionallySizedBox로 바꾸거나, '
          '정당한 고정값이면 같은 줄 또는 윗줄에 "// $marker <이유>"를 적는다.\n'
          '${findings.join('\n')}',
    );
  });

  test('감사 규칙 자체 검증: 큰 값은 잡고 작은 값 · 주석 예외는 통과', () {
    bool flagged(String line, {String previous = ''}) {
      final excused = line.contains(marker) || previous.contains(marker);
      if (excused) return false;
      final code = line.split('//').first;
      for (final entry in patterns.entries) {
        for (final match in entry.key.allMatches(code)) {
          if (entry.value(match) != 0) return true;
        }
      }
      return false;
    }

    expect(flagged('SizedBox(width: 350, child: card)'), isTrue);
    expect(flagged('Container(height: 844)'), isTrue);
    expect(flagged('const Size(390, 844)'), isTrue);
    expect(flagged('BoxConstraints(maxWidth: 390)'), isTrue);
    expect(flagged('Icon(size: 24), width: 24, height: 56'), isFalse);
    expect(flagged('border: Border.all(width: 1.5)'), isFalse);
    expect(flagged('height: 1.5, // 줄 높이'), isFalse);
    expect(flagged('SizedBox(width: 350), // fixed-size: 차트 눈금 폭'), isFalse);
    expect(
      flagged('SizedBox(width: 350)', previous: '// fixed-size: 차트'),
      isFalse,
    );
  });
}
