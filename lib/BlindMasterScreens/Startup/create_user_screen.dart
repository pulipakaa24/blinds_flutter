import 'dart:convert';

import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:flutter/material.dart';

import 'package:blind_master/BlindMasterResources/text_inputs.dart';
import 'package:blind_master/BlindMasterResources/title_text.dart';
import 'package:blind_master/BlindMasterScreens/Startup/verification_waiting_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {

  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final _passFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  Future<void> attemptCreate() async{
    try {
      if (!_emailFormKey.currentState!.validate() || !_passFormKey.currentState!.validate()) {
        throw Exception('Invalid information entered!');
      }

      final payload = {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text,
      };

      final response = await regularPost(payload, 'create_user');

      if (response.statusCode == 201) {
        if(mounted) {
          // Extract token from response body
          final body = json.decode(response.body);
          final token = body['token'];
          
          if (token != null && token.isNotEmpty) {
            // Store token temporarily for verification checking
            final storage = FlutterSecureStorage();
            await storage.write(key: 'temp_token', value: token);
            
            // Navigate to verification waiting screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerificationWaitingScreen(token: token),
              ),
            );
          } else {
            throw Exception('No token received from server');
          }
        }
      } else {
        if (response.statusCode == 409) throw Exception('Email Already In Use!');
        if (response.statusCode == 429) {
          final body = json.decode(response.body);
          final retryAfter = body['retryAfter'] ?? 'some time';
          throw Exception('Too many account creation attempts. Please try again in $retryAfter minutes.');
        }
        throw Exception('Create failed: ${response.statusCode}');
      }

    } catch(e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackbar(e)
      );
      return;
    }
    
  }

  String? passwordValidator(String? input) {
    if (input == null || input.isEmpty) {
      return 'Password is required';
    }
    if (input.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? confirmPasswordValidator(String? input) {
    if (input == null || input.isEmpty) {
      return 'Please confirm your password';
    }
    if (input != passwordController.text) {
      return "Passwords do not match!";
    }
    return null;
  }

  String? emailValidator(String? input) {
    if (input == null || input.isEmpty) {
      return 'Email is required';
    }

    final emailPattern = r'^[^@]+@[^@]+\.[^@]+$';

    if (!RegExp(emailPattern).hasMatch(input)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).primaryColorLight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TitleText("Create Account", txtClr: Colors.white),
            Container(
              padding: EdgeInsets.fromLTRB(40, 10, 40, 10),
              child: Column(
                children: [
                  BlindMasterMainInput("Preferred Name (optional)", controller: nameController),
                  SizedBox(height: 20),
                  Form(
                    key: _emailFormKey,
                    autovalidateMode: AutovalidateMode.onUnfocus,
                    child: BlindMasterMainInput(
                      "Email",
                      controller: emailController,
                      validator: emailValidator,
                    ),
                  ),
                  Form(
                    key: _passFormKey,
                    autovalidateMode: AutovalidateMode.onUnfocus,
                    child: Column(
                      children: [
                        BlindMasterMainInput(
                          "Password",
                          password: true, 
                          controller: passwordController,
                          validator: passwordValidator,
                        ),
                        BlindMasterMainInput(
                          "Confirm Password",
                          validator: confirmPasswordValidator,
                          password: true,
                          controller: confirmPasswordController,
                        )
                      ],
                    )
                  )
                ],
              ),
            ),
            ElevatedButton(
              onPressed: attemptCreate, 
              child: Text(
                "Create"
              ),
            )
          ],
        ),
      ),
    );
  }
}