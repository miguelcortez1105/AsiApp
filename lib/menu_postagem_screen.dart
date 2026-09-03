import 'package:flutter/material.dart';
import 'aba_calendario.dart';
import 'aba_cadastro_postagem.dart';
import 'aba_feed_social.dart';
import 'postagem.dart';

class MenuPostagemScreen extends StatefulWidget {
  const MenuPostagemScreen({super.key});

  @override
  State<MenuPostagemScreen> createState() => _MenuPostagemScreenState();
}

class _MenuPostagemScreenState extends State<MenuPostagemScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Postagem> _postagensSimuladas = []; // TODO: substituir por dados reais do Firestore
  final String nomeUsuarioLogado = 'Ana Alves'; // TODO: buscar do Firestore quando conectado

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
          AbaCadastroPostagem(
            postagens: _postagensSimuladas,
            nomeUsuarioLogado: nomeUsuarioLogado,
            aoPublicar: () => setState(() {}),
          ),
          AbaFeedSocial(postagens: _postagensSimuladas),
        ],
      ),
    );
  }
}