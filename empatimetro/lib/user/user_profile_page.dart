import 'dart:convert';

import 'package:empatimetro/user/change_password_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../defaultWidgets.dart';
import '../home_page.dart';
import 'edit_user_profile_page.dart';
import 'user_data.dart';

class UserDataElement extends StatelessWidget {
  String _title;
  String _value;

  UserDataElement(this._title, this._value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                _value != null ? _value : "Desconocido",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserProfilePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return UserProfilePageView();
  }
}

class UserProfilePageView extends State<UserProfilePage> {
  UserData _userData;
  String _titleText = "";
  String _userID = "";
  Widget _dataList = Center(
    child: CircularProgressIndicator(),
  );

  final String _serverDir = 'bioinformatica.ugr.es';
  final String _getUserDataPath = '/empathos/getUserData';

  @override
  void initState() {
    super.initState();
    initSessionParams();
    _getUserData();
  }

  void initSessionParams() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String email = preferences.getString("email");
    String userID = preferences.getString("userID");
    List<String> emailDescompuesto = email.split("@");
    setState(() {
      _titleText = "Perfil de " + emailDescompuesto[0];
      _titleText = "Perfil de " + emailDescompuesto[0];
      _userID = userID;
    });
  }

  Widget _buildDataList() {
    return Column(
      children: <Widget>[
        UserDataElement("Nombre", _userData.name),
        UserDataElement("Apellidos", _userData.surname),
        UserDataElement("País", _userData.country),
        UserDataElement("Género", _userData.gender),
        UserDataElement("Fecha de nacimiento", _userData.birthday),
      ],
    );
  }

  /*
   * Converts a formatted String into UserData.
   * @param body: String with user data in json.
   */
  void _buildUserData(String body) {
    var userData = jsonDecode(body);
    setState(() {
      _userData = new UserData.fromJson(userData);
      _userData.setId(_userID);
      _userData.parseGenderToSpanish();
      _userData.castBirthday();
      _dataList = _buildDataList();
    });
    print(jsonEncode(_userData));
  }

  /*
   * Gets the current User Data from Server.
   * @returns response: response got from Server.
   */
  Future<http.Response> _getUserDataFromServer() async {
    await Future.delayed(Duration(milliseconds: 100));
    Map params = {
      "id": _userID,
    };

    Map<String, String> qParams = {
      "json": jsonEncode(params),
    };

    Uri uri = Uri.https(_serverDir, _getUserDataPath, qParams);
    http.Response response = await http.get(uri);
    return response;
  }

  /*
   * Fetches the User Data from the Server. If the response is OK, shows the
   * data.
   */
  void _getUserData() {
    _getUserDataFromServer().then((http.Response response) {
      if (response.statusCode == 200) {
        _buildUserData(response.body);
      } else {
        _showWarning("Error #" + response.statusCode.toString(), _goBack);
      }
    });
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

  /*
   * Function called when the "Back" button is pressed. It returns to the Home
   * Page.
   */
  void _goBack() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => HomePage()));
  }

  void _goToEditUserProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditUserProfilePage(_userData)));
  }

  void _goToChangePassword() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => ChangePasswordPage()));
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
                  child: PageTitle(_titleText),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                  child: _dataList,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 30, horizontal: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      DefButton("Editar Perfil", _goToEditUserProfile),
                      DefButton("Cambiar contraseña", _goToChangePassword),
                      DefButton("Atrás", _goBack),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
