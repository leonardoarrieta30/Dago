import 'dart:convert';
import 'package:dago_application/components/upload_file.dart';
import 'package:dago_application/models/Person.dart';
import 'package:dago_application/models/document.dart';
import 'package:dago_application/models/response/docu_response.dart';
import 'package:dago_application/models/response/login_response.dart';
import 'package:dago_application/models/response/sign_up_response.dart';
import 'package:dago_application/models/response/social_response.dart';
import 'package:dago_application/models/social.dart';
import 'package:dago_application/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class HttpHelper {
  final String urlBase = 'http://137.184.228.142:3000/api/v1';

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
    String descripcionPersonal,
    int usuario_id,
    String base64Image,
  ) async {
    final response = await http.post(
      Uri.parse('$urlBase/personas'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'locacion': locacion,
        'puesto_trabajo': puesto_trabajo,
        'area': descripcionPersonal,
        'foto_perfil': base64Image,
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
    if (response.statusCode == 201) {
      return SignUpResponse.fromJson({
        'status': data['status'],
        'persona': data['persona'],
        'message': data['message'],
      });
    }
    if (response.statusCode == 400) {
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
    String descripcionPersonal,
    int usuario_id,
    int personaId,
    String base64Image,
  ) async {
    try {
      print('Enviando solicitud para actualizar persona...');
      print('URL: ${Uri.parse('$urlBase/personas/$personaId')}');

      final response = await http.patch(
        Uri.parse('$urlBase/personas/$personaId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'locacion': locacion,
          'puesto_trabajo': puesto_trabajo,
          'area': descripcionPersonal,
          'foto_perfil': base64Image,
          'usuarioId': usuario_id,
        }),
      );

      print('Código de estado de la respuesta: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          print('Datos decodificados: $data');
          return SignUpResponse.fromJson({
            'status': data['status'],
            'persona': data['persona'],
            'message': data['message'],
          });
        } catch (e) {
          print('Error al decodificar JSON: $e');
          return SignUpResponse.fromJson({
            'status': -1,
            'persona': null,
            'message': "Error al procesar la respuesta del servidor",
          });
        }
      } else {
        print('Respuesta no exitosa. Código: ${response.statusCode}');
        return SignUpResponse.fromJson({
          'status': -1,
          'persona': null,
          'message': "Error del servidor: ${response.statusCode}",
        });
      }
    } catch (e) {
      print('Excepción al actualizar persona: $e');
      return SignUpResponse.fromJson({
        'status': -1,
        'persona': null,
        'message': "Error de red o del servidor: $e",
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

  // Future<SocialResponse> actualizarRedSocial(
  //     String nombre, int personId, int socialId) async {
  //   final response = await http.patch(
  //     Uri.parse('$urlBase/socials/$socialId'),
  //     headers: <String, String>{
  //       'Content-Type': 'application/json; charset=UTF-8',
  //     },
  //     body: jsonEncode(<String, dynamic>{
  //       'nombre': nombre,
  //       'personaId': personId,
  //     }),
  //   );
  //   final Map<String, dynamic> data = json.decode(response.body);
  //   if (response.statusCode == 200) {
  //     return SocialResponse.fromJson({
  //       'status': data['status'],
  //       'social': data['social'],
  //       'message': data['message'],
  //     });
  //   }
  //   if (response.statusCode == 401) {
  //     return SocialResponse.fromJson({
  //       'status': data['status'],
  //       'social': null,
  //       'message': data['message'],
  //     });
  //   }
  //   if (response.statusCode == 404) {
  //     return SocialResponse.fromJson({
  //       'status': data['status'],
  //       'social': null,
  //       'message': data['message'],
  //     });
  //   } else {
  //     return SocialResponse.fromJson({
  //       'status': -1,
  //       'social': null,
  //       'message': "Error se cayo el servidor",
  //     });
  //   }
  // }

  // Future<List<SocialResponse>> actualizarRedesSociales(
  //     int personId, Map<String, String> socialNetworks) async {
  //   List<SocialResponse> responses = [];

  //   for (var entry in socialNetworks.entries) {
  //     String networkName = entry.key;
  //     String username = entry.value;

  //     // Primero, intentamos obtener el ID de la red social existente
  //     SocialResponse existingResponse =
  //         await obtenerRedSocialPorNombre(networkName, personId);

  //     if (existingResponse.status == 1 && existingResponse.social != null) {
  //       // Si la red social ya existe, la actualizamos
  //       SocialResponse updateResponse = await actualizarRedSocial(
  //         username,
  //         personId,
  //         existingResponse.social!.id,
  //       );
  //       responses.add(updateResponse);
  //     } else {
  //       // Si la red social no existe, la creamos
  //       SocialResponse createResponse = await crearRedSocial(
  //         networkName,
  //         username,
  //         personId,
  //       );
  //       responses.add(createResponse);
  //     }
  //   }

  //   return responses;
  // }

  // Future<SocialResponse> obtenerRedSocialPorNombre(
  //     String nombre, int personId) async {
  //   final response = await http.get(
  //     Uri.parse('$urlBase/socials?nombre=$nombre&personaId=$personId'),
  //     headers: <String, String>{
  //       'Content-Type': 'application/json; charset=UTF-8',
  //     },
  //   );

  //   final Map<String, dynamic> data = json.decode(response.body);
  //   return SocialResponse.fromJson(data);
  // }

  // Future<SocialResponse> crearRedSocial(
  //     String nombre, String username, int personId) async {
  //   final response = await http.post(
  //     Uri.parse('$urlBase/socials'),
  //     headers: <String, String>{
  //       'Content-Type': 'application/json; charset=UTF-8',
  //     },
  //     body: jsonEncode(<String, dynamic>{
  //       'nombre': nombre,
  //       'username': username,
  //       'personaId': personId,
  //     }),
  //   );

  //   final Map<String, dynamic> data = json.decode(response.body);
  //   return SocialResponse.fromJson(data);
  // }

  Future<SocialResponse> actualizarRedesSociales(
      int personaId, List<Social> socialNetworks) async {
    try {
      final response = await http.post(
        Uri.parse('$urlBase/socials'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'personaId': personaId,
          'socialNetworks': socialNetworks
              .map((network) => {
                    'nombre': network.nombre,
                    // 'url': network.url,
                    // 'icono': network.icono,
                    'personaId': network.personaId,
                  })
              .toList(),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return SocialResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update social networks: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update social networks: $e');
    }
  }

  Future<SocialResponse> getRedesSociales(int personaId) async {
    final response = await http.get(
      Uri.parse('$urlBase/socials/$personaId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return SocialResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load social networks');
    }
  }

  Future<SignUpResponse> eliminarRedSocial(int socialId) async {
    final response = await http.delete(
      Uri.parse('$urlBase/socials/$socialId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return SignUpResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to delete social network');
    }
  }

  Future<DocuResponse> crearDocumento(
      String titulo, String docuBase64, int usuarioId) async {
    final response = await http.post(
      Uri.parse('$urlBase/documentos'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'titulo': titulo,
        'documento_base64': docuBase64,
        "fecha_subida": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'usuarioId': usuarioId,
      }),
    );

    if (response.statusCode == 201) {
      return DocuResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create document');
    }
  }

  Future<List<Document>> getDocumentosByUserId(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$urlBase/documentos/byUsuarioId/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print("todavia no entra");
        if (jsonResponse['status'] == 1) {
          print("entro");
          List<dynamic> documentos = jsonResponse['documento'];
          print('Response body2: $documentos');
          return documentos.map((json) => Document.fromJson(json)).toList();
        } else {
          print('No se encontraron documentos: ${jsonResponse['message']}');
          return [];
        }
      } else {
        print('Failed to load documents. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error in getDocumentosByUserId: $e');
      return [];
    }
  }

  /* Future<List<Document>> getDocumentosByArea(
      String area, String fromDateStr, String toDateStr) async {
    print("desde $fromDateStr");
    print("hasta $toDateStr");
    try {
      final response = await http.get(
        Uri.parse(
            '$urlBase/documentos/pdfs-by-area?area=$area&desde=$fromDateStr&hasta=$toDateStr'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 1) {
          List<dynamic> documentos = jsonResponse['documentos'];
          return documentos.map((json) => Document.fromJson(json)).toList();
        } else {
          print('No se encontraron documentos: ${jsonResponse['mensaje']}');
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      print('Error in getDocumentosByUserId: $e');
      return [];
    }
  } */

  Future<List<Document>> getDocumentosByArea(
      String? areaParameter, String? fromDateStr, String? toDateStr) async {
    print("desde $fromDateStr");
    print("hasta $toDateStr");
    var area = areaParameter?.trim();
    try {
      // Construcción dinámica de la URL con los parámetros
      String queryParams = '';

      // Agregar el área solo si se proporciona
      if (area != null && area.isNotEmpty) {
        queryParams += 'area=$area';
      }

      // Agregar las fechas solo si se proporcionan
      if (fromDateStr != null &&
          toDateStr != null &&
          fromDateStr.isNotEmpty &&
          toDateStr.isNotEmpty) {
        if (queryParams.isNotEmpty) {
          queryParams += '&';
        }
        queryParams += 'desde=$fromDateStr&hasta=$toDateStr';
      }

      // Crear la URL con los parámetros condicionales
      final String url = '$urlBase/documentos/pdfs-by-area';
      final Uri uri =
          Uri.parse(queryParams.isNotEmpty ? '$url?$queryParams' : url);

      print('URL de la solicitud: $uri');
      final response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print(response.statusCode);
      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 1) {
          List<dynamic> documentos = jsonResponse['documentos'];
          return documentos.map((json) => Document.fromJson(json)).toList();
        } else {
          print('No se encontraron documentos: ${jsonResponse['mensaje']}');
          return [];
        }
      } else {
        print('Error en la solicitud: Código de estado ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error in getDocumentosByArea: $e');
      return [];
    }
  }

// Método para obtener el base64 del documento específico
  Future<String?> getDocumentoBase64(int documentoId) async {
    try {
      final String url =
          '$urlBase/documentos/pdf/$documentoId'; // Asegúrate de que esta URL sea correcta
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse[
            'documento_base64']; // Asegúrate de que este campo exista en la respuesta
      } else {
        print('Error en la solicitud: Código de estado ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error en getDocumentoBase64: $e');
      return null;
    }
  }

  Future<bool> getAreaByUsuarioId(int usuarioId) async {
    final response = await http.get(
      Uri.parse('$urlBase/personas/areaByUsuarioId/$usuarioId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 1) {
        return data['isExists'];
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

// Ejemplo de método en HttpHelper para recuperar contraseña (esta en proceso)
  Future<void> sendPasswordResetEmail(String email) async {
    // Lógica para enviar solicitud al servidor para enviar el correo de recuperación
    final response = await http.post(
      Uri.parse('https://tu-api.com/recuperar-password'),
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      // Lógica en caso de éxito
    } else {
      // Lógica en caso de error
    }
  }

  Future<void> deleteDocumentoById(int documentoId) async {
    final response = await http.delete(
      Uri.parse('$urlBase/documentos/$documentoId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['status'] != 1) {
        throw Exception(
            'Error al eliminar el documento: ${responseData['message']}');
      }
    } else {
      throw Exception('Error en la solicitud: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> hasArea(int usuarioId) async {
    final response = await http.get(
      Uri.parse('$urlBase/personas/hasArea/$usuarioId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return {
        'hasArea': data['hasArea'],
        'status': data['status'],
        'message': data['message'],
      };
    } else if (response.statusCode == 404) {
      return {
        'hasArea': false,
        'status': 2,
        'message': 'Persona no encontrada',
      };
    } else {
      throw Exception('Error al verificar el área: ${response.statusCode}');
    }
  }
}
