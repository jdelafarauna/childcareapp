import 'package:flutter/material.dart';
import '../services/storage.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _rol = 'usuario';
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final users = await Storage.getUsers();

    if (users.containsKey(email)) {
      setState(() { _error = 'El usuario ya existe'; _loading = false; });
      return;
    }

    users[email] = {
      'password': pass,
      'role': _rol,
      'chats': {},
      'availableDates': <String>[],
      'subjects': <String>[],
      'reservations': <dynamic>[], // <-- NUEVO
    };
    await Storage.saveUsers(users);
    await Storage.setSessionEmail(email);

    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => HomePage(email: email, role: _rol),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v == null || !v.contains('@') ? 'Email inválido' : null,
              ),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (v) => v == null || v.length < 4 ? 'Mínimo 4 caracteres' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _rol,
                decoration: const InputDecoration(labelText: 'Tipo de cuenta'),
                items: const [
                  DropdownMenuItem(value: 'usuario', child: Text('Usuario')),
                  DropdownMenuItem(value: 'profesor', child: Text('Profesor')),
                ],
                onChanged: (v) => setState(() => _rol = v ?? 'usuario'),
              ),
              const SizedBox(height: 20),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading ? const CircularProgressIndicator() : const Text('Registrarse'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
