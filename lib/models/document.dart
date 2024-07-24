class Document {
  final int id;
  final String titulo;
  final String documentoBase64;
  final DateTime fechaSubida;
  final int usuarioId;

  Document(
      {required this.id,
      required this.titulo,
      required this.documentoBase64,
      required this.fechaSubida,
      required this.usuarioId});

  Document.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? 0,
        titulo = json['titulo'] ?? '',
        documentoBase64 = json['documento_base64'] ?? '',
        fechaSubida = DateTime.parse(
          json['fecha_subida'] ?? '',
        ),
        usuarioId = json['usuarioId'] ?? 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'documento_base64': documentoBase64,
      'fecha_subida': fechaSubida.toIso8601String(),
      // 'estado_documento': estadoDocumento,+
    };
  }
}
