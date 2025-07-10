import 'package:flutter/material.dart';

class BlindmasterProgressIndicator extends StatelessWidget {
  const BlindmasterProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColorDark,
        )
      )
    );
  }
}