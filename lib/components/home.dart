import 'dart:convert';
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
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
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
      initialDate:
          isFromDate ? _fromDate ?? DateTime.now() : _toDate ?? DateTime.now(),
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
    }
  }

  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty ||
        _fromDate == null ||
        _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Por favor, complete todos los campos de búsqueda')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simular llamada API
    await Future.delayed(Duration(seconds: 2));

    // Simulación de respuesta de API
    final response = {
      'results': [
        {'id': 1, 'title': 'Resultado 1', 'date': '2024-09-15'},
        {'id': 2, 'title': 'Resultado 2', 'date': '2024-09-16'},
        {'id': 3, 'title': 'Resultado 3', 'date': '2024-09-17'},
      ]
    };

    setState(() {
      _searchResults = response['results']!;
      _isLoading = false;
    });
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
                  hintText: 'Buscar por área...',
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
                          ? 'Hasta'
                          : 'Hasta: ${DateFormat('dd/MM/yyyy').format(_toDate!)}'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: _performSearch,
                  child: Text('Buscar'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(200, 50), // Ajusta el tamaño del botón
                  ),
                ),
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
                            title: Text(result['title']),
                            subtitle: Text(result['date']),
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
