import 'dart:async';

import 'package:flutter/material.dart';
import 'aba_calendario.dart';
import 'aba_cadastro_postagem.dart';
import 'aba_feed_social.dart';
import '../perfil/perfil_screen.dart';
import '../core/widgets/app_background.dart';
import '../core/widgets/app_bottom_nav.dart';
import '../core/widgets/app_header.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class MenuPostagemScreen extends StatefulWidget {
  const MenuPostagemScreen({super.key, required this.currentProfile});

  final UserProfile currentProfile;

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
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return Padding(
                padding: EdgeInsets.only(
                  left: isWide ? 48 : 20,
                  right: isWide ? 48 : 20,
                  top: isWide ? 34 : 22,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ScreenHeader(
                          tela: 'P O S T A G E M',
                          title: 'Menu de postagem',
                          subtitle: 'Calendário, publicação e feed em um só lugar',
                        ),
                        const SizedBox(height: 16),
                        TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.white,
                          indicatorColor: AppColors.primary,
                          labelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                          unselectedLabelStyle: AppTextStyles.caption,
                          tabs: const [
                            Tab(text: 'Calendário'),
                            Tab(text: 'Postar'),
                            Tab(text: 'Feed'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: const [
                              AbaCalendario(),
                              AbaCadastroPostagem(),
                              AbaFeedSocial(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentTab: AppTab.postagem,
        profile: widget.currentProfile,
      ),
    );
  }
}