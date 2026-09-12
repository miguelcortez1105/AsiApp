import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:asiapp_mobile/feature/auth/login_page.dart';
import '../core/data/firebase_repository.dart';
import 'package:asiapp_mobile/feature/core/theme/app_text_styles.dart';

class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    this.role = 'Membro',
    this.uid = '',
    this.photoUrl,
  });

  final String name;
  final String email;
  final String role;
  final String uid;
  final String? photoUrl;

  UserProfile copyWith({String? name, String? email, String? role, String? photoUrl}) => UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        uid: uid,
        photoUrl: photoUrl ?? this.photoUrl,
      );

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'role': role,
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    return UserProfile(
      uid: document.id,
      name: data['name'] as String? ?? 'Usuário',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'Membro',
      photoUrl: data['photoUrl'] as String?,
    );
  }
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

  Future<void> _saveProfile() async {
    final name = _nomeController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe seu nome.')),
      );
      return;
    }
    final updatedProfile = widget.profile.copyWith(name: name);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      await firebaseUser.updateDisplayName(name);
      await FirebaseRepository.instance.saveProfile(
        updatedProfile.copyWith(
          name: name,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop(updatedProfile);
  }

    Future<void> _logout() async {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sair da conta'),
          content: const Text('Tem certeza que deseja sair?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sair'),
            ),
          ],
        ),
      );

      if (confirmar != true) return;

      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }

  Future<void> _changePhoto() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    final extension = image.name.split('.').last.toLowerCase();
    final photoUrl = await FirebaseRepository.instance.uploadProfileImage(
      uid: firebaseUser.uid,
      bytes: bytes,
      extension: extension == 'jpg' ? 'jpeg' : extension,
    );
    await firebaseUser.updatePhotoURL(photoUrl);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto atualizada com sucesso.')),
      );
    }
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
                onPressed: _changePhoto,
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
            const SizedBox(height: 16),

            Center(
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
                    backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Sair da conta',
                    style: AppTextStyles.button.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
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