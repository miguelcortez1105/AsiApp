import 'dart:async';

import 'package:asiapp_mobile/feature/core/widgets/app_background.dart';
import 'package:asiapp_mobile/feature/core/widgets/app_bottom_nav.dart';
import 'package:asiapp_mobile/feature/core/theme/app_text_styles.dart';
import 'package:asiapp_mobile/feature/core/theme/app_colors.dart';
import 'package:asiapp_mobile/feature/core/widgets/app_header.dart';
import 'package:flutter/material.dart';
import '../core/data/firebase_repository.dart';
import '../home/home_page.dart';
import '../pessoas/gestao_de_pessoas.dart';
import '../perfil/perfil_screen.dart';

class CadastroDeProjetos extends StatefulWidget {
  const CadastroDeProjetos({super.key, required this.currentProfile});

  final UserProfile currentProfile;

  @override
  State<CadastroDeProjetos> createState() => _CadastroDeProjetosState();
}

class _CadastroDeProjetosState extends State<CadastroDeProjetos> {
  static const _areas = ['Mobile', 'Desktop', 'Dados', 'Sites', 'Pessoas'];
  static const _statuses = ['A Iniciar', 'Em Andamento', 'Concluído'];

  final _minimumController = TextEditingController();
  final _maximumController = TextEditingController();
  List<Project> _projects = [];
  List<PersonRecord> _people = [];
  String? _areaFilter;
  String? _statusFilter;
  StreamSubscription<List<Project>>? _projectsSubscription;
  StreamSubscription<List<PersonRecord>>? _peopleSubscription;

  bool get _canCreate =>
      Hierarchy.canManageProjects(widget.currentProfile.role);

  List<Project> get _filteredProjects => _projects.where((project) {
    final minimum =
        double.tryParse(_minimumController.text.replaceAll(',', '.')) ?? 0;
    final maximum =
        double.tryParse(_maximumController.text.replaceAll(',', '.')) ??
        double.infinity;
    final areaMatches = _areaFilter == null || project.area == _areaFilter;
    final statusMatches =
        _statusFilter == null || project.status == _statusFilter;
    final value = _projectValue(project.value);
    return areaMatches && statusMatches && value >= minimum && value <= maximum;
  }).toList();

  double _projectValue(String value) =>
      double.tryParse(
        value.replaceAll(RegExp(r'[^0-9,.]'), '').replaceAll(',', '.'),
      ) ??
      0;

  @override
  void initState() {
    super.initState();
    _projectsSubscription = FirebaseRepository.instance
        .watchProjects(
          memberId: _canCreate
              ? null
              : (widget.currentProfile.uid.isEmpty
                    ? '__missing_uid__'
                    : widget.currentProfile.uid),
        )
        .listen((projects) {
          if (mounted) setState(() => _projects = projects);
        });
    if (_canCreate) {
      _peopleSubscription = FirebaseRepository.instance.watchPeople().listen((
        people,
      ) {
        if (mounted) {
          setState(
            () => _people = people.where((person) => person.isActive).toList(),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _projectsSubscription?.cancel();
    _peopleSubscription?.cancel();
    _minimumController.dispose();
    _maximumController.dispose();
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
                        tela: 'P R O J E T O S',
                        title: 'Gestão de Projetos',
                        subtitle: 'Acompanhe e gerencie todos os projetos da empresa!',
                      ),
                      const SizedBox(height: 16),
                      _buildFilters(),
                      Expanded(
                        child: _filteredProjects.isEmpty
                            ? Center(
                                child: Text(
                                  _canCreate
                                      ? 'Nenhum projeto cadastrado.'
                                      : 'Você ainda não participa de nenhum projeto.',
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.only(
                                  top: 12,
                                  bottom: isWide ? 34 : 100,
                                ),
                                itemCount: _filteredProjects.length,
                                itemBuilder: (context, index) =>
                                    _buildProjectCard(_filteredProjects[index]),
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
    floatingActionButton: _canCreate
        ? FloatingActionButton.extended(
            onPressed: _openProjectForm,
            icon: const Icon(Icons.add),
            label: const Text('Novo projeto'),
          )
        : null,
    bottomNavigationBar: AppBottomNav(
      currentTab: AppTab.projetos,
      profile: widget.currentProfile,
    ),
  );
}

Widget _buildFilters() => Theme(
  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
  child: ExpansionTile(
    title: Text(
      'Filtros de busca',
      style: AppTextStyles.body.copyWith(
        color: AppColors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
    leading: const Icon(Icons.filter_alt_outlined, color: AppColors.white),
    iconColor: AppColors.white,
    collapsedIconColor: AppColors.white,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Área',
                      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.white),
                    ),
                    dropdownColor: const Color(0xFF0F142C),
                    style: AppTextStyles.caption.copyWith(color: AppColors.white),
                    initialValue: _areaFilter,
                    items: _areas
                        .map(
                          (area) => DropdownMenuItem(value: area, child: Text(area)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _areaFilter = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Status',
                      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.white),
                    ),
                    dropdownColor: const Color(0xFF0F142C),
                    style: AppTextStyles.caption.copyWith(color: AppColors.white),
                    initialValue: _statusFilter,
                    items: _statuses
                        .map(
                          (status) => DropdownMenuItem(value: status, child: Text(status)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _statusFilter = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minimumController,
                    onChanged: (_) => setState(() {}),
                    style: AppTextStyles.caption.copyWith(color: AppColors.white),
                    decoration: InputDecoration(
                      labelText: 'Valor mínimo',
                      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maximumController,
                    onChanged: (_) => setState(() {}),
                    style: AppTextStyles.caption.copyWith(color: AppColors.white),
                    decoration: InputDecoration(
                      labelText: 'Valor máximo',
                      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.white),
                    ),
                  ),
                ),
              ],
            ),
            
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() {
                  _areaFilter = null;
                  _statusFilter = null;
                  _minimumController.clear();
                  _maximumController.clear();
                }),
                child: Text(
                  'Limpar filtros',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);

  Widget _buildProjectCard(Project project) => Card(
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: project.color.withAlpha(24),
        child: Icon(Icons.folder_outlined, color: project.color),
      ),
      title: Text(
        project.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${project.area} • ${project.status} • ${project.members}',
      ),
      trailing: Text(project.value),
    ),
  );

  Future<void> _openProjectForm() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NewProjectSheet(
        currentProfile: widget.currentProfile,
        initialArea: _areas.first,
        initialManagerId: '',
        initialStatus: _statuses.first,
        initialSelectedMemberIds: {widget.currentProfile.uid},
        people: _people,
        areas: _areas,
        statuses: _statuses,
      ),
    );
  }
}

class _NewProjectSheet extends StatefulWidget {
  const _NewProjectSheet({
    required this.currentProfile,
    required this.initialArea,
    required this.initialManagerId,
    required this.initialStatus,
    required this.initialSelectedMemberIds,
    required this.people,
    required this.areas,
    required this.statuses,
  });

  final UserProfile currentProfile;
  final String initialArea;
  final String initialManagerId;
  final String initialStatus;
  final Set<String> initialSelectedMemberIds;
  final List<PersonRecord> people;
  final List<String> areas;
  final List<String> statuses;

  @override
  State<_NewProjectSheet> createState() => _NewProjectSheetState();
}

class _NewProjectSheetState extends State<_NewProjectSheet> {
  late final TextEditingController _nameController = TextEditingController();
  late final TextEditingController _clientController = TextEditingController();
  late final TextEditingController _valueController = TextEditingController();

  late String _area = widget.initialArea;
  late String _managerId = widget.initialManagerId;
  late String _status = widget.initialStatus;
  late final Set<String> _selectedMemberIds =
      Set<String>.from(widget.initialSelectedMemberIds);
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty || _selectedMemberIds.isEmpty) {
      setState(
        () => _formError = 'Informe o nome e selecione ao menos uma pessoa.',
      );
      return;
    }

    PersonRecord? manager;
    for (final person in widget.people) {
      if (person.uid == _managerId) {
        manager = person;
        break;
      }
    }

    final value =
        double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0;

    try {
      await FirebaseRepository.instance.saveProject(
        data: {
          'name': _nameController.text.trim(),
          'client': _clientController.text.trim(),
          'area': _area,
          'manager': manager?.name ?? widget.currentProfile.name,
          'managerId': _managerId.isEmpty ? widget.currentProfile.uid : _managerId,
          'memberIds': _selectedMemberIds.toList(),
          'members': '${_selectedMemberIds.length} pessoas',
          'value': 'R\$ ${value.toStringAsFixed(2)}',
          'progress': 0,
          'status': _status,
          'color': '087E8B',
          'createdBy': widget.currentProfile.uid,
        },
      );

      if (!mounted) return;

      final messenger = ScaffoldMessenger.maybeOf(context);
      FocusScope.of(context).unfocus();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (messenger != null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Projeto cadastrado com sucesso.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _formError =
            'Não foi possível cadastrar o projeto. Verifique sua permissão e tente novamente.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Novo projeto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome do projeto'),
            ),
            TextField(
              controller: _clientController,
              decoration: const InputDecoration(labelText: 'Cliente'),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Área responsável',
              ),
              initialValue: _area,
              items: widget.areas
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _area = value!),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Gerente'),
              initialValue: _managerId.isEmpty ? null : _managerId,
              items: widget.people
                  .map(
                    (person) => DropdownMenuItem(
                      value: person.uid,
                      child: Text(person.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _managerId = value ?? ''),
            ),
            const SizedBox(height: 12),
            const Text('Equipe'),
            Wrap(
              spacing: 8,
              children: widget.people
                  .map(
                    (person) => FilterChip(
                      label: Text(person.name),
                      selected: _selectedMemberIds.contains(person.uid),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedMemberIds.add(person.uid);
                        } else {
                          _selectedMemberIds.remove(person.uid);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Status'),
              initialValue: _status,
              items: widget.statuses
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _status = value!),
            ),
            TextField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
            const SizedBox(height: 16),
            if (_formError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _formError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Cadastrar projeto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
