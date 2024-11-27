import 'package:dago_application/components/profile.dart';
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

  late PageController _pageController;
  int _currentPage = 0;

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
    _pageController = PageController(
      viewportFraction: 0.85,
    );
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
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPDFs() async {
    if (_user != null && _httpHelper != null) {
      if (mounted) {
        setState(() => _isLoadingPDFs = true);
      }

      try {
        print('Loading PDFs for user ID: ${_user!.id}');
        final recentDocs = await _httpHelper!.getDocumentosByUserId(_user!.id);
        print("recent docs $recentDocs");
        if (mounted) {
          setState(() {
            _recentPDFs = recentDocs;
            // _recentPDFs = recentDocs
            //..sort((a, b) => b.fechaSubida.compareTo(a.fechaSubida));
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
/*   List<Document> _filterOldPDFs(List<Document> pdfs) {
    final now = DateTime.now();
    return pdfs.where((pdf) {
      final difference = now.difference(pdf.fechaSubida);
      return difference.inDays < 15;
    }).toList();
  } */

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0), // Bordes redondeados
            ),
            title: Text(
              image.description.isEmpty
                  ? 'Agregar observación'
                  : 'Editar observación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            content: TextField(
              controller: TextEditingController(text: image.description),
              onChanged: (value) {
                tempDescription = value;
              },
              decoration: InputDecoration(
                hintText: "Ingrese una observación",
                hintStyle:
                    TextStyle(color: Colors.grey[400]), // Color del placeholder
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: Text(
                  'Guardar',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onPressed: () {
                  Navigator.of(context).pop(tempDescription);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor, // Color principal del tema
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
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
      final hasAreaResponse = await _httpHelper?.hasArea(_user!.id);
      if (hasAreaResponse == null || !hasAreaResponse['hasArea']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Por favor, indique su área en tu perfil antes de subir una foto',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16), // Margen alrededor del SnackBar
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Bordes redondeados
            ),
            // action: SnackBarAction(
            //   label: 'Entendido',
            //   textColor: Colors.white, // Color del botón de acción
            //   onPressed: () {
            //     // Lógica que se ejecuta cuando se presiona el botón
            //     // Navigator.push(
            //     //   context,
            //     //   MaterialPageRoute(builder: (context) => ProfilePage()),
            //     // );
            //   },
            // ),
            duration: Duration(seconds: 3),
          ),
        );

        return;
      }

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0), // Bordes redondeados
              ),
              title: Text(
                'Título del PDF',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        title = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Ingrese el título del PDF",
                      hintStyle:
                          TextStyle(color: Colors.grey[400]), // Estilo del hint
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  if (title != null && title!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Por favor, ingrese un título",
                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                ElevatedButton(
                  child: Text(
                    'Guardar',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onPressed: () {
                    if (title == null || title!.isEmpty) {
                      setState(() {
                        title = ""; // Esto activará el mensaje de advertencia
                      });
                    } else {
                      Navigator.of(context).pop(true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor, // Color principal del tema
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  ),
                ),
              ],
            );
          });
        },
      );

      return confirmed == true ? title : null;
    }

    Future<void> _deletePDF(int documentId) async {
      try {
        // Muestra un diálogo de confirmación
        bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirmar eliminación'),
              content:
                  Text('¿Estás seguro de que quieres eliminar este documento?'),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancelar'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text('Eliminar'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        );

        if (confirmDelete == true) {
          try {
            // Llama al endpoint para eliminar el PDF
            await _httpHelper?.deleteDocumentoById(documentId);

            // Si la eliminación fue exitosa, actualiza la lista de PDFs
            setState(() {
              _recentPDFs.removeWhere((pdf) => pdf.id == documentId);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.delete_forever,
                        color: Colors.white), // Ícono de eliminación
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'PDF eliminado con éxito',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors
                    .redAccent, // Color de fondo rojo para indicar eliminación
                behavior:
                    SnackBarBehavior.floating, // Hacer que el SnackBar flote
                margin: EdgeInsets.all(16), // Margen alrededor del SnackBar
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Bordes redondeados
                ),
                duration: Duration(seconds: 3), // Duración de 3 segundos
              ),
            );
          } catch (e) {
            print('Error al eliminar el PDF: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al eliminar el PDF')),
            );
          }
        }
      } catch (e) {
        print('Error al eliminar el PDF: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el PDF')),
        );
      }
    }

    Future<String?> _generateAndSharePDF() async {
      if (!mounted) return null;
      if (_images.isEmpty) {
        _scaffoldKey.currentState?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.photo_library,
                    color: Colors.white), // Ícono representando fotos
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No hay fotos para generar el documento',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors
                .deepOrangeAccent, // Fondo naranja para resaltar la advertencia
            behavior: SnackBarBehavior.floating, // Hacer que el SnackBar flote
            margin: EdgeInsets.all(16), // Margen alrededor del SnackBar
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Bordes redondeados
            ),
            duration: Duration(seconds: 3), // Duración de 3 segundos
          ),
        );
        return null;
      }

      setState(() => _isGeneratingPDF = true);

      try {
        String? pdfTitle = await _getPDFTitle();
        if (pdfTitle == null || pdfTitle.isEmpty) {
          setState(() => _isGeneratingPDF = false);
          return null;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0), // Bordes redondeados
              ),
              content: Padding(
                padding: const EdgeInsets.all(
                    20.0), // Añade padding para espacio extra
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context)
                              .primaryColor), // Color del indicador de progreso
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Generando PDF...",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign:
                          TextAlign.center, // Alinea el texto en el centro
                    ),
                  ],
                ),
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
              margin: pw.EdgeInsets.all(10),
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.SizedBox(
                        width: 500,
                        height: 600,
                        child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        imageWithDesc.description,
                        style: pw.TextStyle(font: font, fontSize: 14),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
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
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.picture_as_pdf,
                    color: Colors.white), // Ícono representando un PDF
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'PDF generado: ${file.path}',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors
                .blueAccent, // Fondo azul para destacar la acción completada
            behavior: SnackBarBehavior.floating, // Hacer que el SnackBar flote
            margin: EdgeInsets.all(16), // Margen alrededor del SnackBar
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Bordes redondeados
            ),
            duration: Duration(seconds: 4), // Duración de 4 segundos
          ),
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

    Widget _buildImageCard(ImageWithDescription imageWithDesc, int index) {
      return AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) {
          double value = 1.0;
          if (_pageController.position.haveDimensions) {
            value = _pageController.page! - index;
            value = (1 - (value.abs() * 0.3)).clamp(0.85, 1.0);
          }
          return Center(
            child: SizedBox(
              height: Curves.easeInOut.transform(value) * 250,
              width: Curves.easeInOut.transform(value) * 350,
              child: child,
            ),
          );
        },
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => _showDescriptionDialog(imageWithDesc),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(15)),
                      child: Image.file(
                        imageWithDesc.image,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        imageWithDesc.description.isNotEmpty
                            ? imageWithDesc.description
                            : "Toque para añadir observación",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: imageWithDesc.description.isNotEmpty
                              ? Colors.black
                              : Colors.grey,
                          fontStyle: imageWithDesc.description.isNotEmpty
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
        ),
      );
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
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.picture_as_pdf,
                    color: Colors.white), // Ícono representando un PDF
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Primero debes generar el PDF',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors
                .blueAccent, // Fondo azul para destacar la acción pendiente
            behavior: SnackBarBehavior.floating, // Hacer que el SnackBar flote
            margin: EdgeInsets.all(16), // Margen alrededor del SnackBar
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Bordes redondeados
            ),
            duration: Duration(seconds: 3), // Duración de 3 segundos
          ),
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
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.save_alt,
                    color: Colors.white), // Ícono representando guardar
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'PDF guardado en la base de datos y caché',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green, // Fondo verde para indicar éxito
            behavior: SnackBarBehavior.floating, // Hacer que el SnackBar flote
            margin: EdgeInsets.all(16), // Margen alrededor del SnackBar
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Bordes redondeados
            ),
            duration: Duration(seconds: 3), // Duración de 3 segundos
          ),
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

    String _truncateText(String text, int maxLength) {
      if (text.length <= maxLength) return text;
      return text.substring(0, maxLength - 3) + '...';
    }

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        backgroundColor:
            Colors.white, // Fondo blanco para una apariencia limpia
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
                  'Genera Incidencias',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily:
                        'Montserrat', // Usar una fuente moderna y estilizada
                  ),
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
                      Text(
                        'Toma o sube una foto',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          fontFamily:
                              'Montserrat', // Usar una fuente moderna y estilizada
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.camera),
                              label: Text('Tomar Foto',
                                  style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                _takePicture(ImageSource.camera);
                                // Implementar lógica para tomar foto
                                print('Tomar foto');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor:
                                    const Color.fromARGB(255, 49, 47, 47),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                              ),
                            ),
                          ),
                          SizedBox(width: 5), // Espacio entre botones
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.photo_library, size: 18),
                              label: Text('Seleccionar',
                                  style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                _takePicture(ImageSource.gallery);
                                // Implementar lógica para seleccionar imagen
                                print('Seleccionar imagen');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor:
                                    const Color.fromARGB(255, 49, 47, 47),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
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
                  Column(
                    children: [
                      Container(
                        height:
                            280, // Increased height to accommodate for scaling
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _images.length,
                          onPageChanged: (int page) {
                            setState(() {
                              _currentPage = page;
                            });
                          },
                          itemBuilder: (context, index) {
                            return _buildImageCard(_images[index], index);
                          },
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _images.length,
                          (index) => Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? accentColor
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                      child: Text('Generar PDF'),
                      onPressed: _isGeneratingPDF
                          ? null
                          : () async {
                              String? filePath = await _generateAndSharePDF();
                              if (filePath != null) {
                                await _savePDFToDatabase(filePath);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: const Color.fromARGB(255, 49, 47, 47),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    if (_generatedPDFPath != null)
                      ElevatedButton(
                        child: Text(_lastGeneratedPDFName != null
                            ? 'Compartir PDF: ${_truncateText(_lastGeneratedPDFName!, 10)}'
                            : 'Compartir PDF'),
                        onPressed: _sharePDF,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor:
                              const Color.fromARGB(255, 49, 47, 47),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
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
                          'Tus documentos',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                            fontFamily:
                                'Montserrat', // Usar una fuente moderna y estilizada
                          ),
                        ),
                        InkWell(
                          onTap: _loadPDFs,
                          child: Row(
                            children: [
                              Icon(
                                Icons.refresh,
                                color: Colors.black87,
                              ),
                              SizedBox(width: 4),
                              /* Text(
                                'Recargar PDFs',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontFamily:
                                      'Montserrat', // Usar una fuente moderna y estilizada
                                ),
                              ), */
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    /* Text(
                      'Los PDFs se eliminarán automáticamente de esta lista 15 días después de ser agregados',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: textColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ), */
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
                        height: MediaQuery.of(context).size.height *
                            0.42, // Ajusta esta altura según tus necesidades
                        child: ListView.builder(
                          itemCount: _recentPDFs.length,
                          itemBuilder: (context, index) {
                            final document = _recentPDFs[index];
                            return Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 10),
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
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                title: Text(
                                  _truncateText(
                                      document.titulo.split(".").first,
                                      20), // Trunca el texto si es necesario
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  document.fechaSubida,
                                  style: TextStyle(
                                    color: Colors.black54,
                                  ),
                                ),
                                leading: Icon(
                                  Icons.picture_as_pdf,
                                  color: accentColor,
                                  size: 30,
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deletePDF(document.id),
                                ),
                                onTap: () {
                                  print('Abrir PDF: ${document.titulo}');
                                  // Implementa la lógica para abrir el PDF
                                },
                              ),
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
