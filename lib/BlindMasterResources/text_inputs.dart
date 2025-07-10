import 'package:flutter/material.dart';



class BlindMasterMainInput extends StatelessWidget {
  const BlindMasterMainInput(this.label, {super.key, this.controller, this.validator, this.color, this.password = false});

  final String label;
  final TextEditingController? controller;
  final Color? color;
  final bool password;

  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child:TextFormField(
        validator: validator,
        obscureText: password,
        enableSuggestions: false,
        autocorrect: false,
        controller: controller,
        style: TextStyle(
          color: color
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          labelText: label,
          labelStyle: TextStyle(color: color),
          contentPadding: EdgeInsets.all(10),
        ),
      )
    );
  }
}