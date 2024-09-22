class Person {
  final int id;
  String locacion;
  String puestoTrabajo;
  String descripcionPersonal;
  final String foto_perfil;
  final int usuarioId;

  Person(
      {required this.id,
      required this.locacion,
      required this.puestoTrabajo,
      required this.descripcionPersonal,
      required this.foto_perfil,
      required this.usuarioId});

  Person.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        locacion = json['locacion'],
        puestoTrabajo = json['puesto_trabajo'],
        descripcionPersonal = json['area'],
        foto_perfil = json['foto_perfil'],
        usuarioId = json['usuarioId'];

/*   Map<String, dynamic> toJson() {
    return {
      'area': descripcionPersonal,
    };
  } */
}
