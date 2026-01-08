import 'dart:convert';
import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? name;
  String? email;
  String? createdAt;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAccountInfo();
  }

  Future<void> fetchAccountInfo() async {
    try {
      final response = await secureGet('account_info');
      
      if (response == null) {
        throw Exception('No response from server');
      }

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        setState(() {
          name = body['name'] ?? 'N/A';
          email = body['email'] ?? 'N/A';
          
          // Parse and format the created_at timestamp
          if (body['created_at'] != null) {
            try {
              final DateTime dateTime = DateTime.parse(body['created_at']);
              final months = ['January', 'February', 'March', 'April', 'May', 'June',
                             'July', 'August', 'September', 'October', 'November', 'December'];
              createdAt = '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
            } catch (e) {
              createdAt = 'N/A';
            }
          } else {
            createdAt = 'N/A';
          }
          
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load account info');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColorLight,
        foregroundColor: Colors.white,
        title: Text(
          'Account',
          style: GoogleFonts.aBeeZee(),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColorLight,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Info Section
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Theme.of(context).primaryColorLight,
                                child: Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            _buildInfoRow('Name', name ?? 'N/A'),
                            Divider(height: 30),
                            _buildInfoRow('Email', email ?? 'N/A'),
                            Divider(height: 30),
                            _buildInfoRow('Member Since', createdAt ?? 'N/A'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    
                    // Account Options Section
                    Text(
                      'Account Options',
                      style: GoogleFonts.aBeeZee(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 15),
                    Card(
                      elevation: 2,
                      child: Column(
                        children: [
                          // Placeholder for future options
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Center(
                              child: Text(
                                'Additional options will appear here',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
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

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
