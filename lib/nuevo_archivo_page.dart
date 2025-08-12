import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

class NuevoArchivoPage extends StatefulWidget {
  const NuevoArchivoPage({super.key});

  @override
  State<NuevoArchivoPage> createState() => _NuevoArchivoPageState();
}

class _NuevoArchivoPageState extends State<NuevoArchivoPage> {
  String? _nombreArchivo;
  String? _contenidoBase64;

  bool _cargando = false;
  String? _error;

  Future<void> _seleccionarArchivo() async {
    setState(() {
      _error = null;
      _cargando = true;
    });
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _nombreArchivo = file.name;
          _contenidoBase64 = base64Encode(file.bytes!);
          _cargando = false;
        });
      } else {
        setState(() {
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al seleccionar archivo: $e';
        _cargando = false;
      });
    }
  }

  void _guardar() {
    if (_nombreArchivo == null || _contenidoBase64 == null) {
      setState(() {
        _error = 'Por favor selecciona un archivo primero';
      });
      return;
    }
    Navigator.pop(context, {
      'nombre': _nombreArchivo!,
      'contenidoBase64': _contenidoBase64!,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Archivo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _cargando ? null : _seleccionarArchivo,
              icon: const Icon(Icons.attach_file),
              label: Text(_nombreArchivo ?? 'Seleccionar Archivo'),
            ),
            if (_cargando)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const Spacer(),
            ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
