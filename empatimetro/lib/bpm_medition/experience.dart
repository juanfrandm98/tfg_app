import 'package:flutter/material.dart';
import '../defaultWidgets.dart';
import 'medition_page.dart';

class Experience {
  int id;
  String title;
  String description;
  int duration;
  int resultStart;
  int resultDuration;

  Experience(this.id, this.title, this.description, this.duration,
      this.resultStart, this.resultDuration);

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      //int.parse(json["id"]),
      json["id"],
      json["title"],
      json["description"],
      json["duration"],
      json["resultStart"],
      json["resultDuration"],
    );
  }
}

class ExperienceExpanded {
  final Experience _experience;
  bool _expanded = false;

  ExperienceExpanded(this._experience);

  Experience getExperience() {
    return _experience;
  }

  void setExpanded(bool isExpanded) {
    _expanded = isExpanded;
  }

  bool getExpanded() {
    return _expanded;
  }
}

class ExperienceExpandedList extends StatefulWidget {
  final List<Experience> _experiences;

  ExperienceExpandedList(this._experiences);

  @override
  State<StatefulWidget> createState() {
    return ExperienceExpandedListView(_experiences);
  }
}

class ExperienceExpandedListView extends State<ExperienceExpandedList> {
  List<ExperienceExpanded> _experiences = [];

  ExperienceExpandedListView(List<Experience> experiences) {
    for (Experience exp in experiences)
      _experiences.add(new ExperienceExpanded(exp));
  }

  /*
   * Function called when the Button is pressed. It goes to Medition Page.
   */
  void _goToMeditionPage(BuildContext context, Experience exp) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => MeditionPage(exp)));
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList(
      dividerColor: Colors.red,
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _experiences[index].setExpanded(!isExpanded);
        });
      },
      children: _experiences.map<ExpansionPanel>((ExperienceExpanded exp) {
        return ExpansionPanel(
          canTapOnHeader: true,
          headerBuilder: (BuildContext context, bool isExpanded) {
            return Center(
              child: Text(
                exp.getExperience().title,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
          body: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: Text(exp.getExperience().description),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: EdgeInsets.only(right: 5),
                        alignment: Alignment.centerRight,
                        child: Icon(
                          Icons.alarm,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                          padding: EdgeInsets.only(left: 5),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            exp.getExperience().duration.toString() + " seg",
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          )),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: DefButton("Seleccionar",
                    () => _goToMeditionPage(context, exp.getExperience())),
              )
            ],
          ),
          isExpanded: exp.getExpanded(),
        );
      }).toList(),
    );
  }
}
