import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final String email;
  final String role;
  const ProfilePage({super.key, required this.email, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(leading: const Icon(Icons.email), title: const Text('Email'), subtitle: Text(email)),
            ListTile(leading: const Icon(Icons.badge), title: const Text('Rol'), subtitle: Text(role)),
          ],
        ),
      ),
    );
  }
}
