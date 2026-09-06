import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'postagem.dart';


class AbaCadastroPostagem extends StatefulWidget {
  final List<Postagem> postagens;
  final String nomeUsuarioLogado;
  final VoidCallback aoPublicar;

  const AbaCadastroPostagem({
    super.key,
    required this.postagens,
    required this.nomeUsuarioLogado,
    required this.aoPublicar,
  });

  @override
  State<AbaCadastroPostagem> createState() => _AbaCadastroPostagemState();
}

class _AbaCadastroPostagemState extends State<AbaCadastroPostagem> {
  final TextEditingController _textoController = TextEditingController();
  Uint8List? _imagemSelecionada;

  List<Postagem> get _minhasPostagens => widget.postagens
      .where((postagem) => postagem.nomeAutor == widget.nomeUsuarioLogado)
      .toList();

  Future<void> _selecionarImagem() async {
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tirar foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (origem == null) return;

    final picker = ImagePicker();
    final imagemEscolhida = await picker.pickImage(source: origem);

    if (imagemEscolhida == null) return;

    final bytes = await imagemEscolhida.readAsBytes();
    setState(() {
      _imagemSelecionada = bytes;
    });
  }

  void _publicarPostagem() {
    if (_textoController.text.trim().isEmpty) return;

    setState(() {
      widget.postagens.insert(
        0,
        Postagem(
          texto: _textoController.text.trim(),
          nomeAutor: widget.nomeUsuarioLogado,
          imagemBytes: _imagemSelecionada,
        ),
      );
      _textoController.clear();
      _imagemSelecionada = null;
    });

    widget.aoPublicar();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Postagem criada!')),
    );
  }
  
  void _excluirPostagem(Postagem postagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir postagem'),
        content: const Text('Deseja excluir esta postagem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.postagens.remove(postagem);
              });
              Navigator.pop(context);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _textoController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'No que você está pensando?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          if (_imagemSelecionada != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _imagemSelecionada!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    onPressed: () => setState(() => _imagemSelecionada = null),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image_outlined),
                onPressed: _selecionarImagem,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _publicarPostagem,
                child: const Text('Publicar'),
              ),
            ],
          ),
          const Divider(height: 32),
          const Text(
            'Minhas postagens',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _minhasPostagens.isEmpty
                ? const Center(child: Text('Você ainda não postou nada'))
                : ListView.builder(
                    itemCount: _minhasPostagens.length,
                    itemBuilder: (context, index) {
                      final postagem = _minhasPostagens[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _excluirPostagem(postagem),
                                  ),
                                ],
                              ),
                              Text(postagem.texto),
                              if (postagem.imagemBytes != null) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    postagem.imagemBytes!,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
