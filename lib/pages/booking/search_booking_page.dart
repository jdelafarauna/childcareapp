import 'package:flutter/material.dart';
import '../../services/storage.dart';
import '../chat_page.dart';
import '../calendar/professor_calendar_page.dart';

class SearchBookingPage extends StatefulWidget {
  final String currentEmail;
  const SearchBookingPage({super.key, required this.currentEmail});

  @override
  State<SearchBookingPage> createState() => _SearchBookingPageState();
}

class _SearchBookingPageState extends State<SearchBookingPage> {
  final List<String> _selectedDays = [];
  final _subjectCtrl = TextEditingController();
  bool _searching = false;
  List<String> _results = [];

  Future<void> _addDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      final s = picked.toIso8601String().substring(0, 10);
      if (!_selectedDays.contains(s)) {
        setState(() => _selectedDays.add(s));
      }
    }
  }

  void _removeDay(String d) => setState(() => _selectedDays.remove(d));

  bool _subjectMatches(List<String> teacherSubjects, String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    return teacherSubjects.any((s) => s.toLowerCase().contains(q));
  }

  Future<void> _search() async {
    setState(() { _searching = true; _results = []; });
    final users = await Storage.getUsers();
    final query = _subjectCtrl.text;

    final profs = <String>[];
    users.forEach((email, data) {
      if (data['role'] == 'profesor') {
        final days = (data['availableDates'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final subjects = (data['subjects'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final hasDays = _selectedDays.every((d) => days.contains(d));
        final hasSubject = _subjectMatches(subjects, query);
        if (hasDays && hasSubject) profs.add(email);
      }
    });

    setState(() { _results = profs; _searching = false; });
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

  Future<void> _openReserveSheet(String profesorEmail) async {
    final users = await Storage.getUsers();
    final prof = users[profesorEmail] ?? {};
    final List<String> profDays =
        (prof['availableDates'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final List<String> profSubjects =
        (prof['subjects'] as List?)?.map((e) => e.toString()).toList() ?? [];

    final List<String> daysForPicker = _selectedDays.isNotEmpty
        ? profDays.where((d) => _selectedDays.contains(d)).toList()
        : profDays;

    if (daysForPicker.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este profesor no tiene los días seleccionados disponibles.')),
      );
      return;
    }

    String chosenDate = daysForPicker.first;
    TimeOfDay? start;
    TimeOfDay? end;

    String? selectedSubject = profSubjects.isNotEmpty ? profSubjects.first : null;
    final manualCtrl = TextEditingController(
      text: _subjectCtrl.text.isNotEmpty ? _subjectCtrl.text : '',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> pickStart() async {
              final now = TimeOfDay.now();
              final t = await showTimePicker(context: ctx, initialTime: start ?? now);
              if (t != null) setLocal(() => start = t);
            }

            Future<void> pickEnd() async {
              final base = start ?? TimeOfDay.now();
              final t = await showTimePicker(context: ctx, initialTime: end ?? base);
              if (t != null) setLocal(() => end = t);
            }

            String _fmt(TimeOfDay? t) =>
                t == null ? '--:--' : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

            String subjectToSave() {
              if (profSubjects.isNotEmpty) {
                return (selectedSubject ?? '').trim();
              }
              return manualCtrl.text.trim();
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                left: 16, right: 16, top: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Reservar clase con $profesorEmail', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: chosenDate,
                    items: daysForPicker.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => setLocal(() => chosenDate = v ?? chosenDate),
                    decoration: const InputDecoration(labelText: 'Día', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickStart,
                          icon: const Icon(Icons.schedule),
                          label: Text('Inicio: ${_fmt(start)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickEnd,
                          icon: const Icon(Icons.schedule_outlined),
                          label: Text('Fin: ${_fmt(end)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (profSubjects.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: selectedSubject,
                      items: profSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setLocal(() => selectedSubject = v),
                      decoration: const InputDecoration(labelText: 'Asignatura', border: OutlineInputBorder()),
                    )
                  else
                    TextField(
                      controller: manualCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Asignatura',
                        hintText: 'Ej: Matemáticas',
                        border: OutlineInputBorder(),
                      ),
                    ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Confirmar reserva'),
                      onPressed: () async {
                        final subj = subjectToSave();
                        if (subj.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Indica la asignatura')),
                          );
                          return;
                        }
                        if (start == null || end == null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Selecciona hora de inicio y fin')),
                          );
                          return;
                        }
                        final s = '${start!.hour.toString().padLeft(2, '0')}:${start!.minute.toString().padLeft(2, '0')}';
                        final e = '${end!.hour.toString().padLeft(2, '0')}:${end!.minute.toString().padLeft(2, '0')}';
                        try {
                          await Storage.addReservation(
                            profesor: profesorEmail,
                            usuario: widget.currentEmail,
                            date: chosenDate,
                            start: s,
                            end: e,
                            subject: subj,
                          );
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Reserva creada: $chosenDate $s–$e · $subj')),
                            );
                          }
                        } catch (err) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(err.toString().replaceFirst('Exception: ', ''))),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSearch = _selectedDays.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Reservar por fecha')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDay,
        child: const Icon(Icons.add),
        tooltip: 'Añadir día',
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Filtrar por asignatura (opcional)',
                hintText: 'Ej: Matemáticas, Inglés...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.menu_book),
              ),
              onSubmitted: (_) => canSearch ? _search() : null,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in _selectedDays)
                    Chip(label: Text(d), onDeleted: () => _removeDay(d)),
                  if (_selectedDays.isEmpty)
                    const Text('Añade uno o más días con el botón +'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton.icon(
              onPressed: canSearch && !_searching ? _search : null,
              icon: const Icon(Icons.search),
              label: const Text('Buscar profesores disponibles'),
            ),
          ),
          const Divider(),
          if (_searching)
            const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
          if (!_searching)
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('Sin resultados'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final email = _results[i];
                        return Card(
                          child: ListTile(
                            title: Text(email),
                            subtitle: const Text('Disponible los días seleccionados'),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton(onPressed: () => _openChat(email), child: const Text('Chatear')),
                                OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => ProfessorCalendarPage(profesorEmail: email),
                                    ));
                                  },
                                  child: const Text('Calendario'),
                                ),
                                ElevatedButton(onPressed: () => _openReserveSheet(email), child: const Text('Reservar')),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
