import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/main.dart';

void main() {
  testWidgets('앱이 스플래시 라우트로 뜨고 mock 배지를 표시한다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RehearsalLabApp()));
    await tester.pumpAndSettle();
    expect(find.text('RehearsalLab'), findsWidgets);
    expect(find.text('개발용 목업'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
