import 'dart:convert';
import 'dart:developer';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:empatimetro/defaultWidgets.dart';
import 'package:empatimetro/home_page.dart';
import 'package:flutter/material.dart';
import 'chart.dart';
import 'experience_result.dart';

class SelectEmotionPage extends StatefulWidget {
  SelectEmotionPage(this._experience);

  final ExperienceResult _experience;

  @override
  SelectEmotionPageView createState() {
    return SelectEmotionPageView(_experience);
  }
}

class SelectEmotionPageView extends State<SelectEmotionPage> {
  SelectEmotionPageView(this._experience);

  ExperienceResult _experience;

  Future<String> _serverAnswer;

  // Variables to manage the user experience's feedback.
  final _emotionTextController = TextEditingController();
  double _valence = -5;
  double _arousal = -5;
  double _dominance = -5;

  final String _pageExplanation =
      "En este cuestionario, su tarea consistirá en evaluar el estado afectivo en el que se encuentre justo EN ESTE MOMENTO. Para ello, utilizaremos una escala de evaluación pictográfica, mostrando tres filas: valencia (agradable-desagradable), arousal (activado-relajado) y control (control total-sin control). Seleccione con la barra de desplazamiento correspondiente el lugar (muñeco o espacio) que corresponda con su estado afectivo actual.";

  // URL parts
  final String _serverDir = 'bioinformatica.ugr.es';
  final String _newResultPath = '/empathos/newExperienceResult';
  final String _addResultsPath = '/empathos/addExperienceResults';

  // Variable to limit the value's amount per message
  final int _maxAmount = 100;

  //////////////////////////////////////////////////////////////////////////////
  //                                                                          //
  //               Initialization and Cleanning Functions                     //
  //                                                                          //
  //////////////////////////////////////////////////////////////////////////////

  /*
   * Release the memory allocated to variables when state object is removed.
   * It adds the emotion text controller removal.
   */
  @override
  void dispose() {
    _emotionTextController.dispose();
    super.dispose();
  }

  /*
   * It is called when the object's state is created. Initialize some values.
   */
  @override
  void initState() {
    super.initState();
    setState(() {
      _valence = -5;
      _arousal = -5;
      _dominance = -5;
    });
  }

  void _goToHomePage() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => HomePage()));
  }

  void _pop() {
    Navigator.of(context).pop();
  }

  //////////////////////////////////////////////////////////////////////////////
  //                                                                          //
  //                    Experience Interaction Functions                      //
  //                                                                          //
  //////////////////////////////////////////////////////////////////////////////

  /*
   * Function that checks if the emotion textField is empty. If it isn't,
   * it updates the experience with it.
   */
  bool checkEmotion() {
    FocusScope.of(context).unfocus();

    if (_emotionTextController.text.isNotEmpty) {
      _experience.setUserEmotion(_emotionTextController.text);
      return true;
    }

    return false;
  }

  /*
   * Function that returns a list with the values of the Experience (without
   * the time values).
   */
  List<double> _getExperienceValues() {
    List<SensorValue> sensorResults = _experience.getResults();
    List<double> onlyValues = [];

    for (SensorValue sensorValue in sensorResults)
      onlyValues.add(sensorValue.getValue());

    return onlyValues;
  }

  /*
   * Function that fills the experience object with the sliders' values.
   */
  void _updateExperienceWithSliders() {
    _experience.setUserParams(_valence.abs().round(), _arousal.abs().round(),
        _dominance.abs().round());
  }

  //////////////////////////////////////////////////////////////////////////////
  //                                                                          //
  //                        Communication Functions                           //
  //                                                                          //
  //////////////////////////////////////////////////////////////////////////////

  /*
   * Function that send prepares to send all the Experience Result and creates
   * the status confirm.
   */
  void _postExperienceResults() {
    _serverAnswer = _sendExperienceResult();
    _confirmMessage();
  }

  /*
   * Main communication function to add a new Experience Result to the DB.
   */
  Future<String> _sendExperienceResult() async {
    http.Response firstReceived = await _sendNewExperienceResult();
    String message = firstReceived.body;

    if (firstReceived.statusCode == 200) {
      http.Response finalReceived = await _sendResults();
      if (finalReceived.statusCode != 200) message = finalReceived.body;
    }

    return message;
  }

  /*
   * Send the basic information of the new Experience Result
   */
  Future<http.Response> _sendNewExperienceResult() async {
    final Map<String, String> qParams = {
      'json': jsonEncode(_experience),
    };

    final Uri uri = Uri.https(_serverDir, _newResultPath, qParams);
    http.Response response = await http.get(uri);

    return response;
  }

  /*
   * Send the result values of the new Experience Result in different messages.
   */
  Future<http.Response> _sendResults() async {
    List<double> values = _getExperienceValues();
    List<double> partialValues;
    http.Response response;
    int finalEnvio;
    int contador = 0;

    while (contador < values.length) {
      partialValues = [];
      finalEnvio = contador + _maxAmount;

      for (contador;
          contador < finalEnvio && contador < values.length;
          contador++) partialValues.add(values[contador]);

      Map params = {
        "userID": _experience.getUserID(),
        "startTime": _experience.getFormattedStartTime(),
        "results": jsonEncode(partialValues),
      };

      Map<String, String> qParams = {
        "json": jsonEncode(params),
      };

      Uri uri = Uri.https(_serverDir, _addResultsPath, qParams);
      response = await http.get(uri);

      if (response.statusCode != 200) return response;
    }

    return response;
  }

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                            Button Functions                              //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

/*
   * Function called when the "Finish" button is pressed. It starts the
   * communication process with the server to store the new experience results.
   */
  void _finish() async {
    if (checkEmotion()) {
      if(_experience.getExperienceID() == "1") {
        _notifyText("El tutorial ha finalizado", _goToHomePage);
      } else {
        _updateExperienceWithSliders();
        _postExperienceResults();
      }
    } else {
      _notifyText("Debes escribir la emoción que sientes antes de continuar.", _pop);
    }
  }

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                            Layout Functions                              //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

/*
   * Warning text that is shown when the user try to send the new Experience
   * Result data to the server without typing the emotion he/she think that
   * feels.
   */
  Future<void> _notifyText(String text, Function func) async {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(text),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: func,
              )
            ],
          );
        });
  }

/*
   * Shows the message that is received from the server.
   * @param received: body of the server's response.
   */
  Future<void> _confirmMessage() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: FutureBuilder<String>(
            future: _serverAnswer,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data);
              } else if (snapshot.hasError) {
                return Text("$snapshot.error");
              }
              return CircularProgressIndicator();
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Volver al inicio"),
              onPressed: () => _goToHomePage(),
            )
          ],
        );
      },
    );
  }

/*
   * Main layout construction.
   */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(238, 238, 238, 1),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 30),
                child:
                    PageTitle("¿Cómo te has sentido durante la experiencia?"),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _pageExplanation,
                ),
              ),
              Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 30),
                child: TextField(
                  controller: _emotionTextController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Describa cómo se ha sentido con una palabra",
                    hintText: "feliz",
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Agradable",
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Desagradable (9-1)",
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              Image.asset("assets/SAMicons/valence.png"),
              Slider(
                value: _valence,
                min: -9,
                max: -1,
                divisions: 8,
                label: _valence == null
                    ? 5.toString()
                    : _valence.abs().round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _valence = value;
                  });
                },
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Activad@",
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Relajad@ (9-1)",
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              Image.asset("assets/SAMicons/arousal.png"),
              Slider(
                value: _arousal,
                min: -9,
                max: -1,
                divisions: 8,
                label: _arousal == null
                    ? 5.toString()
                    : _arousal.abs().round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _arousal = value;
                  });
                },
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Control total",
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Sin control (9-1)",
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              Image.asset("assets/SAMicons/dominance.png"),
              Slider(
                value: _dominance,
                min: -9,
                max: -1,
                divisions: 8,
                label: _dominance == null
                    ? 5.toString()
                    : _dominance.abs().round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _dominance = value;
                  });
                },
              ),
              Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(top: 50),
                child: DefButton("Terminar", _finish),
              ),
            ],
          ),
        ),
      )),
    );
  }
}
