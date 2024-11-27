import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:another_flushbar/flushbar.dart';
import 'package:dago_application/data/remote/http_helper.dart';
import 'package:dago_application/models/document.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = "";
  TextEditingController _searchController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  List<Document> _searchResults = [];
  bool _isLoading = false;
  HttpHelper? _httpHelper;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _httpHelper = HttpHelper();
    _loadUserName();
    _fetchAllDocuments(); // Cargar todos los documentos inicialmente
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchAllDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _httpHelper!.getDocumentosByArea(null, null, null);

      if (!mounted) return;

      setState(() {
        _searchResults = response ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar documentos: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('usuario');
    if (userJson != null) {
      final userData = jsonDecode(userJson);
      setState(() {
        _userName = userData['nombre'] ?? "";
      });
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return "Buenos Días";
    } else if (hour < 19) {
      return "Buenas Tardes";
    } else {
      return "Buenas Noches";
    }
  }

  void _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? (_fromDate ?? DateTime.now())
          : (_toDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          _toDate = null; // Resetear la fecha "Hasta"
        } else {
          _toDate = picked;
        }
      });
      _performSearch(); // Realizar búsqueda después de seleccionar la fecha
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_fromDate != null) {
        _performSearch();
      }
    });
  }

  Future<void> _performSearch() async {
    if (_fromDate == null) {
      // Si no hay fecha "Desde", cargamos todos los documentos
      await _fetchAllDocuments();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String fromDateStr = DateFormat('yyyy-MM-dd').format(_fromDate!);
      String toDateStr = _toDate != null
          ? DateFormat('yyyy-MM-dd').format(_toDate!)
          : DateFormat('yyyy-MM-dd').format(DateTime.now());
      String? area =
          _searchController.text.isNotEmpty ? _searchController.text : null;

      final response = await _httpHelper!.getDocumentosByArea(
        area,
        fromDateStr,
        toDateStr,
      );

      if (!mounted) return;

      setState(() {
        _searchResults = response;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar documentos: $e')),
      );
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      // Para Android 11+ necesitas el permiso MANAGE_EXTERNAL_STORAGE
      if (await Permission.manageExternalStorage.isDenied ||
          await Permission.manageExternalStorage.isPermanentlyDenied) {
        var status = await Permission.manageExternalStorage.request();
        if (status.isGranted) {
          // Permiso concedido
        } else {
          // Permiso denegado
          _showPermissionDeniedMessage();
        }
      }
    } else {
      // Para Android 10 o inferior usa los permisos de almacenamiento
      if (await Permission.storage.isDenied ||
          await Permission.storage.isPermanentlyDenied) {
        var status = await Permission.storage.request();
        if (status.isGranted) {
          // Permiso concedido
        } else {
          // Permiso denegado
          _showPermissionDeniedMessage();
        }
      }
    }
  }

  void _showPermissionDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.lock,
                color: Colors.white), // Ícono de advertencia o bloqueo
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Se requieren permisos de almacenamiento para guardar el documento.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orangeAccent, // Cambiar el color de fondo
        behavior: SnackBarBehavior.floating, // Hacer que el SnackBar flote
        margin: EdgeInsets.all(16), // Margen alrededor del SnackBar
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Bordes redondeados
        ),
        // action: SnackBarAction(
        //   label: 'Permitir',
        //   textColor: Colors.white, // Color del texto de la acción
        //   onPressed: () {
        //     // Lógica para solicitar permisos
        //   },
        // ),
        duration:
            Duration(seconds: 4), // Mantener el SnackBar visible por 4 segundos
      ),
    );
  }

  Future<void> _saveAndOpenPDF(String base64String, String fileName) async {
    // Solicitar permisos de almacenamiento
    await _checkAndRequestPermissions(); // Método que acabamos de implementar

    try {
      // Decodificar el string base64
      Uint8List bytes = base64Decode(base64String);

      // Obtener el directorio de almacenamiento externo permitido
      Directory? appDocDir;
      if (Platform.isAndroid &&
          (await Permission.manageExternalStorage.isGranted)) {
        appDocDir = await getExternalStorageDirectory();
      } else {
        appDocDir = await getApplicationDocumentsDirectory();
      }

      // Asegúrate de que el directorio exista
      if (appDocDir != null && !await appDocDir.exists()) {
        await appDocDir.create(recursive: true);
      }

      // Crear la ruta completa del archivo
      String filePath = '${appDocDir!.path}/$fileName';

      // Escribir el archivo en el sistema de archivos
      File file = File(filePath);
      await file.writeAsBytes(bytes);

      // Abrir el archivo usando OpenFile
      await OpenFile.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar el documento: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      backgroundColor: Colors.white, // Fondo blanco para una apariencia limpia
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_getGreeting()}, $_userName!",
                style: TextStyle(
                  fontSize: 28, // Aumentar el tamaño de la fuente
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily:
                      'Montserrat', // Usar una fuente moderna y estilizada
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar documentos por área...',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontFamily: 'Montserrat',
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey[400]!,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.blueGrey[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Colors.blueGrey[100]!,
                            width: 1,
                          ),
                        ),
                      ),
                      onPressed: () => _selectDate(context, true),
                      child: Text(
                        _fromDate == null
                            ? 'Desde'
                            : 'Desde: ${DateFormat('dd/MM/yyyy').format(_fromDate!)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Montserrat',
                          color: Colors.blueGrey[800],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.blueGrey[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Colors.blueGrey[100]!,
                            width: 1,
                          ),
                        ),
                      ),
                      onPressed: () => _selectDate(context, false),
                      child: Text(
                        _toDate == null
                            ? 'Hasta (opcional)'
                            : 'Hasta: ${DateFormat('dd/MM/yyyy').format(_toDate!)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Montserrat',
                          color: Colors.blueGrey[800],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return GestureDetector(
                            onTap: () async {
                              showDialog(
                                context: context,
                                barrierDismissible:
                                    false, // No permitir cerrar el diálogo al hacer clic fuera
                                builder: (BuildContext context) {
                                  return Center(
                                    child:
                                        CircularProgressIndicator(), // Indicador de carga
                                  );
                                },
                              );
                              // Obtener el base64 del documento al hacer clic
                              String? base64 = await _httpHelper!
                                  .getDocumentoBase64(result.id);
                              // Cerrar el diálogo después de obtener la respuesta
                              Navigator.of(context).pop();
                              if (base64 != null) {
                                _saveAndOpenPDF(base64, '${result.titulo}.pdf');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Error al obtener el documento')),
                                );
                              }
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 10),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf,
                                    size: 50,
                                    color: Colors.redAccent,
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          result.titulo.split(".").first,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Montserrat',
                                            color: Colors.black87,
                                            letterSpacing: 0.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          'Área: ${result.user?.persona?.descripcionPersonal ?? 'No especificada'}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                            fontFamily: 'Montserrat',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Fecha de subida: ${result.fechaSubida}',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 14,
                                            fontFamily: 'Montserrat',
                                          ),
                                        ),
                                        Text(
                                          'Creador: ${result.user?.nombre} ${result.user?.apellido}',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 14,
                                            fontFamily: 'Montserrat',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
