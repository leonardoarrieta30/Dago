import 'dart:convert';

import 'package:dago_application/components/bienvenida.dart';
import 'package:dago_application/models/response/login_response.dart';
import 'package:dago_application/models/user.dart';
import 'package:flutter/material.dart';
import 'package:dago_application/components/security/signup.dart';
import 'package:dago_application/data/remote/http_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _usuarioController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true; // Para controlar la visibilidad de la contraseña

  HttpHelper? _httpHelper;

  // Paleta de colores
  final Color primaryColor = Color(0xFF007BFF); // Azul fuerte
  final Color accentColor = Color(0xFF28A745); // Verde fuerte
  final Color backgroundColor = Color(0xFFE9ECEF); // Gris claro
  final Color textColor = Color(0xFF6C757D); // Gris medio
  final Color buttonColor = Color(0xFFFD7E14); // Naranja fuerte
  final Color secondaryTextColor = Color(0xFF5A9BD5); // Azul claro

  @override
  void initState() {
    _httpHelper = HttpHelper();
    super.initState();
  }

  void _saveSessionData(User? user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String usuarioJson = jsonEncode(user?.toJson());
    // print(usuarioJson);
    await prefs.setString('usuario', usuarioJson);
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscureText,
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
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: textColor,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
/*         title: Text('Acceso Construcción',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), */
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
                Icons.architecture,
                size: 80,
                color: Color(0xFFA0522D), // Marrón tierra
              ),
              SizedBox(height: 20),
              Text(
                'Bienvenido, Inge',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Accede a tu cuenta para comenzar',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              _buildTextField(_usuarioController, 'Email'),
              SizedBox(height: 16.0),
              _buildTextField(_passwordController, 'Contraseña',
                  isPassword: true),
              SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: () {
                  // Aquí iría la lógica de inicio de sesión
                  Future<LoginResponse> response = _httpHelper!
                      .login(_usuarioController.text, _passwordController.text);
                  response.then((value) {
                    if (value.status == 1) {
                      print("Inicio de sesión exitoso: ${value.message}");
                      _saveSessionData(value.user);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),
                      );
                    } else {
                      print("Error al iniciar sesión: ${value.message}");
                    }
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    'Iniciar Sesión',
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignupPage()),
                  );
                },
                child: Text(
                  'Registrese',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8.0),
              TextButton(
                onPressed: () {
                  // Aquí iría la lógica para recuperar la contraseña
                },
                child: Text(
                  'Olvidé mi contraseña',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 16,
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
