import 'dart:convert';

import 'package:blind_master/BlindMasterResources/blind_control_widget.dart';
import 'package:blind_master/BlindMasterResources/blindmaster_progress_indicator.dart';
import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:blind_master/BlindMasterResources/text_inputs.dart';
import 'package:blind_master/BlindMasterScreens/groupControl/edit_group_dialog.dart';
import 'package:blind_master/BlindMasterScreens/schedules_screen.dart';
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
  String currentGroupName = "";
  
  final _groupRenameController = TextEditingController();

  @override
  void dispose() {
    _groupRenameController.dispose();
    super.dispose();
  }

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
    currentGroupName = widget.groupName;
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

  void rename() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            "Rename Group",
            style: GoogleFonts.aBeeZee(),
          ),
          content: BlindMasterMainInput("New Group Name", controller: _groupRenameController),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.red
                    ),
                  )
                ),
                ElevatedButton(
                  onPressed: () {
                    updateGroupName(_groupRenameController.text, widget.groupId);
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColorDark,
                    foregroundColor: Theme.of(context).highlightColor,
                  ),
                  child: const Text("Rename")
                )
              ]
            )
          ],
        );
      }
    );
  }

  Future updateGroupName(String name, int id) async {
    try {
      if (name.isEmpty) throw Exception("New name cannot be empty!");
      final payload = {
        'groupId': id,
        'newName': name,
      };
      final response = await securePost(payload, 'rename_group');
      if (response == null) throw Exception("Auth Error");
      if (response.statusCode != 204) {
        if (response.statusCode == 409) throw Exception("Choose a unique name!");
        throw Exception("Server Error");
      }
      if (!mounted) return;
      setState(() {
        currentGroupName = name;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group renamed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  void editMembers() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return EditGroupDialog(
          groupId: widget.groupId,
          groupName: currentGroupName,
          currentPeripheralIds: peripherals.map((p) => p['peripheral_id'] as int).toList(),
        );
      }
    ).then((_) {
      // Refresh group details after editing
      getGroupDetails();
    });
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
          currentGroupName,
          style: GoogleFonts.aBeeZee(),
        ),
        backgroundColor: Theme.of(context).primaryColorLight,
        foregroundColor: Colors.white,
      ),
      body: loaded 
      ? (allCalibrated
      ? Column(
        children: [
          BlindControlWidget(
            imagePath: imagePath,
            blindPosition: _blindPosition,
            onPositionChanged: (value) {
              setState(() {
                _blindPosition = value;
                updateGroupPosition();
              });
            },
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SchedulesScreen(
                      groupId: widget.groupId,
                      groupName: currentGroupName,
                    )
                  )
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
              heroTag: "rename",
              tooltip: "Rename Group",
              onPressed: rename,
              foregroundColor: Theme.of(context).highlightColor,
              backgroundColor: Theme.of(context).primaryColorDark,
              child: Icon(Icons.drive_file_rename_outline_sharp),
            ),
            FloatingActionButton(
              heroTag: "editMembers",
              tooltip: "Edit Group Members",
              onPressed: editMembers,
              foregroundColor: Theme.of(context).highlightColor,
              backgroundColor: Theme.of(context).primaryColorDark,
              child: Icon(Icons.format_list_bulleted_sharp),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
