import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../email_verification_waiting_screen.dart';

class VerificationWaitingScreen extends BaseVerificationWaitingScreen {
  final String token;
  
  const VerificationWaitingScreen({super.key, required this.token});

  @override
  State<VerificationWaitingScreen> createState() => _VerificationWaitingScreenState();
}

class _VerificationWaitingScreenState extends BaseVerificationWaitingScreenState<VerificationWaitingScreen> {
  @override
  String get title => "Verify Your Email";

  @override
  String get mainMessage => "We've sent a verification link to your email from blindmasterapp@wahwa.com";

  @override
  String get instructionMessage => "Click the link in the email to verify your account. This page will automatically update once verified.";

  @override
  String get successMessage => "Account verified successfully! You can now log in.";

  @override
  Future<bool> checkStatus() async {
    final uri = Uri.parse('https://wahwa.com').replace(path: 'verification_status');
    
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['is_verified'] == true;
    }
    return false;
  }

  @override
  Future<void> resendVerification() async {
    final localHour = DateTime.now().hour;
    final uri = Uri.parse('https://wahwa.com').replace(path: 'resend_verification');
    
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: json.encode({'localHour': localHour}),
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 429) {
      final body = json.decode(response.body);
      final retryAfter = body['retryAfter'] ?? 20;
      throw Exception('Please wait $retryAfter seconds before requesting another email.');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to resend verification email');
    }
  }

  @override
  void onSuccess() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
