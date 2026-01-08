import 'dart:async';
import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:blind_master/BlindMasterResources/title_text.dart';

abstract class BaseVerificationWaitingScreen extends StatefulWidget {
  const BaseVerificationWaitingScreen({super.key});
}

abstract class BaseVerificationWaitingScreenState<T extends BaseVerificationWaitingScreen> extends State<T> {
  Timer? _pollingTimer;
  bool _isChecking = false;

  // Abstract methods to be implemented by subclasses
  String get title;
  String get mainMessage;
  String? get highlightedInfo => null;
  String get instructionMessage;
  String get successMessage;
  
  Future<bool> checkStatus();
  Future<void> resendVerification();
  void onSuccess();

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
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    if (_isChecking) return;
    
    setState(() {
      _isChecking = true;
    });

    try {
      final isComplete = await checkStatus();
      
      if (isComplete) {
        _pollingTimer?.cancel();
        if (!mounted) return;
        
        onSuccess();
        
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[800],
            duration: Duration(seconds: 4),
            content: Text(
              successMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
          )
        );
      }
    } catch (e) {
      // Silently fail for polling - don't show error to user
      print('Status check failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _handleResend() async {
    try {
      await resendVerification();
      
      if (!mounted) return;
      
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackbar(e)
      );
    }
  }

  Future<void> _onRefresh() async {
    await _checkStatus();
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
                    TitleText(title, txtClr: Colors.white),
                    SizedBox(height: 30),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        mainMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (highlightedInfo != null) ...[
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          highlightedInfo!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
                        instructionMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _handleResend,
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
