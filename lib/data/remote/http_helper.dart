import 'dart:convert';
import 'package:dago_application/models/Person.dart';
import 'package:dago_application/models/response/login_response.dart';
import 'package:dago_application/models/response/sign_up_response.dart';
import 'package:dago_application/models/response/social_response.dart';
import 'package:dago_application/models/user.dart';
import 'package:http/http.dart' as http;

class HttpHelper {
  final String urlBase = 'http://192.168.18.7:8080/api/v1';

  Future<Person> getPersonById(int id) async {
    final response = await http.get(Uri.parse('$urlBase/personas/$id'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 1) {
        final Map<String, dynamic> personData = data['persona'];
        return Person.fromJson(personData);
      } else {
        throw Exception('Failed to load person: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load person');
    }
  }

  Future<User> getUserById(int id) async {
    final response = await http.get(Uri.parse('$urlBase/users/$id'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 1) {
        final Map<String, dynamic> userData = data['user'];
        return User.fromJson(userData);
      } else {
        throw Exception('Failed to load user: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<LoginResponse> login(String user, String password) async {
    final response2 = await http.post(
      Uri.parse('$urlBase/users/verificarUsuarioExiste'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'user': user,
        'password': password,
      }),
    );
    final Map<String, dynamic> data = json.decode(response2.body);
    if (response2.statusCode == 200) {
      return LoginResponse.fromJson({
        'status': data['status'],
        'user': data['user'],
        'message': data['message'],
      });
    }
    if (response2.statusCode == 404) {
      return LoginResponse.fromJson({
        'status': data['status'],
        'user': null,
        'message': data['message'],
      });
    } else {
      return LoginResponse.fromJson({
        'status': -1,
        'user': null,
        'message': "Error se cayo el servidor",
      });
    }
  }

  Future<LoginResponse> verificarSiExisteUser(String user) async {
    final response =
        await http.get(Uri.parse('$urlBase/users/findByUser/$user'));
    final Map<String, dynamic> data = json.decode(response.body);
    if (response.statusCode == 200) {
      return LoginResponse.fromJson({
        'status': data['status'],
        'user': data['user'],
        'message': data['message'],
      });
    } else {
      throw Exception('Failed to verify user existence');
    }
  }

  Future<LoginResponse> crearUsuario(
      String user,
      String password,
      String nombre,
      String appellido,
      String fecha_nacimiento,
      String dni) async {
    final response2 = await http.post(
      Uri.parse('$urlBase/users'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'user': user,
        'password': password,
        'nombre': nombre,
        'apellido': appellido,
        'fecha_nacimiento': fecha_nacimiento,
        'dni': dni,
      }),
    );
    final Map<String, dynamic> data2 = json.decode(response2.body);
    if (response2.statusCode == 201) {
      return LoginResponse.fromJson({
        'status': data2['status'],
        'user': data2['user'],
        'message': data2['message'],
      });
    }
    if (response2.statusCode == 401) {
      return LoginResponse.fromJson({
        'status': data2['status'],
        'user': null,
        'message': data2['message'],
      });
    } else {
      return LoginResponse.fromJson({
        'status': -1,
        'user': null,
        'message': "Error se cayo el servidor",
      });
    }
  }

  Future<SignUpResponse> registrarPersona(
    String locacion,
    String puesto_trabajo,
    String descripcion_personal,
    int usuario_id,
  ) async {
    final response = await http.post(
      Uri.parse('$urlBase/personas'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'locacion': locacion,
        'puesto_trabajo': puesto_trabajo,
        'descripcion_personal': descripcion_personal,
        'foto_perfil': 'photo.png',
        'usuarioId': usuario_id,
      }),
    );
    final Map<String, dynamic> data = json.decode(response.body);
    print(data['persona']);
    if (response.statusCode == 201) {
      return SignUpResponse.fromJson({
        'status': data['status'],
        'persona': data['persona'],
        'message': data['message'],
      });
    }
    if (response.statusCode == 401) {
      return SignUpResponse.fromJson({
        'status': data['status'],
        'persona': null,
        'message': data['message'],
      });
    } else {
      return SignUpResponse.fromJson({
        'status': -1,
        'persona': null,
        'message': "Error se cayo el servidor",
      });
    }
  }

  Future<SignUpResponse> actualizarPersona(
    String locacion,
    String puesto_trabajo,
    String descripcion_personal,
    int usuario_id,
    int personaId,
  ) async {
    final response = await http.patch(
      Uri.parse('$urlBase/personas/$personaId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'locacion': locacion,
        'puesto_trabajo': puesto_trabajo,
        'descripcion_personal': descripcion_personal,
        'foto_perfil': 'photo.png',
        'usuarioId': usuario_id,
      }),
    );
    final Map<String, dynamic> data = json.decode(response.body);
    print(data['persona']);
    if (response.statusCode == 200) {
      return SignUpResponse.fromJson({
        'status': data['status'],
        'persona': data['persona'],
        'message': data['message'],
      });
    }
    if (response.statusCode == 401) {
      return SignUpResponse.fromJson({
        'status': data['status'],
        'persona': null,
        'message': data['message'],
      });
    }
    if (response.statusCode == 404) {
      return SignUpResponse.fromJson({
        'status': data['status'],
        'persona': null,
        'message': data['message'],
      });
    } else {
      return SignUpResponse.fromJson({
        'status': -1,
        'persona': null,
        'message': "Error se cayo el servidor",
      });
    }
  }

  Future<SignUpResponse> getPersonaByUserId(int userId) async {
    final response = await http.get(
      Uri.parse('$urlBase/personas/usuario/$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return SignUpResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      // Si la persona no se encuentra, devuelve una respuesta con status 0
      return SignUpResponse(
          persona: null, status: 0, message: 'Persona no encontrada');
    } else {
      throw Exception('Failed to get person');
    }
  }

  Future<SocialResponse> actualizarRedSocial(
      String nombre, int personId, int socialId) async {
    final response = await http.patch(
      Uri.parse('$urlBase/socials/$socialId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'nombre': nombre,
        'personaId': personId,
      }),
    );
    final Map<String, dynamic> data = json.decode(response.body);
    if (response.statusCode == 200) {
      return SocialResponse.fromJson({
        'status': data['status'],
        'social': data['social'],
        'message': data['message'],
      });
    }
    if (response.statusCode == 401) {
      return SocialResponse.fromJson({
        'status': data['status'],
        'social': null,
        'message': data['message'],
      });
    }
    if (response.statusCode == 404) {
      return SocialResponse.fromJson({
        'status': data['status'],
        'social': null,
        'message': data['message'],
      });
    } else {
      return SocialResponse.fromJson({
        'status': -1,
        'social': null,
        'message': "Error se cayo el servidor",
      });
    }
  }
}
