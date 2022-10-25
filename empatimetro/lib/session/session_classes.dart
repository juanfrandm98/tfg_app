import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterData {
  String _email;
  String _password;

  RegisterData(this._email, this._password);

  Map toJson() {
    return {
      "email": _email,
      "password": _password,
    };
  }
}

class UserResponse {
  final String message;
  final String email;
  final String id;

  UserResponse({@required this.message, this.email, this.id});

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
        message: json['message'],
        email: json['email'],
        id: json['id'].toString(),
    );
  }

  Future setPreferences() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setString("email", email);
    preferences.setString("userID", id);
  }
}
