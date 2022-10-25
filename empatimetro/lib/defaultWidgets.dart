import 'package:flutter/material.dart';

class PageTitle extends StatelessWidget {
  PageTitle(this._title);

  final String _title;

  @override
  Widget build(BuildContext context) {
    return Text(
      _title,
      style: TextStyle(
        color: Colors.red,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class DefButton extends StatelessWidget {
  DefButton(this._text, this._function);

  final String _text;
  final Function _function;

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      color: Colors.red,
      child: Text(
        _text,
        style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold
        ),
      ),
      onPressed: () => _function(),
    );
  }
}

