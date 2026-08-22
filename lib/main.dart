import 'package:flutter/material.dart';
import 'feature/auth/login_page.dart';
import 'feature/core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asimov | Painel executivo',
      theme: AppTheme.light,
      home: const LoginPage(),
    );
  }
}
