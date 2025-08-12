import 'package:flutter/material.dart';
import '../services/storage.dart';
import 'register_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final users = await Storage.getUsers();

    if (!users.containsKey(email)) {
      setState(() { _error = 'Usuario no encontrado'; _loading = false; });
      return;
    }
    final user = users[email];
    if (user['password'] != pass) {
      setState(() { _error = 'Contraseña incorrecta'; _loading = false; });
      return;
    }

    await Storage.setSessionEmail(email);
    final role = user['role'] as String? ?? 'usuario';

    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => HomePage(email: email, role: role),
    ));
  }

  void _goRegister() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
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
              const SizedBox(height: 20),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading ? const CircularProgressIndicator() : const Text('Iniciar sesión'),
              ),
              TextButton(onPressed: _goRegister, child: const Text('Crear una cuenta nueva')),
            ],
          ),
        ),
      ),
    );
  }
}
