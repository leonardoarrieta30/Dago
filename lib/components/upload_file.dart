import 'package:dago_application/data/remote/http_helper.dart';
import 'package:dago_application/models/document.dart';
import 'package:dago_application/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

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
  HttpHelper? _httpHelper;
  List<ImageWithDescription> _images = [];
  User? _user;
  String? _generatedPDFPath;
  // List<Document>? _recentPDFs;
  bool _isLoading = true;
  bool _isGeneratingPDF = false;

  // Paleta de colores
  final Color primaryColor = Color(0xFF007BFF);
  final Color accentColor = Color(0xFF28A745);
  final Color backgroundColor = Color(0xFFE9ECEF);
  final Color textColor = Color(0xFF6C757D);
  final Color buttonColor = Color(0xFFFD7E14);
  final Color secondaryTextColor = Color(0xFF5A9BD5);

  @override
  void initState() {
    super.initState();
    _httpHelper = HttpHelper();
    // locationController = TextEditingController();
    // jobTitleController = TextEditingController();
    // bioController = TextEditingController();
    _loadData();
  }

  // Future<void> _clearCache() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('cached_docs');
  // }

  // Future<void> _loadRecentPDFs() async {
  //   if (_user != null && _httpHelper != null) {
  //     try {
  //       SharedPreferences prefs = await SharedPreferences.getInstance();
  //       String? cachedDocs = prefs.getString('cached_docs');

  //       if (cachedDocs != null) {
  //         // Si hay documentos en caché, úsalos
  //         List<dynamic> decodedDocs = jsonDecode(cachedDocs);
  //         _recentPDFs =
  //             decodedDocs.map((doc) => Document.fromJson(doc)).toList();
  //         print('Loaded ${_recentPDFs?.length} PDFs from cache');
  //       } else {
  //         // Si no hay caché, carga desde la API
  //         print('Loading PDFs for user ID: ${_user!.id}');
  //         final recentDocs =
  //             await _httpHelper!.getDocumentosByUserId(_user!.id);
  //         _recentPDFs = recentDocs;
  //         print('Loaded ${_recentPDFs?.length} PDFs from API');

  //         // Guarda los documentos en caché
  //         await prefs.setString('cached_docs', jsonEncode(_recentPDFs));
  //       }
  //     } catch (e) {
  //       print('Error al cargar PDFs recientes: $e');
  //     }
  //   } else {
  //     print('User or httpHelper is null');
  //   }
  // }

  Future<void> _loadUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? usuarioJson = prefs.getString('usuario');
    if (usuarioJson != null) {
      setState(() {
        _user = User.fromJson(jsonDecode(usuarioJson));
      });
    } else {
      print('No hay usuario');
    }
  }

  Future<void> _loadData() async {
    if (!mounted)
      return; // Verificar si el widget está montado antes de continuar

    setState(() => _isLoading = true);
    await _loadUsuario();
    // if (_user != null) {
    //   print(_user?.id);
    //   await _loadRecentPDFs();
    // }

    if (mounted) {
      // Verificar nuevamente si el widget está montado antes de llamar a setState
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    Future<void> _showDescriptionDialog(ImageWithDescription image) async {
      String? newDescription = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          String tempDescription = image.description;
          return AlertDialog(
            title: Text(image.description.isEmpty
                ? 'Agregar observación'
                : 'Editar observación'),
            content: TextField(
              controller: TextEditingController(text: image.description),
              onChanged: (value) {
                tempDescription = value;
              },
              decoration: InputDecoration(hintText: "Ingrese una observación"),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancelar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Guardar'),
                onPressed: () {
                  Navigator.of(context).pop(tempDescription);
                },
              ),
            ],
          );
        },
      );

      if (newDescription != null) {
        setState(() {
          image.updateDescription(newDescription);
        });
      }
    }

    Future<void> _takePicture() async {
      final ImagePicker _picker = ImagePicker();
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        final newImage = ImageWithDescription(File(photo.path));
        await _showDescriptionDialog(newImage);

        setState(() {
          _images.add(newImage);
        });

        final appDir = await getApplicationDocumentsDirectory();
        final fileName = basename(photo.path);
        final savedImage =
            await File(photo.path).copy('${appDir.path}/$fileName');

        setState(() {
          recentUploads.insert(0, UploadedFile(fileName, 'Ahora'));
        });
      }
    }

    Future<String?> _getPDFTitle() async {
      String? title;
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Título del PDF'),
            content: TextField(
              onChanged: (value) {
                title = value;
              },
              decoration:
                  InputDecoration(hintText: "Ingrese el título del PDF"),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancelar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Guardar'),
                onPressed: () {
                  Navigator.of(context).pop(title);
                },
              ),
            ],
          );
        },
      );
      return title;
    }

    Future<String?> _generateAndSharePDF() async {
      if (_images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No hay fotos para generar el PDF')),
        );
        return null;
      }
      setState(() => _isGeneratingPDF = true);
      try {
        String? pdfTitle = await _getPDFTitle();
        if (pdfTitle == null) return null; // El usuario canceló la operación

        final pdf = pw.Document();
        final font = await PdfGoogleFonts.nunitoRegular();
        final boldFont = await PdfGoogleFonts.nunitoBold();

        // Agrega una página de título
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Text(
                  pdfTitle,
                  style: pw.TextStyle(font: boldFont, fontSize: 24),
                ),
              );
            },
          ),
        );

        for (var imageWithDesc in _images) {
          final imageFile = await imageWithDesc.image.readAsBytes();
          final pdfImage = pw.MemoryImage(imageFile);

          pdf.addPage(
            pw.Page(
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Image(pdfImage, height: 500),
                    pw.SizedBox(height: 10),
                    pw.Text(imageWithDesc.description),
                  ],
                );
              },
            ),
          );
        }

        // Solicitar permiso de almacenamiento
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }

        // Obtener el directorio de documentos
        final output = await getExternalStorageDirectory();
        if (output == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo acceder al almacenamiento')),
          );
          return null;
        }

        final file = File("${output.path}/$pdfTitle.pdf");
        await file.writeAsBytes(await pdf.save());

        // Almacenar la ruta del PDF generado
        setState(() {
          _generatedPDFPath = file.path;
          // _recentPDFs.insert(
          //     0,
          //     RecentPDF(
          //       id: DateTime.now()
          //           .millisecondsSinceEpoch, // Esto es solo un ejemplo, idealmente deberías usar un ID único
          //       titulo: pdfTitle,
          //       documentoBase64: base64Encode(file.readAsBytesSync()),
          //       fechaSubida: DateTime.now(),
          //     ));
          // if (_recentPDFs.length > 5) {
          //   _recentPDFs.removeLast(); // Mantener solo los 5 más recientes
          // }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF generado: ${file.path}')),
        );

        return file.path;
      } finally {
        setState(() => _isGeneratingPDF = false);
      }
    }

    Future<void> _sharePDF() async {
      if (_generatedPDFPath != null) {
        await Share.shareFiles([_generatedPDFPath!], text: 'Aquí está tu PDF');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Primero debes generar el PDF')),
        );
      }
    }

    Future<void> _savePDFToDatabase(String filePath) async {
      final file = File(filePath);
      String base64PDF = base64Encode(file.readAsBytesSync());
      String fileName = basename(filePath);

      try {
        final docuResponse =
            await _httpHelper?.crearDocumento(fileName, base64PDF, _user!.id);
        if (docuResponse != null && docuResponse.documento != null) {
          // setState(() {
          //   _recentPDFs?.insert(0, docuResponse.documento!);
          //   if (_recentPDFs!.length > 5) {
          //     _recentPDFs?.removeLast();
          //   }
          // });

          // // Actualiza la caché
          // SharedPreferences prefs = await SharedPreferences.getInstance();
          // await prefs.setString('cached_docs', jsonEncode(_recentPDFs));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF guardado en la base de datos y caché')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el PDF: $e')),
        );
      }
    }

    // Future<void> _sharePDF(String filePath) async {
    //   await Share.shareFiles([filePath], text: 'Aquí está tu PDF');
    // }

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sube tus imágenes',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Captura o selecciona imágenes importantes.',
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
                    Icon(Icons.add_a_photo, size: 50, color: accentColor),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.camera_alt),
                            label: Text('Tomar Foto'),
                            onPressed: () {
                              _takePicture();
                              // Implementar lógica para tomar foto
                              print('Tomar foto');
                            },
                            style: ElevatedButton.styleFrom(
                              primary: buttonColor,
                              onPrimary: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 10), // Espacio entre botones
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.photo_library, size: 18),
                            label: Text('Seleccionar Imagen',
                                style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              // Implementar lógica para seleccionar imagen
                              print('Seleccionar imagen');
                            },
                            style: ElevatedButton.styleFrom(
                              primary: buttonColor,
                              onPrimary: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              if (_images.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showDescriptionDialog(_images[index]),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _images[index].image,
                                  width: 150,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(height: 5),
                              Container(
                                width: 150,
                                child: Text(
                                  _images[index].description.isNotEmpty
                                      ? _images[index].description
                                      : "Toque la imagen para poner una observación",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _images[index].description.isNotEmpty
                                        ? Colors.black
                                        : Colors.grey,
                                    fontStyle:
                                        _images[index].description.isNotEmpty
                                            ? FontStyle.normal
                                            : FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: 30),
              // Text(
              //   'Subidas Recientes',
              //   style: TextStyle(
              //       fontSize: 20,
              //       fontWeight: FontWeight.bold,
              //       color: primaryColor),
              // ),
              // SizedBox(height: 10),
              // Column(
              //   children: recentUploads
              //       .map((file) => UploadedFileWidget(
              //           file, primaryColor, textColor, accentColor))
              //       .toList(),
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    child: _isGeneratingPDF
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Generar PDF'),
                    onPressed: _isGeneratingPDF
                        ? null
                        : () async {
                            String? filePath = await _generateAndSharePDF();
                            if (filePath != null) {
                              await _savePDFToDatabase(filePath);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      primary: accentColor,
                      onPrimary: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                  if (_generatedPDFPath != null)
                    ElevatedButton(
                      child: Text('Compartir PDF'),
                      onPressed: _sharePDF,
                      style: ElevatedButton.styleFrom(
                        primary: buttonColor,
                        onPrimary: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 30),
              // if (_recentPDFs!.isNotEmpty) ...[
              //   Text(
              //     'PDFs Recientes',
              //     style: TextStyle(
              //       fontSize: 20,
              //       fontWeight: FontWeight.bold,
              //       color: primaryColor,
              //     ),
              //   ),
              //   SizedBox(height: 10),
              //   ListView.builder(
              //     shrinkWrap: true,
              //     physics: NeverScrollableScrollPhysics(),
              //     itemCount: _recentPDFs?.length,
              //     itemBuilder: (context, index) {
              //       final document = _recentPDFs?[index];
              //       return ListTile(
              //         title: Text(document!.titulo),
              //         subtitle: Text(DateFormat('dd/MM/yyyy')
              //             .format(document.fechaSubida)),
              //         leading: Icon(Icons.picture_as_pdf, color: accentColor),
              //         // trailing: document.estadoDocumento != null
              //         //     ? Text(document.estadoDocumento!)
              //         //     : null,
              //         onTap: () {
              //           // Implementar acción para abrir o descargar el PDF
              //           print('Abrir PDF: ${document.titulo}');
              //         },
              //       );
              //     },
              //   ),
              // ] else if (!_isLoading) ...[
              //   Text(
              //     'No hay PDFs recientes',
              //     style: TextStyle(fontSize: 16, color: textColor),
              //   ),
              // ],
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

class ImageWithDescription {
  final File image;
  String description;

  ImageWithDescription(this.image, {this.description = ''});

  void updateDescription(String newDescription) {
    description = newDescription;
  }
}

class RecentPDF {
  final int id;
  final String titulo;
  final String documentoBase64;
  final DateTime fechaSubida;
  final String? estadoDocumento;

  RecentPDF({
    required this.id,
    required this.titulo,
    required this.documentoBase64,
    required this.fechaSubida,
    this.estadoDocumento,
  });
  factory RecentPDF.fromJson(Map<String, dynamic> json) {
    return RecentPDF(
      id: json['id'],
      titulo: json['titulo'],
      documentoBase64: json['documento_base64'],
      fechaSubida: DateTime.parse(json['fecha_subida']),
      estadoDocumento: json['estado_documento'],
    );
  }
}
