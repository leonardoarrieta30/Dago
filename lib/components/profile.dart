import 'dart:convert';
import 'package:dago_application/models/person.dart';
import 'package:dago_application/models/response/sign_up_response.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dago_application/data/remote/http_helper.dart';
import 'package:dago_application/models/user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  HttpHelper? _httpHelper;
  SignUpResponse? _personResponse;
  User? _user;
  Person? _person;

  TextEditingController locationController = TextEditingController();
  TextEditingController jobTitleController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _httpHelper = HttpHelper();
    // locationController = TextEditingController();
    // jobTitleController = TextEditingController();
    // bioController = TextEditingController();
    _loadUsuario();
  }

  void _loadUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? usuarioJson = prefs.getString('usuario');
    if (usuarioJson != null) {
      setState(() {
        _user = User.fromJson(jsonDecode(usuarioJson));
        print(_user?.id);
      });
      await _initialize(); // Llama a _initialize() después de cargar el usuario
    } else {
      print('Error: No se encontró información del usuario');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error: No se pudo cargar la información del usuario')),
      );
    }
  }

  // Future<void> _initialize2() async {
  //   if (_user != null) {
  //     _user = await _httpHelper?.getUserById(_user!.id);
  //   }
  // }
  Future<void> _initialize() async {
    if (_user == null) {
      print('Error: User is null in _initialize()');
      if (mounted) {
        // Verificar si el widget aún está montado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error: No se pudo inicializar la información del usuario')),
        );
      }
      return;
    }

    try {
      // Primero, intenta obtener la persona existente
      _personResponse = await _httpHelper?.getPersonaByUserId(_user!.id);

      if (!mounted) return; // Si el widget ya no está montado, no continuamos

      if (_personResponse?.status == 1 && _personResponse?.persona != null) {
        // Si la persona existe, actualiza los controladores con la información existente
        setState(() {
          _person = _personResponse?.persona;
          locationController.text = _person?.locacion ?? '';
          jobTitleController.text = _person?.puestoTrabajo ?? '';
          bioController.text = _person?.descripcionPersonal ?? '';
        });
      } else {
        // Si la persona no existe, NO creamos una nueva automáticamente
        // En su lugar, solo inicializamos _person como null
        setState(() {
          _person = null;
          locationController.text = '';
          jobTitleController.text = '';
          bioController.text = '';
        });
        print('No se encontró información de persona para este usuario');
      }
    } catch (e) {
      print('Error in _initialize(): $e');
      if (mounted) {
        // Verificar si el widget aún está montado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al cargar la información de la persona')),
        );
      }
    }
  }

  String _getAge() {
    if (_user == null) return '';
    final now = DateTime.now();
    DateTime birthDate;
    try {
      birthDate = DateTime.parse(_user!.fechaNacimiento);
    } catch (e) {
      return 'Invalid date format';
    }
    final age = now.difference(birthDate);
    final years = age.inDays ~/ 365;
    return '$years años';
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('usuario');
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE9ECEF),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildAboutSection(),
                  SizedBox(height: 20),
                  _buildBioSection(),
                  SizedBox(height: 20),
                  _buildSocialSection(),
                  SizedBox(height: 20),
                  _buildRecentActivitySection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child:
                        Icon(Icons.person, size: 50, color: Color(0xFF6C757D)),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.nombre ?? '',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                        Text(
                          _user?.user ?? '',
                          style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.exit_to_app,
                        color: Color.fromARGB(255, 163, 8, 8)),
                    onPressed: _logout,
                    tooltip: 'Cerrar sesión',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAboutSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sobre Mí',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA0522D))),
                TextButton(
                  onPressed: () {
                    if (isEditing) {
                      _updateUserInfo();
                    } else {
                      setState(() {
                        isEditing = true;
                      });
                    }
                  },
                  child: Text(
                    isEditing ? 'Guardar' : 'Editar',
                    style: TextStyle(color: Color(0xFF28A745)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            _buildInfoRow('Edad', _getAge()),
            buildEditableRow('Locación', _person?.locacion ?? ''),
            buildEditableRow2('Profesión', _person?.puestoTrabajo ?? ''),
          ],
        ),
      ),
    );
  }

  Widget buildEditableRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Color(0xFF6C757D))),
          SizedBox(height: 8),
          isEditing
              ? TextField(
                  controller: locationController,
                  style: TextStyle(color: Color(0xFF6C757D)),
                  decoration: InputDecoration(
                    hintText: 'La Molina, Lima',
                    hintStyle:
                        TextStyle(color: Color.fromARGB(255, 206, 206, 206)),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6C757D)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF28A745)),
                    ),
                  ),
                )
              : Text(
                  locationController.text.isNotEmpty
                      ? locationController.text
                      : 'No hay información de locación',
                  style: TextStyle(color: Color(0xFF6C757D)),
                ),
        ],
      ),
    );
  }

  Widget buildEditableRow2(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Color(0xFF6C757D))),
          SizedBox(height: 8),
          isEditing
              ? TextField(
                  controller: jobTitleController,
                  style: TextStyle(color: Color(0xFF6C757D)),
                  decoration: InputDecoration(
                    hintText: 'Ingeniero de Software',
                    hintStyle:
                        TextStyle(color: Color.fromARGB(255, 206, 206, 206)),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6C757D)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF28A745)),
                    ),
                  ),
                )
              : Text(
                  jobTitleController.text.isNotEmpty
                      ? jobTitleController.text
                      : 'No hay información de profesión',
                  style: TextStyle(color: Color(0xFF6C757D)),
                ),
        ],
      ),
    );
  }

  void _updateUserInfo() {
    if (_user == null) {
      print('Error: User is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Información de usuario no disponible')),
      );
      return;
    }

    // Primero, verificamos si ya existe una persona para este usuario
    _httpHelper?.getPersonaByUserId(_user!.id).then((response) {
      if (response.status == 1 && response.persona != null) {
        // Si la persona existe, actualizamos la información existente
        _httpHelper
            ?.actualizarPersona(
          locationController.text,
          jobTitleController.text,
          bioController.text,
          _user!.id,
          response.persona!.id,
        )
            .then((updateResponse) {
          if (updateResponse.status == 1) {
            print('Persona actualizada correctamente');
            setState(() {
              _person = updateResponse.persona;
              isEditing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Información actualizada correctamente')),
            );
          } else {
            print('Error al actualizar persona: ${updateResponse.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Error al actualizar la información: ${updateResponse.message}')),
            );
          }
        });
      } else {
        // Si la persona no existe, creamos una nueva
        _httpHelper
            ?.registrarPersona(
          locationController.text,
          jobTitleController.text,
          bioController.text,
          _user!.id,
        )
            .then((createResponse) {
          if (createResponse.status == 1) {
            print('Nueva persona creada correctamente');
            setState(() {
              _person = createResponse.persona;
              isEditing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Información creada correctamente')),
            );
          } else {
            print('Error al crear persona: ${createResponse.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Error al crear la información: ${createResponse.message}')),
            );
          }
        });
      }
    });
  }

  Widget _buildBioSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bio',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA0522D))),
                TextButton(
                  onPressed: () {
                    if (isEditing) {
                      _updateUserInfo();
                    } else {
                      setState(() {
                        isEditing = true;
                      });
                    }
                  },
                  child: Text(
                    isEditing ? 'Guardar' : 'Editar',
                    style: TextStyle(color: Color(0xFF28A745)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            isEditing
                ? TextField(
                    controller: bioController,
                    style: TextStyle(color: Color(0xFF6C757D)),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Escribe algo sobre ti...',
                      hintStyle:
                          TextStyle(color: Color.fromARGB(255, 206, 206, 206)),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF6C757D)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF28A745)),
                      ),
                    ),
                  )
                : Text(
                    bioController.text.isNotEmpty
                        ? bioController.text
                        : 'No hay información de bio',
                    style: TextStyle(color: Color(0xFF6C757D)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Social',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA0522D))),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.flutter_dash, size: 20, color: Color(0xFF5A9BD5)),
                SizedBox(width: 5),
                Text('@johndoe', style: TextStyle(color: Color(0xFF6C757D))),
                SizedBox(width: 20),
                Icon(Icons.link, size: 20, color: Color(0xFF5A9BD5)),
                SizedBox(width: 5),
                Text('John Doe', style: TextStyle(color: Color(0xFF6C757D))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actividad Reciente',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA0522D))),
            SizedBox(height: 10),
            _buildActivityItem('Shared a new blog post', '2 days ago'),
            _buildActivityItem('Liked a post on Instagram', '1 week ago'),
            _buildActivityItem('Commented on a YouTube video', '2 weeks ago'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Color(0xFF6C757D))),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF28A745))),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String activity, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFFAD7A0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.star, color: Color(0xFFFD7E14)),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity, style: TextStyle(color: Color(0xFF6C757D))),
                Text(time,
                    style: TextStyle(color: Color(0xFF6C757D), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
