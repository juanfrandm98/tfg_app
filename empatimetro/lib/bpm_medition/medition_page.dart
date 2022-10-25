import 'dart:async';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:empatimetro/bpm_medition/tutorial_messages.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

import 'chart.dart';
import 'experience.dart';
import 'experience_result.dart';
import 'experiences_list.dart';
import 'select_emotion_page.dart';
import '../defaultWidgets.dart';
import 'package:flutter/material.dart';

import 'package:flutter_better_camera/camera.dart';
//import 'package:camera/camera.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:speech_to_text/speech_to_text.dart' as stt;

class MeditionPage extends StatefulWidget {
  MeditionPage(this._experience);

  final Experience _experience;

  @override
  State<StatefulWidget> createState() {
    return MeditionPageView(_experience);
  }
}

enum TtsState { playing, stopped, paused, continued }

class MeditionPageView extends State<MeditionPage>
    with SingleTickerProviderStateMixin {
  MeditionPageView(this._experience);

  final Experience _experience;
  ExperienceResult _experienceResult;

  // Toggle Button state
  bool _toggled = false;

  // Sensor values from the scanning
  List<SensorValue> _data = <SensorValue>[];

  // Controllers
  CameraController _cameraController;
  AnimationController _animationController;

  // Variables used to calculate sensor values
  static final int _fs = 30; // Sampling frequency (fps)

  // Layout variables
  double _iconScale = 1;

  // Last Camera Image
  CameraImage _image;

  // Timer for Image processing
  Timer _timer;

  // Timer Layout
  Timer _secondsTimer;
  int _currentSeconds = 0;
  Widget _timeCounter;
  int _max;

  // Voice interface
  bool _isPlaying = false;
  FlutterTts _flutterTts;
  TtsState _ttsState = TtsState.stopped;

  // Voice detection
  stt.SpeechToText _speechToText;
  List<stt.LocaleName> _localeNames = [];
  String _currentLocaleId = "es-ES";
  bool _isListening = false;
  bool _abort = false;
  String _correctWord = "empezar";
  String _listenedWords = "";

  // Platform knowledge
  bool get _isIOS => !kIsWeb && Platform.isIOS;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  bool get _isWeb => kIsWeb;

  // Variable to control the finish button
  bool _experienceIsFinished = false;

  // Messages
  Map<String, String> _messages = {
    "beforeExperience":
        "Por favor, antes de continuar ponga su dispositivo en modo avión para evitar estimulos externos a la experiencia. La aplicación le seguirá explicando por voz. ¿Está preparad@?",
    "afterExperience":
        "La toma de medidas ha finalizado, aunque puede seguir con la experiencia si lo desea. Por favor, desactive ahora el modo avión de su dispositivo.",
    "explainVoice2": "acortar mensaje",
    "explainVoice":
        "Colóquese en posición. Asegúrese de que está tapando bien la cámara con su dedo y de que la luz del flash no le molestará. Aunque se apague el flash, continúe con su experiencia. Relájese y cuando esté en posición, diga claramente. Empezar.",
    "cameraMessage":
        "La cámara se mostrará aquí y, durante un registro, este cuadro deberá aparecer completamente en rojo. Sitúe el dedo ÍNDICE sobre la cámara y no lo mueva. Durante los registros no tendrá que estar viendo la pantalla y debería usar una cinta elástica o velcro para mantener el dedo sobre la cámara sin esfuerzo y concentrarse así en la experiencia.",
    "cameraThanks": "Gracias por haber completado esta experiencia.",
  };

  String _userID = "";

  //////////////////////////////////////////////////////////////////////////////
  //                                                                          //
  //                       Initialization Functions                           //
  //                                                                          //
  //////////////////////////////////////////////////////////////////////////////

  /*
   * It is called when the object's state is created. Initialize some values.
   */
  @override
  void initState() {
    super.initState();
    //_buildTimeCounter(_experience.resultStart);
    setState(() {
      _max = _experience.resultStart;
    });
    _getSessionUserID();
    _initTts();
    _initSpeechToText();
    _animationController =
        AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _animationController
      ..addListener(() {
        setState(() {
          _iconScale = 1.0 + _animationController.value * 0.4;
        });
      });
    _initExperienceResult();
  }

  bool _checkTutorial() {
    return _experience.id == 1;
  }

  void _initSpeechToText() async {
    _speechToText = stt.SpeechToText();

    bool hasSpeech = await _speechToText.initialize(
      onStatus: (val) => print("onStatus: $val"),
      onError: (val) {
        print("onError: $val");
        _speechToText.cancel();
        _speechToText.stop();
        _initSpeechToText();
      },
    );
  }

  /*
   * Creates the CameraController object
   */
  Future<String> _initController() async {
    try {
      List _cameras = await availableCameras();
      bool _found = false;

      /*
      for(int i = 0; i < _cameras.length && !_found; i++) {
        _cameraController =
            CameraController(_cameras[i], ResolutionPreset.low);

        await _cameraController.initialize().then((_) {
          if (!mounted) return Future.error("Camera not found");
        });

        _found = await _cameraController.hasFlash;
      }

      if(!_found)
        _cameraController = CameraController(_cameras.first, ResolutionPreset.low);
        */

      _cameraController =
          CameraController(_cameras.first, ResolutionPreset.low);

      await _cameraController.initialize().then((_) {
        if (!mounted) return Future.error("Camera not found");
      });

      await _cameraController.startImageStream((CameraImage image) {
        _image = image;
      });

      await Future.delayed(Duration(milliseconds: 350));

      return null;
    } catch (Exception) {
      debugPrint(Exception.toString());
    }
  }

  /*
   * Initializes the Timer object.
   */
  void _initTimer() async {
    int time = 0;
    _timer = Timer.periodic(Duration(milliseconds: 1000 ~/ _fs), (timer) {
      // First image is always null
      if (_toggled && time <= _fs * _experience.duration) {
        if (time > 0) if (_image != null)
          _scanImage(_image);
        else
          print("no image\n");
        time++;
      }
    });
  }

  void _initSecondsTimer(bool timing, int objective) async {
    setState(() {
      _currentSeconds = 0;
    });

    _secondsTimer = Timer.periodic(
        Duration(seconds: 1),
        (_) => setState(() {
              _currentSeconds++;
              if (_currentSeconds == objective) {
                _secondsTimer.cancel();
                if (timing) {
                  _timer.cancel();
                  _prepareToFinish();
                } else {
                  _startMedition();
                }
              }
            }));
  }

  /*
   * Initializes the FlutterTts object.
   */
  void _initTts() {
    _flutterTts = FlutterTts();

    if (_isAndroid) _getEngines();

    _flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        _ttsState = TtsState.playing;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        _ttsState = TtsState.stopped;
      });
    });

    _flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        _ttsState = TtsState.stopped;
      });
    });

    if (_isWeb || _isIOS) {
      _flutterTts.setPauseHandler(() {
        setState(() {
          print("Paused");
          _ttsState = TtsState.paused;
        });
      });

      _flutterTts.setContinueHandler(() {
        setState(() {
          print("Continued");
          _ttsState = TtsState.continued;
        });
      });
    }

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        _initTts();
      });
    });
  }

  void _initExperienceResult() {
    _experienceResult = new ExperienceResult(_experience.id.toString());
  }

  /*
   * Function used to get the username from the session data.
   */
  void _getSessionUserID() {
    SharedPreferences.getInstance().then((SharedPreferences preferences) {
      String localeID = preferences.getString("localeID");
      setState(() {
        _userID = preferences.getString("userID");
        if (localeID == null)
          _currentLocaleId = "0";
        else
          _currentLocaleId = localeID;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Color.fromRGBO(238, 238, 238, 1),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: PageTitle(_experience.title),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 75),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: <Widget>[
                        _image != null && _toggled
                            ? AspectRatio(
                                aspectRatio:
                                    _cameraController.value.aspectRatio,
                                child: CameraPreview(_cameraController),
                              )
                            : Container(
                                padding: EdgeInsets.all(12),
                                alignment: Alignment.center,
                                color: Colors.grey,
                              ),
                        Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(4),
                          child: AutoSizeText(
                            _toggled
                                ? " "
                                : _experienceIsFinished
                                    ? _messages["cameraThanks"]
                                    : _messages["cameraMessage"],
                            style: TextStyle(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Colors.red,
                    ),
                    width: 290,
                    height: 60,
                    alignment: Alignment.center,
                    child: Text(
                      _experienceIsFinished
                          ? "Experiencia terminada"
                          : "Transcurridos: " +
                              _currentSeconds.toString() +
                              "/" +
                              _max.toString() +
                              " segundos",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: Transform.scale(
                    scale: _iconScale,
                    child: _toggled
                        ? Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 135,
                          )
                        : _experienceIsFinished
                            ? Icon(
                                Icons.favorite_border,
                                color: Colors.grey,
                                size: 135,
                              )
                            : Stack(
                                fit: StackFit.expand,
                                alignment: Alignment.center,
                                children: [
                                  Center(
                                    child: Text(
                                      "Empezar",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.favorite_border),
                                    color: Colors.red,
                                    iconSize: 135,
                                    onPressed: _toggle,
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: EdgeInsets.only(left: 20, right: 10),
                          child: DefButton("Abortar", _prepareToAbort),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: EdgeInsets.only(left: 10, right: 20),
                          child: _experienceIsFinished
                              ? DefButton("Terminar", _goToSelectEmotionPage)
                              : RaisedButton(
                                  color: Colors.grey,
                                  child: Text(
                                    "Terminar",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  //                                                                          //
  //                        Destruction Functions                             //
  //                                                                          //
  //////////////////////////////////////////////////////////////////////////////

  @override
  void dispose() {
    _timer?.cancel();
    _secondsTimer.cancel();
    _toggled = false;
    _disposeCameraController();
    Wakelock.disable();
    _animationController?.stop();
    _animationController?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  /*
   * Destroy the CameraController Object
   */
  void _disposeCameraController() {
    _cameraController?.dispose();
    _cameraController = null;
  }

  //////////////////////////////////////////////////////////////////////////////
  //                                                                          //
  //                         Button's Functions                               //
  //                                                                          //
  //////////////////////////////////////////////////////////////////////////////

  /*
   * Function used to clean the experience when it's started.
   */
  _resetExperience() async {
    _data.clear();
    _experienceResult.deleteResults();
    _experienceResult.startExperience(DateTime.now(), _fs, _userID);
    _initSecondsTimer(false, _experience.resultStart);
  }

  Future<void> _toggle() async {
    if (_checkTutorial()) {
      _startTutorial();
    } else {
      _startToggle();
    }
  }

  Future<void> _startToggle() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_messages["beforeExperience"]),
          actions: <Widget>[
            TextButton(
              child: Text("¡YA!"),
              onPressed: () {
                Navigator.of(context).pop();
                _prepareToStart();
              },
            )
          ],
        );
      },
    );
  }

  /*
   * Function called when the user starts the experience. Initializes the scan
   * process and creates the CameraController object.
   */
  void _startExperience() async {
    _resetExperience();
    setState(() {
      _toggled = true;
    });
  }

  void _startMedition() async {
    //_buildTimeCounter(_experience.resultDuration);
    try {
      String result = await _initController();
      if (result != null) throw Exception(result);
      Wakelock.enable();
      _animationController?.repeat(reverse: true);
      setState(() {
        _max = _experience.resultDuration;
      });
      _initTimer();
      _initSecondsTimer(true, _experience.resultDuration);
    } catch (exception) {
      debugPrint(exception.toString());
      dispose();
    }
  }

  /*
   * Function called when the scan button is untoggled. Stop the scan process.
   */
  void _untoggle() {
    _disposeCameraController();
    if (_secondsTimer != null) _secondsTimer.cancel();
    if (_timer != null) _timer.cancel();
    if (_speechToText != null) _speechToText.stop();
    Wakelock.disable();
    _animationController?.stop();
    _animationController?.value = 0.0;
    setState(() {
      if (_data.isNotEmpty) _experienceResult.setResults(_data);
      _toggled = false;
      _abort = true;
    });
    if(_experienceIsFinished) FlutterRingtonePlayer.playNotification();
  }

  //////////////////////////////////////////////////////////////////////////////
  //                                                                          //
  //                          Navigation Functions                            //
  //                                                                          //
  //////////////////////////////////////////////////////////////////////////////

  /*
   *
   */
  Future<void> _prepareToFinish() async {
    setState(() {
      _experienceIsFinished = true;
    });

    if (_toggled) _untoggle();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_messages["afterExperience"]),
          actions: <Widget>[
            TextButton(
              child: Text("¡YA!"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  Future<void> _prepareToAbort() async {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("¿Seguro que quieres parar?"),
            actions: <Widget>[
              TextButton(
                child: Text("Sí"),
                onPressed: () => _goBack(),
              ),
              TextButton(
                child: Text("No"),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          );
        });
  }

  /*
   *
   */
  void _goToSelectEmotionPage() {
    //printToFile();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SelectEmotionPage(_experienceResult)));
  }

  /*
   *
   */
  void _goBack() {
    _stop();
    _untoggle();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => ExperiencesList()));
  }

  //////////////////////////////////////////////////////////////////////////////
  //                                                                          //
  //                          Data Functions                                  //
  //                                                                          //
  //////////////////////////////////////////////////////////////////////////////

  /*
   * Insert a new SensorValue in _data array using the last read image.
   */
  void _scanImage(CameraImage image) {
    DateTime now = DateTime.now();
    double avg =
        image.planes.first.bytes.reduce((value, element) => value + element) /
            image.planes.first.bytes.length;

    setState(() {
      _data.add(SensorValue(now, avg));
    });
  }

/*
  /*
   *
   */
  void printToFile() async {
    final directory = await getExternalStorageDirectory();
    final filename = directory.path + "/" + _experience.getFilename();
    final file = File(filename);
    var stream = file.openWrite();

    for (SensorValue result in _data)
      await file.writeAsString(result.value.toString() + "\n",
          mode: FileMode.append);

    stream.close();
  }
*/
  //////////////////////////////////////////////////////////////////////////////
  //                                                                          //
  //                          Speech Functions                                //
  //                                                                          //
  //////////////////////////////////////////////////////////////////////////////

  /*
   * This function is needed to use FlutterTTS on Android
   */
  Future _getEngines() async {
    var engines = await _flutterTts.getEngines;
    if (engines != null) for (dynamic engine in engines) print(engine);
  }

  Future _speak(String text) async {
    double volume = 0.5;
    double pitch = 1.0;
    double rate;

    if (_isAndroid)
      rate = 2.0;
    else
      rate = 0.52;

    await _flutterTts.setLanguage("es-ES");
    await _flutterTts.setVolume(volume);
    await _flutterTts.setSpeechRate(rate);
    await _flutterTts.setPitch(pitch);

    setState(() {
      _ttsState = TtsState.playing;
    });

    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.speak(text);
  }

  Future _pause() async {
    var result = await _flutterTts.pause();
    if (result == 1) {
      setState(() {
        _ttsState = TtsState.paused;
      });
    }
  }

  Future _stop() async {
    var result = await _flutterTts.stop();
    if (result == 1) {
      setState(() {
        _ttsState = TtsState.stopped;
      });
    }
  }

  /*
   * Function that is used to stop the SpeechToText listening process.
   */
  void _stopListening() {
    setState(() {
      _isListening = false;
      _speechToText.stop();
      _listenedWords = "";
    });
  }

  /*
   * Function that starts listening to the user.
   */
  Future _listen() async {
    _speechToText.listen(
      localeId: "es-ES",
      //cancelOnError: false,
      onResult: (val) => setState(() {
        _listenedWords = val.recognizedWords;
      }),
    );
  }

  /*
   * Function that checks if the user has said the proper word.
   */
  Future<bool> _checkWords() async {
    bool found = false;

    List<String> separatedWords = _listenedWords.split(" ");

    for (String word in separatedWords)
      if (word.toLowerCase() == _correctWord) found = true;

    setState(() {
      _listenedWords = "";
    });

    return found;
  }

  /*
   * This function explains the medition process to the user speaking and starts
   * to listen it.
   */
  void _prepareToStart() async {
    await _speak(_messages["explainVoice"]);
    bool found = false;
    setState(() {
      _abort = false;
    });

    while (!found && !_abort) {
      _listen();
      await Future.delayed(Duration(milliseconds: 2000));
      found = await _checkWords();
    }

    _stopListening();

    if (!_abort) _startExperience();
  }

  //////////////////////////////////////////////////////////////////////////////
  //                                                                          //
  //                          Tutorial Functions                              //
  //                                                                          //
  //////////////////////////////////////////////////////////////////////////////

  /*
   * Displays a message on the screen.
   * @param text: text to show.
   * @param action: Function which will be done when the AlertDialog button is
   *                pressed.
   * @return showDialog: message displayed.
   */
  void _showTutorial(String text, List<ButtonData> buttons) async {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(text),
            actions: buttons.map<TextButton>((ButtonData data) {
              return TextButton(
                child: Text(data.text),
                onPressed: data.func,
              );
            }).toList(),
          );
        });
  }

  void _pop() {
    Navigator.of(context).pop();
  }

  void _endTutorial() {
    _pop();
    _startToggle();
  }

  void _startTutorial() {
    String text =
        "Esto es un tutorial de la utilización de la aplicación. Sus datos no se registrarán, pero podrá realizar todo el proceso de medición. ¿Quiere saltarlo?";
    List<ButtonData> buttons = [];
    buttons.add(ButtonData("Saltar", _tutorialSix));
    buttons.add(ButtonData("Empezar", _tutorialOne));
    _showTutorial(text, buttons);
  }

  void _tutorialOne() {
    _pop();
    String text =
        "Cuando en cualquier experiencia pulse el botón del corazón que acaba de pulsar, le aparecerán instrucciones de qué debe hacer.";
    List<ButtonData> buttons = [];
    buttons.add(ButtonData("Saltar", _tutorialSix));
    buttons.add(ButtonData("Siguiente", _tutorialTwo));
    _showTutorial(text, buttons);
  }

  void _tutorialTwo() {
    _pop();
    String text =
        "A continuación, una voz le seguirá explicando que debe decir la palabra 'empezar' cuando esté perfectamente colocado. Tómese su tiempo antes de prounciarla.";
    List<ButtonData> buttons = [];
    buttons.add(ButtonData("Saltar", _tutorialSix));
    buttons.add(ButtonData("Siguiente", _tutorialThree));
    _showTutorial(text, buttons);
  }

  void _tutorialThree() {
    _pop();
    String text =
        "Si mira la aplicación durante la prueba, verá que hay dos temporizaciones independientes. El flash se activará cuando comience la segunda.";
    List<ButtonData> buttons = [];
    buttons.add(ButtonData("Saltar", _tutorialSix));
    buttons.add(ButtonData("Siguiente", _tutorialFour));
    _showTutorial(text, buttons);
  }

  void _tutorialFour() {
    _pop();
    String text =
        "El flash se activará y desactivará solo, cuando comience y termine la toma de datos, respectivamente. Aunque se apague, continúe con su experiencia si así lo desea.";
    List<ButtonData> buttons = [];
    buttons.add(ButtonData("Saltar", _tutorialSix));
    buttons.add(ButtonData("Siguiente", _tutorialFive));
    _showTutorial(text, buttons);
  }

  void _tutorialFive() {
    _pop();
    String text =
        "Posteriormente, pulse el botón 'Terminar', que ahora estará activo. Le llevará a un formulario que debe rellenar como bien se indica allí.";
    List<ButtonData> buttons = [];
    buttons.add(ButtonData("Saltar", _tutorialSix));
    buttons.add(ButtonData("Siguiente", _tutorialSix));
    _showTutorial(text, buttons);
  }

  void _tutorialSix() {
    _pop();
    String text =
        "En cualquier momento también puede pulsar 'Abortar' para detener la experiencia y volver al listado anterior.";
    List<ButtonData> buttons = [];
    buttons.add(ButtonData("Terminar", _tutorialSeven));
    _showTutorial(text, buttons);
  }

  void _tutorialSeven() {
    _pop();
    String text =
        "El tutorial ha concluido. Pruebe ahora el funcionamiento de la aplicación.";
    List<ButtonData> buttons = [];
    buttons.add(ButtonData("Entendido", _endTutorial));
    _showTutorial(text, buttons);
  }
}
