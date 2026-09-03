import 'dart:async';

import 'package:flutter/material.dart';

import '../core/data/firebase_repository.dart';
import '../home/home_page.dart';
import '../mngmt/gestao_de_pessoas.dart';
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

  bool get _canCreate => Hierarchy.canManageProjects(widget.currentProfile.role);

  List<Project> get _filteredProjects => _projects.where((project) {
        final minimum = double.tryParse(
              _minimumController.text.replaceAll(',', '.'),
            ) ??
            0;
        final maximum = double.tryParse(
              _maximumController.text.replaceAll(',', '.'),
            ) ??
            double.infinity;
        final areaMatches = _areaFilter == null || project.area == _areaFilter;
        final statusMatches =
            _statusFilter == null || project.status == _statusFilter;
        final value = _projectValue(project.value);
        return areaMatches && statusMatches && value >= minimum && value <= maximum;
      }).toList();

  double _projectValue(String value) =>
      double.tryParse(value.replaceAll(RegExp(r'[^0-9,.]'), '').replaceAll(',', '.')) ?? 0;

  @override
  void initState() {
    super.initState();
    _projectsSubscription = FirebaseRepository.instance
        .watchProjects(memberId: _canCreate ? null : widget.currentProfile.uid)
        .listen((projects) {
      if (mounted) setState(() => _projects = projects);
    });
    if (_canCreate) {
      _peopleSubscription = FirebaseRepository.instance.watchPeople().listen((people) {
        if (mounted) {
          setState(() => _people = people.where((person) => person.isActive).toList());
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
      appBar: AppBar(title: const Text('Meus projetos')),
      body: Column(
        children: [
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
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredProjects.length,
                    itemBuilder: (context, index) =>
                        _buildProjectCard(_filteredProjects[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: _canCreate
          ? FloatingActionButton.extended(
              onPressed: _openProjectForm,
              icon: const Icon(Icons.add),
              label: const Text('Novo projeto'),
            )
          : null,
    );
  }

  Widget _buildFilters() => ExpansionTile(
        title: const Text('Filtros de busca'),
        leading: const Icon(Icons.filter_alt_outlined),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Área'),
                        initialValue: _areaFilter,
                        items: _areas
                            .map((area) => DropdownMenuItem(
                                  value: area,
                                  child: Text(area),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _areaFilter = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Status'),
                        initialValue: _statusFilter,
                        items: _statuses
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _statusFilter = value),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minimumController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'Valor mínimo'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maximumController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'Valor máximo'),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _areaFilter = null;
                    _statusFilter = null;
                    _minimumController.clear();
                    _maximumController.clear();
                  }),
                  child: const Text('Limpar filtros'),
                ),
              ],
            ),
          ),
        ],
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
          subtitle: Text('${project.area} • ${project.status} • ${project.members}'),
          trailing: Text(project.value),
        ),
      );

  Future<void> _openProjectForm() async {
    final nameController = TextEditingController();
    final clientController = TextEditingController();
    final valueController = TextEditingController();
    var area = _areas.first;
    var managerId = '';
    var status = _statuses.first;
    final selectedMemberIds = <String>{widget.currentProfile.uid};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
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
                Text('Novo projeto', style: Theme.of(context).textTheme.titleLarge),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome do projeto'),
                ),
                TextField(
                  controller: clientController,
                  decoration: const InputDecoration(labelText: 'Cliente'),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Área responsável'),
                  initialValue: area,
                  items: _areas
                      .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) => setSheetState(() => area = value!),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Gerente'),
                  initialValue: managerId.isEmpty ? null : managerId,
                  items: _people
                      .map((person) => DropdownMenuItem(
                            value: person.uid,
                            child: Text(person.name),
                          ))
                      .toList(),
                  onChanged: (value) => setSheetState(() => managerId = value ?? ''),
                ),
                const SizedBox(height: 12),
                const Text('Equipe'),
                Wrap(
                  spacing: 8,
                  children: _people
                      .map((person) => FilterChip(
                            label: Text(person.name),
                            selected: selectedMemberIds.contains(person.uid),
                            onSelected: (selected) => setSheetState(() {
                              if (selected) {
                                selectedMemberIds.add(person.uid);
                              } else {
                                selectedMemberIds.remove(person.uid);
                              }
                            }),
                          ))
                      .toList(),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Status'),
                  initialValue: status,
                  items: _statuses
                      .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) => setSheetState(() => status = value!),
                ),
                TextField(
                  controller: valueController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Valor'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty || selectedMemberIds.isEmpty) {
                        return;
                      }
                      PersonRecord? manager;
                      for (final person in _people) {
                        if (person.uid == managerId) manager = person;
                      }
                      final value = double.tryParse(
                            valueController.text.replaceAll(',', '.'),
                          ) ??
                          0;
                      await FirebaseRepository.instance.saveProject(data: {
                        'name': nameController.text.trim(),
                        'client': clientController.text.trim(),
                        'area': area,
                        'manager': manager?.name ?? widget.currentProfile.name,
                        'managerId': managerId.isEmpty
                            ? widget.currentProfile.uid
                            : managerId,
                        'memberIds': selectedMemberIds.toList(),
                        'members': '${selectedMemberIds.length} pessoas',
                        'value': 'R\$ ${value.toStringAsFixed(2)}',
                        'progress': 0,
                        'status': status,
                        'color': '087E8B',
                        'createdBy': widget.currentProfile.uid,
                      });
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    child: const Text('Cadastrar projeto'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    nameController.dispose();
    clientController.dispose();
    valueController.dispose();
  }
}
