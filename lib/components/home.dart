import 'dart:async';
import 'dart:convert';
import 'package:dago_application/data/remote/http_helper.dart';
import 'package:dago_application/models/document.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
    _searchController.addListener(_onSearchChanged);
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

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
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
        } else {
          _toDate = picked;
        }
      });
      _performSearch();
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
    if (_searchController.text.isEmpty || _fromDate == null) {
      setState(() {
        _searchResults = [];
      });
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
      final response = await _httpHelper!.getDocumentosByArea(
        _searchController.text,
        fromDateStr,
        toDateStr,
      );

      setState(() {
        _searchResults = response ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar documentos: $e')),
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
                  color: Color(0xFFA0522D),
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
                          return ListTile(
                            title: Text(result.titulo),
                            onTap: () {
                              // Aquí puedes agregar la lógica para manejar el tap en un resultado
                            },
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
