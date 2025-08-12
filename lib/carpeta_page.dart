import 'package:flutter/material.dart';

import 'models.dart';
import 'nuevo_archivo_page.dart';
import 'archivo_detalle_page.dart';

class CarpetaPage extends StatefulWidget {
  final Carpeta carpeta;
  final VoidCallback onCambios;

  const CarpetaPage({super.key, required this.carpeta, required this.onCambios});

  @override
  State<CarpetaPage> createState() => _CarpetaPageState();
}

class _CarpetaPageState extends State<CarpetaPage> {
  Future<void> _anadirCarpeta() async {
    final nombre = await _mostrarInput(context, 'Nueva Carpeta');
    if (nombre != null && nombre.trim().isNotEmpty) {
      setState(() {
        widget.carpeta.subcarpetas.add(Carpeta(nombre: nombre.trim()));
      });
      widget.onCambios();
    }
  }

  Future<void> _anadirArchivo() async {
    final Map<String, String>? resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NuevoArchivoPage(),
      ),
    );
    if (resultado != null && resultado['nombre']!.trim().isNotEmpty) {
      setState(() {
        widget.carpeta.archivos.add(Archivo(
          nombre: resultado['nombre']!.trim(),
          contenidoBase64: resultado['contenidoBase64'] ?? '',
        ));
      });
      widget.onCambios();
    }
  }

  static Future<String?> _mostrarInput(BuildContext context, String titulo) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Aceptar')),
        ],
      ),
    );
  }

  Future<bool> _confirmarBorrado(String tipo, String nombre) async {
    return (await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Eliminar $tipo'),
            content: Text('¿Seguro que quieres eliminar "$nombre"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        )) ??
        false;
  }

  void _verArchivo(Archivo archivo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArchivoDetallePage(archivo: archivo),
      ),
    );
  }

  void _abrirSubcarpeta(Carpeta carpeta) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarpetaPage(
          carpeta: carpeta,
          onCambios: widget.onCambios,
        ),
      ),
    );
  }

  Widget _buildCarpetaItem(Carpeta carpeta) {
    return ListTile(
      leading: const Icon(Icons.folder),
      title: Text(carpeta.nombre),
      onTap: () => _abrirSubcarpeta(carpeta),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () async {
          final confirmado = await _confirmarBorrado('carpeta', carpeta.nombre);
          if (confirmado) {
            setState(() {
              widget.carpeta.subcarpetas.remove(carpeta);
            });
            widget.onCambios();
          }
        },
      ),
    );
  }

  Widget _buildArchivoItem(Archivo archivo) {
    return ListTile(
      leading: const Icon(Icons.description),
      title: Text(archivo.nombre),
      onTap: () => _verArchivo(archivo),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () async {
          final confirmado = await _confirmarBorrado('archivo', archivo.nombre);
          if (confirmado) {
            setState(() {
              widget.carpeta.archivos.remove(archivo);
            });
            widget.onCambios();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.carpeta.nombre),
        actions: [
          IconButton(onPressed: _anadirCarpeta, icon: const Icon(Icons.create_new_folder)),
          IconButton(onPressed: _anadirArchivo, icon: const Icon(Icons.note_add)),
        ],
      ),
      body: ListView(
        children: [
          ...widget.carpeta.subcarpetas.map(_buildCarpetaItem),
          ...widget.carpeta.archivos.map(_buildArchivoItem),
        ],
      ),
    );
  }
}
