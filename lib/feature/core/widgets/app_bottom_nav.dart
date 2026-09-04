import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../perfil/perfil_screen.dart'; 
import '../data/firebase_repository.dart';
import '../../cadastro-de-projetos/cadastro-de-projetos.dart';
import '../../pessoas/gestao_de_pessoas.dart';
import '../../financeiro/gestao_financeira.dart';
import '../../postagens/menu_postagem_screen.dart';

enum AppTab { inicio, projetos, postagem, pessoas, financeiro }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentTab,
    required this.profile,
  });

  final AppTab currentTab;
  final UserProfile profile;

  static const _tabOrder = [
    AppTab.inicio,
    AppTab.projetos,
    AppTab.financeiro,
    AppTab.postagem,
    AppTab.pessoas,
  ];

  void _navigateTo(BuildContext context, AppTab tab) {
    if (tab == currentTab) return;

    if (tab == AppTab.inicio) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    Widget destination;
    switch (tab) {
      case AppTab.projetos:
        destination = CadastroDeProjetos(currentProfile: profile);
        break;
      case AppTab.postagem:
        destination = MenuPostagemScreen(currentProfile: profile);
        break;
      case AppTab.pessoas:
        destination = GestaoDePessoas(currentProfile: profile);
        break;
      case AppTab.financeiro:
        destination = GestaoFinanceira(currentProfile: profile);
        break;
      case AppTab.inicio:
        return;
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    final visibleTabs = _tabOrder
        .where((tab) => tab != AppTab.financeiro || Hierarchy.canViewFinance(profile.role))
        .toList();

    final selectedIndex = visibleTabs.indexOf(currentTab).clamp(0, visibleTabs.length - 1);

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _navigateTo(context, visibleTabs[index]),
      destinations: visibleTabs.map(_destinationFor).toList(),
    );
  }

  NavigationDestination _destinationFor(AppTab tab) {
    switch (tab) {
      case AppTab.inicio:
        return NavigationDestination(
          icon: SvgPicture.asset('assets/images/nav_home.svg', width: 22, height: 22),
          selectedIcon: SvgPicture.asset('assets/images/nav_home_selected.svg', width: 22, height: 22),
          label: 'Home',
        );
      case AppTab.projetos:
        return const NavigationDestination(
          icon: Icon(Icons.folder_outlined),
          selectedIcon: Icon(Icons.folder_rounded),
          label: 'Projetos',
        );
      case AppTab.financeiro:
        return NavigationDestination(
          icon: SvgPicture.asset('assets/images/nav_financeiro.svg', width: 22, height: 22),
          selectedIcon: SvgPicture.asset('assets/images/nav_financeiro_selected.svg', width: 22, height: 22),
          label: 'Financeiro',
        );
      case AppTab.postagem:
        return const NavigationDestination(
          icon: Icon(Icons.campaign_outlined),
          selectedIcon: Icon(Icons.campaign_rounded),
          label: 'Postagens',
        );
      case AppTab.pessoas:
        return const NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups_rounded),
          label: 'Pessoas',
        );
    }
  }
}