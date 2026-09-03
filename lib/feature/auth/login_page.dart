import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../home/home_page.dart';
import '../perfil/perfil_screen.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/data/firebase_repository.dart';
import 'role_triage_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _corporateDomain = '@asimovjr.com.br';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Informe seu $label.';
    return null;
  }

  String? _emailValidator(String? value) {
    final required = _required(value, 'e-mail');
    if (required != null) return required;
    final email = value!.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Digite um e-mail válido.';
    }
    if (_isSignUp && !email.endsWith(_corporateDomain)) {
      return 'Use seu e-mail corporativo @asimovjr.com.br.';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    final required = _required(value, 'senha');
    if (required != null) return required;
    if (value!.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';
    return null;
  }

  Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  final email = _emailController.text.trim().toLowerCase();
  final password = _passwordController.text;

  try {
    if (_isSignUp) {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(
        _nameController.text.trim(),
      );
      final createdUser = credential.user!;
      await FirebaseRepository.instance.saveProfile(
        UserProfile(
          uid: createdUser.uid,
          name: _nameController.text.trim(),
          email: email,
          role: Hierarchy.awaitingRoleAssignment,
        ),
      );

      if (!mounted) return;

      setState(() => _isSignUp = false);

      _passwordController.clear();
      _confirmPasswordController.clear();

      _showMessage(
        'Cadastro criado com sucesso! Faça seu login.',
      );

      return;
    }

    final credential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (!mounted) return;

    final user = credential.user!;
    final savedProfile = await FirebaseRepository.instance.getProfile(user.uid);
    _openHome(user, savedProfile: savedProfile);
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;

    switch (e.code) {
      case 'email-already-in-use':
        _showMessage('Este e-mail já possui cadastro.');
        break;

      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        _showMessage('E-mail ou senha incorretos.');
        break;

      case 'invalid-email':
        _showMessage('Digite um e-mail válido.');
        break;

      case 'weak-password':
        _showMessage('A senha é muito fraca.');
        break;

      case 'user-disabled':
        _showMessage('Esta conta foi desativada.');
        break;

      case 'operation-not-allowed':
        _showMessage('O login por e-mail e senha está desativado no Firebase.');
        break;

      case 'too-many-requests':
        _showMessage('Muitas tentativas. Aguarde alguns minutos e tente novamente.');
        break;

      case 'network-request-failed':
        _showMessage('Falha de conexão. Verifique sua internet e tente novamente.');
        break;

      case 'auth-domain-config-required':
        _showMessage('O domínio de autenticação não está configurado no Firebase.');
        break;

      case 'requires-recent-login':
        _showMessage('Sua sessão expirou. Faça login novamente.');
        break;

      default:
        _showMessage(
          'Erro de autenticação (${e.code}). ${e.message ?? 'Verifique as configurações do Firebase.'}',
        );
    }
  } on FirebaseException catch (e) {
    debugPrint('Erro do Firebase após o login: ${e.plugin}/${e.code}: ${e.message}');
    if (!mounted) return;

    _showMessage(
      'Erro no ${e.plugin} (${e.code}). ${e.message ?? 'Verifique as regras e a conexão.'}',
    );
  } catch (e, stackTrace) {
    debugPrint('Erro inesperado no login: $e');
    debugPrintStack(stackTrace: stackTrace);
    if (!mounted) return;

    _showMessage(
      'Erro inesperado: $e',
    );
  }
  }

  Future<void> _sendPasswordReset(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      _showMessage('Informe seu e-mail para recuperar a senha.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: normalizedEmail,
      );
      if (!mounted) return;
      _showMessage(
        'Se o e-mail estiver cadastrado, enviaremos as instruções.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage(
        e.code == 'invalid-email'
            ? 'Digite um e-mail válido.'
            : 'Não foi possível enviar as instruções.',
      );
    }
  }

  void _openHome(User user, {UserProfile? savedProfile}) {
    final profile = savedProfile ??
        UserProfile(
          uid: user.uid,
          name: user.displayName ?? 'Usuário',
          email: user.email ?? '',
          role: Hierarchy.awaitingRoleAssignment,
        );

    final destination = Hierarchy.isAwaitingRoleAssignment(profile.role)
        ? RoleTriagePage(profile: profile)
        : HomePage(profile: profile);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => destination),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showForgotPassword() {
    final controller = TextEditingController(text: _emailController.text);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar senha'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'E-mail corporativo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendPasswordReset(controller.text);
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final backgroundImage = screenWidth >= 900
        ? 'assets/images/bg_login_tablet.png'
        : 'assets/images/bg_login_celular.png';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 306),
                child: _buildFormPanel(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormPanel() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBrand(),
        const SizedBox(height: 6),
        Center(
          child: Text(
            _isSignUp
                ? 'Faça o Cadastro para continuar'
                : 'Faça o Login para continuar',
            style: AppTextStyles.body.copyWith(color: AppColors.white),
          ),
        ),
        const SizedBox(height: 26),
        if (_isSignUp) ...[
          _field(
            _nameController,
            'Nome',
            Icons.person_outline,
            validator: (value) => _required(value, 'nome'),
          ),
          const SizedBox(height: 8),
        ],
        _field(
          _emailController,
          'E-mail',
          Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          validator: _emailValidator,
        ),
        const SizedBox(height: 8),
        _field(
          _passwordController,
          'Senha',
          Icons.lock_outline,
          obscureText: _obscurePassword,
          validator: _passwordValidator,
          suffix: IconButton(
            tooltip: 'Mostrar senha',
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.white,
            ),
          ),
        ),
        if (_isSignUp) ...[
          const SizedBox(height: 8),
          _field(
            _confirmPasswordController,
            'Confirmar senha',
            Icons.lock_outline,
            obscureText: _obscureConfirmation,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'As senhas precisam ser iguais.';
              }
              return null;
            },
            suffix: IconButton(
              tooltip: 'Mostrar confirmação',
              onPressed: () =>
                  setState(() => _obscureConfirmation = !_obscureConfirmation),
              icon: Icon(
                _obscureConfirmation
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.white,
              ),
            ),
          ),
        ],
        if (!_isSignUp)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _showForgotPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.only(top: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Esqueceu a senha?',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.white.withValues(alpha: 0.80),
                ),
              ),
            ),
          ),
        const SizedBox(height: 50),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _submit,
            child: Text(
              _isSignUp ? 'Criar cadastro' : 'Entrar',
              style: AppTextStyles.button.copyWith(color: AppColors.white),
            ),
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _isSignUp ? 'Já possui uma conta? ' : 'Não possui uma conta? ',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.white.withValues(alpha: 0.80),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _isSignUp = !_isSignUp;
                _formKey.currentState?.reset();
              }),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _isSignUp ? 'Faça seu login!' : 'Faça seu cadastro!',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildBrand() => Column(
    children: [
      const SizedBox(height: 171),

      SvgPicture.asset('assets/images/asimembro-branco.svg'),

      const SizedBox(height: 12),
      RichText(
        text: TextSpan(
          style: AppTextStyles.caption.copyWith(
            color: AppColors.white,
            letterSpacing: 1.3,
          ),
          children: const [
            TextSpan(text: 'Bem vindo ao '),
            TextSpan(
              text: 'AsiApp!',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    obscureText: obscureText,
    style: AppTextStyles.caption.copyWith(color: AppColors.white),
    decoration: InputDecoration(
      hintText: label,
      prefixIcon: Icon(icon, color: AppColors.white),
      suffixIcon: suffix,
    ),
  );
}
