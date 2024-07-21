import 'package:dago_application/models/user.dart';

class LoginResponse {
  final int status;
  final User? user; // Make user nullable by adding a question mark (?)
  final String message;

  LoginResponse({
    required this.status,
    this.user, // Update the parameter to be nullable
    required this.message,
  });

  LoginResponse.fromJson(Map<String, dynamic> json)
      : status = json['status'],
        user = json['user'] != null
            ? User.fromJson(json['user'])
            : null, // Check if json['user'] is not null before parsing
        message = json['message'];
}
