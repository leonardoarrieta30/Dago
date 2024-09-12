import 'package:dago_application/data/remote/http_helper.dart';
import 'package:dago_application/models/response/login_response.dart';
import 'package:dago_application/models/response/sign_up_response.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  TextEditingController _nombreController = TextEditingController();
  TextEditingController _apellidoController = TextEditingController();
  TextEditingController _usuarioController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _dniController = TextEditingController();
  TextEditingController _fechaNacimientoController = TextEditingController();

  HttpHelper? _httpHelper;

  // Paleta de colores
  final Color primaryColor = Color(0xFF007BFF); // Azul fuerte
  final Color accentColor = Color(0xFF28A745); // Verde fuerte
  final Color backgroundColor = Color(0xFFE9ECEF); // Gris claro
  final Color textColor = Color(0xFF6C757D); // Gris medio
  final Color buttonColor = Color(0xFFFD7E14); // Naranja fuerte
  final Color secondaryTextColor = Color(0xFF5A9BD5); // Azul claro

  initialize() async {}

  @override
  void initState() {
    _httpHelper = HttpHelper();
    initialize();
    super.initState();
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Color(0xFFD2B48C), width: 2), // Marrón claro
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        labelStyle: TextStyle(color: textColor),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: primaryColor,
            colorScheme: ColorScheme.light(primary: primaryColor),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fechaNacimientoController.text =
            DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Registro',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              Icon(
                Icons.person_add,
                size: 80,
                color: Color(0xFFA0522D), // Marrón tierra
              ),
              SizedBox(height: 20),
              Text(
                'Crear Cuenta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Complete sus datos para registrarse',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              _buildTextField(_nombreController, 'Nombre'),
              SizedBox(height: 16.0),
              _buildTextField(_apellidoController, 'Apellido'),
              SizedBox(height: 16.0),
              _buildTextField(_usuarioController, 'Email'),
              SizedBox(height: 16.0),
              _buildTextField(_passwordController, 'Contraseña'),
              SizedBox(height: 16.0),
              _buildTextField(_dniController, 'DNI'),
              SizedBox(height: 16.0),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildTextField(
                      _fechaNacimientoController, 'Fecha de Nacimiento'),
                ),
              ),
              SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: () {
                  // Aquí iría la lógica de registro
                  Future<LoginResponse> response = _httpHelper!.crearUsuario(
                    _usuarioController.text,
                    _passwordController.text,
                    _nombreController.text,
                    _apellidoController.text,
                    _fechaNacimientoController.text,
                    _dniController.text,
                  );

                  response.then((value) {
                    if (value.status == 1) {
                      Navigator.pop(context);
                    } else if (value.status == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al registrar el usuario'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    'Registrarse',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  //primary: buttonColor,
                  //onPrimary: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Ya tengo una cuenta',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
