import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'postagem.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AbaCadastroPostagem extends StatefulWidget {
  const AbaCadastroPostagem({super.key});

  @override
  State<AbaCadastroPostagem> createState() => _AbaCadastroPostagemState();
}

class _AbaCadastroPostagemState extends State<AbaCadastroPostagem> {
  final TextEditingController _textoController = TextEditingController();
  Uint8List? _imagemSelecionada;
  bool _publicando = false;

  String get _nomeUsuarioLogado =>
      FirebaseAuth.instance.currentUser?.email ?? 'Usuário desconhecido';

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

  Future<void> _publicarPostagem() async {
    if (_textoController.text.trim().isEmpty) return;

    setState(() {
      _publicando = true;
    });

    try {
      String? imagemUrl;

      if (_imagemSelecionada != null) {
        final nomeArquivo = 'postagens/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child(nomeArquivo);
        await ref.putData(_imagemSelecionada!);
        imagemUrl = await ref.getDownloadURL();
      }

      final novaPostagem = Postagem(
        texto: _textoController.text.trim(),
        nomeAutor: _nomeUsuarioLogado,
        imagemUrl: imagemUrl,
      );

      await FirebaseFirestore.instance
          .collection('postagens')
          .add(novaPostagem.toMap());

      _textoController.clear();
      setState(() {
        _imagemSelecionada = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Postagem criada!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao publicar: $e')),
        );
      }
    } finally {
      setState(() {
        _publicando = false;
      });
    }
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
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('postagens')
                  .doc(postagem.id)
                  .delete();
              if (context.mounted) Navigator.pop(context);
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
                onPressed: _publicando ? null : _selecionarImagem,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _publicando ? null : _publicarPostagem,
                child: _publicando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Publicar'),
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('postagens')
                  .where('nomeAutor', isEqualTo: _nomeUsuarioLogado)
                  .orderBy('dataCriacao', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final documentos = snapshot.data?.docs ?? [];

                if (documentos.isEmpty) {
                  return const Center(child: Text('Você ainda não postou nada'));
                }

                return ListView.builder(
                  itemCount: documentos.length,
                  itemBuilder: (context, index) {
                    final doc = documentos[index];
                    final postagem = Postagem.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    );

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
                            if (postagem.imagemUrl != null) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  postagem.imagemUrl!,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



