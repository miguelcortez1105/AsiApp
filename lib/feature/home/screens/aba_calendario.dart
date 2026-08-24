import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AbaCalendario extends StatefulWidget {
  const AbaCalendario({super.key});

  @override
  State<AbaCalendario> createState() => _AbaCalendarioState();
}

class _AbaCalendarioState extends State<AbaCalendario> {
  DateTime _diaFocado = DateTime.now();
  DateTime? _diaSelecionado;

  @override
  void initState() {
    super.initState();
    _diaSelecionado = _diaFocado;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _diaFocado,
          selectedDayPredicate: (dia) => isSameDay(_diaSelecionado, dia),
          onDaySelected: (diaSelecionado, diaFocado) {
            setState(() {
              _diaSelecionado = diaSelecionado;
              _diaFocado = diaFocado;
            });
          },
          locale: 'pt_BR',
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: Text(
              'Eventos do dia ${_diaSelecionado?.day}/${_diaSelecionado?.month}',
            ),
          ),
        ),
      ],
    );
  }
}