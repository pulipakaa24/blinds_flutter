import 'dart:convert';
import 'package:blind_master/BlindMasterScreens/groupControl/groups_menu.dart';
import 'package:blind_master/BlindMasterScreens/individualControl/devices_menu.dart';
import 'package:blind_master/BlindMasterScreens/Startup/splash_screen.dart';
import 'package:blind_master/BlindMasterScreens/accountManagement/account_screen.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentPageIndex = 0;
  String greeting = "";
  String? userName;

  @override
  void initState() {
    super.initState();
    fetchUserName();
    getGreeting();
  }

  Future<void> fetchUserName() async {
    try {
      final response = await secureGet('account_info');
      
      if (response != null && response.statusCode == 200) {
        final body = json.decode(response.body);
        final name = body['name'];
        
        // Only set userName if it's not null, not empty, and not just whitespace
        if (name != null && name.toString().trim().isNotEmpty) {
          setState(() {
            userName = name.toString().trim();
            getGreeting(); // Update greeting with name
          });
        }
      }
    } catch (e) {
      // Silently fail - user will just see generic greeting
    }
  }

  void getGreeting() {
    final hour = DateTime.now().hour;
    String timeGreeting;

    if (hour >= 5 && hour < 12) {
      timeGreeting = "Good Morning";
    } else if (hour >= 12 && hour < 18) {
      timeGreeting = "Good Afternoon";
    } else if (hour >= 18 && hour < 22) {
      timeGreeting = "Good Evening";
    } else {
      greeting = "😴";
      return;
    }

    // Add name if available, otherwise just add exclamation mark
    greeting = userName != null ? "$timeGreeting, $userName!" : "$timeGreeting!";
  }

  Future<void> handleLogout() async {
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

      // Call logout endpoint
      final response = await securePost({}, 'logout');
      
      // Remove loading indicator
      if (mounted) Navigator.of(context).pop();

      if (response == null || response.statusCode != 200) {
        throw Exception('Logout failed');
      }

      // Clear stored token
      final storage = FlutterSecureStorage();
      await storage.delete(key: 'token');

      // Navigate to splash screen (which will redirect to login)
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => SplashScreen()),
        (route) => false,
      );
    } catch (e) {
      // Remove loading indicator if still showing
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackbar(e)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColorLight,
        centerTitle: false,
        title: Text(
          greeting,
          style: GoogleFonts.aBeeZee(),
        ),
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColorLight,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.blinds,
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'BlindMaster',
                    style: GoogleFonts.aBeeZee(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            Divider(),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Account'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AccountScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                handleLogout();
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Theme.of(context).primaryColorDark,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.blinds_rounded),
            icon: Icon(Icons.blinds_closed_rounded),
            label: 'Devices',
          ),
          NavigationDestination(
            icon: Icon(Icons.window_outlined),
            selectedIcon: Icon(Icons.window_rounded),
            label: 'Groups',
          ),
        ],
      ),
      body:
          <Widget>[
            DevicesMenu(),
            GroupsMenu(),
          ][currentPageIndex],
    );
  }
}