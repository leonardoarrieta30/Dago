import 'dart:convert';
import 'package:dago_application/models/person.dart';
import 'package:dago_application/models/response/sign_up_response.dart';
import 'package:dago_application/models/social.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dago_application/data/remote/http_helper.dart';
import 'package:dago_application/models/user.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:flutter/services.dart';

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
  bool isEditingSocial = false;

  List<Social> socialNetworks = [];

  File? _image;
  String base64Image = '';

  @override
  void initState() {
    super.initState();
    _httpHelper = HttpHelper();
    // locationController = TextEditingController();
    // jobTitleController = TextEditingController();
    // bioController = TextEditingController();
    _loadUsuario();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSocialNetworks();
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

          if (_person?.foto_perfil != null && _person!.foto_perfil.isNotEmpty) {
            base64Image = _person!.foto_perfil;
            _image = File(''); // Creamos un archivo vacío
          }
        });
        await _loadSocialNetworks();
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

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      // Convertir la imagen a base64
      base64Image = await compressAndEncodeImage(_image!);

      // Actualizar la persona con la nueva imagen
      _updateUserInfoWithImage(base64Image);
    }
  }

  Future<String> compressAndEncodeImage(File imageFile) async {
    Uint8List imageBytes = await imageFile.readAsBytes();
    img.Image image = img.decodeImage(imageBytes)!;

    img.Image compressedImage = img.copyResize(image,
        width: 800); // Ajusta el ancho según tus necesidades

    List<int> compressedBytes = img.encodeJpg(compressedImage,
        quality: 85); // Ajusta la calidad según tus necesidades

    return base64Encode(compressedBytes);
  }

  void _updateUserInfoWithImage(String base64Image) {
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
          base64Image, // Añadimos la imagen en base64
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
            // Verificar si la información básica está completa
            if (_isBasicInfoComplete() && socialNetworks.isEmpty) {
              _addSocialNetwork();
            }
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
          base64Image, // Añadimos la imagen en base64
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
    await prefs.remove('social_networks');
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  void _saveSocialNetworksLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String socialNetworksJson =
        jsonEncode(socialNetworks.map((s) => s.toJson()).toList());
    await prefs.setString('social_networks', socialNetworksJson);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // o cualquier color que prefieras
      statusBarIconBrightness: Brightness.dark, // para iconos oscuros
    ));
    return Scaffold(
      backgroundColor: Color(0xFFE9ECEF),
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false, // Esto quita el botón de retroceso
        toolbarHeight: 0, // Esto hace que el AppBar sea invisible
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
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
                  if (_isBasicInfoComplete()) _buildSocialSection(),
                  // SizedBox(height: 20),
                  // _buildRecentActivitySection(),
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
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: _getProfileImage(),
                          child: _getProfileImage() == null
                              ? Icon(Icons.person,
                                  size: 50, color: Color(0xFF6C757D))
                              : null,
                        ),
                        if (_getProfileImage() == null)
                          Positioned(
                            bottom: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Subir foto',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                      ],
                    ),
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

  ImageProvider? _getProfileImage() {
    if (_image != null && _image!.existsSync()) {
      return FileImage(_image!);
    } else if (base64Image.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(base64Image));
      } catch (e) {
        print('Error decoding base64Image: $e');
      }
    } else if (_person?.foto_perfil != null &&
        _person!.foto_perfil.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(_person!.foto_perfil));
      } catch (e) {
        print('Error decoding _person.foto_perfil: $e');
      }
    }
    return null;
  }

  bool _showDefaultIcon() {
    return _image == null &&
        base64Image.isEmpty &&
        (_person?.foto_perfil == null || _person!.foto_perfil.isEmpty);
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
          base64Image.isEmpty ? response.persona!.foto_perfil : base64Image,
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
            // Verificar si la información básica está completa
            if (_isBasicInfoComplete() && socialNetworks.isEmpty) {
              _addSocialNetwork();
            }
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
          base64Image,
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

  bool _isBasicInfoComplete() {
    return locationController.text.isNotEmpty ||
        jobTitleController.text.isNotEmpty ||
        bioController.text.isNotEmpty;
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

  Future<void> _loadSocialNetworks() async {
    if (_person == null) return;
    try {
      final response = await _httpHelper?.getRedesSociales(_person!.id);
      if (response != null && response.status == 1) {
        setState(() {
          socialNetworks = response.socialNetworks ?? [];
        });
        _saveSocialNetworksLocally(); // Actualiza la caché local
      } else {
        // Si la API falla, intenta cargar desde la caché local
        await _loadSocialNetworksFromLocal();
      }
    } catch (e) {
      print('Error al cargar redes sociales: $e');
      await _loadSocialNetworksFromLocal();
    }
  }

  Future<void> _loadSocialNetworksFromLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? socialNetworksJson = prefs.getString('social_networks');
    if (socialNetworksJson != null) {
      List<dynamic> decodedList = jsonDecode(socialNetworksJson);
      setState(() {
        socialNetworks =
            decodedList.map((item) => Social.fromJson(item)).toList();
      });
    }
  }

  Widget _buildSocialSection() {
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
                Text('Redes Sociales',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA0522D))),
                TextButton(
                  onPressed: () {
                    if (isEditingSocial) {
                      _updateSocialInfo();
                    } else {
                      setState(() {
                        isEditingSocial = true;
                      });
                    }
                  },
                  child: Text(
                    isEditingSocial ? 'Guardar' : 'Editar',
                    style: TextStyle(color: Color(0xFF28A745)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            ...socialNetworks.map((network) => _buildSocialMediaRow(network)),
            if (isEditingSocial)
              ElevatedButton(
                onPressed: _addSocialNetwork,
                child: Text('Agregar Red Social'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaRow(Social network) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.link, size: 20, color: Color(0xFF5A9BD5)),
            onPressed: () => _launchURL(network.nombre),
          ),
          SizedBox(width: 10),
          Expanded(
            child: isEditingSocial
                ? TextField(
                    controller: TextEditingController(text: network.nombre),
                    onChanged: (value) => network.nombre = value,
                    decoration: InputDecoration(
                      hintText: 'Nombre/URL de la red social',
                      border: OutlineInputBorder(),
                    ),
                  )
                : Text(
                    network.nombre,
                    style: TextStyle(color: Color(0xFF6C757D)),
                  ),
          ),
          if (isEditingSocial)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _removeSocialNetwork(network),
            ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se proporcionó una URL válida')),
      );
      return;
    }

    // Añadir 'https://' si no está presente
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    // ignore: deprecated_member_use
    if (await canLaunch(url)) {
      // ignore: deprecated_member_use
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  void _addSocialNetwork() {
    setState(() {
      socialNetworks.add(Social(
          id: 0,
          nombre: '',
          personaId: 0)); // El personaId se asignará en el backend
    });
  }

  void _removeSocialNetwork(Social network) async {
    try {
      final response = await _httpHelper?.eliminarRedSocial(network.id);

      if (response != null && response.status == 1) {
        setState(() {
          socialNetworks.remove(network);
        });
        _saveSocialNetworksLocally();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Red social eliminada correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error al eliminar la red social: ${response?.message ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      print('Error al eliminar la red social: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la red social')),
      );
    }
  }

  void _updateSocialInfo() {
    if (_user == null) {
      print('Error: User is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Información de usuario no disponible')),
      );
      return;
    }

    // Filtrar redes sociales vacías
    socialNetworks =
        socialNetworks.where((network) => network.nombre.isNotEmpty).toList();

    // Actualizar redes sociales
    _httpHelper
        ?.actualizarRedesSociales(
      _user!.id, // Usar el ID del usuario en lugar del ID de la persona
      socialNetworks,
    )
        .then((response) {
      if (response.status == 1) {
        print('Redes sociales actualizadas correctamente');
        setState(() {
          isEditingSocial = false;
          socialNetworks = response.socialNetworks ?? [];
        });
        _saveSocialNetworksLocally();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Redes sociales actualizadas correctamente')),
        );
        _loadSocialNetworks();
      } else {
        print('Error al actualizar redes sociales: ${response.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error al actualizar redes sociales: ${response.message}')),
        );
      }
    });
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
