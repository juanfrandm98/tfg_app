import 'dart:convert';
import 'package:empatimetro/defaultWidgets.dart';
import 'package:empatimetro/home_page.dart';
import 'package:empatimetro/session/register_page.dart';
import 'package:empatimetro/session/session_classes.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  @override
  LoginPageView createState() {
    return LoginPageView();
  }
}

class LoginPageView extends State<LoginPage> {
  // These are used to control the username and password's texts.
  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();

  // Paths to communicate with server.
  final String _serverDir = 'bioinformatica.ugr.es';
  final String _loginPath = '/empathos/loginUser';

  // Bad Form message.
  final String _badForm =
      "Por favor, rellene todos los campos antes de continuar.";

  /*
   * Function that destroys the state, destroying the controllers too.
   */
  @override
  void dispose() {
    _emailTextController.dispose();
    _passwordTextController.dispose();
    super.dispose();
  }

  /*
   * Function that checks if the form is fully filled.
   * @returns true if email and password's text boxes are filled or false if any
   *          is empty.
   */
  bool _checkForm() {
    FocusScope.of(context).unfocus();

    if (_emailTextController.text.isNotEmpty &&
        _passwordTextController.text.isNotEmpty)
      return true;
    else
      return false;
  }

  /*
   * Function that shows a certain warning to the user.
   * @param text: warning text.
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
   * Function that sends the login message to the server. It creates the propper
   * message with the user's email and password.
   * @return response: Server's response.
   */
  Future<http.Response> _sendLogin() async {
    Map params = {
      "email": _emailTextController.text,
      "password": _passwordTextController.text,
    };

    Map<String, String> qParams = {
      "json": jsonEncode(params),
    };

    Uri uri = Uri.https(_serverDir, _loginPath, qParams);
    http.Response response = await http.get(uri);

    return response;
  }

  /*
   * Function that prepares to send the login message to the server if the form
   * is OK and reacts to its answer.
   */
  void _LoginButton() async {
    if (_checkForm()) {
      http.Response response = await _sendLogin();
      UserResponse userResponse =
          new UserResponse.fromJson(jsonDecode(response.body));

      if (response.statusCode == 200) {
        userResponse.setPreferences();
        _goToHomePage();
      } else
        _showWarning(userResponse.message);
    } else
      _showWarning(_badForm);
  }

  /*
   * Function that goes to the Register Page.
   */
  void _goToRegister() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => RegisterPage()));
  }

  /*
   * Function that goes to the Home Page.
   */
  void _goToHomePage() {
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
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 3,
                        child: new LayoutBuilder(builder: (context, constraint) {
                          return new Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: constraint.biggest.height,
                          );
                        }),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
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
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: TextButton(
                          onPressed: () => _goToRegister(),
                          child: Text(
                            "¿No estás registrad@? Pulse aquí.",
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 30),
                        child: DefButton("Login", _LoginButton),),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
