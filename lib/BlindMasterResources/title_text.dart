import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TitleText extends StatelessWidget {
  const TitleText(this.text, {super.key, this.txtClr});

  final String text;
  final Color? txtClr;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.aBeeZee(
        color: txtClr,
        fontSize: 50
      ),
      textAlign: TextAlign.center,
    );
  }
}