import 'package:blind_master/BlindMasterScreens/Startup/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

Map<String, Color> getBackgroundBasedOnTime() {
  final hour = DateTime.now().hour;
  
  Color secondaryLight;
  Color primary;
  Color secondaryDark;
  if (hour >= 5 && hour < 10) {
    // Morning
    primary = Colors.orange;
    secondaryLight = const Color.fromARGB(255, 255, 204, 128);
    secondaryDark = const Color.fromARGB(255, 174, 104, 0);
  } else if (hour >= 10 && hour < 18) {
    // Afternoon
    primary = Colors.blue;
    secondaryLight = const Color.fromARGB(255, 144, 202, 249);
    secondaryDark = const Color.fromARGB(255, 0, 92, 168);
  } else {
    // Evening/Night
    primary = const Color.fromARGB(255, 71, 17, 137);
    secondaryLight = const Color.fromARGB(255, 186, 130, 255);
    secondaryDark = const Color.fromARGB(255, 40, 0, 89);
  }
  
  return {
    'primary': primary,
    'secondaryLight': secondaryLight,
    'secondaryDark': secondaryDark,
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = getBackgroundBasedOnTime();
    return MaterialApp(
      home: SplashScreen(),
      theme: ThemeData(
        useMaterial3: true,
        primaryColorLight: colors['primary'],
        highlightColor: Colors.black,
        disabledColor: Colors.grey,
        primaryColorDark: colors['secondaryLight'],
        brightness: Brightness.light
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        highlightColor: Colors.white,
        primaryColorLight: colors['primary'],
        disabledColor: Colors.grey[800],
        primaryColorDark: colors['secondaryDark'],
        brightness: Brightness.dark
      ),
    );
  }
}

