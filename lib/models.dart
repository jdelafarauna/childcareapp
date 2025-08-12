import 'dart:convert';

class Archivo {
  String nombre;
  String contenidoBase64; // archivo en base64

  Archivo({required this.nombre, required this.contenidoBase64});

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'contenidoBase64': contenidoBase64,
      };

  factory Archivo.fromJson(Map<String, dynamic> json) => Archivo(
        nombre: json['nombre'],
        contenidoBase64: json['contenidoBase64'],
      );

  List<int> get contenidoBytes => base64Decode(contenidoBase64);
}

class Carpeta {
  String nombre;
  List<Archivo> archivos;
  List<Carpeta> subcarpetas;

  Carpeta({
    required this.nombre,
    List<Archivo>? archivos,
    List<Carpeta>? subcarpetas,
  })  : archivos = archivos ?? [],
        subcarpetas = subcarpetas ?? [];

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'archivos': archivos.map((a) => a.toJson()).toList(),
        'subcarpetas': subcarpetas.map((c) => c.toJson()).toList(),
      };

  factory Carpeta.fromJson(Map<String, dynamic> json) => Carpeta(
        nombre: json['nombre'],
        archivos: (json['archivos'] as List<dynamic>)
            .map((a) => Archivo.fromJson(a))
            .toList(),
        subcarpetas: (json['subcarpetas'] as List<dynamic>)
            .map((c) => Carpeta.fromJson(c))
            .toList(),
      );
}
