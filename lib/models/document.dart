import 'dart:convert';

import 'package:dago_application/models/user.dart';

class Document {
  final int id;
  final String titulo;
  final String documentoBase64;
  final String fechaSubida; // Cambiado a String
  final int usuarioId;
  final User? user;

  Document(
    this.user, {
    required this.id,
    required this.titulo,
    required this.documentoBase64,
    required this.fechaSubida,
    required this.usuarioId,
  });

  Document.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? 0,
        titulo = json['titulo'] ?? '',
        documentoBase64 = json['documento_base64'] ?? '',
        fechaSubida =
            json['fecha_subida'] ?? '', // Ya no se convierte a DateTime
        usuarioId = json['usuarioId'] ?? 0,
        user = json['usuario'] != null ? User.fromJson(json['usuario']) : null;

  // Método para convertir una lista de JSON a una lista de Document
  static List<Document> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Document.fromJson(json)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'documento_base64': documentoBase64,
      'fecha_subida': fechaSubida, // No se necesita convertir a ISO8601
      //'user': user?.toJson(),
      // 'estado_documento': estadoDocumento,+
    };
  }

  @override
  String toString() {
    return 'Document{id: $id, titulo: $titulo, fechaSubida: $fechaSubida}';
  }
}
