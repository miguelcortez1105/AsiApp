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
  String cargo = 'Membro'; //tem que vir do firebase

  Uint8List? _fotoPerfilBytes; 
  Future<void> _selecionarFoto() async {
    final picker = ImagePicker();
    final imagemEscolhida = await picker.pickImage(source: ImageSource.gallery);

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

  void _salvarPerfil() {
   // FIREBASE
  
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
       content: Text('Perfil salvo com sucesso!'),
      ),
    );
  }

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
              obscureText: !_senhaVisivel,
              decoration: InputDecoration(
                hintText: 'Digite sua nova senha',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _senhaVisivel ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _senhaVisivel = !_senhaVisivel;
                    });
                  },
                ),
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
                onPressed: _salvarPerfil,
                child: const Text('Salvar alterações'),
              ),//child
            ),
          ], //children
        ),
      ),
    );
  }
}