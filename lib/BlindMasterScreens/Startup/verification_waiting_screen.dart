import 'dart:async';
import 'dart:convert';

import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:blind_master/BlindMasterResources/title_text.dart';
import 'package:http/http.dart' as http;

class VerificationWaitingScreen extends StatefulWidget {
  final String token;
  
  const VerificationWaitingScreen({super.key, required this.token});

  @override
  State<VerificationWaitingScreen> createState() => _VerificationWaitingScreenState();
}

class _VerificationWaitingScreenState extends State<VerificationWaitingScreen> {
  Timer? _pollingTimer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkVerificationStatus();
    });
  }

  Future<void> _checkVerificationStatus() async {
    if (_isChecking) return;
    
    setState(() {
      _isChecking = true;
    });

    try {
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
        if (body['is_verified'] == true) {
          _pollingTimer?.cancel();
          if (!mounted) return;
          
          Navigator.of(context).popUntil((route) => route.isFirst);
          
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green[800],
              duration: Duration(seconds: 4),
              content: Text(
                "Account verified successfully! You can now log in.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
            )
          );
        }
      }
    } catch (e) {
      // Silently fail for polling - don't show error to user
      print('Verification status check failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      final uri = Uri.parse('https://wahwa.com').replace(path: 'resend_verification');
      
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({}),
      ).timeout(const Duration(seconds: 10));
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[800],
            content: Text(
              "Verification email sent! Please check your inbox.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
          )
        );
      } else if (response.statusCode == 429) {
        final body = json.decode(response.body);
        final retryAfter = body['retryAfter'] ?? 20;
        throw Exception('Please wait $retryAfter seconds before requesting another email.');
      } else {
        throw Exception('Failed to resend verification email');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackbar(e)
      );
    }
  }

  Future<void> _onRefresh() async {
    await _checkVerificationStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Container(
          color: Theme.of(context).primaryColorLight,
          child: ListView(
            physics: AlwaysScrollableScrollPhysics(),
            children: [
              Container(
                height: MediaQuery.of(context).size.height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TitleText("Verify Your Email", txtClr: Colors.white),
                    SizedBox(height: 30),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        "We've sent a verification link to your email from blindmasterapp@wahwa.com",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    if (_isChecking)
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    else
                      Icon(
                        Icons.email_outlined,
                        size: 80,
                        color: Colors.white70,
                      ),
                    SizedBox(height: 30),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        "Click the link in the email to verify your account. This page will automatically update once verified.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _resendVerificationEmail,
                      child: Text("Resend Verification Email"),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        "Pull down to check verification status manually",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
