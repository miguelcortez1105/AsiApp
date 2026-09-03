// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asiapp_mobile/feature/auth/role_triage_page.dart';
import 'package:asiapp_mobile/feature/core/data/firebase_repository.dart';
import 'package:asiapp_mobile/feature/perfil/perfil_screen.dart';

void main() {
  test('new users are blocked until a role is assigned', () {
    expect(Hierarchy.isAwaitingRoleAssignment(Hierarchy.awaitingRoleAssignment), isTrue);
    expect(Hierarchy.isAwaitingRoleAssignment(Hierarchy.member), isFalse);
    expect(Hierarchy.isAwaitingRoleAssignment(Hierarchy.presidency), isFalse);
  });

  testWidgets('triage page is shown to users waiting for role assignment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RoleTriagePage(
          profile: const UserProfile(
            uid: 'user-1',
            name: 'Maria Silva',
            email: 'maria@asimovjr.com.br',
            role: Hierarchy.awaitingRoleAssignment,
          ),
        ),
      ),
    );

    expect(find.text('Aguardando atribuição de cargo'), findsOneWidget);
    expect(find.textContaining('Seu cadastro foi realizado com sucesso'), findsOneWidget);
  });
}
