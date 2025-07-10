import 'package:blind_master/BlindMasterScreens/groupControl/groups_menu.dart';
import 'package:blind_master/BlindMasterScreens/individualControl/devices_menu.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentPageIndex = 0;
  String greeting = "";

  @override
  void initState() {
    super.initState();
    getGreeting();
  }

  void getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      greeting = "Good Morning!";
    } else if (hour >= 12 && hour < 18) {
      greeting = "Good Afternoon!";
    } else if (hour >= 18 && hour < 22) {
      greeting = "Good Evening!";
    } else {greeting = "😴";}
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