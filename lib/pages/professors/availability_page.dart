import 'package:flutter/material.dart';
import '../../services/storage.dart';

/// Pantalla para que un profesor gestione sus días disponibles (YYYY-MM-DD)
class AvailabilityPage extends StatefulWidget {
  final String email;
  const AvailabilityPage({super.key, required this.email});

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  bool _loading = true;
  List<String> _dates = []; // almacenadas como YYYY-MM-DD

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await Storage.getUsers();
    final me = users[widget.email] ?? {};
    final List<String> saved = (me['availableDates'] as List?)?.map((e) => e.toString()).toList() ?? [];
    setState(() {
      _dates = saved..sort();
      _loading = false;
    });
  }

  Future<void> _save() async {
    final users = await Storage.getUsers();
    users[widget.email] ??= {};
    users[widget.email]['availableDates'] = _dates;
    await Storage.saveUsers(users);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disponibilidad guardada')));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 0)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      final s = picked.toIso8601String().substring(0, 10); // YYYY-MM-DD
      if (!_dates.contains(s)) {
        setState(() => _dates.add(s));
        await _save();
      }
    }
  }

  void _removeDate(String d) async {
    setState(() => _dates.remove(d));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Mis días disponibles')),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickDate,
        child: const Icon(Icons.add),
      ),
      body: _dates.isEmpty
          ? const Center(child: Text('Aún no añadiste días. Pulsa + para agregar.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _dates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final d = _dates[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_available),
                    title: Text(d),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeDate(d),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
