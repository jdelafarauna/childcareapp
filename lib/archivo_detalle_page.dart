import 'package:flutter/material.dart';
import 'models.dart';

class ArchivoDetallePage extends StatelessWidget {
  final Archivo archivo;

  const ArchivoDetallePage({super.key, required this.archivo});

  @override
  Widget build(BuildContext context) {
    final sizeKB = (archivo.contenidoBytes.length / 1024).toStringAsFixed(2);
    return Scaffold(
      appBar: AppBar(
        title: Text(archivo.nombre),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Nombre: ${archivo.nombre}'),
            Text('Tamaño: $sizeKB KB'),
            const SizedBox(height: 20),
            const Text('Vista previa no disponible.'),
            // Aquí podrías agregar abrir el archivo o compartirlo con plugins extra
          ],
        ),
      ),
    );
  }
}
