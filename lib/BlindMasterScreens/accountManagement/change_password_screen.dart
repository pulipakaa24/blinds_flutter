import 'dart:convert';
import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:blind_master/BlindMasterResources/text_inputs.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String? newPasswordValidator(String? input) {
    if (input == null || input.isEmpty) {
      return 'New password is required';
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
    if (input != newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? oldPasswordValidator(String? input) {
    if (input == null || input.isEmpty) {
      return 'Current password is required';
    }
    return null;
  }

  Future<void> handleChangePassword() async {
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

      final payload = {
        'oldPassword': oldPasswordController.text,
        'newPassword': newPasswordController.text,
      };

      final response = await securePost(payload, 'change_password');

      // Remove loading indicator
      if (mounted) Navigator.of(context).pop();

      if (response == null) {
        throw Exception('No response from server');
      }

      if (response.statusCode == 200) {
        if (!mounted) return;
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[700],
            content: Text('Password changed successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back to account screen
        Navigator.pop(context);
      } else if (response.statusCode == 401) {
        throw Exception('Current password is incorrect');
      } else if (response.statusCode == 400) {
        final body = json.decode(response.body);
        throw Exception(body['error'] ?? 'Invalid request');
      } else {
        throw Exception('Failed to change password');
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
          'Change Password',
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
                Text(
                  'Enter your current password and choose a new password',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                BlindMasterMainInput(
                  'Current Password',
                  controller: oldPasswordController,
                  password: true,
                  validator: oldPasswordValidator,
                ),
                SizedBox(height: 20),
                Divider(),
                SizedBox(height: 20),
                BlindMasterMainInput(
                  'New Password',
                  controller: newPasswordController,
                  password: true,
                  validator: newPasswordValidator,
                ),
                SizedBox(height: 20),
                BlindMasterMainInput(
                  'Confirm New Password',
                  controller: confirmPasswordController,
                  password: true,
                  validator: confirmPasswordValidator,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: handleChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColorLight,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    'Change Password',
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
