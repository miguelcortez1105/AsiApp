import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:asiapp_mobile/feature/home/screens/evento.dart';

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
    'Geral': Colors.blue,
    'Mobile': Colors.green,
    'Comissão Eventos': Colors.pink,
    'Comissão Processo Seletivo': Colors.deepPurple,
    'Vendas': Colors.orange,
    'Marketing': Colors.red,
    'Ciência de Dados': Colors.teal,
    'Desktop': Colors.indigo,
    'RH': Colors.brown,
    'Presidência': Colors.black,
    'Gerentes': Colors.amber,
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

                final coresDoDia = eventos
                    .map((evento) => _coresPorArea[(evento as Evento).areas] ?? Colors.grey)
                    .toSet();

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
                        subtitle: Text(evento.horario),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _podeEditarEventos
          ? FloatingActionButton(
              onPressed: () {
                // TODO: abrir tela/formulário de criar evento
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}