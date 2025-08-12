import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'carpeta_page.dart';

class ApuntesPage extends StatefulWidget {
  const ApuntesPage({super.key});

  @override
  State<ApuntesPage> createState() => _ApuntesPageState();
}

class _ApuntesPageState extends State<ApuntesPage> {
  static const String storageKey = 'apuntes_root';
  Carpeta? rootCarpeta;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(storageKey);
    if (data != null) {
      setState(() {
        rootCarpeta = Carpeta.fromJson(jsonDecode(data));
      });
    } else {
      rootCarpeta = Carpeta(nombre: 'Apuntes');
      await _guardarDatos();
      setState(() {});
    }
  }

  Future<void> _guardarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    if (rootCarpeta != null) {
      await prefs.setString(storageKey, jsonEncode(rootCarpeta!.toJson()));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (rootCarpeta == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return CarpetaPage(
      carpeta: rootCarpeta!,
      onCambios: () async {
        await _guardarDatos();
        setState(() {});
      },
    );
  }
}
