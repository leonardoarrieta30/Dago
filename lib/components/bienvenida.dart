import 'package:dago_application/components/home.dart';
import 'package:dago_application/components/profile.dart';
import 'package:dago_application/components/upload_file.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Lista de páginas que se mostrarán en el área central del Scaffold
  final List<Widget> _pages = [
    HomeScreen(),
    const UploadFile(),
    ProfilePage(),
  ];

  // Función para manejar el cambio de índice en el BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _pages[
            _currentIndex], // Mostrar la página correspondiente al índice seleccionado
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Casa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Subir Archivos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
