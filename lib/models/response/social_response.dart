import 'package:dago_application/models/social.dart';

class SocialResponse {
  final int status;
  final Social? social; // Make user nullable by adding a question mark (?)
  final String message;

  SocialResponse({
    required this.status,
    this.social, // Update the parameter to be nullable
    required this.message,
  });

  SocialResponse.fromJson(Map<String, dynamic> json)
      : status = json['status'],
        social = json['social'] != null
            ? Social.fromJson(json['social'])
            : null, // Check if json['social'] is not null before parsing
        message = json['message'];
}
