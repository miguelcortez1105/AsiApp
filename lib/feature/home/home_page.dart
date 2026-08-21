import 'package:flutter/material.dart';

import '../mngmt/gestao_de_pessoas.dart';
import '../perfil/perfil_screen.dart';

const _ink = Color(0xFF17212B);
const _muted = Color(0xFF6E7A86);
const _paper = Color(0xFFF5F7F8);
const _line = Color(0xFFE3E8EB);
const _teal = Color(0xFF087E8B);
const _coral = Color(0xFFE76F51);

class Project {
  const Project({
    required this.name,
    required this.area,
    required this.manager,
    required this.members,
    required this.value,
    required this.progress,
    required this.status,
    required this.color,
  });
  final String name;
  final String area;
  final String manager;
  final String members;
  final String value;
  final double progress;
  final String status;
  final Color color;
}

const projects = [
  Project(
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
  const HomePage({super.key, this.profile = const UserProfile(name: 'Miguel Cortez', email: 'miguel@asimovjr.com.br')});

  final UserProfile profile;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedArea = 'Todas';
  late UserProfile _profile = widget.profile;

  List<Project> get _profileProjects => projects;

  @override
  Widget build(BuildContext context) {
    final filteredProjects = _selectedArea == 'Todas'
        ? projects
        : projects.where((project) => project.area == _selectedArea).toList();
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : 20,
                vertical: isWide ? 34 : 22,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 34),
                      _buildWelcome(),
                      const SizedBox(height: 24),
                      _buildKpis(isWide),
                      const SizedBox(height: 24),
                      _buildGoalSection(isWide),
                      const SizedBox(height: 34),
                      _buildProjectHeader(),
                      const SizedBox(height: 14),
                      _buildProjects(filteredProjects, isWide),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
      ),
      const SizedBox(width: 12),
      const Text(
        'AsiApp',
        style: TextStyle(
          color: Color.fromARGB(255, 0, 128, 255),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
      const Spacer(),
      IconButton(
        onPressed: () {},
        tooltip: 'Notificações',
        icon: const Icon(Icons.notifications_none_rounded, color: _ink),
      ),
      const SizedBox(width: 4),
      PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'profile') {
            _openProfile();
          } else if (value == 'edit') {
            _showEditProfileDialog();
          } else if (value == 'people') {
            _openPeopleManagement();
          } else {
            _showProjectsDialog();
          }
        },
        tooltip: 'Abrir perfil',
        offset: const Offset(0, 48),
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'profile',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.account_circle_outlined),
              title: Text('Meu perfil'),
            ),
          ),
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_outlined),
              title: Text('Editar perfil'),
            ),
          ),
          PopupMenuItem(
            value: 'projects',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.folder_outlined),
              title: Text('Meus projetos'),
            ),
          ),
          PopupMenuItem(
            value: 'people',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.groups_outlined),
              title: Text('Gestão de pessoas'),
            ),
          ),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFFFC857),
              child: Text(
                _initials(_profile.name),
                style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            if (MediaQuery.sizeOf(context).width > 520)
              Text(
                _profile.name,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    ],
  );

  Future<void> _showEditProfileDialog() async {
    final updatedName = await showDialog<String>(
      context: context,
      builder: (context) {
        var editedName = _profile.name;
        return AlertDialog(
          title: const Text('Editar perfil'),
          content: TextFormField(
            initialValue: _profile.name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onChanged: (value) => editedName = value,
            decoration: const InputDecoration(
              labelText: 'Nome',
              hintText: 'Digite seu nome',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final name = editedName.trim();
                if (name.isNotEmpty) Navigator.pop(context, name);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
    if (updatedName != null && mounted) {
      setState(() => _profile = _profile.copyWith(name: updatedName));
    }
  }

  Future<void> _openProfile() async {
    final updatedProfile = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(builder: (_) => PerfilScreen(profile: _profile)),
    );
    if (updatedProfile != null && mounted) {
      setState(() => _profile = updatedProfile);
    }
  }

  void _openPeopleManagement() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GestaoDePessoas(currentProfile: _profile),
      ),
    );
  }

  void _showProjectsDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Projetos de ${_profile.name}'),
        content: SizedBox(
          width: 360,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _profileProjects.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final project = _profileProjects[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: project.color.withAlpha(24),
                  child: Icon(Icons.folder_outlined, color: project.color),
                ),
                title: Text(project.name),
                subtitle: Text('${project.area} • ${project.status}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'PAINEL EXECUTIVO',
        style: TextStyle(
          color: _teal,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
        ),
      ),
      SizedBox(height: 8),
      Text(
        'Bom dia, ${_profile.name.split(' ').first}.',
        style: const TextStyle(
          color: _ink,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
      SizedBox(height: 8),
      Text(
        'Acompanhe o que move a empresa hoje.',
        style: TextStyle(color: _muted, fontSize: 15),
      ),
    ],
  );

  Widget _buildKpis(bool isWide) {
    final cards = [
      _KpiData(
        'Faturamento acumulado',
        'R\$ 8,42 mi',
        '92,5% da meta anual',
        Icons.trending_up_rounded,
        _teal,
        '+12,8% vs. 2025',
      ),
      _KpiData(
        'Meta anual',
        'R\$ 9,10 mi',
        'R\$ 680 mil restantes',
        Icons.flag_outlined,
        _coral,
        'Dezembro de 2026',
      ),
      _KpiData(
        'Projetos ativos',
        '18',
        '4 áreas de projetos',
        Icons.layers_outlined,
        const Color(0xFF4C6FFF),
        '3 em atenção',
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
              const SizedBox(width: 48),
              Expanded(child: _buildProgressBars()),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGoalCopy(),
              const SizedBox(height: 24),
              _buildProgressBars(),
            ],
          ),
  );

  Widget _buildGoalCopy() => const SizedBox(
    width: 245,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RITMO DA META',
          style: TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Quase lá.',
          style: TextStyle(
            color: _ink,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'O acumulado está acima do ritmo esperado para o período.',
          style: TextStyle(color: _muted, fontSize: 13, height: 1.45),
        ),
        SizedBox(height: 14),
        Row(
          children: [
            Icon(Icons.schedule_rounded, size: 16, color: _teal),
            SizedBox(width: 6),
            Text(
              'Restam 4 meses',
              style: TextStyle(
                color: _teal,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildProgressBars() => Column(
    children: [
      _ProgressLine(
        label: 'Faturamento',
        value: .925,
        amount: '92,5%',
        color: _teal,
      ),
      const SizedBox(height: 20),
      _ProgressLine(
        label: 'Projetos entregues',
        value: .68,
        amount: '68%',
        color: _coral,
      ),
      const SizedBox(height: 20),
      _ProgressLine(
        label: 'Margem operacional',
        value: .81,
        amount: '81%',
        color: const Color(0xFF4C6FFF),
      ),
    ],
  );

  Widget _buildProjectHeader() => Row(
    children: [
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Projetos atuais',
              style: TextStyle(
                color: _ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Visão rápida por área, andamento e responsáveis.',
              style: TextStyle(color: _muted, fontSize: 13),
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
          'Digital',
          'Operações',
          'Pessoas',
          'Tecnologia',
        ].map((area) => PopupMenuItem(value: area, child: Text(area))).toList(),
      ),
    ],
  );

  Widget _buildProjects(List<Project> projects, bool isWide) {
    if (projects.isEmpty) {
      return const Text(
        'Nenhum projeto encontrado.',
        style: TextStyle(color: _muted),
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
