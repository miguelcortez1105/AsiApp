import 'package:flutter/material.dart';

class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    this.role = 'Membro',
  });

  final String name;
  final String email;
  final String role;

  UserProfile copyWith({String? name}) => UserProfile(
        name: name ?? this.name,
        email: email,
        role: role,
      );
}

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>{
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nomeController.text = widget.profile.name;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final name = _nomeController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe seu nome.')),
      );
      return;
    }
    Navigator.of(context).pop(widget.profile.copyWith(name: name));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                child: Text(
                  _initials(widget.profile.name),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
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

            const Text('E-mail'),
            TextField(
              controller: TextEditingController(text: widget.profile.email),
              readOnly: true,
              decoration: const InputDecoration(
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
              widget.profile.role,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            Center(
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Salvar alterações'),
              ),//child
            ),
          ], //children
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}