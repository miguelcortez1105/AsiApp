import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../perfil/perfil_screen.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _corporateDomain = '@asimovjr.com.br';

class _Account {
  const _Account({required this.name, required this.password, required this.role});

  final String name;
  final String password;
  final String role;
}

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
  final Map<String, _Account> _accounts = {};
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim().toLowerCase();

    if (_isSignUp) {
      if (_accounts.containsKey(email)) {
        _showMessage('Este e-mail já possui cadastro.');
        return;
      }
      _accounts[email] = _Account(
        name: _nameController.text.trim(),
        password: _passwordController.text,
        role: 'Membro',
      );
      setState(() => _isSignUp = false);
      _passwordController.clear();
      _confirmPasswordController.clear();
      _showMessage('Cadastro criado como Membro. Faça seu login.');
      return;
    }

    final account = _accounts[email];
    if (account == null || account.password != _passwordController.text) {
      _showMessage('E-mail ou senha incorretos.');
      return;
    }
    _openHome(account);
  }

  void _loginWithGoogle() {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      _showMessage('Informe seu e-mail para continuar com o Google.');
      return;
    }
    if (_accounts.containsKey(email)) {
      _openHome(_accounts[email]!);
    } else {
      _showMessage(
        'O login com Google é válido apenas para e-mails cadastrados.',
      );
    }
  }

  // TEMPORARIO: este botao ignora cadastro e login; removo antes da entrega.
  void _skipAuthentication() {
    _openHome(
      const _Account(
        name: 'Acesso temporario',
        password: '',
        role: 'Visitante',
      ),
    );
  }

  void _openHome(_Account account) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HomePage(
          profile: UserProfile(
            name: account.name,
            email: _emailController.text.trim().toLowerCase(),
            role: account.role,
          ),
        ),
      ),
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
            onPressed: () {
              Navigator.pop(context);
              _showMessage(
                'Se o e-mail estiver cadastrado, enviaremos as instruções.',
              );
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
            _isSignUp ? 'Faça o Cadastro para continuar' : 'Faça o Login para continuar',
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
              onPressed: () => setState(
                () => _obscureConfirmation = !_obscureConfirmation,
              ),
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
              style: AppTextStyles.caption.copyWith(color: AppColors.white.withValues(alpha: 0.80),),
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
              style: AppTextStyles.caption.copyWith(color: AppColors.white.withValues(alpha: 0.80)),
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
        if (!_isSignUp) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.line)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Ou',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.line)),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: _loginWithGoogle,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset('assets/images/google.png', width: 18, height: 18),
                  ),
                Text(
                  'Faça login com o Google',
                  style: AppTextStyles.caption.copyWith(color: AppColors.white),
                ),
                ]
              ),
            ),
          ),
        ],
        //TEMPORARIO 
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
          onPressed: _skipAuthentication,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
            ),
            child: Text('Acessar sem cadastro ou login',
            style: AppTextStyles.caption.copyWith(
                  color: AppColors.white.withValues(alpha: 0.80),
                  fontWeight: FontWeight.w400),
            )
          ),
        )
        
      ],
    ),
  );

  Widget _buildBrand() => Column(
    children: [
      
      const SizedBox(height: 171),

      SvgPicture.asset(
        'assets/images/asimembro-branco.svg',
      ),

      const SizedBox(height: 12),
      RichText(
      text: TextSpan(
        style: AppTextStyles.caption.copyWith(
          color: AppColors.white,
          letterSpacing: 1.3,
        ),
        children: const [ 
          TextSpan(text: 'Bem vindo ao '),
          TextSpan(text: 'AsiApp!', style: TextStyle(fontWeight: FontWeight.w700))
        ],
      ),
      )
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