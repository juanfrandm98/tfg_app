import 'package:empatimetro/defaultWidgets.dart';
import 'package:empatimetro/session/login_page.dart';
import 'package:empatimetro/user/user_profile_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './bpm_medition/experiences_list.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomePageView();
  }
}

enum TtsState { playing, stopped, paused, continued }

class HomePageView extends State<HomePage> {
  String _titleText = "Hola!"; // Welcome text

  /*
   * Function which goes to the Experience's List Page.
   */
  void _goToExperiences() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => ExperiencesList()));
  }

  /*
   * Function which goesto the User Profile's Page.
   */
  void _goToProfile() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => UserProfilePage()));
  }

  /*
   * Function that deletes the user's session data, which are the email and
   * the server's user ID.
   */
  Future deletePreferences() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.remove("email");
    preferences.remove("userID");
    preferences.remove("localeID");
  }

  /*
   * Funcion that delete the session data and goes to the Login Page.
   */
  void _logOut() {
    deletePreferences();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  /*
   * Function that initializes the State. It checks the session data to get the
   * user's email and to set the welcome message.
   */
  @override
  void initState() {
    super.initState();
    _getUsername();
  }

  /*
   * Function that gets the user's email from the session data. It takes the
   * first part (before the '@' character) and sets the welcome message.
   */
  Future _getUsername() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String original = preferences.getString("email");
    List<String> descompuesto = original.split("@");
    setState(() {
      _titleText = "Bienvenid@, " + descompuesto[0];
    });
  }

  /*
   * Function that builds the page layout.
   */
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Color.fromRGBO(238, 238, 238, 1),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    //Image.asset("assets/images/heart.png"),
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

                    PageTitle(_titleText),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    DefButton("Seleccionar experiencia", _goToExperiences),
                    DefButton("Mi perfil", _goToProfile),
                    DefButton("Cerrar sesión", _logOut),
                  ],
                ),
                /*child: ListView(
                  children: <Widget>[
                    DefButton("Seleccionar experiencie", _goToExperiences),
                    DefButton("Cerrar sesión", _logOut),
                  ],
                ),*/
              ),
            ],
          ),
        ),
      ),
    );
  }
}
