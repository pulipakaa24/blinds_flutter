import 'dart:convert';
import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:blind_master/BlindMasterResources/text_inputs.dart';
import 'package:blind_master/BlindMasterScreens/accountManagement/verify_email_change_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangeEmailScreen extends StatefulWidget {
  final String currentEmail;
  
  const ChangeEmailScreen({super.key, required this.currentEmail});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final passwordController = TextEditingController();
  final newEmailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    passwordController.dispose();
    newEmailController.dispose();
    super.dispose();
  }

  String? passwordValidator(String? input) {
    if (input == null || input.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  String? emailValidator(String? input) {
    if (input == null || input.isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(input)) {
      return 'Please enter a valid email';
    }
    if (input == widget.currentEmail) {
      return 'This is your current email';
    }
    return null;
  }

  Future<void> handleChangeEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColorLight,
            ),
          );
        },
      );

      final localHour = DateTime.now().hour;
      final payload = {
        'password': passwordController.text,
        'newEmail': newEmailController.text,
        'localHour': localHour,
      };

      final response = await securePost(payload, 'request-email-change');

      // Remove loading indicator
      if (mounted) Navigator.of(context).pop();

      if (response == null) {
        throw Exception('No response from server');
      }

      if (response.statusCode == 200) {
        if (!mounted) return;
        
        // Navigate to waiting screen
        final success = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailChangeWaitingScreen(newEmail: newEmailController.text),
          ),
        );

        // If email was changed successfully, return true to refresh account info
        if (success == true && mounted) {
          Navigator.pop(context, true);
        }
      } else if (response.statusCode == 401) {
        throw Exception('Password is incorrect');
      } else if (response.statusCode == 409) {
        throw Exception('Email already in use');
      } else if (response.statusCode == 400) {
        final body = json.decode(response.body);
        throw Exception(body['error'] ?? 'Invalid request');
      } else {
        throw Exception('Failed to send verification email');
      }
    } catch (e) {
      // Remove loading indicator if still showing
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColorLight,
        foregroundColor: Colors.white,
        title: Text(
          'Change Email',
          style: GoogleFonts.aBeeZee(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUnfocus,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),
                // Current email display
                Card(
                  elevation: 2,
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            SizedBox(width: 10),
                            Text(
                              'Current Email',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.currentEmail,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Warning card
                Card(
                  elevation: 2,
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange[700]),
                            SizedBox(width: 10),
                            Text(
                              'Important',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'After changing your email, ${widget.currentEmail} will no longer receive any communications from BlindMaster, including password reset codes.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  'Verify your identity and enter new email',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                BlindMasterMainInput(
                  'Current Password',
                  controller: passwordController,
                  password: true,
                  validator: passwordValidator,
                ),
                SizedBox(height: 20),
                Divider(),
                SizedBox(height: 20),
                BlindMasterMainInput(
                  'New Email Address',
                  controller: newEmailController,
                  validator: emailValidator,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: handleChangeEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColorLight,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    'Send Verification Email',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
