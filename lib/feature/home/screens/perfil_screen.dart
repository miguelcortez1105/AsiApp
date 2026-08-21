import 'package:flutter/material.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>{
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  String cargo = 'Membro';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              )
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: (){
                 //logica de trocar foto   
                },
                child: const Text ('Alterar foto'),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('Nome'),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                hintText: 'Digite seu nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Senha'),
            TextField(
              controller: _senhaController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Digite nova senha',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Cargo'),
            Text(
              cargo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            Center(
              child: ElevatedButton(
                onPressed: (){
                  //firbase
                },
                child: const Text('Salvar alterações'),
              ),//child
            ),
          ], //children
        ),
      ),
    );
  }
}