import 'dart:convert';

import 'package:dago_application/models/person.dart';

class User {
  final int id;
  final String user;
  final String password;
  final String nombre;
  final String apellido;
  final String fechaNacimiento;
  final String dni;
  final Person? persona;

  User(this.persona,
      {required this.id,
      required this.user,
      required this.password,
      required this.nombre,
      required this.apellido,
      required this.fechaNacimiento,
      required this.dni});

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        user = json['user'],
        password = json['password'],
        nombre = json['nombre'],
        apellido = json['apellido'],
        fechaNacimiento = json['fecha_nacimiento'],
        dni = json['dni'],
        persona =
            json['persona'] != null ? Person.fromJson(json['persona']) : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user': user,
        'password': password,
        'nombre': nombre,
        'apellido': apellido,
        'fecha_nacimiento': fechaNacimiento,
        'dni': dni,
      };
}
