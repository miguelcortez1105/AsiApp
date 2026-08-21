import 'package:flutter/material.dart';
import 'package:asiapp_mobile/feature/home/screens/perfil_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const PerfilScreen(), // aqui é a mudança principal
    );
  }
}