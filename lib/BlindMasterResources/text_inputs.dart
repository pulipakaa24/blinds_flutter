import 'package:flutter/material.dart';



class BlindMasterMainInput extends StatefulWidget {
  const BlindMasterMainInput(this.label, {super.key, this.controller, this.validator, this.color, this.password = false});

  final String label;
  final TextEditingController? controller;
  final Color? color;
  final bool password;

  final String? Function(String?)? validator;

  @override
  State<BlindMasterMainInput> createState() => _BlindMasterMainInputState();
}

class _BlindMasterMainInputState extends State<BlindMasterMainInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child:TextFormField(
        validator: widget.validator,
        obscureText: widget.password && _obscureText,
        enableSuggestions: false,
        autocorrect: false,
        controller: widget.controller,
        style: TextStyle(
          color: widget.color
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          labelText: widget.label,
          labelStyle: TextStyle(color: widget.color),
          contentPadding: EdgeInsets.all(10),
          suffixIcon: widget.password
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
        ),
      )
    );
  }
}