import 'package:asiapp_mobile/feature/home/screens/postagem.dart';
import 'package:flutter/material.dart';

class AbaCadastroPostagem extends StatefulWidget {
  const AbaCadastroPostagem({super.key});

  @override
  State<AbaCadastroPostagem> createState() => _AbaCadastroPostagemState();
}

class _AbaCadastroPostagemState extends State<AbaCadastroPostagem> {
  final TextEditingController _textoController = TextEditingController();

  final List<Postagem> _postagensSimuladas = []; // TODO: substituir por dados reais do Firestore

  String nomeUsuarioLogado = 'Ana Alves'; // TODO: buscar do Firestore quando conectado

  void _publicarPostagem() {
    if (_textoController.text.trim().isEmpty) return;

    setState(() {
      _postagensSimuladas.insert(
        0,
        Postagem(
          texto: _textoController.text.trim(),
          nomeAutor: nomeUsuarioLogado,
        ),
      );
      _textoController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Postagem criada!')),
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _publicarPostagem,
              child: const Text('Publicar'),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Minhas postagens recentes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _postagensSimuladas.isEmpty
                ? const Center(child: Text('Nenhuma postagem ainda'))
                : ListView.builder(
                    itemCount: _postagensSimuladas.length,
                    itemBuilder: (context, index) {
                      final postagem = _postagensSimuladas[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: postagem.fotoAutorUrl != null
                                ? NetworkImage(postagem.fotoAutorUrl!)
                                : null,
                            child: postagem.fotoAutorUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(postagem.nomeAutor),
                          subtitle: Text(postagem.texto),
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