import 'package:flutter/material.dart';

import 'home_page.dart';
import 'feature/home/screens/perfil_screen.dart';

const _ink = Color(0xFF17212B);
const _muted = Color(0xFF6E7A86);
const _paper = Color(0xFFF5F7F8);
const _teal = Color(0xFF087E8B);
const _coral = Color(0xFFE76F51);
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
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 64 : 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1060),
                    child: isWide ? _buildWideLayout() : _buildFormPanel(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWideLayout() => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(child: _buildIntro()),
      const SizedBox(width: 72),
      SizedBox(width: 410, child: _buildFormPanel()),
    ],
  );

  Widget _buildIntro() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 64,
        height: 64,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Image.asset('assets/logo.png', fit: BoxFit.contain),
      ),
      const SizedBox(height: 28),
      const Text(
        'AsiApp',
        style: TextStyle(
          color: _teal,
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        _isSignUp
            ? 'Seu próximo passo começa aqui.'
            : 'Decisões melhores começam com clareza.',
        style: const TextStyle(
          color: _ink,
          fontSize: 38,
          height: 1.08,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'Acesse o painel executivo da Asimov e acompanhe o que move o negócio.',
        style: TextStyle(color: _muted, fontSize: 16, height: 1.5),
      ),
      const SizedBox(height: 28),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _coral,
              shape: BoxShape.circle,
            ),
          ),
          const Text(
            'Ambiente exclusivo para o time Asimov',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
        ],
      ),
    ],
  );

  Widget _buildFormPanel() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (MediaQuery.sizeOf(context).width < 900) ...[
          _buildMobileBrand(),
          const SizedBox(height: 28),
        ],
        Text(
          _isSignUp ? 'Criar cadastro' : 'Bem-vindo de volta',
          style: const TextStyle(
            color: _ink,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isSignUp
              ? 'Use seu e-mail corporativo para entrar no time.'
              : 'Entre para continuar no seu painel.',
          style: const TextStyle(color: _muted, fontSize: 14),
        ),
        const SizedBox(height: 26),
        if (_isSignUp) ...[
          _field(
            _nameController,
            'Nome',
            Icons.person_outline,
            validator: (value) => _required(value, 'nome'),
          ),
          const SizedBox(height: 14),
        ],
        _field(
          _emailController,
          'E-mail',
          Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          validator: _emailValidator,
        ),
        const SizedBox(height: 14),
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
            ),
          ),
        ),
        if (_isSignUp) ...[
          const SizedBox(height: 14),
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
              ),
            ),
          ),
        ],
        if (!_isSignUp)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPassword,
              child: const Text('Esqueci minha senha'),
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _submit,
            child: Text(_isSignUp ? 'Criar cadastro' : 'Entrar'),
          ),
        ),
        if (!_isSignUp) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('ou', style: TextStyle(color: _muted)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _loginWithGoogle,
              icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
              label: const Text('Continuar com Google'),
            ),
          ),
        ],
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _isSignUp ? 'Já tem uma conta?' : 'Ainda não tem cadastro?',
              style: const TextStyle(color: _muted),
            ),
            TextButton(
              onPressed: () => setState(() {
                _isSignUp = !_isSignUp;
                _formKey.currentState?.reset();
              }),
              child: Text(_isSignUp ? 'Entrar' : 'Cadastre-se'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildMobileBrand() => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Image.asset('assets/logo.png'),
      ),
      const SizedBox(width: 12),
      const Text(
        'AsiApp',
        style: TextStyle(
          color: _teal,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
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
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
    ),
  );
}
