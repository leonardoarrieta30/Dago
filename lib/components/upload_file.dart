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
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

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

  List<Document> _recentPDFs = [];
  bool _isLoadingPDFs = false;
  String? _lastGeneratedPDFName;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPDFs();
    });
  }

  // Future<void> _clearCache() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('cached_docs');
  // }

  @override
  void dispose() {
    _lastGeneratedPDFName =
        null; // Resetea el nombre del PDF al salir del componente
    super.dispose();
  }

  Future<void> _loadPDFs() async {
    if (_user != null && _httpHelper != null) {
      setState(() => _isLoadingPDFs = true);
      try {
        print('Loading PDFs for user ID: ${_user!.id}');
        final recentDocs = await _httpHelper!.getDocumentosByUserId(_user!.id);
        if (mounted) {
          setState(() {
            _recentPDFs = _filterOldPDFs(recentDocs)
              // _recentPDFs = recentDocs
              ..sort((a, b) => b.fechaSubida.compareTo(a.fechaSubida));
            _isLoadingPDFs = false;
          });
        }
        print('Loaded ${_recentPDFs.length} PDFs from API');
      } catch (e) {
        print('Error al cargar PDFs recientes: $e');
        if (mounted) {
          setState(() => _isLoadingPDFs = false);
        }
      }
    } else {
      print(
          'User or httpHelper is null. User: $_user, HttpHelper: $_httpHelper');
    }
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPDFs();
    });

    if (mounted) {
      // Verificar nuevamente si el widget está montado antes de llamar a setState
      setState(() => _isLoading = false);
    }
  }

  //esta para un dia veremos mañana
  List<Document> _filterOldPDFs(List<Document> pdfs) {
    final now = DateTime.now();
    return pdfs.where((pdf) {
      final difference = now.difference(pdf.fechaSubida);
      return difference.inDays < 15;
    }).toList();
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

    Future<void> _takePicture(ImageSource source) async {
      final ImagePicker _picker = ImagePicker();
      final XFile? photo = await _picker.pickImage(source: source);

      if (photo != null) {
        final newImage = ImageWithDescription(File(photo.path));
        await _showDescriptionDialog(newImage);

        setState(() {
          _images.add(newImage);
          _lastGeneratedPDFName = null;
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
      bool? confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible:
            false, // Previene cerrar el diálogo tocando fuera de él
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text('Título del PDF'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        title = value;
                      });
                    },
                    decoration:
                        InputDecoration(hintText: "Ingrese el título del PDF"),
                  ),
                  if (title != null && title!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Por favor, ingrese un título",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text('Guardar'),
                  onPressed: () {
                    if (title == null || title!.isEmpty) {
                      setState(() {
                        title = ""; // Esto activará el mensaje de advertencia
                      });
                    } else {
                      Navigator.of(context).pop(true);
                    }
                  },
                ),
              ],
            );
          });
        },
      );

      return confirmed == true ? title : null;
    }

    Future<String?> _generateAndSharePDF() async {
      if (!mounted) return null; // Verifica si el widget aún está montado
      if (_images.isEmpty) {
        _scaffoldKey.currentState?.showSnackBar(
          // Usa _scaffoldKey en lugar de ScaffoldMessenger.of(context)
          SnackBar(content: Text('No hay fotos para generar el PDF')),
        );
        return null;
      }
      if (!mounted)
        return null; // Verifica nuevamente después de mostrar el SnackBar
      setState(() => _isGeneratingPDF = true);

      try {
        String? pdfTitle = await _getPDFTitle();
        if (pdfTitle == null || pdfTitle.isEmpty) {
          setState(() => _isGeneratingPDF = false);
          return null; // El usuario canceló la operación o no ingresó un título
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Generando PDF..."),
                ],
              ),
            );
          },
        );

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
        if (mounted) {
          setState(() {
            _generatedPDFPath = file.path;
            _lastGeneratedPDFName = pdfTitle;
            _images.clear();
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
        }
        Navigator.of(context).pop();
        _scaffoldKey.currentState?.showSnackBar(
          // Usa _scaffoldKey
          SnackBar(content: Text('PDF generado: ${file.path}')),
        );

        return file.path;
      } catch (e) {
        Navigator.of(context).pop();
        _scaffoldKey.currentState?.showSnackBar(
          // Usa _scaffoldKey
          SnackBar(content: Text('Error al generar el PDF: $e')),
        );
        return null;
      } finally {
        if (mounted) {
          // Verifica si el widget aún está montado antes de llamar a setState
          setState(() => _isGeneratingPDF = false);
        }
      }
    }

    void _deleteImage(int index) {
      setState(() {
        _images.removeAt(index);
      });
    }

    Future<void> _sharePDF() async {
      if (_generatedPDFPath != null) {
        await Share.shareFiles([_generatedPDFPath!], text: 'Aquí está tu PDF');
        // setState(() {
        //   _lastGeneratedPDFName =
        //       null; // Resetea el nombre después de compartir
        // });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Primero debes generar el PDF')),
        );
      }
    }

    Future<void> _savePDFToDatabase(String filePath) async {
      if (!mounted) return; // Añade esta línea
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
        _scaffoldKey.currentState?.showSnackBar(
          SnackBar(content: Text('PDF guardado en la base de datos y caché')),
        );
      } catch (e) {
        _scaffoldKey.currentState?.showSnackBar(
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
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
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
                // SizedBox(height: 10),
                // Text(
                //   'Captura o selecciona imágenes importantes.',
                //   style: TextStyle(fontSize: 16, color: textColor),
                //   textAlign: TextAlign.center,
                // ),
                SizedBox(height: 20),
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
                                _takePicture(ImageSource.camera);
                                // Implementar lógica para tomar foto
                                print('Tomar foto');
                              },
                              style: ElevatedButton.styleFrom(
                                //primary: buttonColor,
                                // onPrimary: Colors.white,
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
                                _takePicture(ImageSource.gallery);
                                // Implementar lógica para seleccionar imagen
                                print('Seleccionar imagen');
                              },
                              style: ElevatedButton.styleFrom(
                                //primary: buttonColor,
                                //onPrimary: Colors.white,
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
                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  _showDescriptionDialog(_images[index]),
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
                                          color: _images[index]
                                                  .description
                                                  .isNotEmpty
                                              ? Colors.black
                                              : Colors.grey,
                                          fontStyle: _images[index]
                                                  .description
                                                  .isNotEmpty
                                              ? FontStyle.normal
                                              : FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: GestureDetector(
                                onTap: () => _deleteImage(index),
                                child: Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                        //primary: accentColor,
                        //onPrimary: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    if (_generatedPDFPath != null)
                      ElevatedButton(
                        child: Text(_lastGeneratedPDFName != null
                            ? 'Compartir PDF: $_lastGeneratedPDFName'
                            : 'Compartir PDF'),
                        onPressed: _sharePDF,
                        style: ElevatedButton.styleFrom(
                          //primary: buttonColor,
                          //onPrimary: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PDFs Recientes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        InkWell(
                          onTap: _loadPDFs,
                          child: Row(
                            children: [
                              Icon(Icons.refresh, color: secondaryTextColor),
                              SizedBox(width: 4),
                              Text(
                                'Recargar PDFs',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Los PDFs se eliminarán automáticamente de esta lista 15 días después de ser agregados',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: textColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 10),
                    if (_isLoadingPDFs)
                      Center(child: CircularProgressIndicator())
                    else if (_recentPDFs.isEmpty)
                      Text(
                        'No hay PDFs recientes',
                        style: TextStyle(fontSize: 16, color: textColor),
                      )
                    else
                      Container(
                        height: 250, // Ajusta esta altura según tus necesidades
                        child: ListView.builder(
                          itemCount: _recentPDFs.length,
                          itemBuilder: (context, index) {
                            final document = _recentPDFs[index];
                            return ListTile(
                              title: Text(document.titulo),
                              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm')
                                  .format(document.fechaSubida)),
                              leading: Icon(Icons.picture_as_pdf,
                                  color: accentColor),
                              onTap: () {
                                print('Abrir PDF: ${document.titulo}');
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
                // SizedBox(height: 20), // Añade espacio antes del botón
                // Padding(
                //   padding: EdgeInsets.symmetric(
                //       horizontal: 20), // Añade padding horizontal
                //   child: ElevatedButton(
                //     child: Text('Recargar PDFs'),
                //     onPressed: _loadPDFs,
                //     style: ElevatedButton.styleFrom(
                //       primary: secondaryTextColor,
                //       onPrimary: Colors.white,
                //       padding: EdgeInsets.symmetric(vertical: 12),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(10),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
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
