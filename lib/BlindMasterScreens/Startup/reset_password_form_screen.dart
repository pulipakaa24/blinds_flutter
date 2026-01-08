import 'package:flutter/material.dart';
import 'dart:convert';
import '../../BlindMasterResources/secure_transmissions.dart';
import '../../BlindMasterResources/text_inputs.dart';
import 'login_screen.dart';

class ResetPasswordFormScreen extends StatefulWidget {
  final String email;
  final String code;

  const ResetPasswordFormScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordFormScreen> createState() => _ResetPasswordFormScreenState();
}

class _ResetPasswordFormScreenState extends State<ResetPasswordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await regularPost(
        {
          'email': widget.email,
          'code': widget.code,
          'newPassword': _passwordController.text,
        },
        '/reset-password',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Navigate back to login screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully! Please log in with your new password.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else if (response.statusCode == 429) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final retryAfter = body['retryAfter'] ?? 'some time';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Too many attempts. Please try again in $retryAfter minutes.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        final body = json.decode(response.body) as Map<String, dynamic>;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['error'] ?? 'Failed to reset password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Theme.of(context).primaryColorLight,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUnfocus,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_open,
                    size: 80,
                    color: Theme.of(context).primaryColorLight,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Create New Password',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter your new password below.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  BlindMasterMainInput(
                    'New Password',
                    controller: _passwordController,
                    password: true,
                    validator: _passwordValidator,
                  ),
                  BlindMasterMainInput(
                    'Confirm New Password',
                    controller: _confirmPasswordController,
                    password: true,
                    validator: _confirmPasswordValidator,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColorLight,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
