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

  final List<Widget> _pages = [
    HomeScreen(),
    const UploadFile(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.grey[200],
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 16,
        unselectedFontSize: 14,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons
                .dashboard_rounded), // Icono más moderno para la página de inicio
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons
                .file_upload_outlined), // Icono más moderno para la subida de archivos
            label: 'Subir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons
                .account_circle_rounded), // Icono más moderno para el perfil
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
