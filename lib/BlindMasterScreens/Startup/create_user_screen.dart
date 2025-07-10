import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:flutter/material.dart';

import 'package:blind_master/BlindMasterResources/text_inputs.dart';
import 'package:blind_master/BlindMasterResources/title_text.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {

  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();

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
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green[800],
              content: Text(
                "Account Successfully Created!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
            )
          );
          Navigator.pop(context);
        }
      } else {
        if (response.statusCode == 409) throw Exception('Email Already In Use!');
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

  String? confirmPasswordValidator(String? input) {
    if (input == passwordController.text) {
      return null;
    }
    else {
      return "Passwords do not match!";
    }
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
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        BlindMasterMainInput(
                          "Password",
                          password: true, 
                          controller: passwordController
                        ),
                        BlindMasterMainInput(
                          "Confirm Password",
                          validator: confirmPasswordValidator,
                          password: true,
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