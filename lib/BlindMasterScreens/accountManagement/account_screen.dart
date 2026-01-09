import 'dart:convert';
import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:blind_master/BlindMasterScreens/accountManagement/change_password_screen.dart';
import 'package:blind_master/BlindMasterScreens/accountManagement/change_email_screen.dart';
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

  Future<void> _handleDeleteAccount() async {
    final primaryColor = Theme.of(context).primaryColorLight;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 10),
              Text('Delete Account'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete your account?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('This action cannot be undone. All your data will be permanently deleted.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('Delete Account'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext loadingContext) {
            return Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          },
        );

        final response = await secureDelete('delete_account');

        // Remove loading indicator
        if (mounted) Navigator.of(context).pop();

        if (response == null) {
          throw Exception('No response from server');
        }

        if (response.statusCode == 200) {
          if (!mounted) return;
          
          // Navigate to splash screen (remove all routes)
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        } else {
          final body = json.decode(response.body);
          throw Exception(body['error'] ?? 'Failed to delete account');
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
  }

  Future<void> _handleChangeEmail() async {
    if (email == null || email == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: Text('Unable to load current email'),
        ),
      );
      return;
    }

    // Navigate to change email screen
    final success = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeEmailScreen(currentEmail: email!),
      ),
    );

    // If email was changed successfully, refresh account info
    if (success == true && mounted) {
      await fetchAccountInfo();
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
                          ListTile(
                            leading: Icon(Icons.email_outlined),
                            title: Text('Change Email'),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: _handleChangeEmail,
                          ),
                          Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.lock_outline),
                            title: Text('Change Password'),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChangePasswordScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    
                    // Danger Zone Section
                    Text(
                      'Danger Zone',
                      style: GoogleFonts.aBeeZee(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 15),
                    Card(
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(Icons.delete_forever, color: Colors.red),
                        title: Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.red),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                        onTap: _handleDeleteAccount,
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
