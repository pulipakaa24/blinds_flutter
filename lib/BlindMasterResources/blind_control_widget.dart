import 'package:flutter/material.dart';

class BlindControlWidget extends StatelessWidget {
  final String imagePath;
  final double blindPosition;
  final Function(double) onPositionChanged;

  const BlindControlWidget({
    super.key,
    required this.imagePath,
    required this.blindPosition,
    required this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.15,
            ),
            Stack(
              children: [
                // Background image
                Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    imagePath,
                    width: MediaQuery.of(context).size.width * 0.7,
                  ),
                ),
                // Blind slats overlay
                Align(
                  alignment: Alignment.center,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final containerHeight = MediaQuery.of(context).size.width * 0.68;
                      final maxSlatHeight = containerHeight / 10;
                      final slatHeight = blindPosition < 5 
                        ? maxSlatHeight * (5 - blindPosition) / 5
                        : maxSlatHeight * (blindPosition - 5) / 5;
                      
                      return Container(
                        margin: EdgeInsets.only(top: MediaQuery.of(context).size.width * 0.05),
                        height: containerHeight,
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(10, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: slatHeight,
                              width: MediaQuery.of(context).size.width * 0.65,
                              color: const Color.fromARGB(255, 121, 85, 72),
                            );
                          }),
                        ),
                      );
                    }
                  )
                )
              ],
            ),
            // Slider on the side
            Expanded(
              child: Center( 
                child: RotatedBox(
                  quarterTurns: -1,
                  child: Slider(
                    value: blindPosition,
                    activeColor: Theme.of(context).primaryColorDark,
                    thumbColor: Theme.of(context).primaryColorLight,
                    inactiveColor: Theme.of(context).primaryColorDark,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    onChanged: onPositionChanged,
                  ),
                ),
              )
            )
          ],
        ),
      ),
    );
  }
}
