import 'package:flutter/material.dart';
import 'postagem.dart';

class AbaFeedSocial extends StatefulWidget {
  final List<Postagem> postagens;

  const AbaFeedSocial({super.key, required this.postagens});

  @override
  State<AbaFeedSocial> createState() => _AbaFeedSocialState();
}

class _AbaFeedSocialState extends State<AbaFeedSocial> {
  void _alternarCurtida(Postagem postagem) {
    setState(() {
      if (postagem.curtidoPorMim) {
        postagem.curtidas--;
        postagem.curtidoPorMim = false;
      } else {
        postagem.curtidas++;
        postagem.curtidoPorMim = true;
      }
    });
  }

  void _alternarRepost(Postagem postagem) {
    setState(() {
      if (postagem.repostadoPorMim) {
        postagem.repostagens--;
        postagem.repostadoPorMim = false;
      } else {
        postagem.repostagens++;
        postagem.repostadoPorMim = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.postagens.isEmpty) {
      return const Center(child: Text('Nenhuma postagem ainda'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.postagens.length,
      itemBuilder: (context, index) {
        final postagem = widget.postagens[index];
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
                if (postagem.imagemBytes != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      postagem.imagemBytes!,
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
                        postagem.curtidoPorMim
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: postagem.curtidoPorMim ? Colors.red : null,
                      ),
                      onPressed: () => _alternarCurtida(postagem),
                    ),
                    Text('${postagem.curtidas}'),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        Icons.repeat,
                        color: postagem.repostadoPorMim ? Colors.green : null,
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
  }
}