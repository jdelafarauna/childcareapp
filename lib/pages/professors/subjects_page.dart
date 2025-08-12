import 'package:flutter/material.dart';
import '../../services/storage.dart';

class SubjectsPage extends StatefulWidget {
  final String email;
  const SubjectsPage({super.key, required this.email});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  bool _loading = true;
  final _ctrl = TextEditingController();
  List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await Storage.getUsers();
    final me = users[widget.email] ?? {};
    final List<String> saved = (me['subjects'] as List?)?.map((e) => e.toString()).toList() ?? [];
    setState(() {
      _subjects = saved..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      _loading = false;
    });
  }

  Future<void> _save() async {
    final users = await Storage.getUsers();
    users[widget.email] ??= {};
    users[widget.email]['subjects'] = _subjects;
    await Storage.saveUsers(users);
  }

  Future<void> _add() async {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) return;
    final s = _normalize(raw);
    if (!_subjects.map(_normalize).contains(s)) {
      setState(() => _subjects.add(raw));
      await _save();
    }
    _ctrl.clear();
  }

  String _normalize(String x) => x.toLowerCase();

  Future<void> _remove(String s) async {
    setState(() => _subjects.remove(s));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Mis asignaturas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: 'Añadir asignatura (p. ej. Matemáticas)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _add, child: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _subjects.isEmpty
                  ? const Center(child: Text('Aún no añadiste asignaturas.'))
                  : ListView.separated(
                      itemCount: _subjects.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final s = _subjects[i];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.menu_book),
                            title: Text(s),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _remove(s),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
