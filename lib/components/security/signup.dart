import 'package:dago_application/data/remote/http_helper.dart';
import 'package:dago_application/models/response/login_response.dart';
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

  // Modern and attractive color palette
  final Color primaryColor = Color(0xFF3B82F6); // Sky blue
  final Color accentColor = Color(0xFFEC4899); // Pink
  final Color backgroundColor = Color(0xFFF3F4F6); // Light grey
  final Color textColor = Color(0xFF111827); // Dark grey
  final Color buttonColor = Color(0xFF10B981); // Green

  String? _nombreError;
  String? _apellidoError;
  String? _usuarioError;
  String? _passwordError;
  String? _dniError;
  String? _fechaNacimientoError;

  initialize() async {}

  @override
  void initState() {
    _httpHelper = HttpHelper();
    initialize();
    super.initState();
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isPassword = false,
    String? errorMessage,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            obscureText: isPassword,
            style: TextStyle(color: textColor, fontSize: 16),
            decoration: InputDecoration(
              labelText: label,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: textColor.withOpacity(0.3), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              labelStyle:
                  TextStyle(color: textColor.withOpacity(0.7), fontSize: 16),
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                errorMessage,
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
        ],
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

  void _validateAndSubmit() {
    setState(() {
      _nombreError =
          _nombreController.text.isEmpty ? 'El nombre es obligatorio' : null;
      _apellidoError = _apellidoController.text.isEmpty
          ? 'El apellido es obligatorio'
          : null;
      _usuarioError = _usuarioController.text.isEmpty ||
              !_usuarioController.text.contains('@')
          ? 'Ingrese un correo válido'
          : null;
      _passwordError = _passwordController.text.isEmpty ||
              _passwordController.text.length < 8
          ? 'La contraseña debe tener al menos 8 caracteres'
          : null;
      _dniError = _dniController.text.isEmpty || _dniController.text.length < 8
          ? 'El DNI debe tener al menos 8 caracteres'
          : null;
      _fechaNacimientoError = _fechaNacimientoController.text.isEmpty
          ? 'Seleccione una fecha de nacimiento'
          : null;
    });

    if (_nombreError == null &&
        _apellidoError == null &&
        _usuarioError == null &&
        _passwordError == null &&
        _dniError == null &&
        _fechaNacimientoError == null) {
      // Si no hay errores, realizar el registro
      _registerUser();
    }
  }

  void _registerUser() {
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
        // Registro exitoso, navegar
        Navigator.pop(context);
      }
    }).catchError((error) {
      // Manejo de errores si es necesario
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Registrate',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Complete sus datos para registrarse',
                style: TextStyle(
                  fontSize: 18,
                  color: textColor.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    _buildTextField(_nombreController, 'Nombre',
                        errorMessage: _nombreError),
                    _buildTextField(_apellidoController, 'Apellido',
                        errorMessage: _apellidoError),
                    _buildTextField(_usuarioController, 'Email',
                        errorMessage: _usuarioError),
                    _buildTextField(_passwordController, 'Contraseña',
                        isPassword: true, errorMessage: _passwordError),
                    _buildTextField(_dniController, 'DNI',
                        errorMessage: _dniError),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: _buildTextField(
                            _fechaNacimientoController, 'Fecha de Nacimiento',
                            errorMessage: _fechaNacimientoError),
                      ),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _validateAndSubmit,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Registrarse',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
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
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Ya tengo una cuenta',
                  style: TextStyle(
                    color: buttonColor,
                    fontSize: 18,
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
