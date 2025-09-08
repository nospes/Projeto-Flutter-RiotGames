// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:riot_profile/main.dart';

void main() {
  testWidgets('carrega tela de busca com AppBar, input e botão Buscar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: RiotApp()));

    expect(find.text('Riot Profile (BR)'), findsOneWidget);

    expect(find.text('Riot ID (ex.: SeuNome#BR1)'), findsOneWidget);

    expect(find.text('Buscar'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Joao#BR1');
    await tester.pump();
  });
}
