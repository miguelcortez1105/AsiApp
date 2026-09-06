import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'postagem.dart';

class AbaFeedSocial extends StatefulWidget {
  const AbaFeedSocial({super.key});

  @override
  State<AbaFeedSocial> createState() => _AbaFeedSocialState();
}

class _AbaFeedSocialState extends State<AbaFeedSocial> {
  // TODO: implementar controle de "já curtiu"/"já repostou" por usuário (subcoleção)
  Future<void> _curtir(Postagem postagem) async {
    await FirebaseFirestore.instance
        .collection('postagens')
        .doc(postagem.id)
        .update({'curtidas': postagem.curtidas + 1});
  }

  Future<void> _repostar(Postagem postagem) async {
    await FirebaseFirestore.instance
        .collection('postagens')
        .doc(postagem.id)
        .update({'repostagens': postagem.repostagens + 1});
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
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () => _curtir(postagem),
                        ),
                        Text('${postagem.curtidas}'),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.repeat),
                          onPressed: () => _repostar(postagem),
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