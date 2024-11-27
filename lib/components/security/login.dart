import 'dart:convert';
import 'package:dago_application/components/bienvenida.dart';
import 'package:dago_application/components/security/forgotpassword.dart';
import 'package:flutter/material.dart';
import 'package:dago_application/components/security/signup.dart';
import 'package:dago_application/data/remote/http_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dago_application/models/response/login_response.dart';
import 'package:dago_application/models/user.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _usuarioController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true; // Control visibility of password

  HttpHelper? _httpHelper;

  // Modern and attractive color palette
  final Color primaryColor = Color(0xFF3B82F6); // Sky blue
  final Color accentColor = Color(0xFFEC4899); // Pink
  final Color backgroundColor = Color(0xFFF3F4F6); // Light grey
  final Color textColor = Color(0xFF111827); // Dark grey
  final Color buttonColor = Color(0xFF10B981); // Green

  @override
  void initState() {
    _httpHelper = HttpHelper();
    super.initState();
  }

  void _saveSessionData(User? user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String usuarioJson = jsonEncode(user?.toJson());
    await prefs.setString('usuario', usuarioJson);
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscureText,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textColor.withOpacity(0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: textColor.withOpacity(0.5),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 40),
              Image.asset(
                'assets/images/ingeniero2r.png', // Ruta de la imagen en tus assets
                height: 130, // Tamaño de la imagen
                width: 130, // Tamaño de la imagen
                fit: BoxFit.contain, // Ajuste de la imagen (opcional)
              ),
              SizedBox(height: 20),
              Text(
                'Bienvenido',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6),
              Text(
                'Inicia sesión para continuar',
                style: TextStyle(
                  fontSize: 18,
                  color: textColor.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              _buildTextField(_usuarioController, 'Email'),
              SizedBox(height: 14),
              _buildTextField(_passwordController, 'Contraseña',
                  isPassword: true),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Lógica de inicio de sesión
                  Future<LoginResponse> response = _httpHelper!
                      .login(_usuarioController.text, _passwordController.text);
                  response.then((value) {
                    if (value.status == 1) {
                      _saveSessionData(value.user);

// Mostrar SnackBar de inicio de sesión exitoso
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.white), // Ícono de éxito
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Inicio de sesión exitoso. Bienvenido!',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor:
                              Colors.green, // Color verde para indicar éxito
                          behavior: SnackBarBehavior
                              .floating, // Hacer que el SnackBar flote
                          margin: EdgeInsets.all(
                              16), // Margen alrededor del SnackBar
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10), // Bordes redondeados
                          ),
                          duration:
                              Duration(seconds: 3), // Duración de 3 segundos
                        ),
                      );

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
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Iniciar Sesión',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 18),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignupPage()),
                  );
                },
                child: Text(
                  'Registrarse',
                  style: TextStyle(
                    color: buttonColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ForgotPasswordPage()),
                  );
                },
                child: Text(
                  'Olvidé mi contraseña',
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
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
