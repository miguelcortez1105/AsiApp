import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'postagem.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

const _borderOnDark = Color(0x33FFFFFF);

class AbaFeedSocial extends StatefulWidget {
  const AbaFeedSocial({super.key});

  @override
  State<AbaFeedSocial> createState() => _AbaFeedSocialState();
}

class _AbaFeedSocialState extends State<AbaFeedSocial> {
  String? get _meuUid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _alternarCurtida(Postagem postagem) async {
    final uid = _meuUid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance.collection('postagens').doc(postagem.id);
    if (postagem.curtidoPorMim(uid)) {
      await ref.update({
        'curtidoPor': FieldValue.arrayRemove([uid]),
      });
    } else {
      await ref.update({
        'curtidoPor': FieldValue.arrayUnion([uid]),
      });
    }
  }

  Future<void> _alternarRepost(Postagem postagem) async {
    final uid = _meuUid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance.collection('postagens').doc(postagem.id);
    if (postagem.repostadoPorMim(uid)) {
      await ref.update({
        'repostadoPor': FieldValue.arrayRemove([uid]),
      });
    } else {
      await ref.update({
        'repostadoPor': FieldValue.arrayUnion([uid]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('postagens')
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
              'Nenhuma postagem ainda',
              style: AppTextStyles.body.copyWith(color: AppColors.muted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: documentos.length,
          itemBuilder: (context, index) {
            final doc = documentos[index];
            final postagem = Postagem.fromMap(doc.id, doc.data() as Map<String, dynamic>);
            final euCurti = postagem.curtidoPorMim(_meuUid);
            final euRepostei = postagem.repostadoPorMim(_meuUid);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
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
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withAlpha(40),
                          foregroundColor: AppColors.primary,
                          backgroundImage: postagem.fotoAutorUrl != null
                              ? NetworkImage(postagem.fotoAutorUrl!)
                              : null,
                          child: postagem.fotoAutorUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          postagem.nomeAutor,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            euCurti ? Icons.favorite : Icons.favorite_border,
                            color: euCurti ? AppColors.coral : AppColors.white,
                          ),
                          onPressed: () => _alternarCurtida(postagem),
                        ),
                        Text(
                          '${postagem.curtidas}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.white),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            Icons.repeat,
                            color: euRepostei ? AppColors.primary : AppColors.white,
                          ),
                          onPressed: () => _alternarRepost(postagem),
                        ),
                        Text(
                          '${postagem.repostagens}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}