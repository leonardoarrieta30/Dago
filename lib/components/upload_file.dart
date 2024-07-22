import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UploadFile extends StatefulWidget {
  const UploadFile({Key? key}) : super(key: key);

  @override
  State<UploadFile> createState() => _UploadFileState();
}

class _UploadFileState extends State<UploadFile> {
  List<UploadedFile> recentUploads = [
    UploadedFile('Annual Report 2022.pdf', '2 days ago'),
    UploadedFile('Marketing Presentation.pdf', '1 week ago'),
    UploadedFile('Tax Forms 2021.pdf', '1 month ago'),
  ];

  // Paleta de colores
  final Color primaryColor = Color(0xFF007BFF); // Azul fuerte
  final Color accentColor = Color(0xFF28A745); // Verde fuerte
  final Color backgroundColor = Color(0xFFE9ECEF); // Gris claro
  final Color textColor = Color(0xFF6C757D); // Gris medio
  final Color buttonColor = Color(0xFFFD7E14); // Naranja fuerte
  final Color secondaryTextColor = Color(0xFF5A9BD5); // Azul claro

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // o cualquier color que prefieras
      statusBarIconBrightness: Brightness.dark, // para iconos oscuros
    ));
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false, // Esto quita el botón de retroceso
        toolbarHeight: 0, // Esto hace que el AppBar sea invisible
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sube tus archivos PDF',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Almacena y gestiona de forma segura tus documentos importantes.',
                style: TextStyle(fontSize: 16, color: textColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: secondaryTextColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.upload_file, size: 50, color: accentColor),
                    SizedBox(height: 10),
                    // Text('Arrastra y suelta tus archivos PDF aquí',
                    //     textAlign: TextAlign.center,
                    //     style: TextStyle(color: textColor)),
                    // Text('o', style: TextStyle(color: textColor)),
                    // SizedBox(height: 10),
                    ElevatedButton(
                      child: Text('Seleccionar Archivos'),
                      onPressed: () {
                        // Implementar lógica de selección de archivos
                      },
                      style: ElevatedButton.styleFrom(
                        primary: buttonColor,
                        onPrimary: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Text(
                'Subidas Recientes',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor),
              ),
              SizedBox(height: 10),
              Column(
                children: recentUploads
                    .map((file) => UploadedFileWidget(
                        file, primaryColor, textColor, accentColor))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadedFile {
  final String name;
  final String uploadTime;

  UploadedFile(this.name, this.uploadTime);
}

class UploadedFileWidget extends StatelessWidget {
  final UploadedFile file;
  final Color primaryColor;
  final Color textColor;
  final Color accentColor;

  UploadedFileWidget(
      this.file, this.primaryColor, this.textColor, this.accentColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file, color: primaryColor),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: textColor)),
                Text('Subido ${file.uploadTime}',
                    style: TextStyle(
                        fontSize: 12, color: textColor.withOpacity(0.7))),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.visibility, color: accentColor),
            onPressed: () {
              // Implementar la lógica para ver el archivo
              print('Ver archivo: ${file.name}');
            },
            tooltip: 'Ver archivo',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: accentColor),
            onPressed: () {
              // Implementar la lógica para eliminar el archivo
              print('Eliminar archivo: ${file.name}');
            },
            tooltip: 'Eliminar archivo',
          ),
        ],
      ),
    );
  }
}
