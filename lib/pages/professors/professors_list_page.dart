import 'package:flutter/material.dart';
import '../../services/storage.dart';
import '../chat_page.dart';
import '../calendar/professor_calendar_page.dart';

class ProfessorsListPage extends StatefulWidget {
  final String currentEmail;
  const ProfessorsListPage({super.key, required this.currentEmail});

  @override
  State<ProfessorsListPage> createState() => _ProfessorsListPageState();
}

class _ProfessorsListPageState extends State<ProfessorsListPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _profs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await Storage.getUsers();
    final profs = <Map<String, dynamic>>[];
    users.forEach((email, data) {
      if (data['role'] == 'profesor') {
        profs.add({
          'email': email,
          'subjects': (data['subjects'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
        });
      }
    });
    setState(() {
      _profs = profs;
      _loading = false;
    });
  }

  void _openChat(String profesorEmail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          emailUsuario: widget.currentEmail,
          emailProfesor: profesorEmail,
          nombreProfesor: profesorEmail,
        ),
      ),
    );
  }

  void _openCalendar(String profesorEmail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfessorCalendarPage(profesorEmail: profesorEmail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Profesores')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _profs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final p = _profs[i];
          final email = p['email'] as String;
          final subjects = (p['subjects'] as List).join(', ');
          return Card(
            child: ListTile(
              title: Text(email),
              subtitle: Text(subjects.isEmpty ? 'Sin asignaturas publicadas' : subjects),
              trailing: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(onPressed: () => _openChat(email), child: const Text('Chatear')),
                  ElevatedButton(onPressed: () => _openCalendar(email), child: const Text('Calendario')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
