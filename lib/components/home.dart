import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dago_application/data/remote/http_helper.dart';
import 'package:dago_application/models/document.dart';
import 'package:flutter/material.dart';
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
    //_searchController.addListener(_onSearchChanged);
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
        _searchResults = response ?? [];
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

  Future<void> _saveAndOpenPDF(String base64String, String fileName) async {
    // Solicitar permisos de almacenamiento
    var status = await Permission.storage.request();
    if (status.isGranted) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Decodificar el string base64
        Uint8List bytes = base64Decode(base64String);

        // Obtener el directorio de documentos
        Directory? appDocDir = await getExternalStorageDirectory();
        String filePath = '${appDocDir!.path}/$fileName';

        // Escribir el archivo
        File file = File(filePath);
        await file.writeAsBytes(bytes);

        setState(() {
          _isLoading = false;
        });

        // Abrir el archivo
        await OpenFile.open(filePath);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar el documento: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Se requieren permisos de almacenamiento para guardar el documento')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE9ECEF),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_getGreeting()}, $_userName!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 58, 19, 1),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar documentos por área...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                //onSubmitted: (_) => _performSearch(),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _selectDate(context, true),
                      child: Text(_fromDate == null
                          ? 'Desde'
                          : 'Desde: ${DateFormat('dd/MM/yyyy').format(_fromDate!)}'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _selectDate(context, false),
                      child: Text(_toDate == null
                          ? 'Hasta (opcional)'
                          : 'Hasta: ${DateFormat('dd/MM/yyyy').format(_toDate!)}'),
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
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color.fromARGB(255, 80, 7,
                                      47), // Puedes cambiar este color
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                title: Text(
                                  result.titulo.split(".").first,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'KronaOne',
                                  ),
                                ),
                                onTap: () {
                                  _saveAndOpenPDF(result.documentoBase64,
                                      '${result.titulo}.pdf');
                                },
                                // Puedes añadir más detalles aquí si lo deseas
                                trailing: Icon(Icons.arrow_forward_ios),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Área: ${result.user?.persona?.descripcionPersonal ?? 'No especificada'}',
                                      style: TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'Fecha de subida: ${result.fechaSubida}',
                                      style: TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      'Reporte de: ${result.user?.nombre} ${result.user?.apellido}',
                                      style: TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                /*  subtitle: Text(
                                  result.fechaSubida,
                                  style: TextStyle(
                                    color: Colors.black,
                                  ),
                                ), */
                              ),
                            ),
                          );
                        },
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
