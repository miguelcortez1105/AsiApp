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

InputDecoration _formFieldDecoration(String label) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    borderSide: BorderSide(color: Colors.black, width: 1.2),
  );
  return InputDecoration(
    labelText: label,
    labelStyle: AppTextStyles.caption.copyWith(color: AppColors.white),
    filled: true,
    fillColor: Colors.transparent,
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: Colors.black, width: 1.6),
    ),
  );
}

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
  Project? _selectedProject; // projeto atualmente exibido
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

  // Garante que sempre exista um projeto válido selecionado dentro
  // do conjunto atualmente filtrado. Se o selecionado sair da lista
  // (por causa de um filtro), cai automaticamente para o primeiro.
  Project? get _displayedProject {
    final filtered = _filteredProjects;
    if (filtered.isEmpty) return null;
    final stillValid = _selectedProject != null &&
        filtered.any((project) => project.name == _selectedProject!.name);
    return stillValid ? _selectedProject : filtered.first;
  }

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
                      const SizedBox(height: 12),
                      _buildProjectSelector(),
                      Expanded(
                        child: _filteredProjects.isEmpty
                            ? Center(
                                child: Text(
                                  _canCreate
                                      ? 'Nenhum projeto cadastrado.'
                                      : 'Você ainda não participa de nenhum projeto.',
                                ),
                              )
                            : Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 440),
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      top: 12,
                                      bottom: isWide ? 34 : 100,
                                    ),
                                    child: _buildProjectCard(_displayedProject!),
                                  ),
                                ),
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
    floatingActionButton: _canCreate ? _buildCreateProjectButton() : null,
    bottomNavigationBar: AppBottomNav(
      currentTab: AppTab.projetos,
      profile: widget.currentProfile,
    ),
  );
}

Widget _buildCreateProjectButton() => Material(
  color: Colors.transparent,
  borderRadius: BorderRadius.circular(28),
  elevation: 4,
  child: InkWell(
    borderRadius: BorderRadius.circular(28),
    onTap: _openProjectForm,
    child: Ink(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primary,
            Color.alphaBlend(
              Colors.black.withValues(alpha: 0.8),
              AppColors.primary,
            ),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add, color: AppColors.white),
          const SizedBox(width: 8),
          Text(
            'Cadastrar projeto',
            style: AppTextStyles.button.copyWith(color: AppColors.white),
          ),
        ],
      ),
    ),
  ),
);

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
                  _selectedProject = null;
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

  Widget _buildProjectSelector() {
    final filtered = _filteredProjects;
    if (filtered.isEmpty) return const SizedBox.shrink();
    final selected = _displayedProject;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Projeto',
          labelStyle: AppTextStyles.caption.copyWith(color: AppColors.white),
        ),
        dropdownColor: const Color(0xFF0F142C),
        style: AppTextStyles.caption.copyWith(color: AppColors.white),
        initialValue: selected?.name,
        items: filtered
            .map(
              (project) => DropdownMenuItem(
                value: project.name,
                child: Text(project.name),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() {
          _selectedProject = filtered.firstWhere(
            (project) => project.name == value,
            orElse: () => filtered.first,
          );
        }),
      ),
    );
  }

  Widget _buildProjectCard(Project project) => Card(
    color: AppColors.primaryDark,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProjectField('Projeto', project.name),
          _buildProjectField('Gerente', project.manager),
          _buildProjectField('Área', project.area),
          _buildProjectField('Valor', project.value),
          _buildProjectField('Status', project.status),
          _buildActionsField('Ações', [
            _buildActionButton(
              icon: Icons.edit_outlined,
              color: AppColors.primary,
              onTap: () {},
            ),
            _buildActionButton(
              icon: Icons.delete_outline,
              color: AppColors.coral,
              onTap: () {},
            ),
          ]),
        ],
      ),
    ),
  );

  Widget _buildProjectField(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 88,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryDark, width: 1),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(color: AppColors.white),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildActionsField(String label, List<Widget> actions) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 88,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryDark, width: 1),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                actions[i],
              ],
            ],
          ),
        ),
      ],
    ),
  );

  // Botão de ação (editar/excluir): fundo colorido + ícone branco.
  // Por enquanto os taps não fazem nada (onTap vazio).
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.white, width: 1),
        ),
        child: Icon(icon, size: 18, color: AppColors.white),
      ),
    ),
  );

  Future<void> _openProjectForm() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              style: AppTextStyles.h2.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              style: AppTextStyles.body.copyWith(color: AppColors.white),
              decoration: _formFieldDecoration('Nome do projeto'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _clientController,
              style: AppTextStyles.body.copyWith(color: AppColors.white),
              decoration: _formFieldDecoration('Cliente'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              decoration: _formFieldDecoration('Área responsável'),
              dropdownColor: const Color(0xFF0F142C),
              style: AppTextStyles.caption.copyWith(color: AppColors.white),
              initialValue: _area,
              items: widget.areas
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _area = value!),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              decoration: _formFieldDecoration('Gerente'),
              dropdownColor: const Color(0xFF0F142C),
              style: AppTextStyles.caption.copyWith(color: AppColors.white),
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
            const SizedBox(height: 14),
            Text(
              'Equipe',
              style: AppTextStyles.body.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.black, width: 1.2),
                      ),
                      backgroundColor: AppColors.primaryDark,
                      selectedColor: AppColors.primary,
                      checkmarkColor: AppColors.white,
                      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.white),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              decoration: _formFieldDecoration('Status'),
              dropdownColor: const Color(0xFF0F142C),
              style: AppTextStyles.caption.copyWith(color: AppColors.white),
              initialValue: _status,
              items: widget.statuses
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _status = value!),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.body.copyWith(color: AppColors.white),
              decoration: _formFieldDecoration('Valor'),
            ),
            const SizedBox(height: 16),
            if (_formError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _formError!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.coral,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
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