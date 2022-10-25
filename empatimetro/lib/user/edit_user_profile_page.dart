import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../defaultWidgets.dart';
import 'user_data.dart';
import 'user_profile_page.dart';
import 'package:http/http.dart' as http;

class EditUserProfilePage extends StatefulWidget {
  final UserData _userData;

  EditUserProfilePage(this._userData);

  @override
  State<StatefulWidget> createState() {
    return EditUserProfilePageView(this._userData);
  }
}

class EditUserProfilePageView extends State<EditUserProfilePage> {
  UserData _userData;

  final _nameTextController = TextEditingController();
  final _surnameTextController = TextEditingController();
  final _countryTextController = TextEditingController();

  DateTime _selectedDate;
  String _selectedGender = "Hombre";

  final String _serverDir = 'bioinformatica.ugr.es';
  final String _setUserDataPath = '/empathos/setUserData';

  EditUserProfilePageView(this._userData);

  @override
  void initState() {
    super.initState();
    if (_userData.name != null) _nameTextController.text = _userData.name;
    if (_userData.surname != null)
      _surnameTextController.text = _userData.surname;
    if (_userData.country != null)
      _countryTextController.text = _userData.country;
    if (_userData.gender != null) _selectedGender = _userData.gender;
    if (_userData.birthday != null)
      _selectedDate = DateTime.parse(_userData.birthday);
  }

  @override
  void dispose() {
    _nameTextController.dispose();
    _surnameTextController.dispose();
    _countryTextController.dispose();
    super.dispose();
  }

  void _goToProfile() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => UserProfilePage()));
  }

  void _updateUserData() {
    if(_nameTextController.text != null) _userData.name = _nameTextController.text; else _userData.name = null;
    if(_surnameTextController.text != null) _userData.surname = _surnameTextController.text; else _userData.surname = null;
    if(_countryTextController.text != null) _userData.country = _countryTextController.text; else _userData.country = null;
    _userData.gender = _selectedGender;
    _userData.parseGenderToEnglish();
    _userData.birthday = _parseSelectedDate();
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

  Future<http.Response> _sendUserDataToServer() async {
    Map<String, String> qParams = {
      "json": jsonEncode(_userData),
    };

    Uri uri = Uri.https(_serverDir, _setUserDataPath, qParams);
    http.Response response = await http.get(uri);
    return response;
  }

  void _sendUserData() {
    _sendUserDataToServer().then((http.Response response) {
      if (response.statusCode == 200) {
        _showWarning(response.body, _goToProfile);
      } else {
        print("ERROR #" + response.statusCode.toString() + ":\n" + response.body);
        _showWarning("Error #" + response.statusCode.toString(),
            () => Navigator.of(context).pop());
      }
    });
  }

  void _saveButton() {
    _updateUserData();
    _sendUserData();
  }

  void _deleteDateButton() {
    setState(() {
      _selectedDate = null;
    });
  }

  void _selectDate() async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
      });
  }

  String _parseSelectedDate() {
    if (_selectedDate != null) {
      String day = _selectedDate.day.toString();
      if (day.length < 2) day = "0" + day;

      String month = _selectedDate.month.toString();
      if (month.length < 2) month = "0" + month;

      String year = _selectedDate.year.toString();

      return "$year-$month-$day";
    } else {
      return "";
    }
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
                  child: PageTitle("Editar perfil"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: TextField(
                    controller: _nameTextController,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Nombre",
                        hintText: "Inserte su nombre"),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: TextField(
                    controller: _surnameTextController,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Apellidos",
                        hintText: "Inserte sus apellidos"),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: TextField(
                    controller: _countryTextController,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "País",
                        hintText: "Inserte su país natal"),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: <Widget>[
                      Text(
                        "Género",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 25,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedGender,
                        onChanged: (String newValue) {
                          setState(() {
                            _selectedGender = newValue;
                          });
                        },
                        items: <String>["Hombre", "Mujer", "Otro"]
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: <Widget>[
                      Text(
                        "Fecha de nacimiento",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 25,
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: 2,
                            child: DefButton("Selec.", _selectDate),
                          ),
                          Expanded(
                            flex: 3,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                              height: 35,
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: _selectedDate != null
                                  ? Text(_parseSelectedDate())
                                  : Text(""),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.red,
                              ),
                              child: IconButton(
                                onPressed: _deleteDateButton,
                                icon: Icon(Icons.delete),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 30, horizontal: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      DefButton("Guardar cambios", _saveButton),
                      DefButton("Cancelar", _goToProfile),
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
