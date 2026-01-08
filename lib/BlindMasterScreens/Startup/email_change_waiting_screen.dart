import 'dart:async';
import 'dart:convert';

import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:flutter/material.dart';
import '../email_verification_waiting_screen.dart';

class EmailChangeWaitingScreen extends BaseVerificationWaitingScreen {
  final String newEmail;
  
  const EmailChangeWaitingScreen({super.key, required this.newEmail});

  @override
  State<EmailChangeWaitingScreen> createState() => _EmailChangeWaitingScreenState();
}

class _EmailChangeWaitingScreenState extends BaseVerificationWaitingScreenState<EmailChangeWaitingScreen> {
  @override
  String get title => "Verify New Email";

  @override
  String get mainMessage => "We've sent a verification link to:";

  @override
  String? get highlightedInfo => widget.newEmail;

  @override
  String get instructionMessage => "Click the link in the email to verify your new email address. This page will automatically update once verified.";

  @override
  String get successMessage => "Email changed successfully!";

  @override
  Future<bool> checkStatus() async {
    final response = await secureGet('pending-email-status');
    
    if (response == null) {
      throw Exception('No response from server');
    }
    
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['hasPending'] == false;
    }
    return false;
  }

  @override
  Future<void> resendVerification() async {
    final localHour = DateTime.now().hour;
    final response = await securePost(
      {
        'newEmail': widget.newEmail,
        'localHour': localHour,
      },
      'request-email-change',
    );
    
    if (response == null) {
      throw Exception('No response from server');
    }
    
    if (response.statusCode != 200) {
      final body = json.decode(response.body);
      throw Exception(body['error'] ?? 'Failed to resend verification email');
    }
  }

  @override
  void onSuccess() {
    Navigator.of(context).pop(true); // Return true to indicate success
  }
}
