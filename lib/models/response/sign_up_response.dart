import 'package:dago_application/models/person.dart';

class SignUpResponse {
  final int status;
  final Person? persona; // Make user nullable by adding a question mark (?)
  final String message;

  SignUpResponse({
    required this.status,
    required this.persona, // Update the parameter to be nullable
    required this.message,
  });

  SignUpResponse.fromJson(Map<String, dynamic> json)
      : status = json['status'],
        persona = json['persona'] != null
            ? Person.fromJson(json['persona'])
            : null, // Check if json['user'] is not null before parsing
        message = json['message'];
}
