import 'package:flutter/material.dart';

class Projeto {
  String id;
  String nome;
  String cliente;
  String areaResponsavel;
  String gerenteProjeto;
  List<String> equipe;
  DateTime prazo; 
  double valor;
  String status;

  Projeto({
    required this.id,
    required this.nome,
    required this.cliente,
    required this.areaResponsavel,
    required this.gerenteProjeto,
    required this.equipe,
    required this.prazo,
    required this.valor,
    this.status = 'A Iniciar',
  });
}

class CadastroDeProjetos extends StatefulWidget {
  @override
  _CadastroDeProjetosState createState() => _CadastroDeProjetosState();
}

class _CadastroDeProjetosState extends State<CadastroDeProjetos> {
  // Mock 
  final List<String> _areas = ['Mobile', 'Desktop', 'Dados', 'Sites'];
  final List<String> _statusList = ['A Iniciar', 'Em Andamento', 'Concluído'];
  final List<String> _membrosCadastrados = ['Miguel', 'Ana', 'João', 'Maria', 'Carlos', 'Matheus', 'Sofia'];
  
  List<Projeto> _projetosDb = [
    Projeto(
      id: '1', 
      nome: 'App Asimov', 
      cliente: 'Interno', 
      areaResponsavel: 'Mobile',
      gerenteProjeto: 'Miguel', 
      equipe: ['Ana', 'João'], 
      prazo: DateTime(2026, 12, 12), 
      valor: 15000, 
      status: 'Em Andamento'
    ),
  ];

  String? _filtroArea;
  String? _filtroStatus; 
  final _valorMinCtrl = TextEditingController();
  final _valorMaxCtrl = TextEditingController();

  List<Projeto> get _projetosFiltrados {
    return _projetosDb.where((p) {
      final areaMatch = _filtroArea == null || p.areaResponsavel == _filtroArea;
      final statusMatch = _filtroStatus == null || p.status == _filtroStatus;
      
      final vMin = double.tryParse(_valorMinCtrl.text) ?? 0.0;
      final vMax = double.tryParse(_valorMaxCtrl.text) ?? double.infinity;
      final valorMatch = p.valor >= vMin && p.valor <= vMax;

      return areaMatch && statusMatch && valorMatch;
    }).toList();
  }

  void _abrirFormulario({Projeto? projetoExistente}) {
    final bool isEdicao = projetoExistente != null;
    
    final _formKey = GlobalKey<FormState>();
    final _nomeCtrl = TextEditingController(text: projetoExistente?.nome ?? '');
    final _clienteCtrl = TextEditingController(text: projetoExistente?.cliente ?? '');
    final _valorCtrl = TextEditingController(text: projetoExistente?.valor != null ? projetoExistente!.valor.toString() : '');
    
    DateTime? _dataSelecionada = projetoExistente?.prazo;
    final _prazoCtrl = TextEditingController(
      text: projetoExistente?.prazo != null 
          ? '${projetoExistente!.prazo.day.toString().padLeft(2, '0')}/${projetoExistente!.prazo.month.toString().padLeft(2, '0')}/${projetoExistente!.prazo.year}'
          : '',
    );
    
    String? _areaSelecionada = projetoExistente?.areaResponsavel;
    String? _gerenteSelecionado = projetoExistente?.gerenteProjeto;
    String _statusSelecionado = projetoExistente?.status ?? 'A Iniciar';
    List<String> _equipeSelecionada = projetoExistente?.equipe != null 
        ? List.from(projetoExistente!.equipe) 
        : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 24,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdicao ? 'Editar Projeto' : 'Novo Projeto', 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _nomeCtrl, 
                        decoration: const InputDecoration(labelText: 'Nome do Projeto'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome do projeto' : null,
                      ),
                      TextFormField(
                        controller: _clienteCtrl, 
                        decoration: const InputDecoration(labelText: 'Cliente'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Informe o cliente' : null,
                        onChanged: (v) => setModalState(() {}), // Atualiza para revalidar a regra do valor se mudar para "Interno"
                      ),
                      
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Área Responsável'),
                        value: _areaSelecionada,
                        items: _areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                        onChanged: (v) => setModalState(() => _areaSelecionada = v),
                        validator: (v) => v == null ? 'Selecione a área responsável' : null,
                      ),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Gerente de Projeto'),
                        value: _gerenteSelecionado,
                        items: _membrosCadastrados.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (v) => setModalState(() => _gerenteSelecionado = v),
                        validator: (v) => v == null ? 'Selecione o gerente do projeto' : null,
                      ),
                      
                      const SizedBox(height: 16),
                      const Text('Equipe:'),
                      Wrap(
                        spacing: 8.0,
                        children: _membrosCadastrados.map((membro) {
                          final isSelected = _equipeSelecionada.contains(membro);
                          return FilterChip(
                            label: Text(membro),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setModalState(() {
                                selected ? _equipeSelecionada.add(membro) : _equipeSelecionada.remove(membro);
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _prazoCtrl,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Prazo',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              onTap: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dataSelecionada ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    _dataSelecionada = picked;
                                    _prazoCtrl.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                                  });
                                }
                              },
                              validator: (v) => _dataSelecionada == null ? 'Selecione o prazo' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _valorCtrl, 
                              decoration: InputDecoration(
                                labelText: _clienteCtrl.text.trim().toLowerCase() == 'interno' 
                                    ? 'Valor (R\$) (Opcional)' 
                                    : 'Valor (R\$)'
                              ), 
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) {
                                final isInterno = _clienteCtrl.text.trim().toLowerCase() == 'interno';
                                
                                if (!isInterno) {
                                  // Projeto NÃO interno: Valor é OBRIGATÓRIO e deve ser > 0
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Informe o valor do projeto';
                                  }
                                  final valorParsed = double.tryParse(v.replaceAll(',', '.'));
                                  if (valorParsed == null) {
                                    return 'Digite um número válido';
                                  }
                                  if (valorParsed <= 0) {
                                    return 'O valor deve ser maior que zero';
                                  }
                                } else {
                                  // Projeto interno: Valor é OPCIONAL, mas se preenchido, deve ser válido
                                  if (v != null && v.trim().isNotEmpty) {
                                    final valorParsed = double.tryParse(v.replaceAll(',', '.'));
                                    if (valorParsed == null || valorParsed < 0) {
                                      return 'Valor inválido';
                                    }
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 10),
                      if (isEdicao)
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Status do Projeto'),
                          value: _statusSelecionado,
                          items: _statusList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setModalState(() => _statusSelecionado = v!),
                        ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final double valorFinal = _valorCtrl.text.trim().isEmpty 
                                  ? 0.0 
                                  : (double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0.0);

                              final novoProjeto = Projeto(
                                id: isEdicao ? projetoExistente.id : DateTime.now().toString(),
                                nome: _nomeCtrl.text,
                                cliente: _clienteCtrl.text,
                                areaResponsavel: _areaSelecionada ?? '',
                                gerenteProjeto: _gerenteSelecionado ?? '',
                                equipe: _equipeSelecionada,
                                prazo: _dataSelecionada!,
                                valor: valorFinal,
                                status: _statusSelecionado,
                              );

                              setState(() {
                                if (isEdicao) {
                                  final index = _projetosDb.indexWhere((p) => p.id == projetoExistente.id);
                                  _projetosDb[index] = novoProjeto;
                                } else {
                                  _projetosDb.add(novoProjeto);
                                }
                              });
                              Navigator.pop(context);
                            }
                          },
                          child: Text(isEdicao ? 'Salvar Alterações' : 'Cadastrar Projeto'),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Projetos')),
      body: Column(
        children: [
          ExpansionTile(
            title: const Text('Filtros de Busca'),
            leading: const Icon(Icons.filter_alt),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Área', isDense: true),
                            value: _filtroArea,
                            items: _areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                            onChanged: (v) => setState(() => _filtroArea = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Status', isDense: true),
                            value: _filtroStatus,
                            items: _statusList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setState(() => _filtroStatus = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _valorMinCtrl,
                            decoration: const InputDecoration(labelText: 'Valor Mínimo (R\$)'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _valorMaxCtrl,
                            decoration: const InputDecoration(labelText: 'Valor Máximo (R\$)'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _filtroArea = null;
                        _filtroStatus = null;
                        _valorMinCtrl.clear();
                        _valorMaxCtrl.clear();
                      }),
                      child: const Text('Limpar Filtros'),
                    )
                  ],
                ),
              )
            ],
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: _projetosFiltrados.length,
              itemBuilder: (context, index) {
                final projeto = _projetosFiltrados[index];
                final prazoFormatado = '${projeto.prazo.day.toString().padLeft(2, '0')}/${projeto.prazo.month.toString().padLeft(2, '0')}/${projeto.prazo.year}';
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(projeto.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cliente: ${projeto.cliente} | Área: ${projeto.areaResponsavel}'),
                        Text('Valor: R\$ ${projeto.valor.toStringAsFixed(2)} | Prazo: $prazoFormatado'),
                        const SizedBox(height: 4),
                        Chip(label: Text(projeto.status), backgroundColor: Colors.blue.withOpacity(0.1)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _abrirFormulario(projetoExistente: projeto),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
        tooltip: 'Cadastrar Projeto',
      ),
    );
  }
}