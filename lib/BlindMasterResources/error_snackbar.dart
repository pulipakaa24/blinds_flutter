import 'package:flutter/material.dart';

SnackBar errorSnackbar(
  Object e, {
  Color backgroundColor = const Color.fromARGB(255, 196, 26, 14),
  Duration duration = const Duration(seconds: 3),
}) {
  return SnackBar(
    backgroundColor: Color.fromARGB(255, 196, 26, 14),
    content: Text(
      e.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), ''),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 15,
        color: Colors.white
      )
    )
  );
}