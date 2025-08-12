import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Usuarios y Profesores',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Modelo simple de usuario
class User {
  final String email;
  final String password;
  final String role; // 'usuario' o 'profesor'

  User({required this.email, required this.password, required this.role});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'role': role,
      };

  static User fromJson(Map<String, dynamic> json) => User(
        email: json['email'],
        password: json['password'],
        role: json['role'],
      );
}

// -------------------- Login Page ---------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<Map<String, dynamic>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersStr = prefs.getString('users');
    if (usersStr == null) return {};
    return jsonDecode(usersStr);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    final users = await _loadUsers();

    if (!users.containsKey(email)) {
      setState(() {
        _error = 'Usuario no encontrado';
        _loading = false;
      });
      return;
    }

    final userData = users[email];
    if (userData['password'] != password) {
      setState(() {
        _error = 'Contraseña incorrecta';
        _loading = false;
      });
      return;
    }

    // Guardar sesión activa
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_email', email);

    setState(() {
      _loading = false;
    });

    // Redirigir según rol
    if (userData['role'] == 'profesor') {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => ProfesoresDashboard(email: email)));
    } else {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => UsuariosDashboard(email: email)));
    }
  }

  void _irRegistro() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const RegistroPage()));
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
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Email inválido' : null,
              ),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (v) =>
                    v == null || v.length < 4 ? 'Mínimo 4 caracteres' : null,
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Text(_error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Iniciar sesión'),
              ),
              TextButton(
                onPressed: _irRegistro,
                child: const Text('Crear una cuenta nueva'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Registro Page --------------------

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  String _rol = 'usuario';

  bool _loading = false;
  String? _error;

  Future<Map<String, dynamic>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersStr = prefs.getString('users');
    if (usersStr == null) return {};
    return jsonDecode(usersStr);
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    final users = await _loadUsers();

    if (users.containsKey(email)) {
      setState(() {
        _error = 'El usuario ya existe';
        _loading = false;
      });
      return;
    }

    users[email] = {
      'password': password,
      'role': _rol,
      'chats': {},
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('users', jsonEncode(users));

    // Guardar sesión activa
    await prefs.setString('session_email', email);

    setState(() {
      _loading = false;
    });

    // Redirigir según rol
    if (_rol == 'profesor') {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => ProfesoresDashboard(email: email)));
    } else {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => UsuariosDashboard(email: email)));
    }
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
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Email inválido' : null,
              ),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (v) =>
                    v == null || v.length < 4 ? 'Mínimo 4 caracteres' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _rol,
                decoration: const InputDecoration(labelText: 'Tipo de cuenta'),
                items: const [
                  DropdownMenuItem(value: 'usuario', child: Text('Usuario')),
                  DropdownMenuItem(value: 'profesor', child: Text('Profesor')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _rol = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Text(_error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
              ElevatedButton(
                onPressed: _loading ? null : _registrar,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Registrarse'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- Usuarios Dashboard ------------------

class UsuariosDashboard extends StatefulWidget {
  final String email;

  const UsuariosDashboard({super.key, required this.email});

  @override
  State<UsuariosDashboard> createState() => _UsuariosDashboardState();
}

class _UsuariosDashboardState extends State<UsuariosDashboard> {
  Map<String, dynamic> _users = {};
  Map<String, dynamic>? _userData;
  bool _loading = true;
  List<Map<String, dynamic>> _profesores = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString('users');
    if (usersStr == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    final usersMap = jsonDecode(usersStr);

    final profesoresFiltrados = usersMap.entries.where((e) => e.value['role'] == 'profesor').toList();

    setState(() {
      _users = usersMap;
      _userData = usersMap[widget.email];
      _profesores = profesoresFiltrados
          .map((e) => {
                'email': e.key,
                'nombre': e.key.split('@')[0],
              })
          .toList();
      _loading = false;
    });
  }

  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_email');
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false);
  }

  void _abrirChatConProfesor(String profesorEmail, String profesorNombre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          emailUsuario: widget.email,
          emailProfesor: profesorEmail,
          nombreProfesor: profesorNombre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Usuario'),
        actions: [
          IconButton(
              onPressed: _cerrarSesion, icon: const Icon(Icons.logout), tooltip: 'Cerrar sesión'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Profesores disponibles:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (_profesores.isEmpty)
            const Text('No hay profesores disponibles'),
          ..._profesores.map((profesor) {
            return Card(
              child: ListTile(
                title: Text(profesor['nombre']!),
                subtitle: Text(profesor['email']!),
                trailing: ElevatedButton(
                  child: const Text('Chatear'),
                  onPressed: () => _abrirChatConProfesor(profesor['email']!, profesor['nombre']!),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ----------------- Profesores Dashboard ------------------

class ProfesoresDashboard extends StatefulWidget {
  final String email;

  const ProfesoresDashboard({super.key, required this.email});

  @override
  State<ProfesoresDashboard> createState() => _ProfesoresDashboardState();
}

class _ProfesoresDashboardState extends State<ProfesoresDashboard> {
  Map<String, dynamic> _users = {};
  bool _loading = true;
  List<Map<String, dynamic>> _usuarios = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString('users');
    if (usersStr == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    final usersMap = jsonDecode(usersStr);

    final usuariosFiltrados = usersMap.entries.where((e) => e.value['role'] == 'usuario').toList();

    setState(() {
      _users = usersMap;
      _usuarios = usuariosFiltrados
          .map((e) => {
                'email': e.key,
                'nombre': e.key.split('@')[0],
              })
          .toList();
      _loading = false;
    });
  }

  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_email');
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false);
  }

  void _abrirChatConUsuario(String usuarioEmail, String usuarioNombre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          emailUsuario: usuarioEmail,
          emailProfesor: widget.email,
          nombreProfesor: widget.email,
          esProfesor: true,
          nombreUsuario: usuarioNombre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Profesor'),
        actions: [
          IconButton(
              onPressed: _cerrarSesion, icon: const Icon(Icons.logout), tooltip: 'Cerrar sesión'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Chats con usuarios:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (_usuarios.isEmpty)
            const Text('No hay usuarios registrados'),
          ..._usuarios.map((usuario) {
            return Card(
              child: ListTile(
                title: Text(usuario['nombre']!),
                subtitle: Text(usuario['email']!),
                trailing: ElevatedButton(
                  child: const Text('Chatear'),
                  onPressed: () => _abrirChatConUsuario(usuario['email']!, usuario['nombre']!),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ----------------- Página de Chat ------------------

class ChatPage extends StatefulWidget {
  final String emailUsuario;
  final String emailProfesor;
  final String nombreProfesor;
  final bool esProfesor;
  final String? nombreUsuario;

  ChatPage({
    super.key,
    required this.emailUsuario,
    required this.emailProfesor,
    required this.nombreProfesor,
    this.esProfesor = false,
    this.nombreUsuario,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> _chat = [];
  final TextEditingController _mensajeCtrl = TextEditingController();
  bool _loading = true;

  String get chatKey {
    // La clave que identifica el chat entre usuario y profesor
    final sortedEmails = [widget.emailUsuario, widget.emailProfesor]..sort();
    return 'chat_${sortedEmails[0]}_${sortedEmails[1]}';
  }

  Future<Map<String, dynamic>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersStr = prefs.getString('users');
    if (usersStr == null) return {};
    return jsonDecode(usersStr);
  }

  Future<void> _cargarChat() async {
  final prefs = await SharedPreferences.getInstance();
  final users = await _loadUsers();
  final chats = users[widget.esProfesor ? widget.emailProfesor : widget.emailUsuario]['chats'] ?? {};
  final chatStr = chats[chatKey];
  if (chatStr != null) {
    final List<dynamic> decoded = jsonDecode(chatStr);
    setState(() {
      _chat = decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    });

  }
  setState(() {
    _loading = false;
  });
}


  Future<void> _guardarChat() async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _loadUsers();

    final emailActual = widget.esProfesor ? widget.emailProfesor : widget.emailUsuario;
    final emailOtro = widget.esProfesor ? widget.emailUsuario : widget.emailProfesor;

    final chatStr = jsonEncode(_chat);

    users[emailActual]['chats'] ??= {};
    users[emailActual]['chats'][chatKey] = chatStr;

    users[emailOtro]['chats'] ??= {};
    users[emailOtro]['chats'][chatKey] = chatStr;

    await prefs.setString('users', jsonEncode(users));
  }

  @override
  void initState() {
    super.initState();
    _cargarChat();
  }

  void _enviarMensaje() async {
    final texto = _mensajeCtrl.text.trim();
    if (texto.isEmpty) return;
    final nuevoMensaje = {
      'emisor': widget.esProfesor ? 'profesor' : 'usuario',
      'texto': texto,
      'fecha': DateTime.now().toIso8601String(),
    };
    setState(() {
      _chat.add(nuevoMensaje);
      _mensajeCtrl.clear();
    });
    await _guardarChat();
  }

  Widget _buildMensaje(Map<String, dynamic> mensaje) {
    final esEmisor = (widget.esProfesor && mensaje['emisor'] == 'profesor') ||
        (!widget.esProfesor && mensaje['emisor'] == 'usuario');
    final align = esEmisor ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bgColor = esEmisor ? Colors.blue[300] : Colors.grey[300];
    final textColor = esEmisor ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(mensaje['texto'], style: TextStyle(color: textColor)),
          ),
          Text(
            DateTime.parse(mensaje['fecha']).toLocal().toString().substring(0, 16),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.esProfesor
        ? 'Chat con ${widget.nombreUsuario ?? widget.emailUsuario.split('@')[0]}'
        : 'Chat con ${widget.nombreProfesor}';

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Column(
        children: [
          Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      reverse: false,
                      itemCount: _chat.length,
                      itemBuilder: (_, i) => _buildMensaje(_chat[i]),
                    )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _enviarMensaje,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
