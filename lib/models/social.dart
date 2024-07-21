class Social {
  final int id;
  final String nombre;
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
}
