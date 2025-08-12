import 'package:flutter/material.dart';
import '../../services/storage.dart';

class ProfessorCalendarPage extends StatefulWidget {
  final String profesorEmail;
  const ProfessorCalendarPage({super.key, required this.profesorEmail});

  @override
  State<ProfessorCalendarPage> createState() => _ProfessorCalendarPageState();
}

class _ProfessorCalendarPageState extends State<ProfessorCalendarPage> {
  DateTime _current = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _loading = true;
  Map<String, String> _statuses = {};

  Color _colorFor(String s) {
    switch (s) {
      case 'free': return Colors.green;
      case 'partial': return Colors.amber;
      case 'full': return Colors.red;
      default: return Colors.grey.shade300; // unavailable
    }
  }

  String _fmtKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadMonth() async {
    setState(() => _loading = true);
    final map = await Storage.monthStatusesForProfessor(
      profesor: widget.profesorEmail,
      year: _current.year,
      month: _current.month,
    );
    setState(() {
      _statuses = map;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  void _prevMonth() {
    setState(() => _current = DateTime(_current.year, _current.month - 1, 1));
    _loadMonth();
  }

  void _nextMonth() {
    setState(() => _current = DateTime(_current.year, _current.month + 1, 1));
    _loadMonth();
  }

  Future<void> _showDayDetail(DateTime day) async {
    final users = await Storage.getUsers();
    final prof = users[widget.profesorEmail] ?? {};
    final key = _fmtKey(day);
    final status = _statuses[key] ?? 'unavailable';
    final window = Storage.getWindowForDateSync(prof, key);
    final List res = (prof['reservations'] as List?) ?? [];

    final slots = res
        .where((r) => r['date'] == key)
        .map((r) => '${r['start']}–${r['end']} (${r['status']}) · ${r['subject'] ?? ''}')
        .toList();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: _colorFor(status), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text('Estado: $status'),
              ],
            ),
            const SizedBox(height: 8),
            Text('Franja: ${window == null ? "—" : "${window['start']} – ${window['end']}"}'),
            const SizedBox(height: 8),
            const Text('Reservas:'),
            if (slots.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 4), child: Text('No hay reservas.')),
            if (slots.isNotEmpty)
              ...slots.map((s) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• $s'),
                  )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(_current.year, _current.month, 1).weekday; // 1..7 (Mon..Sun)
    final daysInMonth = DateTime(_current.year, _current.month + 1, 0).day;

    final cells = <Widget>[];

    // Encabezado (L a D)
    const names = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    cells.addAll(names.map((n) => Center(child: Text(n, style: const TextStyle(fontWeight: FontWeight.bold)))));

    // Huecos previos al día 1
    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_current.year, _current.month, d);
      final key = _fmtKey(date);
      final st = _statuses[key] ?? 'unavailable';
      final color = _colorFor(st);

      cells.add(GestureDetector(
        onTap: () => _showDayDetail(date),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            color: color.withOpacity(st == 'unavailable' ? 0.3 : 0.25),
          ),
          alignment: Alignment.center,
          height: 40,
          child: Text('$d'),
        ),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Calendario · ${widget.profesorEmail}'),
        actions: [
          IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
          IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _Legend(color: Colors.green, label: 'Libre'),
                      _Legend(color: Colors.amber, label: 'Huecos'),
                      _Legend(color: Colors.red, label: 'Completo'),
                      _Legend(color: Colors.grey, label: 'No disponible'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 7,
                      children: cells,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
