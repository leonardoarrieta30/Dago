// ignore_for_file: file_names

class Person {
  final int id;
  String locacion;
  String puestoTrabajo;
  String descripcionPersonal;
  // final Blob foto_perfil;
  final int usuarioId;

  Person(
      {required this.id,
      required this.locacion,
      required this.puestoTrabajo,
      required this.descripcionPersonal,
      required this.usuarioId});

  Person.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        locacion = json['locacion'],
        puestoTrabajo = json['puesto_trabajo'],
        descripcionPersonal = json['descripcion_personal'],
        // foto_perfil = json['foto_perfil'],
        usuarioId = json['usuarioId'];
}
