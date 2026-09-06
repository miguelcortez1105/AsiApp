import 'package:cloud_firestore/cloud_firestore.dart';

class Evento {
  String? id; // ID do documento no Firestore
  String titulo;
  String horario;
  List<String> areas;
  DateTime data;

  Evento({
    this.id,
    required this.titulo,
    required this.horario,
    required this.areas,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'horario': horario,
      'areas': areas,
      'data': Timestamp.fromDate(data),
    };
  }

  factory Evento.fromMap(String id, Map<String, dynamic> map) {
    return Evento(
      id: id,
      titulo: map['titulo'] ?? '',
      horario: map['horario'] ?? '',
      areas: List<String>.from(map['areas'] ?? []),
      data: (map['data'] as Timestamp).toDate(),
    );
  }
}