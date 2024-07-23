
import 'package:dago_application/models/document.dart';

class DocuResponse {
  final int status;
  final Document? documento; // Make user nullable by adding a question mark (?)
  final String message;

  DocuResponse({
    required this.status,
    required this.documento, // Update the parameter to be nullable
    required this.message,
  });

  DocuResponse.fromJson(Map<String, dynamic> json)
      : status = json['status'],
        documento = json['documento'] != null
            ? Document.fromJson(json['documento'])
            : null, // Check if json['user'] is not null before parsing
        message = json['message'];
}
