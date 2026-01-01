import 'package:flutter/material.dart';

SnackBar errorSnackbar(
  Object e, {
  Color backgroundColor = const Color.fromARGB(255, 196, 26, 14),
  Duration duration = const Duration(seconds: 3),
}) {
  final errorText = e is String 
    ? e 
    : (e.toString().contains(':') 
        ? e.toString().substring(e.toString().indexOf(':') + 1).trim()
        : e.toString());
  
  return SnackBar(
    backgroundColor: Color.fromARGB(255, 196, 26, 14),
    content: Text(
      errorText,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 15,
        color: Colors.white
      )
    )
  );
}