import 'package:cloud_firestore/cloud_firestore.dart';

class Postagem {
  String? id;
  String texto;
  final String nomeAutor;
  final String autorUid;
  final String? fotoAutorUrl;
  String? imagemUrl;
  List<String> curtidoPor;
  List<String> repostadoPor;
  DateTime dataCriacao;

  Postagem({
    this.id,
    required this.texto,
    required this.nomeAutor,
    required this.autorUid,
    this.fotoAutorUrl,
    this.imagemUrl,
    List<String>? curtidoPor,
    List<String>? repostadoPor,
    DateTime? dataCriacao,
  })  : curtidoPor = curtidoPor ?? [],
        repostadoPor = repostadoPor ?? [],
        dataCriacao = dataCriacao ?? DateTime.now();

  int get curtidas => curtidoPor.length;
  int get repostagens => repostadoPor.length;

  bool curtidoPorMim(String? meuUid) => curtidoPor.contains(meuUid);
  bool repostadoPorMim(String? meuUid) => repostadoPor.contains(meuUid);

  Map<String, dynamic> toMap() {
    return {
      'texto': texto,
      'nomeAutor': nomeAutor,
      'autorUid': autorUid,
      'fotoAutorUrl': fotoAutorUrl,
      'imagemUrl': imagemUrl,
      'curtidoPor': curtidoPor,
      'repostadoPor': repostadoPor,
      'dataCriacao': Timestamp.fromDate(dataCriacao),
    };
  }

  factory Postagem.fromMap(String id, Map<String, dynamic> map) {
    return Postagem(
      id: id,
      texto: map['texto'] ?? '',
      nomeAutor: map['nomeAutor'] ?? '',
      autorUid: map['autorUid'] ?? '',
      fotoAutorUrl: map['fotoAutorUrl'],
      imagemUrl: map['imagemUrl'],
      curtidoPor: List<String>.from(map['curtidoPor'] ?? []),
      repostadoPor: List<String>.from(map['repostadoPor'] ?? []),
      dataCriacao: (map['dataCriacao'] as Timestamp).toDate(),
    );
  }
}