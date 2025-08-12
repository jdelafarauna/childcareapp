import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/storage.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _seedExampleUsers();
  runApp(const App());
}

Future<void> _seedExampleUsers() async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString('users');
  if (existing != null) return; // ya hay datos, no tocar

  final exampleUsers = {
    "nuria@gmail.com": {
      "password": "nuria",
      "role": "profesor",
      "chats": {},
      "availableDates": <String>[],
      "subjects": <String>[],
      "reservations": <dynamic>[],
    },
    "jose@gmail.com": {
      "password": "jose",
      "role": "usuario",
      "chats": {},
      "availableDates": <String>[],
      "subjects": <String>[],
      "reservations": <dynamic>[],
    }
  };

  await prefs.setString('users', jsonEncode(exampleUsers));
}

class App extends StatelessWidget {
  const App({super.key});

  Future<Widget> _decideStart() async {
    final email = await Storage.getSessionEmail();
    if (email == null) return const LoginPage();
    final users = await Storage.getUsers();
    final user = users[email];
    if (user == null) return const LoginPage();
    final role = (user['role'] as String?) ?? 'usuario';
    return HomePage(email: email, role: role);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Usuarios y Profesores',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Widget>(
        future: _decideStart(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snap.data!;
        },
      ),
    );
  }
}
