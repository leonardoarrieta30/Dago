class Document {
  final int id;
  final String titulo;
  final String documentoBase64;
  final String fechaSubida;
  final int usuarioId;

  Document(
      {required this.id,
      required this.titulo,
      required this.documentoBase64,
      required this.fechaSubida,
      required this.usuarioId});

  Document.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        titulo = json['titulo'],
        documentoBase64 = json['documento_base64'],
        fechaSubida = json['fecha_subida'],
        usuarioId = json['usuarioId'];
}
