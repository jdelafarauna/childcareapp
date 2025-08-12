import 'package:flutter/material.dart';
import '../../services/storage.dart';

class ReservationsPage extends StatefulWidget {
  final String currentEmail;
  final String role; // 'usuario' | 'profesor'
  const ReservationsPage({super.key, required this.currentEmail, required this.role});

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await Storage.getUsers();
    final me = users[widget.currentEmail] ?? {};
    final List list = (me['reservations'] as List?) ?? [];
    final items = list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();

    items.sort((a, b) {
      final c = (a['date'] as String).compareTo(b['date'] as String);
      if (c != 0) return c;
      return (a['start'] as String).compareTo(b['start'] as String);
    });

    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'accepted': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange; // pending
    }
  }

  Future<void> _decide(String reservationId, String newStatus) async {
    try {
      await Storage.updateReservationStatus(
        profesorEmail: widget.currentEmail,
        reservationId: reservationId,
        newStatus: newStatus,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reserva ${newStatus == "accepted" ? "aceptada" : "denegada"}')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProfesor = widget.role == 'profesor';

    return Scaffold(
      appBar: AppBar(title: const Text('Mis reservas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No tienes reservas todavía.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = _items[i];
                    final counterpart = isProfesor ? r['usuario'] : r['profesor'];
                    final subject = (r['subject'] ?? '').toString().trim();
                    final status = (r['status'] ?? 'pending').toString();

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.schedule),
                        title: Text('${r['date']}  ${r['start']}–${r['end']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isProfesor ? 'Alumno: $counterpart' : 'Profesor: $counterpart'),
                            Text('Asignatura: ${subject.isEmpty ? '—' : subject}'),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: isProfesor && status == 'pending'
                            ? Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => _decide(r['id'], 'rejected'),
                                    child: const Text('Denegar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _decide(r['id'], 'accepted'),
                                    child: const Text('Aceptar'),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
