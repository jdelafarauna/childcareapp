import 'package:flutter/material.dart';
import '../widgets/menu_card.dart';
import '../services/storage.dart';
import 'profile_page.dart';
import 'professors/professors_list_page.dart';
import 'professors/availability_page.dart';
import 'professors/subjects_page.dart';
import 'professors/hours_page.dart';
import 'booking/search_booking_page.dart';
import 'reservations/reservations_page.dart';
import 'chats/chats_list_page.dart';
import 'calendar/professor_calendar_page.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  final String email;
  final String role;
  const HomePage({super.key, required this.email, required this.role});

  int _calcColumns(double width) {
    final n = (width / 150).floor();
    return n.clamp(2, 4);
  }

  @override
  Widget build(BuildContext context) {
    final isProfesor = role == 'profesor';

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = _calcColumns(constraints.maxWidth);
        const childAspect = 1.8;

        final items = <Widget>[
          MenuCard(
            compact: true,
            icon: Icons.search,
            title: 'Buscar profesores',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProfessorsListPage(currentEmail: email),
              ));
            },
          ),
          MenuCard(
            compact: true,
            icon: Icons.event_available,
            title: 'Reservar por fecha\n(+ asignatura)',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => SearchBookingPage(currentEmail: email),
              ));
            },
          ),
          MenuCard(
            compact: true,
            icon: Icons.list_alt,
            title: 'Mis reservas',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ReservationsPage(currentEmail: email, role: role),
              ));
            },
          ),
          if (isProfesor)
            MenuCard(
              compact: true,
              icon: Icons.calendar_month,
              title: 'Mis días disponibles',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AvailabilityPage(email: email),
                ));
              },
            ),
          if (isProfesor)
            MenuCard(
              compact: true,
              icon: Icons.access_time,
              title: 'Mi franja horaria',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => HoursPage(email: email),
                ));
              },
            ),
          if (isProfesor)
            MenuCard(
              compact: true,
              icon: Icons.menu_book,
              title: 'Mis asignaturas',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => SubjectsPage(email: email),
                ));
              },
            ),
          if (isProfesor)
            MenuCard(
              compact: true,
              icon: Icons.calendar_view_month,
              title: 'Mi calendario',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ProfessorCalendarPage(profesorEmail: email),
                ));
              },
            ),
          MenuCard(
            compact: true,
            icon: Icons.account_circle,
            title: 'Mi perfil',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProfilePage(email: email, role: role),
              ));
            },
          ),
          MenuCard(
            compact: true,
            icon: Icons.logout,
            title: 'Cerrar sesión',
            onTap: () async {
              await Storage.clearSession();
              // ignore: use_build_context_synchronously
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text('Inicio · $role'),
            actions: [
              IconButton(
                tooltip: 'Mis chats',
                icon: const Icon(Icons.forum_outlined),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatsListPage(currentEmail: email, isProfesor: isProfesor),
                  ));
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: childAspect,
              ),
              itemBuilder: (_, i) => items[i],
            ),
          ),
        );
      },
    );
  }
}
