import 'dart:async';
import 'dart:convert';

import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:blind_master/BlindMasterScreens/home_screen.dart';
import 'package:blind_master/BlindMasterScreens/Startup/login_screen.dart';
import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/fade_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Widget nextScreen = LoginScreen();

  @override
  void initState() {
    super.initState();
    _routeNext();
  }

  Future<void> _routeNext() async {
    await verifyToken();
    _animateBackgroundBasedOnTime();
  }

  Future<void> verifyToken() async{
    final storage = FlutterSecureStorage();

    try {
      http.Response? response = await secureGet('verify');
      if (response == null) {
        nextScreen = LoginScreen();
        return;
      }

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final newToken = body['token'];

        if (newToken != null) {
          await storage.write(key: 'token', value: newToken); // ✅ Rotate
        }
        
        nextScreen = HomeScreen();
      } else {
        nextScreen = LoginScreen();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackbar(e)
      );
      nextScreen = LoginScreen();
    }
  }

  void _animateBackgroundBasedOnTime() {

    // Optionally navigate to your main app after a short delay
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        // MaterialPageRoute(builder: (context) => const MainAppScreen())
        fadeTransition(nextScreen),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        color: Theme.of(context).primaryColorLight,
        child: Center(
          child: Image.asset('assets/images/2xwhite.png', height: 250)
        ),
      ),
    );
  }
}