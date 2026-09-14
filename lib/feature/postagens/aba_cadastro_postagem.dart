import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:asiapp_mobile/feature/postagens/postagem.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';


const _borderOnDark = Color(0x33FFFFFF);

class AbaCadastroPostagem extends StatefulWidget {
  const AbaCadastroPostagem({super.key});

  @override
  State<AbaCadastroPostagem> createState() => _AbaCadastroPostagemState();
}

class _AbaCadastroPostagemState extends State<AbaCadastroPostagem> {
  final TextEditingController _textoController = TextEditingController();
  Uint8List? _imagemSelecionada;
  bool _publicando = false;

  String get _meuUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _selecionarImagem() async {
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.primaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.white),
                title: Text(
                  'Escolher da galeria',
                  style: AppTextStyles.body.copyWith(color: AppColors.white),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: AppColors.white),
                title: Text(
                  'Tirar foto',
                  style: AppTextStyles.body.copyWith(color: AppColors.white),
                ),
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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Usuário não autenticado');

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final nomeReal = userDoc.data()?['name'] ?? 'Usuário';

      String? imagemUrl;
      if (_imagemSelecionada != null) {
        final nomeArquivo = 'postagens/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child(nomeArquivo);
        await ref.putData(_imagemSelecionada!);
        imagemUrl = await ref.getDownloadURL();
      }

      final novaPostagem = Postagem(
        texto: _textoController.text.trim(),
        nomeAutor: nomeReal,
        autorUid: uid,
        imagemUrl: imagemUrl,
      );

      await FirebaseFirestore.instance.collection('postagens').add(novaPostagem.toMap());

      _textoController.clear();
      setState(() => _imagemSelecionada = null);

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
      setState(() => _publicando = false);
    }
  }

  void _excluirPostagem(Postagem postagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Excluir postagem',
          style: AppTextStyles.h2.copyWith(color: AppColors.white),
        ),
        content: Text(
          'Deseja excluir esta postagem?',
          style: AppTextStyles.body.copyWith(color: AppColors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: AppTextStyles.button.copyWith(color: AppColors.white),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: AppColors.white,
            ),
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

  InputDecoration _formFieldDecoration(String hint) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Colors.black, width: 1.2),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.caption.copyWith(color: AppColors.muted),
      filled: true,
      fillColor: Colors.transparent,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.black, width: 1.6),
      ),
    );
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
            style: AppTextStyles.body.copyWith(color: AppColors.white),
            decoration: _formFieldDecoration('No que você está pensando?'),
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
                    icon: const Icon(Icons.close, color: AppColors.white),
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
                icon: const Icon(Icons.image_outlined, color: AppColors.white),
                onPressed: _publicando ? null : _selecionarImagem,
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                onPressed: _publicando ? null : _publicarPostagem,
                child: _publicando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Publicar'),
              ),
            ],
          ),
          Divider(height: 32, color: _borderOnDark),
          Text(
            'Minhas postagens',
            style: AppTextStyles.body.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('postagens')
                  .where('autorUid', isEqualTo: _meuUid)
                  .orderBy('dataCriacao', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro: ${snapshot.error}',
                      style: AppTextStyles.body.copyWith(color: AppColors.white),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final documentos = snapshot.data?.docs ?? [];

                if (documentos.isEmpty) {
                  return Center(
                    child: Text(
                      'Você ainda não postou nada',
                      style: AppTextStyles.body.copyWith(color: AppColors.muted),
                    ),
                  );
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
                      color: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: _borderOnDark),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: AppColors.coral),
                                  onPressed: () => _excluirPostagem(postagem),
                                ),
                              ],
                            ),
                            Text(
                              postagem.texto,
                              style: AppTextStyles.body.copyWith(color: AppColors.white),
                            ),
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