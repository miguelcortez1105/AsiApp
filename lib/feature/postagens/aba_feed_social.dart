import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'postagem.dart';

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
          return Center(child: Text('Erro: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final documentos = snapshot.data?.docs ?? [];
        if (documentos.isEmpty) {
          return const Center(child: Text('Nenhuma postagem ainda'));
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
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(postagem.texto),
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
                            color: euCurti ? Colors.red : null,
                          ),
                          onPressed: () => _alternarCurtida(postagem),
                        ),
                        Text('${postagem.curtidas}'),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            Icons.repeat,
                            color: euRepostei ? Colors.green : null,
                          ),
                          onPressed: () => _alternarRepost(postagem),
                        ),
                        Text('${postagem.repostagens}'),
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