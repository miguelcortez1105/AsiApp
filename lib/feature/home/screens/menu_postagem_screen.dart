import 'package:flutter/material.dart';
import 'package:asiapp_mobile/feature/home/screens/aba_calendario.dart';
import 'package:asiapp_mobile/feature/home/screens/aba_cadastro_postagem.dart';

class MenuPostagemScreen extends StatefulWidget {
  const MenuPostagemScreen({super.key});

  @override
  State<MenuPostagemScreen> createState() => _MenuPostagemScreenState();
}

class _MenuPostagemScreenState extends State<MenuPostagemScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu de Postagem'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Calendário'),
            Tab(text: 'Postar'),
            Tab(text: 'Feed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const AbaCalendario(),
          const AbaCadastroPostagem(),
          const Center(child: Text('Aba Feed Social')),
        ],
      ),
    );
  }
}