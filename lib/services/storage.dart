import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static const _kUsers = 'users';
  static const _kSession = 'session_email';

  // ---------- Base ----------
  static Future<Map<String, dynamic>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kUsers);
    if (s == null) return {};
    try { return jsonDecode(s); } catch (_) { return {}; }
  }

  static Future<void> saveUsers(Map<String, dynamic> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsers, jsonEncode(users));
  }

  static Future<String?> getSessionEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSession);
  }

  static Future<void> setSessionEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSession, email);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSession);
  }

  // ---------- Helpers de tiempo ----------
  static int _hmToMin(String hm) {
    final p = hm.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    return h * 60 + m;
  }

  static String _pad2(int x) => x.toString().padLeft(2, '0');

  static bool _overlaps(String aStart, String aEnd, String bStart, String bEnd) {
    final as = _hmToMin(aStart), ae = _hmToMin(aEnd);
    final bs = _hmToMin(bStart), be = _hmToMin(bEnd);
    return (as < be) && (bs < ae);
  }

  static String _uuidLike() => 'r${DateTime.now().microsecondsSinceEpoch}';

  // ---------- Franjas (horarios) ----------
  /// Franja por defecto (todos los días salvo override)
  static Future<void> setDefaultWindow({
    required String profesor,
    required String start, // HH:mm
    required String end,   // HH:mm
  }) async {
    if (_hmToMin(start) >= _hmToMin(end)) {
      throw Exception('La hora de inicio debe ser anterior a la de fin.');
    }
    final users = await getUsers();
    users[profesor] ??= {};
    users[profesor]['defaultWindow'] = {'start': start, 'end': end};
    await saveUsers(users);
  }

  /// Franja específica por día (override). Si start/end son null, elimina override.
  static Future<void> setDayWindow({
    required String profesor,
    required String date, // YYYY-MM-DD
    String? start,
    String? end,
  }) async {
    final users = await getUsers();
    users[profesor] ??= {};
    final map = (users[profesor]['dayWindows'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v)),
        ) ??
        {};
    if (start == null || end == null) {
      map.remove(date);
    } else {
      if (_hmToMin(start) >= _hmToMin(end)) {
        throw Exception('La hora de inicio debe ser anterior a la de fin.');
      }
      map[date] = {'start': start, 'end': end};
    }
    users[profesor]['dayWindows'] = map;
    await saveUsers(users);
  }

  /// Franja aplicable para un día (override → default → null)
  static Map<String, String>? getWindowForDateSync(Map<String, dynamic> prof, String date) {
    final dayWindows = (prof['dayWindows'] as Map?)?.map(
      (k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v)),
    );
    if (dayWindows != null && dayWindows.containsKey(date)) {
      final raw = dayWindows[date];
      final w = raw != null
      ? Map<String, dynamic>.from(raw as Map)
      : <String, dynamic>{};

      return {'start': w['start'].toString(), 'end': w['end'].toString()};
    }
    final def = prof['defaultWindow'];
    if (def != null && def is Map) {
      return {'start': def['start'].toString(), 'end': def['end'].toString()};
    }
    return null;
  }

  // ---------- Reservas ----------
  /// Crea reserva con estado `pending`
  static Future<void> addReservation({
    required String profesor,
    required String usuario,
    required String date,   // YYYY-MM-DD
    required String start,  // HH:mm
    required String end,    // HH:mm
    required String subject,
  }) async {
    if (_hmToMin(start) >= _hmToMin(end)) {
      throw Exception('La hora de inicio debe ser anterior a la de fin.');
    }

    final users = await getUsers();
    users[profesor] ??= {};
    users[usuario] ??= {};

    users[profesor]['availableDates'] ??= <String>[];
    users[profesor]['reservations'] ??= <dynamic>[];
    users[usuario]['reservations'] ??= <dynamic>[];

    // Día debe estar marcado disponible
    final List profAvail = (users[profesor]['availableDates'] as List);
    if (!profAvail.map((e) => e.toString()).contains(date)) {
      throw Exception('El profesor no tiene disponible el día $date.');
    }

    // Debe existir una franja aplicable
    final window = getWindowForDateSync(users[profesor], date);
    if (window == null) {
      throw Exception('El profesor no tiene franja horaria definida para ese día.');
    }
    final ws = window['start']!, we = window['end']!;
    if (_hmToMin(start) < _hmToMin(ws) || _hmToMin(end) > _hmToMin(we)) {
      throw Exception('La reserva debe estar dentro de la franja ${ws}–$we.');
    }

    // Solapes profesor
    final List profRes = (users[profesor]['reservations'] as List);
    for (final r in profRes) {
      if (r['date'] == date && _overlaps(start, end, r['start'], r['end'])) {
        throw Exception('El profesor ya tiene una reserva solapada en ese horario.');
      }
    }

    // Solapes alumno
    final List userRes = (users[usuario]['reservations'] as List);
    for (final r in userRes) {
      if (r['date'] == date && _overlaps(start, end, r['start'], r['end'])) {
        throw Exception('Tienes otra reserva que se solapa en ese horario.');
      }
    }

    final id = _uuidLike();
    final payload = {
      'id': id,
      'usuario': usuario,
      'profesor': profesor,
      'date': date,
      'start': start,
      'end': end,
      'subject': subject,
      'status': 'pending',
    };

    profRes.add(Map<String, dynamic>.from(payload));
    userRes.add(Map<String, dynamic>.from(payload));
    await saveUsers(users);
  }

  /// Profesor decide: 'accepted' | 'rejected'
  static Future<void> updateReservationStatus({
    required String profesorEmail,
    required String reservationId,
    required String newStatus,
  }) async {
    if (newStatus != 'accepted' && newStatus != 'rejected') {
      throw Exception('Estado inválido.');
    }

    final users = await getUsers();
    final prof = users[profesorEmail];
    if (prof == null) throw Exception('Profesor no encontrado.');

    final List profRes = (prof['reservations'] as List? ?? <dynamic>[]);
    final idx = profRes.indexWhere((r) => r['id'] == reservationId);
    if (idx < 0) throw Exception('Reserva no encontrada.');

    final reserva = Map<String, dynamic>.from(profRes[idx]);
    final usuarioEmail = reserva['usuario'] as String;

    // Update profesor
    reserva['status'] = newStatus;
    profRes[idx] = reserva;

    // Update usuario
    final user = users[usuarioEmail] ??= {};
    final List userRes = (user['reservations'] as List? ?? <dynamic>[]);
    final uidx = userRes.indexWhere((r) => r['id'] == reservationId);
    if (uidx >= 0) {
      final r2 = Map<String, dynamic>.from(userRes[uidx]);
      r2['status'] = newStatus;
      userRes[uidx] = r2;
    }

    await saveUsers(users);
  }

  // ---------- Estados de calendario ----------
  /// 'free' | 'partial' | 'full' | 'unavailable' para un día
  static String dayStatusForProfessorSync(Map<String, dynamic> prof, String date) {
    final avail = (prof['availableDates'] as List?)?.map((e) => e.toString()).toList() ?? [];
    if (!avail.contains(date)) return 'unavailable';

    final window = getWindowForDateSync(prof, date);
    if (window == null) return 'unavailable';
    final ws = window['start']!, we = window['end']!;
    final wStart = _hmToMin(ws), wEnd = _hmToMin(we);
    final windowMinutes = wEnd - wStart;
    if (windowMinutes <= 0) return 'unavailable';

    final List res = (prof['reservations'] as List?) ?? [];
    final intervals = <List<int>>[];
    for (final r in res) {
      if (r['date'] == date) {
        final rs = _hmToMin(r['start']);
        final re = _hmToMin(r['end']);
        final s = rs.clamp(wStart, wEnd);
        final e = re.clamp(wStart, wEnd);
        if (s < e) intervals.add([s, e]);
      }
    }
    if (intervals.isEmpty) return 'free';

    // Merge intervals
    intervals.sort((a, b) => a[0].compareTo(b[0]));
    final merged = <List<int>>[];
    for (final iv in intervals) {
      if (merged.isEmpty || iv[0] > merged.last[1]) {
        merged.add([iv[0], iv[1]]);
      } else {
        merged.last[1] = iv[1] > merged.last[1] ? iv[1] : merged.last[1];
      }
    }
    int booked = 0;
    for (final m in merged) {
      booked += (m[1] - m[0]);
    }
    if (booked <= 0) return 'free';
    if (booked >= windowMinutes) return 'full';
    return 'partial';
  }

  /// Mapa mensual: { 'YYYY-MM-DD': 'free'|'partial'|'full'|'unavailable' }
  static Future<Map<String, String>> monthStatusesForProfessor({
    required String profesor,
    required int year,
    required int month, // 1..12
  }) async {
    final users = await getUsers();
    final prof = users[profesor] as Map<String, dynamic>?;
    if (prof == null) return {};

    final days = DateTime(year, month + 1, 0).day;
    final result = <String, String>{};
    for (int d = 1; d <= days; d++) {
      final key = '$year-${_pad2(month)}-${_pad2(d)}';
      result[key] = dayStatusForProfessorSync(prof, key);
    }
    return result;
  }
}
