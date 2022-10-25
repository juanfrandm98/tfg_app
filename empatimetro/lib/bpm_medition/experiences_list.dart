import 'dart:convert';

import 'package:flutter/cupertino.dart';

import 'experience.dart';
import '../defaultWidgets.dart';
import 'package:flutter/material.dart';
import '../home_page.dart';
import 'package:http/http.dart' as http;

class ExperiencesList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ExperiencesListView();
  }
}

class ExperiencesListView extends State<ExperiencesList> {
  List<Experience> _experiences = [];
  Widget _listWidget = Center(
    child: CircularProgressIndicator(),
  );

  final String _serverDir = 'bioinformatica.ugr.es';
  final String _getListPath = '/empathos/getTestsList';

  final Map<String, String> _messages = {
    "topMessage":
        "Si es la primera vez que utiliza la aplicación, le recomendamos encarecidamente que lleve a cabo la experiencia de prueba antes que ninguna otra para familiarizarse con su metodología. ¡Gracias!",
  };

  /*
   * It is called when the object's state is created. Initialize some values. In
   * the future, it will ask the server to create the proper Experiences List.
   */
  @override
  void initState() {
    super.initState();
    _getExperiences();
  }

  /*
   * Converts a formatted String into Experiences, and add them to _experiences.
   * @param body: String with experiences in json.
   */
  void _buildExperiences(String body) {
    var experiences = jsonDecode(body);
    for (var exp in experiences) _experiences.add(Experience.fromJson(exp));
  }

  /*
   * Gets the Experience List from Server.
   * @returns response: response got from Server.
   */
  Future<http.Response> _getExperiencesFromServer() async {
    Uri uri = Uri.https(_serverDir, _getListPath);
    http.Response response = await http.get(uri);
    return response;
  }

  /*
   * Fetches the experience list from the Server. If the response is OK, fills
   * in the list and creates the widget to show them.
   */
  void _getExperiences() {
    _getExperiencesFromServer().then((http.Response response) {
      if (response.statusCode == 200) {
        _buildExperiences(response.body);
        setState(() {
          _listWidget = ExperienceExpandedList(_experiences);
        });
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

  /*
   * Layout construction.
   */
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Color.fromRGBO(238, 238, 238, 1),
        body: SafeArea(
          child: Container(
            alignment: Alignment.topCenter,
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.1),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: PageTitle("Lista de experiencias"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                            horizontal: BorderSide(
                          color: Colors.red,
                          width: 3,
                        )),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          _messages["topMessage"],
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: _listWidget,
                  ),
                  Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: DefButton("Atrás", _goBack),
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
