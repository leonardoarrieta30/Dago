import 'dart:convert';

import 'package:dago_application/data/remote/http_helper.dart';
import 'package:dago_application/models/user.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // final String userName = "John";
  User? _user;
  HttpHelper? _httpHelper;

  @override
  void initState() {
    super.initState();
    _httpHelper = HttpHelper();
    _loadUsuario();
  }

  void _loadUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? usuarioJson = prefs.getString('usuario');
    if (usuarioJson != null) {
      setState(() {
        _user = User.fromJson(jsonDecode(usuarioJson));
        _initialize();
      });
    }
  }

  Future<void> _initialize() async {
    if (_user != null) {
      _user = await _httpHelper?.getUserById(_user!.id);
      setState(() {});
    }
  }

  // Replace with actual user name
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

  String _getUserName() {
    if (_user != null) {
      return _user!.nombre;
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // o cualquier color que prefieras
      statusBarIconBrightness: Brightness.dark, // para iconos oscuros
    ));
    return Scaffold(
      backgroundColor: Color(0xFFE9ECEF),
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false, // Esto quita el botón de retroceso
        toolbarHeight: 0, // Esto hace que el AppBar sea invisible
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personalized Welcome
              Text(
                "${_getGreeting()}, ${_getUserName()}!",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA0522D)),
              ),
              SizedBox(height: 20),

              // Quick Access Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAccessButton(Icons.person, "Profile"),
                  _buildQuickAccessButton(Icons.notifications, "Notifications"),
                  _buildQuickAccessButton(Icons.settings, "Settings"),
                ],
              ),
              SizedBox(height: 20),

              // Notifications and Alerts
              Card(
                child: ListTile(
                  leading: Icon(Icons.notification_important,
                      color: Color(0xFFFD7E14)),
                  title: Text("New update available!"),
                  subtitle: Text("Tap to see what's new"),
                  onTap: () {},
                ),
              ),
              SizedBox(height: 20),

              // User Progress
              Text(
                "Your Progress",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C757D)),
              ),
              LinearProgressIndicator(
                value: 0.7,
                backgroundColor: Color(0xFFFAD7A0),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF28A745)),
              ),
              Text("70% Complete", style: TextStyle(color: Color(0xFF6C757D))),
              SizedBox(height: 20),

              // Recent Activities
              Text(
                "Recent Activities",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C757D)),
              ),
              _buildRecentActivity("Document uploaded", "2 hours ago"),
              _buildRecentActivity("Profile updated", "Yesterday"),
              SizedBox(height: 20),

              // Featured Content
              Text(
                "Featured Content",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C757D)),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.article, color: Color(0xFF5A9BD5)),
                  title: Text("How to organize your documents"),
                  subtitle: Text("Read our latest guide"),
                  onTap: () {},
                ),
              ),
              SizedBox(height: 20),

              // Useful Resources
              Text(
                "Useful Resources",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C757D)),
              ),
              _buildResourceLink(Icons.help, "FAQ"),
              _buildResourceLink(Icons.support, "Support"),
              SizedBox(height: 20),

              // Social Media
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: Icon(Icons.facebook), onPressed: () {}),
                  // IconButton(icon: Icon(Icons.twitter), onPressed: () {}),
                  // IconButton(icon: Icon(Icons.linkedin), onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF28A745),
      ),
    );
  }

  Widget _buildQuickAccessButton(IconData icon, String label) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Color(0xFF007BFF)),
          onPressed: () {},
        ),
        Text(label, style: TextStyle(color: Color(0xFF6C757D))),
      ],
    );
  }

  Widget _buildRecentActivity(String activity, String time) {
    return ListTile(
      leading: Icon(Icons.access_time, color: Color(0xFF5A9BD5)),
      title: Text(activity),
      subtitle: Text(time),
      dense: true,
    );
  }

  Widget _buildResourceLink(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF28A745)),
      title: Text(label),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: () {},
    );
  }
}
