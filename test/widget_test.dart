// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:asiapp_mobile/main.dart';

void main() {
  testWidgets('renders executive dashboard and filters projects', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    expect(find.text('Faturamento acumulado'), findsOneWidget);
    expect(find.text('R\$ 8,42 mi'), findsOneWidget);
    expect(find.text('Projetos ativos'), findsOneWidget);
    expect(find.text('RITMO DA META'), findsOneWidget);
    expect(find.text('Portal de Clientes'), findsOneWidget);

    await tester.ensureVisible(find.text('Todas'));
    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Digital').last);
    await tester.pumpAndSettle();

    expect(find.text('Portal de Clientes'), findsOneWidget);
    expect(find.text('Expansão Asimov'), findsNothing);
  });
}
