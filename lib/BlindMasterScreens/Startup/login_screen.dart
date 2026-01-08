import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:blind_master/BlindMasterScreens/Startup/create_user_screen.dart';
import 'package:blind_master/BlindMasterScreens/Startup/forgot_password_screen.dart';
import 'package:blind_master/BlindMasterScreens/home_screen.dart';
import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/fade_transition.dart';
import 'package:blind_master/BlindMasterResources/text_inputs.dart';
import 'package:blind_master/BlindMasterResources/title_text.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dart:convert';

import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool inputWrong = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> attemptSignIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    final payload = { 
      'email': email,
      'password': password,
    }; // query parameters

    try {
      final response = await regularPost(payload, 'login');
      if (response.statusCode != 200) {
        if (response.statusCode == 400) {throw Exception('Email and Password Necessary');}
        else if (response.statusCode == 403) {
          // Email not verified
          if (!mounted) return;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.orange[700],
              duration: Duration(seconds: 4),
              content: Text(
                "Your account has not been verified. Please check your email from blindmasterapp@wahwa.com and verify your account.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
            )
          );
          return;
        }
        else if (response.statusCode == 429) {
          final body = json.decode(response.body);
          final retryAfter = body['retryAfter'] ?? 'some time';
          throw Exception('Too many login attempts. Please try again in $retryAfter minutes.');
        }
        else if (response.statusCode == 500) {throw Exception('Server Error');}
        else {throw Exception('Incorrect email or password');}
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final token = body['token'] as String;

      if (token.isEmpty) throw Exception('Token Not Received');
      final storage = FlutterSecureStorage();
      await storage.write(key: 'token', value: token);

    } catch(e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackbar(e)
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      fadeTransition(HomeScreen()),
    );
  }

  void switchToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateUserScreen()),
    );
  }

  void switchToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).primaryColorLight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TitleText("BlindMaster"),
            Container(
              padding: EdgeInsets.fromLTRB(40, 10, 40, 10),
              child: Column(
                children: [
                  BlindMasterMainInput("Email", controller: emailController),
                  BlindMasterMainInput("Password", controller: passwordController, password: true),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(bottom:10),
              child: ElevatedButton(
                onPressed: attemptSignIn, 
                child: Text(
                  "Log In"
                ),
              )
            ),
            ElevatedButton(
              onPressed: switchToCreate, 
              child: Text(
                "Create Account"
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: switchToForgotPassword,
              child: Text(
                "Forgot Password?"
              ),
            ),
          ],
        ),
      ),
    );
  }
}