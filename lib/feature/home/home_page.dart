import 'dart:async';

import 'package:asiapp_mobile/feature/core/theme/app_colors.dart';
import 'package:asiapp_mobile/feature/core/widgets/app_header.dart';
import '../core/widgets/app_bottom_nav.dart';
import '../core/widgets/app_background.dart';
import '../core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../perfil/perfil_screen.dart';
import '../core/data/firebase_repository.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'models/dashboard_metrics.dart';

class Project {
  const Project({
    this.id = '',
    required this.name,
    required this.area,
    required this.manager,
    required this.members,
    required this.value,
    required this.progress,
    required this.status,
    required this.color,
    this.memberIds = const [],
  });
  final String id;
  final String name;
  final String area;
  final String manager;
  final String members;
  final String value;
  final double progress;
  final String status;
  final Color color;
  final List<String> memberIds;

  factory Project.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    final colorValue = (data['color'] as String? ?? '087E8B')
        .replaceFirst('#', '');
    final rawMemberIds = data['memberIds'];
    final memberIds = rawMemberIds is List
      ? rawMemberIds.whereType<String>().toList()
      : <String>[];
    final rawMembers = data['members'];
    return Project(
      id: document.id,
      name: data['name'] as String? ?? 'Projeto sem nome',
      area: data['area'] as String? ?? 'Outros',
      manager: data['manager'] as String? ?? 'Não informado',
        members: rawMembers is String
          ? rawMembers
          : '${memberIds.length} pessoas',
      value: data['value'] as String? ?? 'R\$ 0',
      progress: (data['progress'] as num?)?.toDouble() ?? 0,
      status: data['status'] as String? ?? 'Sem status',
      color: Color(int.tryParse('FF$colorValue', radix: 16) ?? 0xFF087E8B),
      memberIds: memberIds,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.profile = const UserProfile(
      name: 'Miguel Cortez',
      email: 'miguel@asimovjr.com.br',
    ),
  });

  final UserProfile profile;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedArea = 'Todas';

  late UserProfile _profile = widget.profile;

  List<Project> _projects = [];

  StreamSubscription<List<Project>>? _projectsSubscription;

  StreamSubscription<DashboardMetrics?>? _dashboardSubscription;

  StreamSubscription<List<PortalBjIndicator>>? _portalBjSubscription;

  DashboardMetrics? _dashboardMetrics;

  List<PortalBjIndicator> _portalBjIndicators = [];

  double get _percentualMeta {
  final metrics = _dashboardMetrics;

  if (metrics == null || metrics.annualGoal <= 0) {
    return 0;
  }

  return ((metrics.currentRevenue / metrics.annualGoal) * 100)
      .clamp(0, 100);
}

double get _gapMeta {
  final metrics = _dashboardMetrics;

  if (metrics == null) {
    return 0;
  }

  return (metrics.annualGoal - metrics.currentRevenue)
      .clamp(0, double.infinity);
}

double get _variacaoAnual {
  final metrics = _dashboardMetrics;

  if (metrics == null || metrics.previousYearRevenue <= 0) {
    return 0;
  }

  return ((metrics.currentRevenue -
              metrics.previousYearRevenue) /
          metrics.previousYearRevenue) *
      100;
}

String _formatCurrency(double value) {
  return NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  ).format(value);
}

String _formatPortalBjValue(PortalBjIndicator indicator) {
  switch (indicator.unit.toLowerCase()) {
    case 'moeda':
      return _formatCurrency(indicator.achieved);

    case 'percentual':
      return '${indicator.achieved.toStringAsFixed(1)}%';

    default:
      return indicator.achieved.toStringAsFixed(2);
  }
}

  @override
  void initState() {
    super.initState();
    _projectsSubscription = FirebaseRepository.instance.watchProjects(
      memberId: Hierarchy.canManageProjects(_profile.role)
          ? null
          : (_profile.uid.isEmpty ? '__missing_uid__' : _profile.uid),
    ).listen(
      (loadedProjects) {
        if (mounted) {
          setState(() => _projects = loadedProjects);
        }
      },
      onError: (_) {},
    );

  final anoAtual = DateTime.now().year;

  _dashboardSubscription =
      FirebaseRepository.instance
          .watchDashboardMetrics(anoAtual)
          .listen(
    (metrics) {
      if (mounted) {
        setState(() {
          _dashboardMetrics = metrics;
        });
      }
    },
    onError: (_) {},
  );

  _portalBjSubscription =
      FirebaseRepository.instance
          .watchPortalBjIndicators(anoAtual)
          .listen(
    (indicators) {
      if (mounted) {
        setState(() {
          _portalBjIndicators = indicators;
        });
      }
    },
    onError: (_) {},
  );
  }

  @override
  void dispose() {
    _projectsSubscription?.cancel();
    _dashboardSubscription?.cancel();
    _portalBjSubscription?.cancel();

    super.dispose();
  }
@override
Widget build(BuildContext context) {
  final filteredProjects = _selectedArea == 'Todas'
    ? _projects
    : _projects.where((project) => project.area == _selectedArea).toList();

  return Scaffold(
    backgroundColor: Colors.transparent,
    extendBody: true,
    body: AppBackground(
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: isWide ? 48 : 20,
                right: isWide ? 48 : 20,
                top: isWide ? 34 : 22,
                bottom: isWide ? 34 : 100,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 16),
                      _buildKpis(isWide),
                      _buildGoalSection(isWide),
                      const SizedBox(height: 16),
                      _buildProjectsSection(filteredProjects, isWide),
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
      currentTab: AppTab.inicio,
      profile: _profile,
    ),
  );
}

  Widget _buildHeader(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'H O M E',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.white,
              letterSpacing: 4.0, // Espaçamento largo igual ao do print
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bem vindo, ${_profile.name.split(' ').first}!', // Aspas adicionadas
            style: AppTextStyles.h2.copyWith(
              color: AppColors.white, // Fonte em destaque
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Acompanhe os processos da empresa hoje',
            style: AppTextStyles.body.copyWith(
              color: AppColors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      const SizedBox(height: 24),
      Align(
        alignment: Alignment.topLeft,
        child: _buildProfileButton(context),
      ),
    ],
  );

  Widget _buildProfileButton(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: _openProfile,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            Container(
              width: 42, // Tamanho do ícone um pouco maior
              height: 42, 
              child: SvgPicture.asset('assets/images/icon_home.svg'),
            ),
            const SizedBox(height: 4), 
            Text(
              'AsiPerfil',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _openProfile() async {
    final updatedProfile = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(builder: (_) => PerfilScreen(profile: _profile)),
    );
    if (updatedProfile != null && mounted) {
      setState(() => _profile = updatedProfile);
    }
  }

  Widget _buildKpis(bool isWide) {
    final currentRevenue = _dashboardMetrics?.currentRevenue ?? 0;
    final annualGoal = _dashboardMetrics?.annualGoal ?? 0;

    final cards = [
      _KpiData(
        title: 'Faturamento',
        achievedValue: _formatCurrency(currentRevenue),
        goalValue: _formatCurrency(annualGoal),
        progress: annualGoal > 0 ? (currentRevenue / annualGoal) : 0,
        leftFooter: 'GAP ${_formatCurrency(_gapMeta)}',
        rightFooter: '${_percentualMeta.toStringAsFixed(0)}% da meta atual',
      ),
      _KpiData(
        title: 'Faturamento acumulado',
        achievedValue: _formatCurrency(currentRevenue),
        progress: 1.0, 
        centerFooter: '${_variacaoAnual >= 0 ? '+' : ''}${_variacaoAnual.toStringAsFixed(1)}% vs ${_dashboardMetrics?.previousYearRevenue != null ? DateTime.now().year - 1 : "ano anterior"}',
      ),
      _KpiData(
        title: 'Meta anual',
        achievedValue: _formatCurrency(annualGoal),
        progress: 1.0,
        centerFooter: 'Faltam ${_formatCurrency(_gapMeta)}',
      ),
      _KpiData(
        title: 'Projetos',
        achievedLabel: 'Ativos',
        achievedValue: '${_projects.length}',
        progress: 1.0,
        centerFooter: '${_projects.length} áreas de projetos ativas',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 2 : 1, 
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 190, 
      ),
      itemBuilder: (context, index) => _KpiCard(data: cards[index]),
    );
  }

  Widget _buildGoalSection(bool isWide) => _Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            'Portal BJ',
            style: AppTextStyles.h2.copyWith(color: AppColors.white),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(const Color(0xFF76C86F), 'Indicadores\nEssenciais'),
            const SizedBox(width: 32),
            _buildLegendItem(AppColors.primary, 'Indicadores\nComplementares'),
          ],
        ),
        const SizedBox(height: 24),
        _buildProgressBars(),
      ],
    ),
  );

  Widget _buildLegendItem(Color color, String label) => Row(
    children: [
      Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label, 
        style: AppTextStyles.caption.copyWith(color: AppColors.white),
      ),
    ],
  );

  Widget _buildProgressBars() {
    if (_portalBjIndicators.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Nenhum indicador encontrado.',
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          ),
        ),
      );
    }

    return Column(
      children: _portalBjIndicators.map((indicator) {
        final isEssential = indicator.type.toLowerCase() == 'essencial';
        
        // Verde customizado e os Azuis baseados no AppColors
        final cardColor = isEssential ? const Color(0xFF76C86F) : AppColors.primary;
        final trackColor = isEssential ? const Color(0xFF5FA85A) : AppColors.primaryDark;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _PortalBjCard(
            title: indicator.name,
            achieved: _formatPortalBjValue(indicator),
            progress: indicator.progress / 100,
            cardColor: cardColor,
            trackColor: trackColor,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProjectsSection(List<Project> projects, bool isWide) => _Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            'Projetos',
            style: AppTextStyles.display.copyWith(
              color: AppColors.white,
              fontSize: 28,
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (projects.isEmpty)
          Center(
            child: Text(
              'Nenhum projeto encontrado.',
              style: AppTextStyles.caption.copyWith(color: AppColors.white),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: projects.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _ProjectCard(project: projects[index]),
          ),
      ],
    ),
  );
}

class _KpiData {
  const _KpiData({
    required this.title,
    this.achievedLabel = 'Alcançado',
    required this.achievedValue,
    this.goalValue,
    required this.progress,
    this.leftFooter,
    this.rightFooter,
    this.centerFooter,
  });
  final String title;
  final String achievedLabel;
  final String achievedValue;
  final String? goalValue;
  final double progress;
  final String? leftFooter;
  final String? rightFooter;
  final String? centerFooter;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});
  final _KpiData data;

  @override
  Widget build(BuildContext context) => _Surface(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          data.title, 
          style: AppTextStyles.body.copyWith(
            color: AppColors.white, 
            fontWeight: FontWeight.w600,
          )
        ),
        const SizedBox(height: 12),
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.primaryDark, // Utilizando a cor escura do tema
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: data.progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary, // Cor principal do tema
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: data.goalValue != null 
                      ? MainAxisAlignment.spaceBetween 
                      : MainAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: data.goalValue != null 
                          ? CrossAxisAlignment.start 
                          : CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          data.achievedLabel, 
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.white.withOpacity(0.9), 
                            fontWeight: FontWeight.w500,
                          )
                        ),
                        Text(
                          data.achievedValue, 
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.white, 
                          )
                        ),
                      ],
                    ),
                    if (data.goalValue != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Meta', 
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.white.withOpacity(0.9), 
                              fontWeight: FontWeight.w500,
                            )
                          ),
                          Text(
                            data.goalValue!, 
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.white, 
                            )
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (data.centerFooter != null)
          Center(
            child: Text(
              data.centerFooter!, 
              style: AppTextStyles.button.copyWith(
                color: AppColors.primary, 
              )
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (data.leftFooter != null) 
                Text(
                  data.leftFooter!, 
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted)
                ),
              if (data.rightFooter != null) 
                Text(
                  data.rightFooter!, 
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted)
                ),
            ],
          ),
      ],
    ),
  );
}

class _PortalBjCard extends StatelessWidget {
  const _PortalBjCard({
    required this.title,
    required this.achieved,
    required this.progress,
    required this.cardColor,
    required this.trackColor,
  });
  
  final String title;
  final String achieved;
  final double progress;
  final Color cardColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.button.copyWith(color: AppColors.white),
        ),
        const SizedBox(height: 12),
        Container(
          height: 56, 
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Alcançado', 
                          style: AppTextStyles.caption.copyWith(color: AppColors.white, fontSize: 10)
                        ),
                        Text(
                          achieved, 
                          style: AppTextStyles.button.copyWith(color: AppColors.white)
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Meta', 
                          style: AppTextStyles.caption.copyWith(color: AppColors.white, fontSize: 10)
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 1,
          color: AppColors.white.withOpacity(0.4),
        ),
        const SizedBox(height: 12),
        Text(
          'GAP R\$ 0,00', 
          style: AppTextStyles.caption.copyWith(
            color: AppColors.white, 
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.primary, // Cor azul vibrante
      borderRadius: BorderRadius.circular(24), // Bordas mais arredondadas como no print
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                project.name,
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.white,
                  fontSize: 20,
                ),
              ),
            ),
            // Gerente jogado bem pra direita, já que o número de
            // pessoas saiu dessa linha e desceu pra linha de baixo.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.ink),
                  const SizedBox(width: 6),
                  Text(
                    project.manager,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_up_rounded, size: 16, color: AppColors.ink),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Número de pessoas do projeto, agora numa linha própria
        // abaixo do cabeçalho, liberando espaço ali em cima.
        Row(
          children: [
            const Icon(Icons.people_outline_rounded, size: 20, color: AppColors.white),
            const SizedBox(width: 6),
            Text(
              project.members.replaceAll(RegExp(r'[^0-9]'), ''),
              style: AppTextStyles.body.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentes que sem placerat. In id cursus mi pretium tellus duis convallis.',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.white.withOpacity(0.9),
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.padding});
  
  final Widget child;
  final EdgeInsetsGeometry? padding;
  
  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.ink, // Trocado para o azul muito escuro do seu tema
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}