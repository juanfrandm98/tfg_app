import 'chart.dart';

class ExperienceResult {
  String _experienceID;
  String _userID;
  String _userEmotion;
  List<SensorValue> _results;
  DateTime _startTime;
  int _fs;
  int _valence;
  int _arousal;
  int _dominance;

  ExperienceResult(this._experienceID);

  /*
   * Function used to set the initial params. of the experience's result.
   *
   * @startTime: moment when the app starts to collect results.
   * @fs: frequency used to collect results.
   */
  void startExperience(DateTime startTime, int fs, String userID) {
    _userID = userID;
    _startTime = startTime;
    _fs = fs;
  }

  /*
   * Returns the ID of the user who is doing the experience.
   */
  String getUserID() {
    return _userID;
  }

  /*
   * Returns the ID of the experience which has been done.
   */
  String getExperienceID() {
    return _experienceID;
  }

  /*
   * Returns the start time with the proper format
   */
  String getFormattedStartTime() {
    return _formatStartTime();
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
   * Returns the experience's results
   */
  List<SensorValue> getResults() {
    return _results;
  }

  /*
   * Empties the experience's results array
   */
  void deleteResults() {
    _results = [];
  }

  /*
   * Sets the emotion selected by the username.
   * @param emotion: selected emotion.
   */
  void setUserEmotion(String emotion) {
    _userEmotion = emotion;
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

  String _formatStartTime() {
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
      "experienceID": _experienceID,
      "userID": _userID,
      "userEmotion": _userEmotion,
      "startTime": _formatStartTime(),
      "frequency": _fs,
      "valence": _valence,
      "arousal": _arousal,
      "dominance": _dominance,
    };
  }
}