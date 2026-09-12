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

const _ink = Color(0xFF17212B);
const _muted = Color(0xFF6E7A86);
const _line = Color(0xFFE3E8EB);
const _teal = Color(0xFF087E8B);
const _coral = Color(0xFFE76F51);

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

const projects = [
  Project(
    id: 'demo-portal',
    name: 'Portal de Clientes',
    area: 'Digital',
    manager: 'Miguel',
    members: '6 pessoas',
    value: 'R\$ 480 mil',
    progress: 0.78,
    status: 'No prazo',
    color: _teal,
  ),
  Project(
    id: 'demo-expansao',
    name: 'Expansão Asimov',
    area: 'Operações',
    manager: 'Matheus',
    members: '9 pessoas',
    value: 'R\$ 1,2 mi',
    progress: 0.54,
    status: 'Atenção',
    color: _coral,
  ),
  Project(
    id: 'demo-academia',
    name: 'Academia de Itajubá',
    area: 'Pessoas',
    manager: 'Matheus',
    members: '4 pessoas',
    value: 'R\$ 215 mil',
    progress: 0.36,
    status: 'No prazo',
    color: Color(0xFF4C6FFF),
  ),
  Project(
    id: 'demo-dados',
    name: 'Modernização de Dados',
    area: 'Tecnologia',
    manager: 'Leo',
    members: '8 pessoas',
    value: 'R\$ 860 mil',
    progress: 0.22,
    status: 'Em risco',
    color: Color(0xFF9B5DE5),
  ),
];

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

  late List<Project> _projects =
      Hierarchy.canManageProjects(widget.profile.role)
       ? projects 
       : [];

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
                      _buildProjectHeader(),
                      const SizedBox(height: 16),
                      _buildProjects(filteredProjects, isWide),
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

  Widget _buildHeader(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: ScreenHeader(
          tela: 'H O M E',
          title: 'Bem vindo, ${_profile.name.split(' ').first}!',
          subtitle: 'Acompanhe os processos da empresa hoje',
        ),
      ),
      _buildProfileButton(context),
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
          children: [
            Container(
              width: 32,
              height: 32, 
              child: SvgPicture.asset('assets/images/icon_home.svg'),
            ),
            const SizedBox(width: 8),
            Text(
              'AsiPerfil',
              style: AppTextStyles.caption.copyWith(color: AppColors.white),
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
    final cards = [
      _KpiData(
        'Faturamento acumulado',
        _formatCurrency(
          _dashboardMetrics?.currentRevenue ?? 0,
        ),
        '${_percentualMeta.toStringAsFixed(1)}% da meta anual',
        Icons.trending_up_rounded,
        _teal,
        '${_variacaoAnual >= 0 ? '+' : ''}'
            '${_variacaoAnual.toStringAsFixed(1)}% vs. ano anterior',
      ),

      _KpiData(
        'Meta anual',
        _formatCurrency(
          _dashboardMetrics?.annualGoal ?? 0,
        ),
        '${_formatCurrency(_gapMeta)} restantes',
        Icons.flag_outlined,
        _coral,
        'Ano ${DateTime.now().year}',
      ),

      _KpiData(
        'Projetos ativos',
        '${_projects.length}',
        '${_projects.map((project) => project.area).toSet().length} áreas de projetos',
        Icons.layers_outlined,
        const Color(0xFF4C6FFF),
        'Dados do Firebase',
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 3 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 12,
        mainAxisExtent: 155,
      ),
      itemBuilder: (context, index) => _KpiCard(data: cards[index]),
    );
  }

  Widget _buildGoalSection(bool isWide) => _Surface(
    child: isWide
        ? Row(
            children: [
              _buildGoalCopy(),
              Expanded(child: _buildProgressBars()),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGoalCopy(),
              
              _buildProgressBars(),
            ],
          ),
  );

  Widget _buildGoalCopy() => SizedBox(
    width: 245,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portal BJ',
          style: AppTextStyles.caption.copyWith(color: AppColors.black),
        ),
      ],
    ),
  );

  Widget _buildProgressBars() => Column(
    children: [
      _ProgressLine(
        label: 'CSAT',
        value: .925,
        amount: '92,5%',
        color: const Color(0xFF88D46C),
      ),
      const SizedBox(height: 8),
      _ProgressLine(
        label: 'Tempo de Permanencia no MEJ',
        value: .68,
        amount: '68%',
        color: const Color(0xFF88D46C),
      ),
      const SizedBox(height: 8),
      _ProgressLine(
        label: 'Engajamento com o  MEJ',
        value: .81,
        amount: '81%',
        color: const Color(0xFF88D46C),
      ),
      const SizedBox(height: 8),
      _ProgressLine(
        label: 'Politicas de Diversidade e Inclusão',
        value: .925,
        amount: '92,5%',
        color: const Color(0xFF007FFF),
      ),
      const SizedBox(height: 8),
      _ProgressLine(
        label: 'Faturamento Colaborativo',
        value: .68,
        amount: '68%',
        color: const Color(0xFF007FFF),
      ),
      const SizedBox(height: 8),
      _ProgressLine(
        label: 'Projetos de Impacto',
        value: .81,
        amount: '81%',
        color: const Color(0xFF007FFF)
      ),
    ],
  );

  Widget _buildProjectHeader() => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Projetos atuais',
              style: AppTextStyles.h2.copyWith(color: AppColors.white),
            ),
            SizedBox(height: 4),
            Text(
              'Visão rápida por área, andamento e responsáveis.',
              style: AppTextStyles.caption.copyWith(color: AppColors.white),
            ),
          ],
        ),
      ),
      PopupMenuButton<String>(
        initialValue: _selectedArea,
        onSelected: (value) => setState(() => _selectedArea = value),
        tooltip: 'Filtrar por área',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedArea,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.tune_rounded, size: 16, color: _muted),
            ],
          ),
        ),
        itemBuilder: (context) => [
          'Todas',
          'Mobile',
          'Desktop',
          'Dados',
          'Sites',
          'Pessoas',
        ].map((area) => PopupMenuItem(value: area, child: Text(area))).toList(),
      ),
    ],
  );

  Widget _buildProjects(List<Project> projects, bool isWide) {
    if (projects.isEmpty) {
      return Text(
        'Nenhum projeto encontrado.',
        style: AppTextStyles.caption.copyWith(color: AppColors.white),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 2 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isWide ? 2.15 : 2.0,
      ),
      itemBuilder: (context, index) => _ProjectCard(project: projects[index]),
    );
  }
}

class _KpiData {
  const _KpiData(
    this.label,
    this.value,
    this.detail,
    this.icon,
    this.color,
    this.footer,
  );
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  final String footer;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});
  final _KpiData data;
  @override
  Widget build(BuildContext context) => _Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: data.color.withAlpha(24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(data.icon, color: data.color, size: 18),
            ),
            const Spacer(),
            Text(
              data.footer,
              style: TextStyle(
                color: data.color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(data.label, style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 3),
        Text(
          data.value,
          style: const TextStyle(
            color: _ink,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(data.detail, style: const TextStyle(color: _muted, fontSize: 11)),
      ],
    ),
  );
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.value,
    required this.amount,
    required this.color,
  });
  final String label;
  final double value;
  final String amount;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 8,
          backgroundColor: _line,
          color: color,
        ),
      ),
    ],
  );
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});
  final Project project;
  @override
  Widget build(BuildContext context) => _Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                project.name,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _StatusPill(status: project.status),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          project.area,
          style: TextStyle(
            color: project.color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            const Icon(Icons.person_outline_rounded, size: 15, color: _muted),
            const SizedBox(width: 5),
            Text(
              project.manager,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
            const Spacer(),
            Text(
              project.members,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: project.progress,
                  minHeight: 6,
                  backgroundColor: _line,
                  color: project.color,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(project.progress * 100).round()}%',
              style: const TextStyle(
                color: _ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text(
              'Orçamento',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
            const Spacer(),
            Text(
              project.value,
              style: const TextStyle(
                color: _ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
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
    final color = status == 'No prazo'
        ? _teal
        : status == 'Atenção'
        ? _coral
        : const Color(0xFFD1495B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _line),
    ),
    child: child,
  );
}
