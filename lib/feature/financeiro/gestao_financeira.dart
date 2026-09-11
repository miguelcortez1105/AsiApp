import 'dart:async';
import 'package:asiapp_mobile/feature/core/widgets/app_background.dart';
import 'package:asiapp_mobile/feature/core/widgets/app_header.dart';
import 'package:asiapp_mobile/feature/core/widgets/app_bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../perfil/perfil_screen.dart';
import '../core/data/firebase_repository.dart';

const _ink = Color(0xFFF4FAFF);
const _muted = Color(0xFFB5C8D8);
const _paper = Color(0xFF020A12);
const _surface = Color(0xFF0B2D4D);
const _line = Color(0xFF245274);
const _teal = Color(0xFF007FFF);  
const _coral = Color(0xFFFF6B6B);
const _green = Color(0xFF6FD8C0);

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
  DateTime _focusedMonth = DateTime(2026, 8);
  String _typeFilter = 'Todos';
  String _categoryFilter = 'Todas';
  String _supplierFilter = 'Todos';
  String _valueFilter = 'Todos';
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _entriesSubscription;

  final List<_FinancialEntry> _entries = [
    _FinancialEntry(
      title: 'Contrato Portal de Clientes',
      supplier: 'Cliente Portal',
      category: 'Faturamento',
      date: DateTime(2026, 8, 8),
      amount: 48000,
      type: _EntryType.entrada,
    ),
    _FinancialEntry(
      title: 'Mensalidade coworking',
      supplier: 'Hub Itajubá',
      category: 'Operacional',
      date: DateTime(2026, 8, 10),
      amount: 1850,
      type: _EntryType.saida,
      attachment: 'nota_coworking.pdf',
    ),
    _FinancialEntry(
      title: 'Serviços de contabilidade',
      supplier: 'Contábil Asimov',
      category: 'Impostos',
      date: DateTime(2026, 8, 15),
      amount: 920,
      type: _EntryType.saida,
      attachment: 'comprovante_contabil.jpg',
    ),
    _FinancialEntry(
      title: 'Expansão Asimov',
      supplier: 'Cliente Expansão',
      category: 'Faturamento',
      date: DateTime(2026, 8, 22),
      amount: 12000,
      type: _EntryType.entrada,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entriesSubscription = FirebaseFirestore.instance
        .collection('financial_entries')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || snapshot.docs.isEmpty) return;
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
                      _buildHeader(),
                      const SizedBox(height: 22),
                      _buildTabs(),
                      const SizedBox(height: 24),
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
      floatingActionButton: _tabIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _showEntryDialog,
              icon: const Icon(Icons.add),
              label: const Text('Novo lançamento'),
              backgroundColor: _teal,
              foregroundColor: _ink,
            )
          : null,
      bottomNavigationBar: AppBottomNav(
        currentTab: AppTab.financeiro,
        profile: widget.currentProfile,
      ),
    );
  }

  Widget _buildAccessDenied() => Scaffold(
    backgroundColor: _paper,
    appBar: AppBar(
      title: const Text('Gestão financeira'),
      backgroundColor: _paper,
      foregroundColor: _ink,
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 52, color: _coral),
            const SizedBox(height: 16),
            const Text(
              'Acesso restrito',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta área está disponível apenas para a Presidência e a Diretoria.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _teal,
                side: const BorderSide(color: _teal),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildHeader() => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      if (_tabIndex != 0)
        OutlinedButton.icon(
          onPressed: _showEntryDialog,
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Enviar comprovante'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _teal,
            side: const BorderSide(color: _teal),
          ),
        ),
    ],
  );

  Widget _buildTabs() => Container(
    decoration: BoxDecoration(
      color: _surface,
      border: Border.all(color: _line),
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
          color: _tabIndex == index ? _teal : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: _tabIndex == index ? Colors.white : _muted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: _tabIndex == index ? Colors.white : _muted,
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
      _buildKpis(),
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
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    _monthLabel(_focusedMonth),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _ink,
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
                  icon: const Icon(Icons.chevron_right),
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
      ..._entries
          .where((entry) => entry.date.isAfter(DateTime(2026, 8, 23)))
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
                      style: const TextStyle(
                        color: _muted,
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
                ? _surface
                : entries.first.type == _EntryType.entrada
                ? _green.withAlpha(24)
                : _coral.withAlpha(24);
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  if (entries.isNotEmpty)
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: entries.first.type == _EntryType.entrada
                          ? _green
                          : _coral,
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
      _buildKpis(),
      const SizedBox(height: 24),
      _sectionTitle('Filtrar lançamentos'),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _filter('Tipo', _typeFilter, [
            'Todos',
            'Entradas',
            'Saídas',
          ], (value) => setState(() => _typeFilter = value!)),
          _filter('Valor', _valueFilter, [
            'Todos',
            'Até R\$ 2 mil',
            'Acima de R\$ 2 mil',
          ], (value) => setState(() => _valueFilter = value!)),
          _filter(
            'Fornecedor',
            _supplierFilter,
            [
              'Todos',
              ...{..._entries.map((entry) => entry.supplier)},
            ],
            (value) => setState(() => _supplierFilter = value!),
          ),
          _filter(
            'Categoria',
            _categoryFilter,
            [
              'Todas',
              ...{..._entries.map((entry) => entry.category)},
            ],
            (value) => setState(() => _categoryFilter = value!),
          ),
        ],
      ),
      const SizedBox(height: 18),
      ..._filteredEntries.map(_entryTile),
    ],
  );

  Widget _buildReportsTab() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildKpis(),
      const SizedBox(height: 24),
      _sectionTitle('Fluxo de caixa'),
      const SizedBox(height: 10),
      _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Agosto 2026', style: TextStyle(color: _muted)),
            const SizedBox(height: 18),
            _reportLine('Entradas', _totalEntries, _green),
            const SizedBox(height: 14),
            _reportLine('Saídas', _totalExits, _coral),
            const Divider(),
            _reportLine(
              'Saldo projetado',
              _totalEntries - _totalExits,
              _teal,
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
          category == 'Faturamento' ? _green : _coral,
        );
      }),
    ],
  );

  Widget _buildKpis() => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      _kpi('A receber', _totalEntries, _green, Icons.trending_up_rounded),
      _kpi('A pagar', _totalExits, _coral, Icons.trending_down_rounded),
      _kpi(
        'Saldo',
        _totalEntries - _totalExits,
        _teal,
        Icons.account_balance_wallet_outlined,
      ),
    ],
  );

  Widget _kpi(String label, double value, Color color, IconData icon) =>
      SizedBox(
        width: 220,
        child: _panel(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(24),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _entryTile(_FinancialEntry entry) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: _panel(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: (entry.type == _EntryType.entrada ? _green : _coral)
              .withAlpha(24),
          foregroundColor: entry.type == _EntryType.entrada ? _green : _coral,
          child: Icon(
            entry.type == _EntryType.entrada
                ? Icons.arrow_downward
                : Icons.arrow_upward,
          ),
        ),
        title: Text(
          entry.title,
          style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
        subtitle: Text(
          '${entry.supplier}  •  ${entry.category}\n${_dateLabel(entry.date)}${entry.attachment == null ? '' : '  •  ${entry.attachment}'}',
          style: const TextStyle(color: _muted),
        ),
        trailing: Text(
          '${entry.type == _EntryType.entrada ? '+' : '-'} R\$ ${entry.amount.toStringAsFixed(2).replaceAll('.', ',')}',
          style: TextStyle(
            color: entry.type == _EntryType.entrada ? _green : _coral,
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
          style: TextStyle(
            color: strong ? _ink : _muted,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
      Text(
        'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}',
        style: TextStyle(
          color: color,
          fontSize: strong ? 18 : 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      color: _ink,
      fontSize: 19,
      fontWeight: FontWeight.w800,
    ),
  );
  Widget _panel({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _surface,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
  Widget _filter(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) => SizedBox(
    width: 210,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: _surface,
      ),
      style: const TextStyle(color: _ink),
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    ),
  );

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
          title: const Text('Novo lançamento'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                  ),
                  TextField(
                    controller: supplier,
                    decoration: const InputDecoration(
                      labelText: 'Fornecedor / cliente',
                    ),
                  ),
                  TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      prefixText: 'R\$ ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<_EntryType>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
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
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Categoria'),
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Data: ${_dateLabel(date)}'),
                    trailing: const Icon(Icons.calendar_today_outlined),
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
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
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
