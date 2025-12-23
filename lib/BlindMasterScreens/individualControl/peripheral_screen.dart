import 'dart:convert';

import 'package:blind_master/BlindMasterResources/blindmaster_progress_indicator.dart';
import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:blind_master/BlindMasterResources/text_inputs.dart';
import 'package:blind_master/BlindMasterScreens/schedules_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class PeripheralScreen extends StatefulWidget {
  const PeripheralScreen({super.key, required this.peripheralId, required this.deviceId, required this.peripheralNum, required this.deviceName});
  final int peripheralId;
  final int peripheralNum;
  final int deviceId;
  final String deviceName;
  @override
  State<PeripheralScreen> createState() => _PeripheralScreenState();
}

class _PeripheralScreenState extends State<PeripheralScreen> {
  IO.Socket? socket;
  String imagePath = "";
  String peripheralName = "...";
  bool loaded = false;
  bool calibrated = false;
  bool calibrating = false;
  double _blindPosition = 5.0;
  DateTime? lastSet;
  String lastSetMessage = "";

  final _peripheralRenameController = TextEditingController();

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
    initSocket();
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }

  Future<void> initSocket() async {
    try {
      socket = await connectSocket();
      if (socket == null) throw Exception("Unsuccessful socket connection");
      socket?.on("success", (_) {
        socket?.on("posUpdates", (list) {
          for (var update in list) {
            if (update is Map<String, dynamic>) {
              if (update['periphID'] == widget.peripheralId) {
                if (!mounted) return;
                setState(() {
                  _blindPosition = (update['pos'] as int).toDouble();
                });
              }
            }
          }
        });
        socket?.on("calib", (periphData) {
          if (periphData is Map<String, dynamic>) {
            if (periphData['periphID'] == widget.peripheralId) {
              if (!mounted) return;
              setState(() {
                calibrating = true;
                calibrated = false;
              });
            }
          }
        });
        socket?.on("calib_done", (periphData) {
          if (periphData is Map<String, dynamic>) {
            if (periphData['periphID'] == widget.peripheralId) {
              if (!mounted) return;
              setState(() {
                calibrating = false;
                calibrated = true;
              });
            }
          }
        });
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  Future<void> calibrate() async {
    try {
      final payload = {
        'periphId': widget.peripheralId
      };

      final response = await securePost(payload, 'calib');
      
      if (response == null) throw Exception("auth error");
      if (response.statusCode != 202) throw Exception("Server Error");
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  Future<void> cancelCalib() async {
    try {
      final payload = {
        'periphId': widget.peripheralId
      };

      final response = await securePost(payload, 'cancel_calib');
      
      if (response == null) throw Exception("auth error");
      if (response.statusCode != 202) throw Exception("Server Error");
      setState(() {
        calibrated = false;
        calibrating = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  Future<void> getName() async {
    try {
      final payload = {
        'periphId': widget.peripheralId
      };
      final response = await secureGet('peripheral_name', queryParameters: payload);
      if (response == null) throw Exception("auth error");
      if (response.statusCode != 200) throw Exception("Server Error");
      final body = json.decode(response.body);
      setState(() => peripheralName = body['name']);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  Future loop() async{
    try {
      final payload = {
        'periphId': widget.peripheralId
      };

      final response = await secureGet('peripheral_status', queryParameters: payload);
      if (response == null) throw Exception("auth error");
      if (response.statusCode != 200) {
        if (response.statusCode == 404) throw Exception("Device Not Found");
        throw Exception("Server Error");
      }
      final body = json.decode(response.body) as Map<String, dynamic>;
      if (!body['await_calib']){
        if (!body['calibrated']) {
          calibrated = false;
          calibrating = false;
        }
        else {
          getImage();
          final nowUtc = DateTime.now().toUtc();
          final lastSetUtc = DateTime.parse(body['last_set']);
          final Duration difference = nowUtc.difference(lastSetUtc);
          if (!lastSetUtc.isUtc) throw Exception("Why isn't the server giving UTC?");
          final diffDays = difference.inDays > 0;
          final diffHours = difference.inHours > 0;
          final diffMins = difference.inMinutes > 0;
          lastSetMessage = "Last set ${diffDays ? '${difference.inDays.toString()} days' : diffHours ? '${difference.inHours.toString()} hours' : diffMins ? '${difference.inMinutes.toString()} minutes' : '${difference.inSeconds.toString()} seconds'} ago";
          _blindPosition = (body['last_pos'] as int).toDouble();

          calibrated = true;
          calibrating = false;
        }
      }
      else {
        calibrating = true;
      }
      
      setState(() {loaded = true;});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  Future initAll() async{
    getName();
    loop();
  }

  void rename() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            "Rename Peripheral",
            style: GoogleFonts.aBeeZee(),
          ),
          content: BlindMasterMainInput("New Peripheral Name", controller: _peripheralRenameController,),
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
                    updatePeriphName(_peripheralRenameController.text, widget.peripheralId);
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text("Confirm")
                )
              ],
            )
          ],
        );
      }
    );
  }

  Future updatePeriphName(String name, int id) async {
    try {
      if (name.isEmpty) throw Exception("New name cannot be empty!");
      final payload = {
        'periphId': id,
        'newName': name,
      };
      final response = await securePost(payload, 'rename_peripheral');
      if (response == null) throw Exception("Auth Error");
      if (response.statusCode != 204) {
        if (response.statusCode == 409) throw Exception("Choose a unique name!");
        throw Exception("Server Error");
      }
      getName();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  void recalibrate() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            "Recalibrate Peripheral",
            style: GoogleFonts.aBeeZee(),
          ),
          content: const Text(
            "This will take under a minute",
            textAlign: TextAlign.center,
          ),
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
                    calibrate();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text("Confirm")
                )
              ],
            )
          ],
        );
      }
    );
  }

  Future updateBlindPosition() async {
    try {
      final payload = {
        'periphId': widget.peripheralId,
        'periphNum': widget.peripheralNum,
        'deviceId': widget.deviceId,
        'newPos': _blindPosition.toInt(),
      };

      final response = await securePost(payload, 'manual_position_update');
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
          "${widget.deviceName} - $peripheralName",
          style: GoogleFonts.aBeeZee(),
        ),
        backgroundColor: Theme.of(context).primaryColorLight,
        foregroundColor: Colors.white,
      ),

      body: loaded 
      ? (calibrating
      ? RefreshIndicator(
        onRefresh: initAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "Calibrating... Check again soon."
                    ),
                  ),
                  ElevatedButton(
                    onPressed: cancelCalib,
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.red
                      ),
                    )
                  )
                ]
              )
            )
          )
        )
      )
      : (calibrated
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
                          // fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width * 0.7,
                        ),
                      ),

                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          margin: EdgeInsets.only(top: MediaQuery.of(context).size.width * 0.05),
                          height: MediaQuery.of(context).size.width * 0.68,
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(10, (index) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: _blindPosition < 5 ? 
                                  5.4 * (5 - _blindPosition)
                                  : 5.4 * (_blindPosition - 5),
                                width: MediaQuery.of(context).size.width * 0.65, // example
                                color: const Color.fromARGB(255, 121, 85, 72),
                              );
                            }),
                          ),
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
                              updateBlindPosition();
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
              lastSetMessage
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SchedulesScreen(peripheralId: widget.peripheralId, periphName: peripheralName,
                    deviceId: widget.deviceId, peripheralNum: widget.peripheralNum, deviceName: widget.deviceName,)
                  )
                );
              },
              child: Text(
                "Set Schedules"
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
                  "Peripheral Not Calibrated"
                ),
              ),
              ElevatedButton(
                onPressed: calibrate,
                child: const Text("Calibrate")
              )
            ],
          )
        )
      )))
      : BlindmasterProgressIndicator(),
      floatingActionButton: Container(
        padding: EdgeInsets.all(25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: "rename",
              tooltip: "Rename Peripheral",
              onPressed: rename,
              foregroundColor: Theme.of(context).highlightColor,
              backgroundColor: Theme.of(context).primaryColorDark,
              child: Icon(Icons.drive_file_rename_outline_sharp),
            ),
            FloatingActionButton(
              heroTag: "recalibrate",
              tooltip: "Recalibrate Peripheral",
              onPressed: recalibrate,
              foregroundColor: Theme.of(context).highlightColor,
              backgroundColor: Theme.of(context).primaryColorDark,
              child: Icon(Icons.swap_vert),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}