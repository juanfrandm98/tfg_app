import 'dart:convert';

import 'package:empatimetro/defaultWidgets.dart';
import 'package:empatimetro/home_page.dart';
import 'package:empatimetro/session/session_classes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  RegisterPageView createState() {
    return RegisterPageView();
  }
}

class RegisterPageView extends State<RegisterPage> {
  // All Text Fields Controllers.
  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();
  final _passwordConfirmTextController = TextEditingController();

  // All the warning messages
  final Map<String, String> _messages = {
    "badForm": "Por favor, rellene todos los campos antes de continuar.",
    "badPass": "La contraseña y su confirmación deben coincidir.",
  };

  // Server paths
  final String _serverDir = 'bioinformatica.ugr.es';
  final String _registerPath = '/empathos/registerUser';

  /*
   * Function that destroys the state, including the text controllers.
   */
  @override
  void dispose() {
    _emailTextController.dispose();
    _passwordTextController.dispose();
    _passwordConfirmTextController.dispose();
    super.dispose();
  }

  /*
   * Function that checks if the form is properly filled.
   * @returns true if email, password and password confirm are filled, false in
   *          other case.
   */
  bool _checkForm() {
    FocusScope.of(context).unfocus();

    if (_emailTextController.text.isNotEmpty &&
        _passwordTextController.text.isNotEmpty &&
        _passwordConfirmTextController.text.isNotEmpty) {
      return true;
    }

    return false;
  }

  /*
   * Function that checks if both password inputs are the same.
   * @returns true if the passwords are the same, false in other case.
   */
  bool _checkPassword() {
    if (_passwordTextController.text == _passwordConfirmTextController.text)
      return true;
    else
      return false;
  }

  /*
   * Function that shows a warning to the user.
   * @param text: Warning text.
   */
  Future<void> _showWarning(String text) async {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(text),
            actions: <Widget>[
              TextButton(
                child: Text("Entendido"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  /*
   * Function that shows the server response.
   * @param message: server response's body.
   * @param statusCode: server response's status code.
   */
  Future<void> _showServerResponse(String message, int statusCode) async {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(message),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: statusCode == 200
                    ? () => _finishRegister()
                    : () => Navigator.of(context).pop(),
              )
            ],
          );
        });
  }

  /*
   * Function called when the 'Register' button is pressed. It checks the form
   * and the passwords, sends a message to the server and acts according to its
   * response.
   */
  void _RegisterButton() async {
    if (_checkForm()) {
      if (_checkPassword()) {
        RegisterData registerData = _createRegisterData();
        print(jsonEncode(registerData));
        http.Response response = await _sendRegisterData(registerData);
        print(response.body);

        UserResponse userResponse =
            new UserResponse.fromJson(jsonDecode(response.body));

        if (response.statusCode == 200) userResponse.setPreferences();

        _showServerResponse(userResponse.message, response.statusCode);
      } else {
        _showWarning(_messages["badPass"]);
      }
    } else {
      _showWarning(_messages["badForm"]);
    }
  }

  /*
   * Function that creates the register data using the form input.
   * @return new RegisterData.
   */
  RegisterData _createRegisterData() {
    return new RegisterData(
      _emailTextController.text,
      _passwordTextController.text,
    );
  }

  /*
   * Function that sends the Register Data to the server.
   * @param data: prepared register data.
   * @return response: Server response.
   */
  Future<http.Response> _sendRegisterData(RegisterData data) async {
    final Map<String, String> qParams = {"json": jsonEncode(data)};

    final Uri uri = Uri.https(_serverDir, _registerPath, qParams);
    http.Response response = await http.get(uri);

    return response;
  }

  /*
   * Function that goes to the Login Page.
   */
  void _goToLogin() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  /*
   * Function that goes to the Home Page.
   */
  void _finishRegister() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => HomePage()));
  }

  /*
   * Function that builds the layout.
   */
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Color.fromRGBO(238, 238, 238, 1),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 30),
                    child: Text(
                      "Proyecto Empatímetro",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: TextField(
                      controller: _emailTextController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Email",
                          hintText: "Inserte su email"),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: TextField(
                      controller: _passwordTextController,
                      obscureText: true,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Contraseña",
                          hintText: "Inserte su contraseña"),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: TextField(
                      controller: _passwordConfirmTextController,
                      obscureText: true,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Confirme su contraseña",
                          hintText: "Vuelva a introducir su contraseña"),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: TextButton(
                      onPressed: () => _goToLogin(),
                      child: Text(
                        "¿Ya está registrad@? Pulse aquí.",
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: DefButton("Registro", _RegisterButton)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
