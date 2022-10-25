import 'dart:convert';

import 'package:empatimetro/bpm_medition/chart.dart';
import 'package:flutter/material.dart';

class Experience {
  int _code;
  int duration;
  String _name;
  List<String> _emotions;
  String _username = "Default";
  String _filename;
  List<SensorValue> _results;
  String _userEmotion;
  DateTime _startTime;
  int _fs;
  int _valence;
  int _arousal;
  int _dominance;

  Experience(this._code, this._name, this.duration, this._emotions);

  /*
   * Function that fills the Experience's attributes. In the future, it will
   * decode a JSON object.
   *
   * @param code: experience's code.
   * @param name: experience's name.
   * @param emotions: experience's possible emotions.
   */
  void setExperience(int code, String name, String _emotions) {
    _code = code;
    _name = name;
  }

  /*
   * Function used to set the initial params. of the experience's result.
   *
   * @username: username of the person who is taking part in the experience.
   * @startTime: moment when the app starts to collect results.
   * @fs: frequency used to collect results.
   */
  void startExperience(String username, DateTime startTime, int fs) {
    _username = username;
    _startTime = startTime;
    _fs = fs;
    _filename = username + "_" + startTime.toString() + ".txt";
  }

  /*
   * Returns the experience's code
   */
  int getCode() {
    return _code;
  }

  /*
   * Returns the experience's name
   */
  String getName() {
    return _name;
  }

  /*
   * Returns the duration of the experience in seconds
   */
  int getDuration() {
    return duration;
  }

  /*
   * Returns the experience's name
   */
  List<String> getEmotions() {
    return _emotions;
  }

  /*
   * Sets the username who test the experience
   * @param user: username
   */
  void setUsername(String user) {
    _username = user;
  }

  /*
   * Returns the username who test the experience.
   */
  String getUsername() {
    return _username;
  }

  /*
   * Returns the experience's results
   */
  List<SensorValue> getResults() {
    return _results;
  }

  /*
   * Sets the experience's results and calculates the times according to
   * _startTime.
   *
   * @param values: results' values
   */
  void setResults(List<SensorValue> values) {
    _results = values;

    for (SensorValue result in _results)
      result.calculateMillisecondsSinceStart(_startTime);
  }

  /*
   * Empties the experience's results array
   */
  void deleteResults() {
    _results = [];
  }

  /*
   * Returns the emotion selected by the username before the experience
   */
  String getUserEmotion() {
    return _userEmotion;
  }

  /*
   * Sets the emotion selected by the username.
   * @param emotion: selected emotion.
   */
  void setUserEmotion(String emotion) {
    _userEmotion = emotion;
  }

  /*
   * Returns the start time of the experience
   */
  DateTime getStartTime() {
    return _startTime;
  }

  /*
   * Returns the start time with the proper format
   */
  String getFormattedStartTime() {
    return formatStartTime();
  }

  /*
   * Sets the start moment of the experience.
   * @param emotion: start time.
   */
  void setStartTime(DateTime time) {
    _startTime = time;
  }

  /*
   * Returns the frequency used to get the experience's results
   */
  int getFS() {
    return _fs;
  }

  /*
   * Returns the filename in which the experience's results are stored.
   */
  String getFilename() {
    return _filename;
  }

  /*
   * Sets the user params, the values the user think that feels.
   * @param valence: affective valence.
   * @param arousal: range from excited to relaxed.
   * @param dominance: auto-control level.
   */
  void setUserParams(int valence, int arousal, int dominance) {
    _valence = valence;
    _arousal = arousal;
    _dominance = dominance;
  }

  /*
   * Sets the frequency used to get the experience's results.
   * @param emotion: frequency.
   */
  void setFS(int freq) {
    _fs = freq;
  }

  String formatStartTime() {
    String day = _startTime.day.toString();
    if (day.length < 2) day = "0" + day;

    String month = _startTime.month.toString();
    if (month.length < 2) month = "0" + month;

    String year = _startTime.year.toString();

    String hour = _startTime.hour.toString();
    if (hour.length < 2) hour = "0" + hour;

    String minute = _startTime.minute.toString();
    if (minute.length < 2) minute = "0" + minute;

    String second = _startTime.second.toString();
    if (second.length < 2) second = "0" + second;

    return "$year-$month-$day $hour:$minute:$second";
  }

  /*
   * It encodes the experience's data which is necessary to store a new test.
   */
  Map toJson() {
    return {
      "experienceID": _code,
      "username": _username,
      "userEmotion": _userEmotion,
      "startTime": formatStartTime(),
      "frequency": _fs,
      "valence": _valence,
      "arousal": _arousal,
      "dominance": _dominance,
      //"filename": _filename
    };
  }
}

class Experience_Widget extends StatelessWidget {
  Experience_Widget(this._experience, this._goToMeditionFunction);

  final Experience _experience;
  final Function _goToMeditionFunction;

  /*
   * Layout construction.
   */
  @override
  Widget build(BuildContext context) {
    /*return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 10),
      width: MediaQuery.of(context).size.width * 0.8,
      child: RaisedButton(
        onPressed: () => _goToMeditionFunction(context, _experience_name),
        color: Colors.pink,
        child: Text(_experience_name),
      ),
    );*/
    /*return RaisedButton(
      onPressed: () => _goToMeditionFunction(context, _experience),
      color: Colors.red,
      child: Text(_experience.getName()),
    );*/
    return RaisedButton(
      color: Colors.red,
      child: Text(
        _experience.getName(),
        style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold
        ),
      ),
      onPressed: () => _goToMeditionFunction(_experience),
    );
  }
}
