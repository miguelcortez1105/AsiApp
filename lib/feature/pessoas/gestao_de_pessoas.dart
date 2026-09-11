import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../perfil/perfil_screen.dart';
import '../core/data/firebase_repository.dart';
import 'package:asiapp_mobile/feature/core/theme/app_colors.dart';
import 'package:asiapp_mobile/feature/core/widgets/app_header.dart';
import '../core/widgets/app_bottom_nav.dart';
import '../core/widgets/app_background.dart';
import '../core/theme/app_text_styles.dart';

const _ink = Color(0xFF17212B);
const _muted = Color(0xFF6E7A86);
const _teal = Color(0xFF087E8B);
const _coral = Color(0xFFE76F51);


const _roles = [
	'Administrador',
	'Presidência',
	'Vice-Presidência',
	'Diretoria',
	'Gerência',
	'Membro',
];
const _roles = Hierarchy.roles;

class PersonRecord {
  const PersonRecord({
    required this.name,
    required this.email,
    required this.role,
    required this.area,
    this.isActive = true,
    this.uid = '',
  });

  final String name;
  final String email;
  final String role;
  final String area;
  final bool isActive;
  final String uid;

  factory PersonRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    return PersonRecord(
      uid: document.id,
      name: data['name'] as String? ?? 'Usuário',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'Membro',
      area: data['area'] as String? ?? 'Outros',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'role': role,
        'area': area,
        'isActive': isActive,
      };

  PersonRecord copyWith({String? role, bool? isActive}) => PersonRecord(
    name: name,
    email: email,
    role: role ?? this.role,
    area: area,
    isActive: isActive ?? this.isActive,
    uid: uid,
  );
}

class GestaoDePessoas extends StatefulWidget {
  const GestaoDePessoas({super.key, required this.currentProfile});

  final UserProfile currentProfile;

  @override
  State<GestaoDePessoas> createState() => _GestaoDePessoasState();
}

//dados_mockados

class _GestaoDePessoasState extends State<GestaoDePessoas> {
  final List<PersonRecord> _people = [
    const PersonRecord(
      name: 'Miguel Cortez',
      email: 'miguelcortez@asimovjr.com.br',
      role: 'Presidência',
      area: 'Executivo',
    ),
    const PersonRecord(
      name: 'Leticia Cortez',
      email: 'leticiacortez@asimovjr.com.br',
      role: 'Diretoria',
      area: 'Operações',
    ),
    const PersonRecord(
      name: 'Leticia Cavalcante',
      email: 'leticiacavalcante@asimovjr.com.br',
      role: 'Gerência',
      area: 'Operações',
    ),
    const PersonRecord(
      name: 'Miguel Cavalcante',
      email: 'miguelcavalcante@asimovjr.com.br',
      role: 'Membro',
      area: 'Operações',
    ),
    const PersonRecord(
      name: 'Joao',
      email: 'joao@asimovjr.com.br',
      role: 'Diretoria',
      area: 'Tecnologia',
    ),
    const PersonRecord(
      name: 'Joao Cavalcante',
      email: 'joaocavalcante@asimovjr.com.br',
      role: 'Membro',
      area: 'Tecnologia',
      isActive: false,
    ),
    const PersonRecord(
      name: 'Miguel',
      email: 'Miguel@asimovjr.com.br',
      role: 'Gerência',
      area: 'Pessoas',
    ),
    const PersonRecord(
      name: 'João Cortez',
      email: 'joaocortez@asimovjr.com.br',
      role: 'Membro',
      area: 'Pessoas',
    ),
  ];
  StreamSubscription<List<PersonRecord>>? _peopleSubscription;

  String _selectedArea = 'Todas';

  bool get _canEdit => Hierarchy.canAssignRole(widget.currentProfile.role);

//cargos

	String _selectedArea = 'Todas';
  @override
  void initState() {
    super.initState();
    _peopleSubscription = FirebaseRepository.instance.watchPeople().listen(
      (loadedPeople) {
        if (loadedPeople.isNotEmpty && mounted) {
          setState(() {
            _people
              ..clear()
              ..addAll(loadedPeople);
          });
        }
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _peopleSubscription?.cancel();
    super.dispose();
  }

  List<String> get _areas => [
    'Todas',
    ...{..._people.map((person) => person.area)}.toList()..sort(),
  ];

  List<PersonRecord> get _filteredPeople => _selectedArea == 'Todas'
      ? _people
      : _people.where((person) => person.area == _selectedArea).toList();

  @override
Widget build(BuildContext context) {
  final groupedPeople = <String, List<PersonRecord>>{};
  for (final person in _filteredPeople) {
    groupedPeople.putIfAbsent(person.area, () => []).add(person);
  }

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
                      _buildHeader(),
                      const SizedBox(height: 22),
                      _buildHierarchyCard(),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Pessoas por área',
                              style: AppTextStyles.body.copyWith(color: AppColors.white),
                            ),
                          ),
                          SizedBox(
                            width: 180,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedArea,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0F142C),
                              style: AppTextStyles.body.copyWith(color: AppColors.white),
                              decoration: InputDecoration(
                                labelText: 'Área',
                                labelStyle: AppTextStyles.caption.copyWith(color: AppColors.white),
                                isDense: true,
                              ),
                              items: _areas
                                  .map(
                                    (area) => DropdownMenuItem(
                                      value: area,
                                      child: Text(
                                        area,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (area) {
                                if (area != null) {
                                  setState(() => _selectedArea = area);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (groupedPeople.isEmpty)
                        Text(
                          'Nenhuma pessoa encontrada nesta área.',
                          style: AppTextStyles.body.copyWith(color: AppColors.white),
                        )
                      else
                        ...groupedPeople.entries.map(
                          (entry) => _buildAreaSection(entry.key, entry.value),
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
      currentTab: AppTab.pessoas,
      profile: widget.currentProfile,
    ),
  );
}

//estrutura e hierarquia

	Widget _buildHeader() => Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					const Text(
						'ESTRUTURA ORGANIZACIONAL',
						style: TextStyle(
							color: _teal,
							fontSize: 12,
							fontWeight: FontWeight.w800,
							letterSpacing: 1.4,
						),
					),
					const SizedBox(height: 8),
					const Text(
						'Pessoas e hierarquia',
						style: TextStyle(
							color: _ink,
							fontSize: 30,
							fontWeight: FontWeight.w800,
						),
					),
					const SizedBox(height: 8),
					Text(
						_canEdit
								? 'Você pode atualizar cargo e status dos membros.'
								: 'Todos podem consultar cargos, áreas e status. A edição é restrita às lideranças autorizadas.',
						style: const TextStyle(color: _muted, fontSize: 15),
					),
				],
			);
  Widget _buildHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const ScreenHeader(
        tela: 'G E S T Ã O',
        title: 'Gestão de Pessoas',
        subtitle: 'Acompanhe e gerencie todos os membros da empresa!',
      ),
      const SizedBox(height: 8),
      Text(
        _canEdit
            ? 'Você pode atualizar cargo e status dos membros.'
            : 'Todos podem consultar cargos, áreas e status. A edição é restrita às lideranças autorizadas.',
        style: AppTextStyles.caption.copyWith(color: AppColors.white),
      ),
    ],
  );

  Widget _buildHierarchyCard() => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hierarquia de acesso',
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              _roles.length,
              (index) => _RoleChip(
                role: _roles[index],
                level: index + 1,
                canEdit: Hierarchy.canManagePeople(_roles[index]),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Edição de cargo e status: Gerência da área, Vice-Presidência e Diretoria.',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
        ],
      ),
    ),
  );

  Widget _buildAreaSection(String area, List<PersonRecord> people) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          area,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${people.length} ${people.length == 1 ? 'pessoa' : 'pessoas'}',
        ),
        children: people.map((person) => _buildPersonTile(person)).toList(),
      ),
    ),
  );

  Widget _buildPersonTile(PersonRecord person) => ListTile(
    leading: CircleAvatar(
      backgroundColor: person.isActive
          ? _teal.withAlpha(24)
          : _muted.withAlpha(24),
      child: Text(
        _initials(person.name),
        style: TextStyle(
          color: person.isActive ? _teal : _muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    title: Text(person.name),
    subtitle: Text('${person.role}  •  ${person.area}\n${person.email}'),
    isThreeLine: true,
    trailing: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Chip(
          label: Text(person.isActive ? 'Ativo' : 'Inativo'),
          labelStyle: TextStyle(
            color: person.isActive ? _teal : _muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          backgroundColor: person.isActive
              ? _teal.withAlpha(18)
              : _muted.withAlpha(18),
          side: BorderSide.none,
        ),
        if (_canEdit)
          IconButton(
            tooltip: 'Editar pessoa',
            onPressed: () => _editPerson(person),
            icon: const Icon(Icons.edit_outlined),
          ),
      ],
    ),
  );

  Future<void> _editPerson(PersonRecord person) async {
    var selectedRole = person.role;
    var isActive = person.isActive;
    final updated = await showDialog<PersonRecord>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Editar ${person.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Cargo'),
                items: _roles
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: (role) {
                  if (role != null) setDialogState(() => selectedRole = role);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Membro ativo'),
                value: isActive,
                onChanged: (value) => setDialogState(() => isActive = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                person.copyWith(role: selectedRole, isActive: isActive),
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (updated == null || !mounted) return;
    final index = _people.indexOf(person);
    setState(() => _people[index] = updated);
    if (updated.uid.isNotEmpty) {
      await FirebaseRepository.instance.savePerson(updated);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.role,
    required this.level,
    required this.canEdit,
  });

  final String role;
  final int level;
  final bool canEdit;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: CircleAvatar(
      radius: 10,
      backgroundColor: canEdit ? _coral : _teal,
      child: Text(
        '$level',
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    ),
    label: Text(role),
    side: BorderSide(
      color: canEdit ? _coral.withAlpha(90) : _teal.withAlpha(90),
    ),
    backgroundColor: canEdit ? _coral.withAlpha(12) : _teal.withAlpha(12),
  );
}
