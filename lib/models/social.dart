class Social {
  final int id;
  String nombre;
  // final String icono;
  // final String url;
  final int personaId;

  Social(
      {required this.id,
      required this.nombre,
      // required this.icono,
      // required this.url,
      required this.personaId});

  Social.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        nombre = json['nombre'],
        // icono = json['icono'],
        // url = json['url'],
        personaId = json['personaId'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'personaId': personaId,
    };
  }
}
