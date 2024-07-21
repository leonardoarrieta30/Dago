import 'package:dago_application/models/social.dart';

class SocialResponse {
  final int status;
  final List<Social>? socialNetworks;
  final String message;

  SocialResponse({
    required this.status,
    this.socialNetworks, // Update the parameter to be nullable
    required this.message,
  });

  SocialResponse.fromJson(Map<String, dynamic> json)
      : status = json['status'],
        socialNetworks = (json['socials'] as List<dynamic>?)
            ?.map((e) => Social.fromJson(e))
            .toList(),
        message = json['message'];
}
