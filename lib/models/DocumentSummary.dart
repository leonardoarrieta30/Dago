class DocumentSummary {
  final int id;
  final String titulo;
  final String fechaSubida;
  final String nombre;
  final String apellido;
  final String area;

  DocumentSummary({
    required this.id,
    required this.titulo,
    required this.fechaSubida,
    required this.nombre,
    required this.apellido,
    required this.area,
  });

  DocumentSummary.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        titulo = json['titulo'],
        fechaSubida = json['fecha_subida'],
        nombre = json['usuario']['nombre'],
        apellido = json['usuario']['apellido'],
        area = json['usuario']['persona']['area'];
}
