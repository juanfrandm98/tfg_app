import 'dart:convert';

import 'package:empatimetro/defaultWidgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'user_profile_page.dart';

class ChangePasswordPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ChangePasswordPageView();
  }
}

class ChangePasswordPageView extends State<ChangePasswordPage> {
  final _oldPasswordTextController = TextEditingController();
  final _newPasswordTextController = TextEditingController();
  final _newPasswordConfirmTextController = TextEditingController();
  String _userID;

  final Map<String, String> _messages = {
    "badForm": "Por favor, rellene todos los campos antes de continuar.",
    "badPass": "La contraseña y su confirmación deben coincidir.",
  };

  final String _serverDir = 'bioinformatica.ugr.es';
  final String _changePasswordPath = '/empathos/changePassword';

  void _initSessionParams() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String userID = preferences.getString("userID");
    setState(() {
      _userID = userID;
    });
  }

  @override
  void initState() {
    super.initState();
    _initSessionParams();
  }

  bool _checkForm() {
    return _oldPasswordTextController.text.isNotEmpty &&
        _newPasswordTextController.text.isNotEmpty &&
        _newPasswordConfirmTextController.text.isNotEmpty;
  }

  bool _checkConfirm() {
    return _newPasswordTextController.text == _newPasswordConfirmTextController.text;
  }

  Future<http.Response> _sendNewPasswordToServer() async {
    final Map json = {
      "id": _userID,
      "actualPassword": _oldPasswordTextController.text,
      "newPassword": _newPasswordTextController.text,
    };

    final Map<String, String> qParams = {"json": jsonEncode(json)};

    final Uri uri = Uri.https(_serverDir, _changePasswordPath, qParams);
    http.Response response = await http.get(uri);

    return response;
  }

  void _sendNewPassword() {
    _sendNewPasswordToServer().then((http.Response response) {
      if(response.statusCode == 200) {
        _showWarning(response.body, _goToProfile);
      } else {
        _showWarning(response.body, () => Navigator.of(context).pop());
      }
    });
  }

  void _saveButton() {
    FocusScope.of(context).unfocus();
    if (_checkForm()) {
      if(_checkConfirm()) {
        _sendNewPassword();
      } else {
        _showWarning(_messages["badPass"], () => Navigator.of(context).pop());
      }
    } else {
      _showWarning(_messages["badForm"], () => Navigator.of(context).pop());
    }
  }

  void _goToProfile() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => UserProfilePage()));
  }

  /*
   * Displays a message on the screen.
   * @param text: text to show.
   * @param action: Function which will be done when the AlertDialog button is
   *                pressed.
   * @return showDialog: message displayed.
   */
  Future<void> _showWarning(String text, Function action) async {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(text),
            actions: <Widget>[
              TextButton(
                child: Text("Entendido"),
                onPressed: () => action(),
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(238, 238, 238, 1),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: PageTitle("Cambiar contraseña"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: TextField(
                    controller: _oldPasswordTextController,
                    obscureText: true,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Contraseña actual",
                        hintText: "Introduzca su contraseña"),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: TextField(
                    controller: _newPasswordTextController,
                    obscureText: true,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Contraseña nueva",
                        hintText: "Introduzca su nueva contraseña"),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: TextField(
                    controller: _newPasswordConfirmTextController,
                    obscureText: true,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Confirme su nueva contraseña",
                        hintText: "Vuelva a introducir su nueva contraseña"),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 30, horizontal: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      DefButton("Guardar Cambios", _saveButton),
                      DefButton("Cancelar", _goToProfile),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
