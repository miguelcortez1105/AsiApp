import 'package:cloud_firestore/cloud_firestore.dart';

class Postagem {
  String? id;
  String texto;
  final String nomeAutor;
  final String? fotoAutorUrl;
  String? imagemUrl;
  int curtidas;
  bool curtidoPorMim;
  int repostagens;
  bool repostadoPorMim;
  DateTime dataCriacao;

  Postagem({
    this.id,
    required this.texto,
    required this.nomeAutor,
    this.fotoAutorUrl,
    this.imagemUrl,
    this.curtidas = 0,
    this.curtidoPorMim = false,
    this.repostagens = 0,
    this.repostadoPorMim = false,
    DateTime? dataCriacao,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'texto': texto,
      'nomeAutor': nomeAutor,
      'fotoAutorUrl': fotoAutorUrl,
      'imagemUrl': imagemUrl,
      'curtidas': curtidas,
      'repostagens': repostagens,
      'dataCriacao': Timestamp.fromDate(dataCriacao),
    };
  }

  factory Postagem.fromMap(String id, Map<String, dynamic> map) {
    return Postagem(
      id: id,
      texto: map['texto'] ?? '',
      nomeAutor: map['nomeAutor'] ?? '',
      fotoAutorUrl: map['fotoAutorUrl'],
      imagemUrl: map['imagemUrl'],
      curtidas: map['curtidas'] ?? 0,
      repostagens: map['repostagens'] ?? 0,
      dataCriacao: (map['dataCriacao'] as Timestamp).toDate(),
    );
  }
}