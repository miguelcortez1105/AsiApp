import 'dart:typed_data';

class Postagem {
  String texto;
  final String nomeAutor;
  final String? fotoAutorUrl;
  final Uint8List? imagemBytes;
  int curtidas;
  bool curtidoPorMim;
  int repostagens;
  bool repostadoPorMim;

  Postagem({
    required this.texto,
    required this.nomeAutor,
    this.fotoAutorUrl,
    this.imagemBytes,
    this.curtidas = 0,
    this.curtidoPorMim = false,
    this.repostagens = 0,
    this.repostadoPorMim = false,
  });
}