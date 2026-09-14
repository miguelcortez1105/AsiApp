import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../core/data/firebase_repository.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_background.dart';
import 'package:asiapp_mobile/feature/auth/login_page.dart';

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
  late final TextEditingController _emailController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nomeController.text = widget.profile.name;
    _emailController = TextEditingController(text: widget.profile.email);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _senhaController.dispose();
    _emailController.dispose();
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
        backgroundColor: AppColors.primaryDark,
        title: Text('Sair da conta', style: AppTextStyles.body.copyWith(color: AppColors.white),),
        content: Text('Tem certeza que deseja sair?', style: AppTextStyles.body.copyWith(color: AppColors.white),),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: AppTextStyles.body.copyWith(color: AppColors.white),),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sair', style: AppTextStyles.body.copyWith(color: AppColors.white),),
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

  Widget _field(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffix,
  }) => TextField(
    controller: controller,
    readOnly: readOnly,
    obscureText: obscureText,
    style: AppTextStyles.caption.copyWith(
      color: readOnly ? AppColors.muted : AppColors.white,
    ),
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.white),
      suffixIcon: suffix,
    ),
  );

  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.white,
        title: Text('Meu Perfil', style: AppTextStyles.h2.copyWith(color: AppColors.white)),
      ),
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 48 : 20,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                _initials(widget.profile.name),
                                style: AppTextStyles.h1.copyWith(
                                  color: AppColors.white,
                                  fontSize: 28,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: _changePhoto,
                              child: Text(
                                'Alterar foto',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _field(_nomeController, 'Nome', Icons.person_outline),
                          const SizedBox(height: 8),

                          _field(
                            _emailController,
                            'E-mail',
                            Icons.mail_outline,
                            readOnly: true,
                          ),
                          const SizedBox(height: 8),

                          _field(
                            _senhaController,
                            'Digite nova senha',
                            Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffix: IconButton(
                              tooltip: 'Mostrar senha',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _fieldLabel('Cargo'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.profile.role,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                           
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                              ),
                              onPressed: _saveProfile,
                              child: const Text('Salvar alterações'),
                            ),
                          ),

                          const SizedBox(height: 12),
                          SizedBox(
                            child: OutlinedButton(
                              onPressed: _logout,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.error,
                                side: BorderSide(color: Theme.of(context).colorScheme.error),
                              ),
                              child: const Text('Sair da conta'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
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