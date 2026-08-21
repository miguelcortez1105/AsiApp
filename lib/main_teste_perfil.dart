import 'package:flutter/material.dart';
import 'package:asiapp_mobile/feature/perfil/perfil_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const PerfilScreen(
        profile: UserProfile(
          name: 'Miguel Cortez',
          email: 'miguel@asimovjr.com.br',
        ),
      ),
    );
  }
}