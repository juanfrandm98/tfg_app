import 'package:flutter/material.dart';

class UserData {
  String id;
  String message = "";
  String name = "";
  String surname = "";
  String birthday = "";
  String gender = "";
  String country = "";

  UserData({
    @required this.message,
    this.name,
    this.surname,
    this.birthday,
    this.gender,
    this.country,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      message: json['message'],
      name: json['name'],
      surname: json['surname'],
      birthday: json['birthday'],
      gender: json['gender'],
      country: json['country'],
    );
  }

  void setId(String iden) {
    id = iden;
  }

  Map toJson() {
    return {
      "id": id,
      "name": name,
      "surname": surname,
      "birthday": birthday,
      "gender": gender,
      "country": country,
    };
  }

  void parseGenderToSpanish() {
    switch (gender) {
      case "male":
        {
          gender = "Hombre";
        }
        break;

      case "female":
        {
          gender = "Mujer";
        }
        break;

      case "other":
        {
          gender = "Otro";
        }
        break;
    }
  }

  void parseGenderToEnglish() {
    switch (gender) {
      case "Hombre":
        {
          gender = "male";
        }
        break;

      case "Mujer":
        {
          gender = "female";
        }
        break;

      case "Otro":
        {
          gender = "other";
        }
        break;
    }
  }

  void castBirthday() {
    if( birthday != null) {
      List<String> fechaDescompuesta = birthday.split(" ");
      birthday = fechaDescompuesta[0];
    }
  }
}
