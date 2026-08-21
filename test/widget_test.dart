// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:asiapp_mobile/main.dart';

void main() {
  testWidgets('renders executive dashboard and filters projects', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.ensureVisible(find.text('Cadastre-se'));
    await tester.tap(find.text('Cadastre-se'));
    await tester.pumpAndSettle();
    final signupFields = find.byType(TextFormField);
    await tester.enterText(signupFields.at(0), 'Miguel Cortez');
    await tester.enterText(signupFields.at(1), 'miguel@asimovjr.com.br');
    await tester.enterText(signupFields.at(2), 'senha123');
    await tester.enterText(signupFields.at(3), 'senha123');
    await tester.tap(find.text('Criar cadastro').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'miguel@asimovjr.com.br',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'senha123');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Faturamento acumulado'), findsOneWidget);
    expect(find.text('R\$ 8,42 mi'), findsOneWidget);
    expect(find.text('Projetos ativos'), findsOneWidget);
    expect(find.text('RITMO DA META'), findsOneWidget);
    expect(find.text('Portal de Clientes'), findsOneWidget);

    await tester.tap(find.text('Miguel Cortez'));
    await tester.pumpAndSettle();
    expect(find.text('Meu perfil'), findsOneWidget);
    expect(find.text('Editar perfil'), findsOneWidget);
    expect(find.text('Meus projetos'), findsOneWidget);

    await tester.tap(find.text('Meu perfil'));
    await tester.pumpAndSettle();
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Membro'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Miguel Cortez'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meus projetos'));
    await tester.pumpAndSettle();
    expect(find.text('Projetos de Miguel Cortez'), findsOneWidget);
    expect(find.text('Modernização de Dados'), findsNWidgets(2));
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Miguel Cortez'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Miguel Cortez');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Miguel Cortez'), findsOneWidget);

    await tester.ensureVisible(find.text('Todas'));
    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Digital').last);
    await tester.pumpAndSettle();

    expect(find.text('Portal de Clientes'), findsOneWidget);
    expect(find.text('Expansão Asimov'), findsNothing);
  });
}
