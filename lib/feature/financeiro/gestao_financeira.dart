import 'dart:async';
import 'package:asiapp_mobile/feature/core/widgets/app_background.dart';
import 'package:asiapp_mobile/feature/core/widgets/app_header.dart';
import 'package:asiapp_mobile/feature/core/widgets/app_bottom_nav.dart';
import 'package:asiapp_mobile/feature/core/theme/app_colors.dart';
import 'package:asiapp_mobile/feature/core/theme/app_text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../perfil/perfil_screen.dart';
import '../core/data/firebase_repository.dart';

const _green = Color(0xFF6FD8C0);
const _borderOnDark = Color(0x33FFFFFF); 

enum _EntryType { entrada, saida }

class _FinancialEntry {
  const _FinancialEntry({
    required this.title,
    required this.supplier,
    required this.category,
    required this.date,
    required this.amount,
    required this.type,
    this.attachment,
  });
  final String title;
  final String supplier;
  final String category;
  final DateTime date;
  final double amount;
  final _EntryType type;
  final String? attachment;

  factory _FinancialEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    return _FinancialEntry(
      title: data['title'] as String? ?? 'Lançamento',
      supplier: data['supplier'] as String? ?? 'Não informado',
      category: data['category'] as String? ?? 'Outros',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      type: data['type'] == 'entrada' ? _EntryType.entrada : _EntryType.saida,
      attachment: data['attachment'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'supplier': supplier,
        'category': category,
        'date': Timestamp.fromDate(date),
        'amount': amount,
        'type': type == _EntryType.entrada ? 'entrada' : 'saida',
        'attachment': attachment,
      };
}

class GestaoFinanceira extends StatefulWidget {
  const GestaoFinanceira({super.key, required this.currentProfile});
  final UserProfile currentProfile;

  @override
  State<GestaoFinanceira> createState() => _GestaoFinanceiraState();
}

class _GestaoFinanceiraState extends State<GestaoFinanceira> {
  int _tabIndex = 0;
  DateTime _focusedMonth = DateTime(2026, 9);
  String _typeFilter = 'Todos';
  String _categoryFilter = 'Todas';
  String _supplierFilter = 'Todos';
  String _valueFilter = 'Todos';
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _entriesSubscription;

  final List<_FinancialEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _entriesSubscription = FirebaseFirestore.instance
        .collection('financial_entries')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(snapshot.docs.map(_FinancialEntry.fromFirestore));
      });
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _entriesSubscription?.cancel();
    super.dispose();
  }

  // TEMPORARIO: remover o cargo Desenvolvedor quando o controle real de cargos estiver integrado.
  bool get _isAllowed => Hierarchy.canViewFinance(widget.currentProfile.role);
  double get _totalEntries => _entries
      .where((entry) => entry.type == _EntryType.entrada)
      .fold(0, (total, entry) => total + entry.amount);
  double get _totalExits => _entries
      .where((entry) => entry.type == _EntryType.saida)
      .fold(0, (total, entry) => total + entry.amount);
  List<_FinancialEntry> get _filteredEntries => _entries.where((entry) {
    final type =
        _typeFilter == 'Todos' ||
        (_typeFilter == 'Entradas' && entry.type == _EntryType.entrada) ||
        (_typeFilter == 'Saídas' && entry.type == _EntryType.saida);
    final category =
        _categoryFilter == 'Todas' || entry.category == _categoryFilter;
    final supplier =
        _supplierFilter == 'Todos' || entry.supplier == _supplierFilter;
    final value =
        _valueFilter == 'Todos' ||
        (_valueFilter == 'Até R\$ 2 mil' && entry.amount <= 2000) ||
        (_valueFilter == 'Acima de R\$ 2 mil' && entry.amount > 2000);
    return type && category && supplier && value;
  }).toList();

  @override
  Widget build(BuildContext context) {
    if (!_isAllowed) return _buildAccessDenied();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth >= 900 ? 48 : 20,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1160),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ScreenHeader(
                        tela: 'F I N A N C E I R O',
                        title: 'Gestão Financeira',
                        subtitle: 'Acompanhe e gerencie todas as financias da empresa!',
                      ),
                      const SizedBox(height: 16),
                      _buildTabs(),
                      const SizedBox(height: 8),
                      if (_tabIndex == 0)
                        _buildCalendarTab()
                      else if (_tabIndex == 1)
                        _buildEntriesTab()
                      else
                        _buildReportsTab(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _tabIndex == 1 ? _buildCreateEntryButton() : null,
      bottomNavigationBar: AppBottomNav(
        currentTab: AppTab.financeiro,
        profile: widget.currentProfile,
      ),
    );
  }

  Widget _buildCreateEntryButton() => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(28),
    elevation: 4,
    child: InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: _showEntryDialog,
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
              'Novo lançamento',
              style: AppTextStyles.button.copyWith(color: AppColors.white),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildAccessDenied() => Scaffold(
    backgroundColor: AppColors.ink,
    appBar: AppBar(
      title: Text(
        'Gestão financeira',
        style: AppTextStyles.h2.copyWith(color: AppColors.white),
      ),
      backgroundColor: AppColors.ink,
      foregroundColor: AppColors.white,
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 52, color: AppColors.coral),
            const SizedBox(height: 16),
            Text(
              'Acesso restrito',
              style: AppTextStyles.h1.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta área está disponível apenas para a Presidência e a Diretoria.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: Text('Voltar', style: AppTextStyles.button),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildTabs() => Container(
    decoration: BoxDecoration(
      color: AppColors.primaryDark,
      border: Border.all(color: _borderOnDark),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        _tab('Calendário', Icons.calendar_month_outlined, 0),
        _tab('Lançamentos', Icons.swap_vert_rounded, 1),
        _tab('Relatórios', Icons.bar_chart_rounded, 2),
      ],
    ),
  );
  Expanded _tab(String label, IconData icon, int index) => Expanded(
    child: InkWell(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _tabIndex == index ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: _tabIndex == index ? AppColors.white : AppColors.muted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: _tabIndex == index ? AppColors.white : AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildCalendarTab() => Column(
    children: [
      const SizedBox(height: 20),
      _panel(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(
                    () => _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month - 1,
                    ),
                  ),
                  icon: const Icon(Icons.chevron_left, color: AppColors.white),
                ),
                Expanded(
                  child: Text(
                    _monthLabel(_focusedMonth),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(
                    () => _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month + 1,
                    ),
                  ),
                  icon: const Icon(Icons.chevron_right, color: AppColors.white),
                ),
              ],
            ),
            _buildCalendarGrid(),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _sectionTitle('Próximos compromissos'),
      const SizedBox(height: 10),
      if (_entries.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Nenhum lançamento encontrado.',
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          ),
        )
      else
        ..._entries
            .where((entry) => entry.date.isAfter(DateTime.now()))
            .map(_entryTile),
    ],
  );

  Widget _buildCalendarGrid() {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final days = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final offset = first.weekday - 1;
    return Column(
      children: [
        Row(
          children: ['S', 'T', 'Q', 'Q', 'S', 'S', 'D']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: offset + days,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            if (index < offset) return const SizedBox();
            final day = index - offset + 1;
            final entries = _entries
                .where(
                  (entry) =>
                      entry.date.year == _focusedMonth.year &&
                      entry.date.month == _focusedMonth.month &&
                      entry.date.day == day,
                )
                .toList();
            final color = entries.isEmpty
                ? AppColors.primaryDark
                : entries.first.type == _EntryType.entrada
                ? _green.withAlpha(24)
                : AppColors.coral.withAlpha(24);
            return Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  if (entries.isNotEmpty)
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: entries.first.type == _EntryType.entrada
                          ? _green
                          : AppColors.coral,
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEntriesTab() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 24),
      _buildEntryFilters(),
      const SizedBox(height: 18),
      if (_filteredEntries.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Nenhum lançamento encontrado.',
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          ),
        )
      else
        ..._filteredEntries.map(_entryTile),
    ],
  );

  Widget _buildEntryFilters() => Theme(
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
                    child: _filter('Tipo', _typeFilter, [
                      'Todos',
                      'Entradas',
                      'Saídas',
                    ], (value) => setState(() => _typeFilter = value!)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _filter('Valor', _valueFilter, [
                      'Todos',
                      'Até R\$ 2 mil',
                      'Acima de R\$ 2 mil',
                    ], (value) => setState(() => _valueFilter = value!)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _filter(
                      'Fornecedor',
                      _supplierFilter,
                      [
                        'Todos',
                        ...{..._entries.map((entry) => entry.supplier)},
                      ],
                      (value) => setState(() => _supplierFilter = value!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _filter(
                      'Categoria',
                      _categoryFilter,
                      [
                        'Todas',
                        ...{..._entries.map((entry) => entry.category)},
                      ],
                      (value) => setState(() => _categoryFilter = value!),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() {
                    _typeFilter = 'Todos';
                    _valueFilter = 'Todos';
                    _supplierFilter = 'Todos';
                    _categoryFilter = 'Todas';
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

  Widget _buildReportsTab() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 24),
      _sectionTitle('Fluxo de caixa'),
      const SizedBox(height: 10),
      _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _monthLabel(DateTime.now()),
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            _reportLine('Entradas', _totalEntries, _green),
            const SizedBox(height: 14),
            _reportLine('Saídas', _totalExits, AppColors.coral),
            Divider(color: _borderOnDark),
            _reportLine(
              'Saldo projetado',
              _totalEntries - _totalExits,
              AppColors.primary,
              strong: true,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _sectionTitle('Categorias com maior impacto'),
      const SizedBox(height: 10),
      ...['Faturamento', 'Operacional', 'Impostos'].map((category) {
        final total = _entries
            .where((entry) => entry.category == category)
            .fold(0.0, (total, entry) => total + entry.amount);
        return _reportLine(
          category,
          total,
          category == 'Faturamento' ? _green : AppColors.coral,
        );
      }),
    ],
  );

  Widget _entryTile(_FinancialEntry entry) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: _panel(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor:
              (entry.type == _EntryType.entrada ? _green : AppColors.coral)
                  .withAlpha(24),
          foregroundColor:
              entry.type == _EntryType.entrada ? _green : AppColors.coral,
          child: Icon(
            entry.type == _EntryType.entrada
                ? Icons.arrow_downward
                : Icons.arrow_upward,
          ),
        ),
        title: Text(
          entry.title,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        subtitle: Text(
          '${entry.supplier}  •  ${entry.category}\n${_dateLabel(entry.date)}${entry.attachment == null ? '' : '  •  ${entry.attachment}'}',
          style: AppTextStyles.caption.copyWith(color: AppColors.muted),
        ),
        trailing: Text(
          '${entry.type == _EntryType.entrada ? '+' : '-'} R\$ ${entry.amount.toStringAsFixed(2).replaceAll('.', ',')}',
          style: AppTextStyles.body.copyWith(
            color: entry.type == _EntryType.entrada ? _green : AppColors.coral,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );

  Widget _reportLine(
    String label,
    double value,
    Color color, {
    bool strong = false,
  }) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: strong ? AppColors.white : AppColors.muted,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
      Text(
        'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}',
        style: AppTextStyles.body.copyWith(
          color: color,
          fontSize: strong ? 18 : 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
  Widget _sectionTitle(String title) => Text(
    title,
    style: AppTextStyles.h2.copyWith(
      color: AppColors.white,
      fontSize: 19,
      fontWeight: FontWeight.w800,
    ),
  );
  Widget _panel({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.primaryDark,
      border: Border.all(color: _borderOnDark),
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
  Widget _filter(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.white),
    ),
    dropdownColor: AppColors.ink,
    style: AppTextStyles.caption.copyWith(color: AppColors.white),
    items: options
        .map(
          (option) => DropdownMenuItem(
            value: option,
            child: Text(option, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: onChanged,
  );

  InputDecoration _formFieldDecoration(String label, {String? prefixText}) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Colors.black, width: 1.2),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.white),
      prefixText: prefixText,
      prefixStyle: AppTextStyles.body.copyWith(color: AppColors.white),
      filled: true,
      fillColor: Colors.transparent,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.black, width: 1.6),
      ),
    );
  }

  Future<void> _showEntryDialog() async {
    final title = TextEditingController();
    final supplier = TextEditingController();
    final amount = TextEditingController();
    var type = _EntryType.saida;
    var category = 'Operacional';
    var date = DateTime.now();
    String? attachment;
    final result = await showDialog<_FinancialEntry>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.primaryDark,
          title: Text(
            'Novo lançamento',
            style: AppTextStyles.h2.copyWith(color: AppColors.white),
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    style: AppTextStyles.body.copyWith(color: AppColors.white),
                    decoration: _formFieldDecoration('Descrição'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: supplier,
                    style: AppTextStyles.body.copyWith(color: AppColors.white),
                    decoration: _formFieldDecoration('Fornecedor / cliente'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppTextStyles.body.copyWith(color: AppColors.white),
                    decoration: _formFieldDecoration('Valor', prefixText: 'R\$ '),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<_EntryType>(
                    initialValue: type,
                    decoration: _formFieldDecoration('Tipo'),
                    dropdownColor: AppColors.ink,
                    style: AppTextStyles.caption.copyWith(color: AppColors.white),
                    items: const [
                      DropdownMenuItem(
                        value: _EntryType.entrada,
                        child: Text('Entrada / faturamento'),
                      ),
                      DropdownMenuItem(
                        value: _EntryType.saida,
                        child: Text('Saída / pagar'),
                      ),
                    ],
                    onChanged: (value) => setDialogState(() => type = value!),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: _formFieldDecoration('Categoria'),
                    dropdownColor: AppColors.ink,
                    style: AppTextStyles.caption.copyWith(color: AppColors.white),
                    items:
                        const [
                              'Faturamento',
                              'Operacional',
                              'Impostos',
                              'Pessoal',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) =>
                        setDialogState(() => category = value!),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.black, width: 1.2),
                    ),
                    tileColor: Colors.transparent,
                    title: Text(
                      'Data: ${_dateLabel(date)}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.white),
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined, color: AppColors.white),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDate: date,
                      );
                      if (picked != null) setDialogState(() => date = picked);
                    },
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => setDialogState(
                      () => attachment =
                          'comprovante_${DateTime.now().millisecondsSinceEpoch}.pdf',
                    ),
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      attachment == null
                          ? 'Anexar nota ou comprovante'
                          : attachment!,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: AppTextStyles.button.copyWith(color: AppColors.white),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              onPressed: () {
                final parsedAmount = double.tryParse(
                  amount.text.replaceAll(',', '.'),
                );
                if (title.text.trim().isEmpty ||
                    supplier.text.trim().isEmpty ||
                    parsedAmount == null) {
                  return;
                }
                Navigator.pop(
                  context,
                  _FinancialEntry(
                    title: title.text.trim(),
                    supplier: supplier.text.trim(),
                    category: category,
                    date: date,
                    amount: parsedAmount,
                    type: type,
                    attachment: attachment,
                  ),
                );
              },
              child: const Text('Cadastrar'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    supplier.dispose();
    amount.dispose();
    if (result != null && mounted) {
      setState(() => _entries.insert(0, result));
      await FirebaseFirestore.instance
          .collection('financial_entries')
          .add(result.toFirestore());
    }
  }

  String _monthLabel(DateTime date) =>
      '${['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'][date.month - 1]} ${date.year}';
  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}