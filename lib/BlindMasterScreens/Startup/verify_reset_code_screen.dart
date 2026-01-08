import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../BlindMasterResources/secure_transmissions.dart';
import 'reset_password_form_screen.dart';

class VerifyResetCodeScreen extends StatefulWidget {
  final String email;

  const VerifyResetCodeScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyResetCodeScreen> createState() => _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends State<VerifyResetCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String? _codeValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the reset code';
    }
    if (value.length != 6) {
      return 'Code must be 6 characters';
    }
    return null;
  }

  Future<void> _handleVerifyCode() async {
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
          'code': _codeController.text.trim().toUpperCase(),
        },
        '/verify-reset-code',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordFormScreen(
              email: widget.email,
              code: _codeController.text.trim().toUpperCase(),
            ),
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
      } else if (response.statusCode == 401) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final remainingAttempts = body['remainingAttempts'] ?? 0;
        String message = body['error'] ?? 'Invalid or expired code';
        if (remainingAttempts > 0) {
          message += '\n$remainingAttempts attempts remaining before timeout.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange[700],
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        final body = json.decode(response.body) as Map<String, dynamic>;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['error'] ?? 'Invalid or expired code'),
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

  Future<void> _handleResendCode() async {
    setState(() {
      _isResending = true;
    });

    try {
      final response = await regularPost(
        {
          'email': widget.email,
        },
        '/forgot-password',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('A new code has been sent to your email'),
            backgroundColor: Theme.of(context).primaryColorLight,
          ),
        );
        _codeController.clear();
      } else if (response.statusCode == 429) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final retryAfter = body['retryAfter'] ?? 'some time';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please wait $retryAfter seconds before requesting another code.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        final body = json.decode(response.body) as Map<String, dynamic>;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['error'] ?? 'Failed to resend code'),
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
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Code'),
        backgroundColor: Theme.of(context).primaryColorLight,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_read,
                    size: 80,
                    color: Theme.of(context).primaryColorLight,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Check Your Email',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We\'ve sent a 6-character code to ${widget.email}. Enter it below to continue.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Reset Code',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.security),
                      hintText: 'ABC123',
                    ),
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    ],
                    validator: _codeValidator,
                    enabled: !_isLoading && !_isResending,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading || _isResending ? null : _handleVerifyCode,
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
                            'Verify Code',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading || _isResending ? null : _handleResendCode,
                    child: _isResending
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColorLight),
                            ),
                          )
                        : Text(
                            'Didn\'t receive the code? Resend',
                            style: TextStyle(
                              color: Theme.of(context).primaryColorLight,
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
