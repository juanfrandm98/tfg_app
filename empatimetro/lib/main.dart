import 'dart:io';

import 'package:empatimetro/home_page.dart';
import 'package:empatimetro/session/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences preferences = await SharedPreferences.getInstance();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) => runApp(MyApp(preferences.getString("email"))));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  String _email;

  MyApp(this._email);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Empatímetro',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.greimperioen and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.red,
        // This makes the visual density adapt to the platform that you run the
        // app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        //visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _email == null ? LoginPage() : HomePage(),
    );
  }
}
