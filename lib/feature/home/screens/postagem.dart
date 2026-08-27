class Postagem {
  final String texto;
  final String nomeAutor;
  final String? fotoAutorUrl;

  Postagem({
    required this.texto,
    required this.nomeAutor,
    this.fotoAutorUrl,
  });
}