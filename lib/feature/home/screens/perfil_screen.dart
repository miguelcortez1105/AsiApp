import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:image_cropper/image_cropper.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>{
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  bool _senhaVisivel = false;
  final TextEditingController _confirmarSenhaController = TextEditingController();
  bool _confirmarSenhaVisivel = false;
  final _formKey = GlobalKey<FormState>();
  String cargo = 'Membro'; //tem que vir do firebase
  bool _carregando = false;

  Uint8List? _fotoPerfilBytes; 
  Future<void> _selecionarFoto() async {
    final picker = ImagePicker();
    final imagemEscolhida = await picker.pickImage(source: ImageSource.camera);

    if (imagemEscolhida == null) return;

    final imagemRecortada = await ImageCropper().cropImage(
      sourcePath: imagemEscolhida.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Ajustar foto',
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Ajustar foto',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (imagemRecortada == null) return;

    final bytes = await imagemRecortada.readAsBytes();
    setState(() {
      _fotoPerfilBytes = bytes;
    });
  }

  Future<void> _salvarPerfil() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _carregando = true;
      });

      // FIREBASE
      await Future.delayed(const Duration(seconds: 2));
      //mudar isso com o firebase
      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil salvo com sucesso!')),
      );
    }
  }
  void _sairDaConta() {
    //substituir por lógica real de logout (Firebase Auth) quando conectado
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: navegar de volta pra tela de login
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  Widget _buildFoto() {
    return Column(
      children: [
        Center(
          child: CircleAvatar(
            radius: 50,
            backgroundImage: _fotoPerfilBytes != null ? MemoryImage(_fotoPerfilBytes!) : null,
            child: _fotoPerfilBytes == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _selecionarFoto,
            child: const Text('Alterar foto'),
          ),
        ),
      ],
    );
  }

  Widget _buildCampoNome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nome'),
        TextFormField(
          controller: _nomeController,
          decoration: const InputDecoration(
            hintText: 'Digite seu nome',
            border: OutlineInputBorder(),
          ),
          validator: (valor) {
            if (valor == null || valor.trim().isEmpty) {
              return 'Digite seu nome';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCampoSenha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Senha'),
        TextFormField(
          controller: _senhaController,
          obscureText: !_senhaVisivel,
          decoration: InputDecoration(
            hintText: 'Digite sua nova senha',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_senhaVisivel ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _senhaVisivel = !_senhaVisivel;
                });
              },
            ),
          ),
          validator: (valor) {
            if (valor == null || valor.isEmpty) {
              return 'Digite uma senha';
            }
            if (valor.length < 6) {
              return 'A senha precisa ter no mínimo 6 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCampoConfirmarSenha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Confirmar senha'),
        TextFormField(
          controller: _confirmarSenhaController,
          obscureText: !_confirmarSenhaVisivel,
          decoration: InputDecoration(
            hintText: 'Digite a senha novamente',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_confirmarSenhaVisivel ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _confirmarSenhaVisivel = !_confirmarSenhaVisivel;
                });
              },
            ),
          ),
          validator: (valor) {
            if (valor == null || valor.isEmpty) {
              return 'Confirme sua senha';
            }
            if (valor != _senhaController.text) {
              return 'As senhas não coincidem';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCargo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cargo'),
        Text(
          cargo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBotaoSalvar() {
    return Center(
      child: ElevatedButton(
        onPressed: _carregando ? null : _salvarPerfil,
        child: _carregando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Salvar alterações'),
      ),
    );
  }

  Widget _buildBotaoSair() {
    return Center(
      child: TextButton(
        onPressed: _sairDaConta,
        style: TextButton.styleFrom(foregroundColor: Colors.red),
        child: const Text('Sair da conta'),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:CrossAxisAlignment.start,
            children: [
              _buildFoto(),
              const SizedBox(height: 24),
              _buildCampoNome(),
              const SizedBox(height: 16),
              _buildCampoSenha(),
              const SizedBox(height: 16),
              _buildCampoConfirmarSenha(),
              const SizedBox(height: 16),
              _buildCargo(),
              const SizedBox(height: 24),
              _buildBotaoSalvar(),
              const SizedBox(height: 24),
              _buildBotaoSair(),
            ], // children
          ),
        ),
      ),
    );
  }
}