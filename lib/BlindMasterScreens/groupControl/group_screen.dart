import 'dart:convert';

import 'package:blind_master/BlindMasterResources/blindmaster_progress_indicator.dart';
import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key, required this.groupId, required this.groupName});
  final int groupId;
  final String groupName;
  
  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  String imagePath = "";
  bool loaded = false;
  double _blindPosition = 5.0;
  List<Map<String, dynamic>> peripherals = [];
  bool allCalibrated = false;

  void getImage() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 10) {
      imagePath = 'assets/images/MorningSill.png';
    } else if (hour >= 10 && hour < 18) {
      imagePath = 'assets/images/NoonSill.png';
    } else if (hour >= 18 && hour < 22) {
      imagePath = 'assets/images/EveningSill.png';
    } else {
      imagePath = 'assets/images/NightSill.png';
    }
  }

  @override
  void initState() {
    super.initState();
    initAll();
  }

  Future<void> getGroupDetails() async {
    try {
      final payload = {'groupId': widget.groupId.toString()};
      final response = await secureGet('group_details', queryParameters: payload);
      
      if (response == null) throw Exception("auth error");
      if (response.statusCode != 200) throw Exception("Server Error");
      
      final body = json.decode(response.body);
      peripherals = List<Map<String, dynamic>>.from(body['peripherals']);
      
      // Check if all peripherals are calibrated
      allCalibrated = peripherals.every((p) => p['calibrated'] == true);
      
      // Set position to average of all peripheral positions
      if (peripherals.isNotEmpty) {
        final avgPos = peripherals.map((p) => p['last_pos'] as int).reduce((a, b) => a + b) / peripherals.length;
        _blindPosition = avgPos.toDouble();
      }
      
      getImage();
      setState(() => loaded = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  Future initAll() async {
    await getGroupDetails();
  }

  Future updateGroupPosition() async {
    try {
      final payload = {
        'groupId': widget.groupId,
        'newPos': _blindPosition.toInt(),
      };

      final response = await securePost(payload, 'group_position_update');
      if (response == null) throw Exception("Auth Error");
      if (response.statusCode != 202) {
        throw Exception("Server Error");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.groupName,
          style: GoogleFonts.aBeeZee(),
        ),
        backgroundColor: Theme.of(context).primaryColorLight,
        foregroundColor: Colors.white,
      ),
      body: loaded 
      ? (allCalibrated
      ? Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Container(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.15,
                  ),
                  Stack(
                    children: [
                      // Background image
                      Align(
                        alignment: Alignment.center,
                        child: Image.asset(
                          imagePath,
                          width: MediaQuery.of(context).size.width * 0.7,
                        ),
                      ),

                      Align(
                        alignment: Alignment.center,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final containerHeight = MediaQuery.of(context).size.width * 0.68;
                            final maxSlatHeight = containerHeight / 10;
                            final slatHeight = _blindPosition < 5 
                              ? maxSlatHeight * (5 - _blindPosition) / 5
                              : maxSlatHeight * (_blindPosition - 5) / 5;
                            
                            return Container(
                              margin: EdgeInsets.only(top: MediaQuery.of(context).size.width * 0.05),
                              height: containerHeight,
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(10, (index) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: slatHeight,
                                    width: MediaQuery.of(context).size.width * 0.65,
                                    color: const Color.fromARGB(255, 121, 85, 72),
                                  );
                                }),
                              ),
                            );
                          }
                        )
                      )
                    ],
                  ),
                  // Slider on the side
                  Expanded(
                    child: Center( 
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: Slider(
                          value: _blindPosition,
                          activeColor: Theme.of(context).primaryColorDark,
                          thumbColor: Theme.of(context).primaryColorLight,
                          inactiveColor: Theme.of(context).primaryColorDark,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          onChanged: (value) {
                            setState(() {
                              _blindPosition = value;
                              updateGroupPosition();
                            });
                          },
                        ),
                      ),
                    )
                  )
                ],
              ),
            )
          ),
          Container(
            padding: EdgeInsets.all(25),
            child: Text(
              '${peripherals.length} blind${peripherals.length != 1 ? 's' : ''} in this group'
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: () {
                // TODO: Navigate to group schedules screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group schedules coming soon!'))
                );
              },
              child: Text(
                "Set Group Schedules"
              )
            ),
          )
        ]
      )
      : SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Some blinds in this group are not calibrated",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Uncalibrated blinds:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ...peripherals.where((p) => p['calibrated'] != true).map((p) => 
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(p['peripheral_name']),
                )
              ),
            ],
          )
        )
      ))
      : BlindmasterProgressIndicator(),
      floatingActionButton: Container(
        padding: EdgeInsets.all(25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: "placeholder1",
              tooltip: "Placeholder",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!'))
                );
              },
              foregroundColor: Theme.of(context).highlightColor,
              backgroundColor: Theme.of(context).primaryColorDark,
              child: Icon(Icons.settings),
            ),
            FloatingActionButton(
              heroTag: "placeholder2",
              tooltip: "Placeholder",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!'))
                );
              },
              foregroundColor: Theme.of(context).highlightColor,
              backgroundColor: Theme.of(context).primaryColorDark,
              child: Icon(Icons.tune),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
