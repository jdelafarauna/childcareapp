import 'package:flutter/material.dart';
import '../../services/storage.dart';

class HoursPage extends StatefulWidget {
  final String email;
  const HoursPage({super.key, required this.email});

  @override
  State<HoursPage> createState() => _HoursPageState();
}

class _HoursPageState extends State<HoursPage> {
  bool _loading = true;
  String? _defStart;
  String? _defEnd;

  final List<String> _overrides = [];
  Map<String, Map<String, String>> _dayWindows = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await Storage.getUsers();
    final me = users[widget.email] ?? {};
    final def = (me['defaultWindow'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString()));
    final dw = (me['dayWindows'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), {'start': v['start'].toString(), 'end': v['end'].toString()}),
        ) ??
        {};

    setState(() {
      _defStart = def?['start'];
      _defEnd = def?['end'];
      _dayWindows = dw;
      _overrides
        ..clear()
        ..addAll(dw.keys.toList()..sort());
      _loading = false;
    });
  }

  Future<void> _pickDefaultStart() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) {
      setState(() => _defStart = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _pickDefaultEnd() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) {
      setState(() => _defEnd = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _saveDefault() async {
    if (_defStart == null || _defEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona inicio y fin')));
      return;
    }
    try {
      await Storage.setDefaultWindow(profesor: widget.email, start: _defStart!, end: _defEnd!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Franja por defecto guardada')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _addOverride() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    final key = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';

    TimeOfDay? s = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 16, minute: 0));
    if (s == null) return;
    TimeOfDay? e = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
    if (e == null) return;

    final start = '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}';
    final end = '${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}';
    try {
      await Storage.setDayWindow(profesor: widget.email, date: key, start: start, end: end);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Override guardado para $key')));
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString())));
    }
  }

  Future<void> _removeOverride(String date) async {
    await Storage.setDayWindow(profesor: widget.email, date: date, start: null, end: null);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Mi franja horaria')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addOverride,
        tooltip: 'Añadir override por día',
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Franja por defecto', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDefaultStart,
                  icon: const Icon(Icons.schedule),
                  label: Text('Inicio: ${_defStart ?? "--:--"}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDefaultEnd,
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text('Fin: ${_defEnd ?? "--:--"}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _saveDefault, child: const Text('Guardar franja por defecto')),
          const Divider(height: 32),
          const Text('Overrides por día', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_overrides.isEmpty)
            const Text('No tienes overrides por día.')
          else
            ..._overrides.map((d) {
              final w = _dayWindows[d]!;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.edit_calendar),
                  title: Text(d),
                  subtitle: Text('${w['start']} – ${w['end']}'),
                  trailing: IconButton(
                    tooltip: 'Eliminar override',
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeOverride(d),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
