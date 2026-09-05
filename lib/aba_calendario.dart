import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:asiapp_mobile/evento.dart';

class AbaCalendario extends StatefulWidget {
  const AbaCalendario({super.key});

  @override
  State<AbaCalendario> createState() => _AbaCalendarioState();
}

class _AbaCalendarioState extends State<AbaCalendario> {
  DateTime _diaFocado = DateTime.now();
  DateTime? _diaSelecionado;

  String cargoUsuarioLogado = 'Diretor'; //buscar do Firestore quando conectado

  bool get _podeEditarEventos =>
      cargoUsuarioLogado == 'Diretor' || cargoUsuarioLogado == 'Gerente';

  //substituir por dados reais do Firestore quando conectado
  final Map<DateTime, List<Evento>> _eventosSimulados = {
    DateTime.utc(2026, 8, 24): [
      Evento(titulo: 'Reunião Geral', horario: '18:00', areas: ['Geral']),
    ],
    DateTime.utc(2026, 8, 31): [
      Evento(titulo: 'Apresentação Projeto final', horario: '18:00', areas: ['Mobile', 'Desktop', 'Marketing']),
    ],
  };

  final Map<String, Color> _coresPorArea = {
    'Geral': Colors.black,
    'Ciência de Dados': Colors.teal,
    'Comissão Eventos': Colors.brown,
    'Comissão Processo Seletivo': Colors.indigo,
    'Desktop': Colors.green,
    'Gerentes': Colors.amber,
    'Marketing': Colors.pink,
    'Mobile': Colors.deepPurple,
    'Presidência': Colors.red,
    'RH': Colors.cyan,
    'Vendas': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    _diaSelecionado = _diaFocado;
  }

  List<Evento> _eventosDoDia(DateTime dia) {
    final diaSemHora = DateTime.utc(dia.year, dia.month, dia.day);
    return _eventosSimulados[diaSemHora] ?? [];
  }

  void _abrirFormularioEvento({Evento? eventoParaEditar}) {
    final tituloController = TextEditingController(text: eventoParaEditar?.titulo ?? '');
    final horarioController = TextEditingController(text: eventoParaEditar?.horario ?? '');
    List<String> areasSelecionadas = List.from(eventoParaEditar?.areas ?? []);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(eventoParaEditar == null ? 'Novo evento' : 'Editar evento'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tituloController,
                      decoration: const InputDecoration(labelText: 'Título'),
                    ),
                    TextField(
                      controller: horarioController,
                      decoration: const InputDecoration(labelText: 'Horário (ex: 18:00)'),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Áreas envolvidas'),
                    ),
                    ..._coresPorArea.keys.map((area) {
                      return CheckboxListTile(
                        title: Text(area),
                        value: areasSelecionadas.contains(area),
                        onChanged: (marcado) {
                          setStateDialog(() {
                            if (marcado == true) {
                              areasSelecionadas.add(area);
                            } else {
                              areasSelecionadas.remove(area);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (tituloController.text.trim().isEmpty) return;
                    if (areasSelecionadas.isEmpty) return;

                    final diaEscolhido = _diaSelecionado ?? _diaFocado;
                    final diaSemHora = DateTime.utc(
                      diaEscolhido.year,
                      diaEscolhido.month,
                      diaEscolhido.day,
                    );

                    setState(() {
                      if (eventoParaEditar != null) {
                        eventoParaEditar.titulo = tituloController.text.trim();
                        eventoParaEditar.horario = horarioController.text.trim();
                        eventoParaEditar.areas = areasSelecionadas;
                      } else {
                        _eventosSimulados.putIfAbsent(diaSemHora, () => []);
                        _eventosSimulados[diaSemHora]!.add(
                          Evento(
                            titulo: tituloController.text.trim(),
                            horario: horarioController.text.trim(),
                            areas: areasSelecionadas,
                          ),
                        );
                      }
                    });

                    Navigator.pop(context);
                  },
                  child: Text(eventoParaEditar == null ? 'Criar' : 'Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _excluirEvento(Evento evento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir evento'),
        content: Text('Deseja excluir "${evento.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final diaEscolhido = _diaSelecionado ?? _diaFocado;
              final diaSemHora = DateTime.utc(
                diaEscolhido.year,
                diaEscolhido.month,
                diaEscolhido.day,
              );
              setState(() {
                _eventosSimulados[diaSemHora]?.remove(evento);
              });
              Navigator.pop(context);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegenda() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: _coresPorArea.entries.map((entrada) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: entrada.value,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                entrada.key,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2050, 12, 31),
            focusedDay: _diaFocado,
            selectedDayPredicate: (dia) => isSameDay(_diaSelecionado, dia),
            onDaySelected: (diaSelecionado, diaFocado) {
              setState(() {
                _diaSelecionado = diaSelecionado;
                _diaFocado = diaFocado;
              });
            },
            locale: 'pt_BR',
            eventLoader: _eventosDoDia,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, dia, eventos) {
                if (eventos.isEmpty) return null;

                final coresDoDia = <Color>{};
                for (final evento in eventos) {
                  for (final area in (evento as Evento).areas) {
                    coresDoDia.add(_coresPorArea[area] ?? Colors.grey);
                  }
                }

                return Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: coresDoDia.map((cor) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: cor,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          _buildLegenda(),
          const SizedBox(height: 16),
          Expanded(
            child: _eventosDoDia(_diaSelecionado ?? _diaFocado).isEmpty
                ? const Center(child: Text('Nenhum evento neste dia'))
                : ListView.builder(
                    itemCount: _eventosDoDia(_diaSelecionado ?? _diaFocado).length,
                    itemBuilder: (context, index) {
                      final evento = _eventosDoDia(_diaSelecionado ?? _diaFocado)[index];
                      return ListTile(
                        leading: const Icon(Icons.event),
                        title: Text(evento.titulo),
                        subtitle: Text('${evento.horario} • ${evento.areas.join(', ')}'),
                        trailing: _podeEditarEventos
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () =>
                                        _abrirFormularioEvento(eventoParaEditar: evento),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _excluirEvento(evento),
                                  ),
                                ],
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _podeEditarEventos
          ? FloatingActionButton(
              onPressed: () => _abrirFormularioEvento(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}